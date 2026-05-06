--!optimize 2
-- This file is part of the Satset networking library and is licensed under MIT License; see LICENSE.txt for details
-- SchemaCompiler — transforms a schema dictionary into a deterministic ordered structure.

local Types = require("../Types")

-- [ Types ]

export type FieldDef = {
	name: string,
	type: Types.Type<any>,
	offset: number, -- Byte offset in the state buffer (only for fixed-size schemas)
	index: number, -- 0-based field index used for bitmask operations
}

export type CompiledSchema = {
	fields: { FieldDef },
	fixedSize: number?, -- nil if any field is variable-sized
	fieldCount: number,
	fieldsByName: { [string]: FieldDef }, -- O(1) lookup for runtime access
	encoder: ((b: buffer, offset: number, data: { [string]: any }) -> ())?, -- compiled fast-path encoder
	decoder: ((b: buffer, offset: number, callback: (...any) -> ()) -> ())?, -- zero-allocation callback decoder
}

local SchemaCompiler = {}

-- [ Private ]

--[[
	Generates a specialized encoder closure for fixed-size schemas.
	
	We use direct builtin calls to ensure the Luau compiler can apply its default 
	Global Import and FASTCALL optimizations. This avoids the overhead of 
	manual localization which can sometimes hinder these built-in VM paths.
]]
local function buildFixedEncoder(fields: { FieldDef }): (b: buffer, offset: number, data: { [string]: any }) -> ()
	local count = #fields

	if count == 1 then
		local f1 = fields[1]
		local name1, write1, off1 = f1.name, f1.type.write, f1.offset
		return function(b: buffer, offset: number, data: { [string]: any })
			write1(b, offset + off1, data[name1])
		end
	elseif count == 2 then
		local f1, f2 = fields[1], fields[2]
		local name1, write1, off1 = f1.name, f1.type.write, f1.offset
		local name2, write2, off2 = f2.name, f2.type.write, f2.offset
		return function(b: buffer, offset: number, data: { [string]: any })
			write1(b, offset + off1, data[name1])
			write2(b, offset + off2, data[name2])
		end
	elseif count == 3 then
		local f1, f2, f3 = fields[1], fields[2], fields[3]
		local name1, write1, off1 = f1.name, f1.type.write, f1.offset
		local name2, write2, off2 = f2.name, f2.type.write, f2.offset
		local name3, write3, off3 = f3.name, f3.type.write, f3.offset
		return function(b: buffer, offset: number, data: { [string]: any })
			write1(b, offset + off1, data[name1])
			write2(b, offset + off2, data[name2])
			write3(b, offset + off3, data[name3])
		end
	end

	local names = table.create(count)
	local writes = table.create(count)
	local offsets = table.create(count)
	for i, field in fields do
		names[i] = field.name
		writes[i] = field.type.write
		offsets[i] = field.offset
	end

	return function(b: buffer, offset: number, data: { [string]: any })
		for i = 1, count do
			writes[i](b, offset + offsets[i], data[names[i]])
		end
	end
end

--[[
	Generates a specialized zero-allocation decoder.
	
	Instead of returning a table (allocation), this passes raw values 
	directly to the provided callback.
]]
local function buildFixedDecoder(fields: { FieldDef }): (b: buffer, offset: number, callback: (...any) -> ()) -> ()
	local count = #fields

	if count == 1 then
		local f1 = fields[1]
		local read1, off1 = f1.type.read, f1.offset
		return function(b: buffer, offset: number, callback: (...any) -> ())
			callback(read1(b, offset + off1))
		end
	elseif count == 2 then
		local f1, f2 = fields[1], fields[2]
		local read1, off1 = f1.type.read, f1.offset
		local read2, off2 = f2.type.read, f2.offset
		return function(b: buffer, offset: number, callback: (...any) -> ())
			callback(read1(b, offset + off1), read2(b, offset + off2))
		end
	elseif count == 3 then
		local f1, f2, f3 = fields[1], fields[2], fields[3]
		local read1, off1 = f1.type.read, f1.offset
		local read2, off2 = f2.type.read, f2.offset
		local read3, off3 = f3.type.read, f3.offset
		return function(b: buffer, offset: number, callback: (...any) -> ())
			callback(read1(b, offset + off1), read2(b, offset + off2), read3(b, offset + off3))
		end
	end

	local reads = table.create(count)
	local offsets = table.create(count)
	for i, field in fields do
		reads[i] = field.type.read
		offsets[i] = field.offset
	end

	return function(b: buffer, offset: number, callback: (...any) -> ())
		-- Note: varargs allocation for 4+ fields is a VM limitation,
		-- but for the most common 1-3 field packets, this is 100% zero-alloc.
		callback(
			reads[1](b, offset + offsets[1]),
			reads[2](b, offset + offsets[2]),
			reads[3](b, offset + offsets[3]),
			reads[4](b, offset + offsets[4])
		)
	end
end

-- [ Public API ]

function SchemaCompiler.compile(schema: { [string]: Types.Type<any> }): CompiledSchema
	local fields: { FieldDef } = {}
	local isFixedSize = true
	local totalFixed = 0

	for name, typeInfo in schema do
		table.insert(fields, {
			name = name,
			type = typeInfo,
			offset = 0,
			index = 0,
		})
	end

	table.sort(fields, function(a, b)
		return a.name < b.name
	end)

	local fieldsByName: { [string]: FieldDef } = {}
	local currentOffset = 0

	for i, field in fields do
		field.index = i - 1

		if not field.type.isFixed then
			isFixedSize = false
		else
			field.offset = currentOffset
			currentOffset += field.type.size
			totalFixed += field.type.size
		end

		fieldsByName[field.name] = field
	end

	local encoder: ((b: buffer, offset: number, data: { [string]: any }) -> ())? = nil
	local decoder: ((b: buffer, offset: number, callback: (...any) -> ()) -> ())? = nil

	if isFixedSize then
		encoder = buildFixedEncoder(fields)
		decoder = buildFixedDecoder(fields)
	end

	return {
		fields = fields,
		fixedSize = if isFixedSize then totalFixed else nil,
		fieldCount = #fields,
		fieldsByName = fieldsByName,
		encoder = encoder,
		decoder = decoder,
	}
end

return SchemaCompiler
