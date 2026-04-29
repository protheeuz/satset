-- 100 Vector3 positions. Tests float serialization throughput.
local Array = {}
for _ = 1, 100 do
	table.insert(Array, Vector3.new(math.random() * 2048 - 1024, math.random() * 512, math.random() * 2048 - 1024))
end
return Array
