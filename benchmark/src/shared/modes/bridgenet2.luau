-- BridgeNet2 benchmark mode (v1.0.0 API).
-- BridgeNet2 uses ReferenceBridge with string identifiers.
local BridgeNet2 = require(game:GetService("ReplicatedStorage").DevPackages.BridgeNet2)

local Benches = require(game:GetService("ReplicatedStorage").Shared.benches)

local Events = {}

for Name in Benches do
	Events[Name] = BridgeNet2.ReferenceBridge("BridgeBench_" .. Name)
end

return Events
