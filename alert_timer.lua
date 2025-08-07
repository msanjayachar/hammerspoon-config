-- ~/.hammerspoon/timers/alert_timer.lua
---@diagnostic disable-next-line: undefined-global
local hs = hs

local module = {}

local timers = {}

local counter = 0

function module.start()
	timers.everyThreeSeconds = hs.timer.doEvery(1800, function()
		counter = counter + 1
		local totalMinutes = counter * 30
		local hours = math.floor(totalMinutes / 60)
		-- local totalSeconds = counter * 3
		local minutes = totalMinutes % 60

		-- local msg = string.format("%d second(s) passed", totalSeconds)
		local msg = ""
		if hours > 0 and minutes > 0 then
			msg = string.format("%d hr %d min passed", hours, minutes)
		elseif hours > 0 then
			msg = string.format("%d hr passed", hours)
		else
			msg = string.format("%d min passed", minutes)
		end
		hs.alert.show("Half an hour just went by", 1)
		hs.alert.show(msg, 2)
	end)
end

return module
