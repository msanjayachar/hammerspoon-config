-- ~/.hammerspoon/appSwitcher.lua

local eventtap = hs.eventtap
local eventTypes = eventtap.event.types
local application = hs.application

local appBindings = {
	br = "Brave Browser",
	ch = "Google Chrome",
	vs = "Visual Studio Code",
	ff = "Firefox",
	tt = "iTerm",
}

local sequence = ""
local isCapsActive = false

local function reset()
	sequence = ""
	isCapsActive = false
end

local function launchApp()
	local appName = appBindings[sequence]
	if appName then
		application.launchOrFocus(appName)
	end
	reset()
end

local function handler(event)
	local code = event:getKeyCode()
	local flags = event:getFlags()
	local char = event:getCharacters()

	hs.alert("hello from appSwitcher")

	-- CapsLock key down
	if code == 57 and event:getType() == eventTypes.keyDown then
		isCapsActive = true
		return true -- block CapsLock input
	end

	-- if CapsLock is active, intercept next 2 keys
	if isCapsActive and event:getType() == eventTypes.keyDown then
		if char:match("^%a$") then
			sequence = sequence .. char:lower()
			if #sequence == 2 then
				launchApp()
			end
		end
		return true -- block input
	end

	return false
end

local tap = eventtap.new({ eventTypes.keyDown }, handler)
tap:start()
