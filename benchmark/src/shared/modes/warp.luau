-- Warp benchmark mode (v1.0.14 API).
-- Warp uses string identifiers. Server/Client are separate constructors.
local RunService = game:GetService("RunService")
local Warp = require(game:GetService("ReplicatedStorage").DevPackages.Warp)

local Benches = require(game:GetService("ReplicatedStorage").Shared.benches)

local IsServer = RunService:IsServer()
local Events = {}

for Name in Benches do
	local eventName = "WarpBench_" .. Name
	if IsServer then
		Events[Name] = Warp.Server(eventName)
	else
		Events[Name] = Warp.Client(eventName)
	end
end

return Events
