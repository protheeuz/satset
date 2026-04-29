-- 100 entities, each with 6 u8 fields. Simulates a typical NPC/player sync payload.
local Array = {}
for _ = 1, 100 do
	table.insert(Array, {
		id = math.random(1, 255),
		x = math.random(1, 255),
		y = math.random(1, 255),
		z = math.random(1, 255),
		orientation = math.random(1, 255),
		animation = math.random(1, 255),
	})
end
return Array
