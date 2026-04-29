-- 1000 boolean values. Tests minimal-payload throughput and packing efficiency.
local Array = {}
for _ = 1, 1000 do
	table.insert(Array, math.random() > 0.5)
end
return Array
