-- Realistic game packet: player state update with mixed types.
-- Simulates what a typical game sends per player per frame.
return {
	id = math.random(1, 255),
	health = math.random(0, 100),
	position = Vector3.new(math.random() * 2048 - 1024, math.random() * 512, math.random() * 2048 - 1024),
	velocity = Vector3.new(math.random() * 100 - 50, math.random() * 100 - 50, math.random() * 100 - 50),
	name = "Player_" .. tostring(math.random(1000, 9999)),
	isRunning = math.random() > 0.5,
	animation = math.random(1, 255),
	team = math.random(1, 4),
}
