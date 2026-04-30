-- Benchmark server. Receives data from all modes and validates correctness.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Satset = require(ReplicatedStorage.DevPackages.Satset)
Satset.start()

local Benches = require(ReplicatedStorage.Shared.benches)
local Modes = require(ReplicatedStorage.Shared.modes)

local function compareTables(a: any, b: any): boolean
	if a == b then
		return true
	end
	if type(a) ~= type(b) then
		return false
	end
	if type(a) ~= "table" then
		return false
	end

	local keys = {}
	for key, value in a do
		local other = b[key]
		if other == nil or not compareTables(value, other) then
			return false
		end
		keys[key] = true
	end

	for key in b do
		if not keys[key] then
			return false
		end
	end

	return true
end

local function compareValues(a: any, b: any): boolean
	if type(a) == "table" or type(b) == "table" then
		return compareTables(a, b)
	end
	return a == b
end

-- Track received counts per bench per tool for loss calculation.
local received = {}
for name, data in Benches do
	local benchReceived = {}
	received[name] = benchReceived

	local function onReceive(tool: string)
		benchReceived[tool] = 0

		return function(player, value)
			benchReceived[tool] += 1
			if benchReceived[tool] > 1 then
				return
			end

			-- ByteNet swaps argument order.
			if tool == "bytenet" then
				player, value = value, player
			end

			if not compareValues(data, value) then
				warn("Received incorrect data with " .. tool .. " for " .. name)
			else
				print("> " .. tool .. " passed " .. name .. " validation!")
			end
		end
	end

	for tool, events in Modes do
		local event = events[name]
		local callback = onReceive(tool)

		if tool == "roblox" or tool == "packet" then
			-- Roblox and Suphi-Packet use .OnServerEvent
			event.OnServerEvent:Connect(callback)
		elseif tool == "bridgenet2" or tool == "warp" then
			-- BridgeNet2 and Warp use standard :Connect()
			event:Connect(callback)
		elseif event.listen then
			-- Satset and ByteNet use .listen()
			event.listen(callback)
		end
	end
end

-- Client pulls received counts to compute packet loss.
ReplicatedStorage.Shared.GetRecieved.OnServerInvoke = function()
	return received
end

-- Client sends JSON results, server writes them out.
ReplicatedStorage.Shared.Generate.OnServerEvent:Connect(function(_player, json)
	local output = Instance.new("StringValue")
	output.Name = "Result"
	output.Value = json
	output.Parent = game
	print("Generated results")
end)
