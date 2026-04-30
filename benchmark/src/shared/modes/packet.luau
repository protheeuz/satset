-- Suphi Packet benchmark mode.
-- Wraps each Packet object so `fire` is a self-bound closure,
-- matching the benchmark harness convention (event.fire or event.Fire).
local Packet = require(game:GetService("ReplicatedStorage").SuphiPacket)

local function wrap(pkt)
	return {
		fire = function(data) pkt:Fire(data) end,
		Fire = function(data) pkt:Fire(data) end,
		OnServerEvent = pkt.OnServerEvent,
	}
end

return {
	Booleans = wrap(Packet("Booleans", {Packet.Boolean8})),
	Entities = wrap(Packet("Entities", {
		{
			id = Packet.NumberU8,
			x = Packet.NumberU8,
			y = Packet.NumberU8,
			z = Packet.NumberU8,
			orientation = Packet.NumberU8,
			animation = Packet.NumberU8,
		}
	})),
	Vectors = wrap(Packet("Vectors", {Packet.Vector3F32})),
	Strings = wrap(Packet("Strings", {Packet.String})),
	Mixed = wrap(Packet("Mixed", {
		id = Packet.NumberU8,
		health = Packet.NumberU8,
		position = Packet.Vector3F32,
		velocity = Packet.Vector3F32,
		name = Packet.String,
		isRunning = Packet.Boolean8,
		animation = Packet.NumberU8,
		team = Packet.NumberU8,
	})),
	SingleValue = wrap(Packet("SingleValue", Packet.NumberU8)),
}
