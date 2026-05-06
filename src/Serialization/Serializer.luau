--!native
--!optimize 2
-- This file is part of the Satset networking library and is licensed under MIT License; see LICENSE.txt for details
-- Serializer — handles the actual encoding and decoding of data into binary buffers.

local Sanitizer = require("./Sanitizer")
local SchemaCompiler = require("./SchemaCompiler")

local Serializer = {}

-- [ Public API ]

--[[
	Calculates how many bytes are needed to encode a given data table.
	
	For fixed-size schemas, this is a constant time operation. For 
	variable-size schemas (like those with strings or arrays), we 
	calculate the size on the fly based on the actual values.
]]
function Serializer.calculateSize(compiled: SchemaCompiler.CompiledSchema, data: { [string]: any }): number
	if compiled.fixedSize then
		return compiled.fixedSize
	end

	local size = 0
	for _, field in compiled.fields do
		size += field.type.getSize(data[field.name])
	end
	return size
end

--[[
	Encodes a data table into a fresh buffer.
]]
function Serializer.encode(compiled: SchemaCompiler.CompiledSchema, data: { [string]: any }): buffer
	local size = Serializer.calculateSize(compiled, data)
	local b = buffer.create(size)
	Serializer.encodeInto(compiled, data, b, 0)
	return b
end

--[[
	Encodes data directly into an existing buffer at the specified offset.
	
	This is our zero-allocation hot path. We reuse buffers as much as 
	possible to avoid GC pressure.
]]
function Serializer.encodeInto(
	compiled: SchemaCompiler.CompiledSchema,
	data: { [string]: any },
	b: buffer,
	offset: number
): number
	-- Compiled encoder fast-path: bypasses the field loop entirely.
	if compiled.encoder then
		compiled.encoder(b, offset, data)
		return compiled.fixedSize :: number
	end

	local cursor = offset
	for _, field in compiled.fields do
		local value = data[field.name]
		field.type.write(b, cursor, value)
		cursor += field.type.getSize(value)
	end
	return cursor - offset
end

--[[
	Decodes data from a buffer at the specified offset.
	
	Includes security checks for buffer overflows and malformed float 
	values (NaN/Infinity). Returns nil if the payload is suspicious.
	
	If a callback is provided, it will be called with the decoded values 
	as arguments (Zero-Allocation path).
]]
function Serializer.decodeFrom(
	compiled: SchemaCompiler.CompiledSchema,
	b: buffer,
	offset: number,
	callback: ((...any) -> ())?
): ({ [string]: any }?, number)
	local bufLen = buffer.len(b)

	-- Bulk bounds check for fixed-size schemas.
	if compiled.fixedSize and (offset + compiled.fixedSize) > bufLen then
		return nil, 0
	end

	-- Compiled decoder fast-path: single bounds check, then direct read.
	if compiled.decoder then
		if callback then
			compiled.decoder(b, offset, callback)
			return nil, compiled.fixedSize :: number
		else
			-- Fallback to table allocation if no callback is provided.
			local data = {}
			local function fill(...)
				local args = { ... }
				for i, field in compiled.fields do
					data[field.name] = args[i]
				end
			end
			compiled.decoder(b, offset, fill)
			return data, compiled.fixedSize :: number
		end
	end

	local data = if callback then nil else {}
	local cursor = offset
	local decodedValues = if callback then table.create(compiled.fieldCount) else nil

	for i, field in compiled.fields do
		if not Sanitizer.checkBounds(b, cursor, field.type.size) then
			return nil, 0
		end

		local val = field.type.read(b, cursor)

		if callback and decodedValues then
			decodedValues[i] = val
		elseif data then
			data[field.name] = val
		end

		cursor += field.type.getSize(val)
	end

	if callback and decodedValues then
		callback(table.unpack(decodedValues))
		return nil, cursor - offset
	end

	return data, cursor - offset
end

--[[
	Convenience wrapper for decoding a full buffer from the start.
]]
function Serializer.decode(compiled: SchemaCompiler.CompiledSchema, b: buffer): { [string]: any }?
	local data, _ = Serializer.decodeFrom(compiled, b, 0)
	return data
end

return Serializer
