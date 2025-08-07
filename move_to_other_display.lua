---@diagnostic disable-next-line: undefined-global
local hs = hs

local M = {}

function M.moveWindowToOtherDisplay()
	local win = hs.window.focusedWindow()
	if not win then
		return
	end

	local currentScreen = win:screen()
	local allScreens = hs.screen.allScreens()

	if #allScreens ~= 2 then
		hs.alert.show("Requires exactly 2 displays")
		return
	end

	local otherScreen = (allScreens[1] == currentScreen) and allScreens[2] or allScreens[1]
	win:moveToScreen(otherScreen, false, true)
end

return M
