-- Satset benchmark mode.
local RunService = game:GetService("RunService")
local Satset = require(game:GetService("ReplicatedStorage").Packages.Satset)
local Types = Satset.Types

-- We don't call Satset.start() here anymore.
-- It should be called by the main Server/Client runners.

-- Entity struct type (6 x u8, fixed 6 bytes)
local EntityType = {
	read = function(b: buffer, cursor: number)
		return {
			id = buffer.readu8(b, cursor),
			x = buffer.readu8(b, cursor + 1),
			y = buffer.readu8(b, cursor + 2),
			z = buffer.readu8(b, cursor + 3),
			orientation = buffer.readu8(b, cursor + 4),
			animation = buffer.readu8(b, cursor + 5),
		}
	end,
	write = function(b: buffer, cursor: number, value: any)
		buffer.writeu8(b, cursor, value.id)
		buffer.writeu8(b, cursor + 1, value.x)
		buffer.writeu8(b, cursor + 2, value.y)
		buffer.writeu8(b, cursor + 3, value.z)
		buffer.writeu8(b, cursor + 4, value.orientation)
		buffer.writeu8(b, cursor + 5, value.animation)
	end,
	size = 6,
	getSize = function()
		return 6
	end,
	isFixed = true,
} :: any

local Packets = {
	Booleans = Satset.definePacket({
		name = "SatsetBenchBooleans",
		schema = { value = Types.array(Types.bool) },
		reliable = true,
	}),
	Entities = Satset.definePacket({
		name = "SatsetBenchEntities",
		schema = { value = Types.array(EntityType) },
		reliable = true,
	}),
	Vectors = Satset.definePacket({
		name = "SatsetBenchVectors",
		schema = { value = Types.array(Types.Vector3) },
		reliable = true,
	}),
	Strings = Satset.definePacket({
		name = "SatsetBenchStrings",
		schema = { value = Types.array(Types.string8) },
		reliable = true,
	}),
	Mixed = Satset.definePacket({
		name = "SatsetBenchMixed",
		schema = {
			id = Types.u8,
			health = Types.u8,
			position = Types.Vector3,
			velocity = Types.Vector3,
			name = Types.string8,
			isRunning = Types.bool,
			animation = Types.u8,
			team = Types.u8,
		},
		reliable = true,
	}),
	SingleValue = Satset.definePacket({
		name = "SatsetBenchSingleValue",
		schema = { value = Types.u8 },
		reliable = true,
	}),
}

-- Wrap with common fire/listen interface for the benchmark runner.
local Wrapped = {}
for name, packet: any in Packets do
	Wrapped[name] = {
		fire = function(data: any)
			if RunService:IsClient() then
				local isWrapped = (type(data) == "table" and data[1] ~= nil) or type(data) == "number"
				if isWrapped then
					packet:fireServer({ value = data })
				else
					packet:fireServer(data)
				end
			end
		end,
		listen = function(callback: any)
			packet:listen(function(decoded, sender)
				local val = decoded.value or decoded
				callback(sender, val)
			end)
		end,
	}
end

return Wrapped
