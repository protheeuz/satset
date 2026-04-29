-- Native Roblox baseline. One RemoteEvent per bench, no serialization.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Benches = require(ReplicatedStorage.Shared.benches)

local Events = {}
local IsServer = RunService:IsServer()

for Name in Benches do
	local Event: RemoteEvent
	if IsServer then
		Event = Instance.new("RemoteEvent")
		Event.Name = "RobloxBench_" .. Name
		Event.Parent = ReplicatedStorage
	else
		Event = ReplicatedStorage:WaitForChild("RobloxBench_" .. Name)
	end
	Events[Name] = Event
end

return Events
