-- ~/.hammerspoon/timers/alert_timer.lua
---@diagnostic disable-next-line: undefined-global
local hs = hs

local module = {}

function module.start()
	hs.timer.doEvery(60, function()
		hs.alert.show("⏰ 1 minute just went by!")
	end)

	-- hs.timer.doEvery(1800, function()
	-- 	hs.alert.show("⏰ 30 minutes just went by!")
	-- end)
end

return module
