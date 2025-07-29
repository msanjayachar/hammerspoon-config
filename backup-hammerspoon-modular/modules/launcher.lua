-- modules/launcher.lua
local hs = hs
local launcher = {}

local inputBuffer, lastKeyTime = "", 0
local timeout = 2
local leaderActive, leaderTimeoutSecond = false, 2.0
local leaderTimer = nil

local sequence = ""
local inLauncherMode = false
local launcherTimer = nil
local launcherTimeout = 1.0

local appShortcuts = {
  br = "Brave Browser",
  ch = "Google Chrome",
  vs = "Visual Studio Code",
  it = "ITerm",
  ds = "Discord",
}

local keyInterceptor = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
  if not inLauncherMode then return false end
  local key = event:getCharacters():lower()
  if #key ~= 1 then return true end
  sequence = sequence .. key
  if #sequence == 2 then
    local app = appShortcuts[sequence]
    if app then hs.application.launchOrFocus(app) end
    launcher.exitLauncherMode()
  else
    launcher.resetLauncherTimer()
  end
  return true
end)

local capsWatcher = hs.eventtap.new({ hs.eventtap.event.types.flagsChanged }, function(event)
  if event:getKeyCode() == hs.keycodes.map["capslock"] then
    if not inLauncherMode then launcher.enterLauncherMode() end
  end
  return false
end)

function launcher.enterLauncherMode()
  inLauncherMode = true
  sequence = ""
  keyInterceptor:start()
  launcher.resetLauncherTimer()
  hs.alert.show("Launcher Mode")
end

function launcher.exitLauncherMode()
  inLauncherMode = false
  sequence = ""
  keyInterceptor:stop()
  if launcherTimer then launcherTimer:stop() launcherTimer = nil end
end

function launcher.resetLauncherTimer()
  if launcherTimer then launcherTimer:stop() end
  launcherTimer = hs.timer.doAfter(launcherTimeout, function()
    launcher.exitLauncherMode()
  end)
end

capsWatcher:start()

local leaderTap = hs.eventtap.new({ hs.eventtap.event.types.flagsChanged }, function(event)
  local flags = event:getFlags()
  local keycode = event:getKeyCode()
  if keycode == hs.keycodes.map["capslock"] and not flags["capslock"] then
    leaderActive = true
    if leaderTimer then leaderTimer:stop() end
    leaderTimer = hs.timer.doAfter(leaderTimeoutSecond, function() leaderActive = false end)
    return true
  end
  return false
end)
leaderTap:start()

local appTriggers = appShortcuts
local keyTap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
  if not leaderActive then return false end
  local char = event:getCharacters()
  local currentTime = hs.timer.secondsSinceEpoch()
  if currentTime - lastKeyTime > timeout then inputBuffer = "" end
  inputBuffer = inputBuffer .. char
  lastKeyTime = currentTime
  for trigger, appName in pairs(appTriggers) do
    if inputBuffer == trigger then
      hs.application.launchOrFocus(appName)
      inputBuffer = "" leaderActive = false
      return true
    end
  end
  if #inputBuffer > 2 then inputBuffer = char end
  return false
end)
keyTap:start()

hs.timer.doEvery(60, function()
  if keyTap:isEnabled() then keyTap:stop() end
  keyTap:start()
end)

return launcher








