-- 100 short strings (8-32 chars). Tests variable-length serialization.
local CHARS = "abcdefghijklmnopqrstuvwxyz0123456789"
local Array = {}
for _ = 1, 100 do
	local len = math.random(8, 32)
	local chars = table.create(len)
	for j = 1, len do
		local idx = math.random(1, #CHARS)
		chars[j] = string.sub(CHARS, idx, idx)
	end
	table.insert(Array, table.concat(chars))
end
return Array
