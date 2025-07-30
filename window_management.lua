--- Window management module for Hammerspoon
local windowManagement = {}

---@diagnostic disable-next-line: undefined-global
local hs = hs

-- Move focused window to specific screen position
local function moveFocusedWindow(xAlign, yAlign)
	local win = hs.window.focusedWindow()
	if not win then
		return
	end
	local screen = win:screen()
	local screenFrame = screen:frame()
	local size = win:size()
	local x = screenFrame.x + (screenFrame.w - size.w) * xAlign
	local y = screenFrame.y + (screenFrame.h - size.h) * yAlign
	win:setFrame(hs.geometry.rect(x, y, size.w, size.h))
end

-- Initialize window management hotkeys
function windowManagement.init()
	-- Bottom Left (Cmd + Shift + J opens bottom left window)
	hs.hotkey.bind({ "cmd", "shift" }, "j", function()
		moveFocusedWindow(0, 1)
	end)

	-- Bottom Right (Cmd + Shift + L opens bottom right window)
	hs.hotkey.bind({ "cmd", "shift" }, "l", function()
		moveFocusedWindow(1, 1)
	end)

	-- Middle Right (Cmd + Shift + O opens middle right window)
	hs.hotkey.bind({ "cmd", "shift" }, "o", function()
		moveFocusedWindow(1, 0.5)
	end)

	-- Middle Left (Cmd + Shift + U opens middle left window)
	hs.hotkey.bind({ "cmd", "shift" }, "u", function()
		moveFocusedWindow(0, 0.5)
	end)

	-- Center (Cmd + Shift + K opens center window)
	hs.hotkey.bind({ "cmd", "shift" }, "k", function()
		moveFocusedWindow(0.5, 0.5)
	end)
end

return windowManagement
