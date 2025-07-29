-- modules/window_mover.lua
local hs = hs
local function moveFocusedWindow(xAlign, yAlign)
  local win = hs.window.focusedWindow()
  if not win then return end
  local screen = win:screen()
  local screenFrame = screen:frame()
  local width, height = 500, 600
  local x = screenFrame.x + (screenFrame.w - width) * xAlign
  local y = screenFrame.y + (screenFrame.h - height) * yAlign
  win:setFrame(hs.geometry.rect(x, y, width, height))
end

local function bindMoverHotkeys()
  hs.hotkey.bind({ "cmd", "shift" }, "j", function() moveFocusedWindow(0, 1) end)
  hs.hotkey.bind({ "cmd", "shift" }, "l", function() moveFocusedWindow(1, 1) end)
  hs.hotkey.bind({ "cmd", "shift" }, "o", function() moveFocusedWindow(1, 0.5) end)
  hs.hotkey.bind({ "cmd", "shift" }, "u", function() moveFocusedWindow(0, 0.5) end)
  hs.hotkey.bind({ "cmd", "shift" }, "k", function() moveFocusedWindow(0.5, 0.5) end)
end

bindMoverHotkeys()
return {}

