-- modules/cursor_focus.lua
local hs = hs
local function focusAppAndMoveCursor(bundleId, position)
  local app = hs.application.get(bundleId)
  if app then
    app:activate()
    hs.timer.doAfter(0.3, function()
      local win = app:mainWindow()
      if win and win:isStandard() and win:isVisible() and win:isFocused() then
        hs.mouse.absolutePosition(position)
      end
    end)
  end
end
return { focusAppAndMoveCursor = focusAppAndMoveCursor }
