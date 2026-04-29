-- This file is part of the Satset networking library and is licensed under MIT License; see LICENSE.txt for details
-- Types — defines all primitive and composite networking types.

-- [ Builtin Localization ]
-- We localize these for GETIMPORT and FASTCALL optimization in the Luau VM.
local readu8 = buffer.readu8
local readu16 = buffer.readu16
local readu32 = buffer.readu32
local readi8 = buffer.readi8
local readi16 = buffer.readi16
local readi32 = buffer.readi32
local readf32 = buffer.readf32
local readf64 = buffer.readf64
local writeu8 = buffer.writeu8
local writeu16 = buffer.writeu16
local writeu32 = buffer.writeu32
local writei8 = buffer.writei8
local writei16 = buffer.writei16
local writei32 = buffer.writei32
local writef32 = buffer.writef32
local writef64 = buffer.writef64
local readstring = buffer.readstring
local writestring = buffer.writestring
local clamp = math.clamp
local round = math.round
local sqrt = math.sqrt
local abs = math.abs
local max = math.max
local huge = math.huge

-- [ Types ]

export type Type<T> = {
	read: (b: buffer, cursor: number) -> T,
	write: (b: buffer, cursor: number, value: T) -> (),
	size: number,
	getSize: (value: T) -> number,
	isFixed: boolean,
}

local Types = {}

-- [ Private Logic ]

local function fixedSize(size: number)
	return function()
		return size
	end
end

-- Clamps NaN and ±Infinity to 0. Prevents malicious clients from
-- injecting poisoned floats that propagate through server arithmetic.
local function sanitizeFloat(v: number): number
	if v ~= v or v == huge or v == -huge then
		return 0
	end
	return v
end

-- [ Primitives ]

Types.u8 = {
	read = readu8,
	write = writeu8,
	size = 1,
	getSize = fixedSize(1),
	isFixed = true,
}

Types.u16 = {
	read = readu16,
	write = writeu16,
	size = 2,
	getSize = fixedSize(2),
	isFixed = true,
}

Types.u32 = {
	read = readu32,
	write = writeu32,
	size = 4,
	getSize = fixedSize(4),
	isFixed = true,
}

Types.i8 = {
	read = readi8,
	write = writei8,
	size = 1,
	getSize = fixedSize(1),
	isFixed = true,
}

Types.i16 = {
	read = readi16,
	write = writei16,
	size = 2,
	getSize = fixedSize(2),
	isFixed = true,
}

Types.i32 = {
	read = readi32,
	write = writei32,
	size = 4,
	getSize = fixedSize(4),
	isFixed = true,
}

Types.f32 = {
	read = function(b: buffer, cursor: number)
		return sanitizeFloat(readf32(b, cursor))
	end,
	write = function(b: buffer, cursor: number, value: number)
		writef32(b, cursor, sanitizeFloat(value))
	end,
	size = 4,
	getSize = fixedSize(4),
	isFixed = true,
}

Types.f64 = {
	read = function(b: buffer, cursor: number)
		return sanitizeFloat(readf64(b, cursor))
	end,
	write = function(b: buffer, cursor: number, value: number)
		writef64(b, cursor, sanitizeFloat(value))
	end,
	size = 8,
	getSize = fixedSize(8),
	isFixed = true,
}

Types.bool = {
	read = function(b: buffer, cursor: number)
		return readu8(b, cursor) ~= 0
	end,
	write = function(b: buffer, cursor: number, value: boolean)
		writeu8(b, cursor, value and 1 or 0)
	end,
	size = 1,
	getSize = fixedSize(1),
	isFixed = true,
}

Types.u4 = {
	read = function(b: buffer, cursor: number)
		return bit32.band(readu8(b, cursor), 0xF)
	end,
	write = function(b: buffer, cursor: number, value: number)
		writeu8(b, cursor, bit32.band(value, 0xF))
	end,
	size = 1,
	getSize = fixedSize(1),
	isFixed = true,
}

-- [ Variable Size Types ]

Types.string8 = {
	read = function(b: buffer, cursor: number)
		local len = readu8(b, cursor)
		return readstring(b, cursor + 1, len)
	end,
	write = function(b: buffer, cursor: number, value: string)
		local len = #value
		writeu8(b, cursor, len)
		writestring(b, cursor + 1, value, len)
	end,
	size = 1,
	getSize = function(value: string)
		return 1 + #value
	end,
	isFixed = false,
}

Types.string16 = {
	read = function(b: buffer, cursor: number)
		local len = readu16(b, cursor)
		return readstring(b, cursor + 2, len)
	end,
	write = function(b: buffer, cursor: number, value: string)
		local len = #value
		writeu16(b, cursor, len)
		writestring(b, cursor + 2, value, len)
	end,
	size = 2,
	getSize = function(value: string)
		return 2 + #value
	end,
	isFixed = false,
}

-- [ Roblox Native Types ]

Types.Vector3 = {
	read = function(b: buffer, cursor: number)
		return Vector3.new(
			sanitizeFloat(readf32(b, cursor)),
			sanitizeFloat(readf32(b, cursor + 4)),
			sanitizeFloat(readf32(b, cursor + 8))
		)
	end,
	write = function(b: buffer, cursor: number, value: Vector3)
		writef32(b, cursor, sanitizeFloat(value.X))
		writef32(b, cursor + 4, sanitizeFloat(value.Y))
		writef32(b, cursor + 8, sanitizeFloat(value.Z))
	end,
	size = 12,
	getSize = fixedSize(12),
	isFixed = true,
}

Types.Vector2 = {
	read = function(b: buffer, cursor: number)
		return Vector2.new(sanitizeFloat(readf32(b, cursor)), sanitizeFloat(readf32(b, cursor + 4)))
	end,
	write = function(b: buffer, cursor: number, value: Vector2)
		writef32(b, cursor, sanitizeFloat(value.X))
		writef32(b, cursor + 4, sanitizeFloat(value.Y))
	end,
	size = 8,
	getSize = fixedSize(8),
	isFixed = true,
}

Types.Color3 = {
	read = function(b: buffer, cursor: number)
		local r = readu8(b, cursor) / 255
		local g = readu8(b, cursor + 1) / 255
		local bl = readu8(b, cursor + 2) / 255
		return Color3.new(r, g, bl)
	end,
	write = function(b: buffer, cursor: number, value: Color3)
		writeu8(b, cursor, clamp(round(value.R * 255), 0, 255))
		writeu8(b, cursor + 1, clamp(round(value.G * 255), 0, 255))
		writeu8(b, cursor + 2, clamp(round(value.B * 255), 0, 255))
	end,
	size = 3,
	getSize = fixedSize(3),
	isFixed = true,
}

-- [ Specialized Optimization Types ]

--[[
	Vector3Quantized: compressed 6-byte Vector3.
	
	By default, this maps a 1024-stud range into 16-bit signed integers. 
	It provides ~0.03 stud precision while saving 6 bytes per position 
	compared to standard f32.
]]
function Types.Vector3Quantized(range: number?): Type<Vector3>
	local r = range or 1024
	local SCALE = 32767 / r

	return {
		read = function(b: buffer, cursor: number)
			local x = readi16(b, cursor) / SCALE
			local y = readi16(b, cursor + 2) / SCALE
			local z = readi16(b, cursor + 4) / SCALE
			return Vector3.new(x, y, z)
		end,
		write = function(b: buffer, cursor: number, value: Vector3)
			writei16(b, cursor, clamp(round(value.X * SCALE), -32767, 32767))
			writei16(b, cursor + 2, clamp(round(value.Y * SCALE), -32767, 32767))
			writei16(b, cursor + 4, clamp(round(value.Z * SCALE), -32767, 32767))
		end,
		size = 6,
		getSize = fixedSize(6),
		isFixed = true,
	}
end

--[[
	Vector2Quantized: compressed 4-byte Vector2.
	
	Same quantization approach as Vector3Quantized but for 2D coordinates.
	Provides ~0.03 stud precision at the default 1024-stud range.
]]
function Types.Vector2Quantized(range: number?): Type<Vector2>
	local r = range or 1024
	local SCALE = 32767 / r

	return {
		read = function(b: buffer, cursor: number)
			local x = readi16(b, cursor) / SCALE
			local y = readi16(b, cursor + 2) / SCALE
			return Vector2.new(x, y)
		end,
		write = function(b: buffer, cursor: number, value: Vector2)
			writei16(b, cursor, clamp(round(value.X * SCALE), -32767, 32767))
			writei16(b, cursor + 2, clamp(round(value.Y * SCALE), -32767, 32767))
		end,
		size = 4,
		getSize = fixedSize(4),
		isFixed = true,
	}
end

--[[
	CFrame: high-efficiency 18-byte CFrame.
	
	Uses "smallest-three" quaternion compression. We drop the largest 
	quaternion component and reconstruct it on the receiver side. 
	This saves 10+ bytes per CFrame with negligible precision loss.
]]
Types.CFrame = {
	read = function(b: buffer, cursor: number)
		local px = sanitizeFloat(readf32(b, cursor))
		local py = sanitizeFloat(readf32(b, cursor + 4))
		local pz = sanitizeFloat(readf32(b, cursor + 8))
		local raw_a = readi16(b, cursor + 12)
		local raw_b = readi16(b, cursor + 14)
		local raw_c = readi16(b, cursor + 16)

		local largest = bit32.band(bit32.rshift(bit32.band(raw_a, 0xFFFF), 14), 3)
		local va = bit32.band(raw_a, 0x3FFF)
		if va >= 0x2000 then
			va = va - 0x4000
		end

		local QSCALE = 0.7071067811865476 / 8191
		local a = va * QSCALE
		local b_val = raw_b / 32767 * 0.7071067811865476
		local c_val = raw_c / 32767 * 0.7071067811865476

		local d = sqrt(max(0, 1 - (a * a + b_val * b_val + c_val * c_val)))
		local qx, qy, qz, qw
		if largest == 0 then
			qw, qx, qy, qz = d, a, b_val, c_val
		elseif largest == 1 then
			qx, qw, qy, qz = d, a, b_val, c_val
		elseif largest == 2 then
			qy, qw, qx, qz = d, a, b_val, c_val
		else
			qz, qw, qx, qy = d, a, b_val, c_val
		end

		local x2, y2, z2 = qx + qx, qy + qy, qz + qz
		local xx, xy, xz = qx * x2, qx * y2, qx * z2
		local yy, yz, zz = qy * y2, qy * z2, qz * z2
		local wx, wy, wz = qw * x2, qw * y2, qw * z2

		return CFrame.new(
			px,
			py,
			pz,
			1 - (yy + zz),
			xy - wz,
			xz + wy,
			xy + wz,
			1 - (xx + zz),
			yz - wx,
			xz - wy,
			yz + wx,
			1 - (xx + yy)
		)
	end,

	write = function(b: buffer, cursor: number, value: CFrame)
		local components = { value:GetComponents() }
		writef32(b, cursor, sanitizeFloat(components[1]))
		writef32(b, cursor + 4, sanitizeFloat(components[2]))
		writef32(b, cursor + 8, sanitizeFloat(components[3]))

		local r00, r01, r02 = components[4], components[5], components[6]
		local r10, r11, r12 = components[7], components[8], components[9]
		local r20, r21, r22 = components[10], components[11], components[12]

		local trace = r00 + r11 + r22
		local qw, qx, qy, qz
		if trace > 0 then
			local s = sqrt(trace + 1) * 2
			qw, qx, qy, qz = 0.25 * s, (r21 - r12) / s, (r02 - r20) / s, (r10 - r01) / s
		elseif r00 > r11 and r00 > r22 then
			local s = sqrt(1 + r00 - r11 - r22) * 2
			qw, qx, qy, qz = (r21 - r12) / s, 0.25 * s, (r01 + r10) / s, (r02 + r20) / s
		elseif r11 > r22 then
			local s = sqrt(1 + r11 - r00 - r22) * 2
			qw, qx, qy, qz = (r02 - r20) / s, (r01 + r10) / s, 0.25 * s, (r12 + r21) / s
		else
			local s = sqrt(1 + r22 - r00 - r11) * 2
			qw, qx, qy, qz = (r10 - r01) / s, (r02 + r20) / s, (r12 + r21) / s, 0.25 * s
		end

		local mag = sqrt(qw * qw + qx * qx + qy * qy + qz * qz)
		qw, qx, qy, qz = qw / mag, qx / mag, qy / mag, qz / mag

		local abs_w, abs_x, abs_y, abs_z = abs(qw), abs(qx), abs(qy), abs(qz)
		local largest, max_val = 0, abs_w
		if abs_x > max_val then
			largest, max_val = 1, abs_x
		end
		if abs_y > max_val then
			largest, max_val = 2, abs_y
		end
		if abs_z > max_val then
			largest = 3
		end

		local vals = { qw, qx, qy, qz }
		if vals[largest + 1] < 0 then
			qw, qx, qy, qz = -qw, -qx, -qy, -qz
		end

		local a, b_val, c_val
		if largest == 0 then
			a, b_val, c_val = qx, qy, qz
		elseif largest == 1 then
			a, b_val, c_val = qw, qy, qz
		elseif largest == 2 then
			a, b_val, c_val = qw, qx, qz
		else
			a, b_val, c_val = qw, qx, qy
		end

		local QSCALE_INV = 8191 / 0.7071067811865476
		local enc_a = clamp(round(a * QSCALE_INV), -8191, 8191)
		local packed_a = bit32.bor(bit32.band(enc_a, 0x3FFF), bit32.lshift(largest, 14))

		writeu16(b, cursor + 12, packed_a)
		local QSCALE_B = 32767 / 0.7071067811865476
		writei16(b, cursor + 14, clamp(round(b_val * QSCALE_B), -32767, 32767))
		writei16(b, cursor + 16, clamp(round(c_val * QSCALE_B), -32767, 32767))
	end,
	size = 18,
	getSize = fixedSize(18),
	isFixed = true,
}

-- [ Collection Wrappers ]

function Types.optional(innerType: Type<any>): Type<any>
	return {
		read = function(b: buffer, cursor: number)
			if readu8(b, cursor) == 0 then
				return nil
			end
			return innerType.read(b, cursor + 1)
		end,
		write = function(b: buffer, cursor: number, value: any)
			if value == nil then
				writeu8(b, cursor, 0)
			else
				writeu8(b, cursor, 1)
				innerType.write(b, cursor + 1, value)
			end
		end,
		size = 1,
		getSize = function(value: any)
			return if value == nil then 1 else 1 + innerType.getSize(value)
		end,
		isFixed = false,
	}
end

function Types.array(elementType: Type<any>): Type<{ any }>
	return {
		read = function(b: buffer, cursor: number)
			local len = readu16(b, cursor)
			local arr, pos = table.create(len), cursor + 2
			for i = 1, len do
				local val = elementType.read(b, pos)
				arr[i] = val
				pos += elementType.getSize(val)
			end
			return arr
		end,
		write = function(b: buffer, cursor: number, value: { any })
			local len = #value
			writeu16(b, cursor, len)
			local pos = cursor + 2
			for i = 1, len do
				local val = value[i]
				elementType.write(b, pos, val)
				pos += elementType.getSize(val)
			end
		end,
		size = 2,
		getSize = function(value: { any })
			local total = 2
			for i = 1, #value do
				total += elementType.getSize(value[i])
			end
			return total
		end,
		isFixed = false,
	}
end

function Types.map(keyType: Type<any>, valueType: Type<any>): Type<{ [any]: any }>
	return {
		read = function(b: buffer, cursor: number)
			local count = readu16(b, cursor)
			local result, pos = {}, cursor + 2
			for _ = 1, count do
				local key = keyType.read(b, pos)
				pos += keyType.getSize(key)
				local val = valueType.read(b, pos)
				pos += valueType.getSize(val)
				result[key] = val
			end
			return result
		end,
		write = function(b: buffer, cursor: number, value: { [any]: any })
			local keys, n = {}, 0
			for k in value do
				n += 1
				keys[n] = k
			end
			table.sort(keys, function(a, b_key)
				return tostring(a) < tostring(b_key)
			end)

			writeu16(b, cursor, n)
			local pos = cursor + 2
			for i = 1, n do
				local k = keys[i]
				local v = value[k]
				keyType.write(b, pos, k)
				pos += keyType.getSize(k)
				valueType.write(b, pos, v)
				pos += valueType.getSize(v)
			end
		end,
		size = 2,
		getSize = function(value: { [any]: any })
			local total = 2
			for k, v in value do
				total += keyType.getSize(k) + valueType.getSize(v)
			end
			return total
		end,
		isFixed = false,
	}
end

function Types.enum(values: { string }): Type<string>
	local toIndex, toValue = {}, {}
	for i, v in values do
		toIndex[v], toValue[i - 1] = i - 1, v
	end

	return {
		read = function(b: buffer, cursor: number)
			local idx = readu8(b, cursor)
			return toValue[idx] or values[1]
		end,
		write = function(b: buffer, cursor: number, value: string)
			writeu8(b, cursor, toIndex[value] or 0)
		end,
		size = 1,
		getSize = fixedSize(1),
		isFixed = true,
	}
end

return Types
