-- modules/scroll.lua
local hs = hs
local scrollAmount = 5
local scrollUp = hs.hotkey.new({ "cmd" }, "u", function()
  hs.eventtap.event.newScrollEvent({ 0, scrollAmount }, {}, "line"):post()
end, nil, function()
  hs.eventtap.event.newScrollEvent({ 0, scrollAmount }, {}, "line"):post()
end)

local scrollDown = hs.hotkey.new({ "cmd" }, "o", function()
  hs.eventtap.event.newScrollEvent({ 0, -scrollAmount }, {}, "line"):post()
end, nil, function()
  hs.eventtap.event.newScrollEvent({ 0, -scrollAmount }, {}, "line"):post()
end)

scrollUp:enable()
scrollDown:enable()
return {}
