-- Mode loader. Each mode wraps a networking library with a common interface.
-- Disabled modes are skipped (set to true to disable).
local DISABLED_MODES = {}

local Modes = {}
for _, Mode in script:GetChildren() do
	if DISABLED_MODES[Mode.Name] then
		continue
	end
	Modes[Mode.Name] = require(Mode)
end

return Modes
