-- ByteNet benchmark mode (v0.4.6 API).
local ByteNet = require(game:GetService("ReplicatedStorage").DevPackages.ByteNet)

-- ByteNet 0.4.6 requires the schema to be in the 'value' field.
return ByteNet.defineNamespace("Benchmark", function()
	return {
		Booleans = ByteNet.definePacket({
			value = ByteNet.array(ByteNet.bool),
		}),
		Entities = ByteNet.definePacket({
			value = ByteNet.array(ByteNet.struct({
				id = ByteNet.uint8,
				x = ByteNet.uint8,
				y = ByteNet.uint8,
				z = ByteNet.uint8,
				orientation = ByteNet.uint8,
				animation = ByteNet.uint8,
			})),
		}),
		Vectors = ByteNet.definePacket({
			value = ByteNet.array(ByteNet.vec3),
		}),
		Strings = ByteNet.definePacket({
			value = ByteNet.array(ByteNet.string),
		}),
		Mixed = ByteNet.definePacket({
			value = ByteNet.struct({
				id = ByteNet.uint8,
				health = ByteNet.uint8,
				position = ByteNet.vec3,
				velocity = ByteNet.vec3,
				name = ByteNet.string,
				isRunning = ByteNet.bool,
				animation = ByteNet.uint8,
				team = ByteNet.uint8,
			}),
		}),
		SingleValue = ByteNet.definePacket({
			value = ByteNet.uint8,
		}),
	}
end)
