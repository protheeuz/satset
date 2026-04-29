-- This file is part of the Satset networking library and is licensed under MIT License; see LICENSE.txt for details
-- Benchmark bench loader. Resets random seed for deterministic data across server/client.

local Benches = {}
for _, Bench in script:GetChildren() do
	math.randomseed(0)
	Benches[Bench.Name] = require(Bench)
end
return Benches
