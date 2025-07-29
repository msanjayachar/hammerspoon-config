-- modules/keybindings.lua
local hs = hs
local sequenceTimeout = 0.15
local sequenceTimeoutTwo = 0.30
local isShiftPressed = function()
  return hs.eventtap.checkKeyboardModifiers()["shift"]
end

local sequence_last_cmd_j_press_time = 0
local sequence_last_cmd_l_press_time = 0
local sequence_last_cmd_slash_press_time = 0
local sequence_last_cmd_period_press_time = 0

local hotkeyGroups = {}

-- (Hotkey logic omitted here for brevity; should be separated into functions)
-- Return hotkeyGroups or setup function

return {}
