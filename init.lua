---@diagnostic disable-next-line: undefined-global
local hs = hs

local sequenceTimeout = 0.15 -- Time in seconds for the second tap to register (250 milliseconds)
local sequenceTimeoutTwo = 0.30

-- Global state for tracking sequences (initialized to 0)
local sequence_last_cmd_j_press_time = 0
local sequence_last_cmd_l_press_time = 0
local sequence_last_cmd_slash_press_time = 0 -- For Home (cmd + /)
local sequence_last_cmd_period_press_time = 0 -- For End (cmd + .)

local inputBuffer = ""
local lastKeyTime = 0
-- If you type slowly, inputBuffer resets. You might want to increase this to 1.5 or even 2.0
-- Make the typing of "br" more forgiving
local timeout = 2
local leaderActive = false
local leaderTimeoutSecond = 2.0
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
	if not inLauncherMode then
		return false
	end

	local key = event:getCharacters():lower()
	if #key ~= 1 then
		return true
	end -- Ignore non-character keys

	sequence = sequence .. key

	if #sequence == 2 then
		local app = appShortcuts[sequence]
		if app then
			hs.application.launchOrFocus(app)
		end
		exitLauncherMode()
	else
		resetLauncherTimer()
	end

	return true -- Suppress key from reaching apps
end)

-- Detect Caps Lock tap
local capsWatcher = hs.eventtap.new({ hs.eventtap.event.types.flagsChanged }, function(event)
	if event:getKeyCode() == hs.keycodes.map["capslock"] then
		if not inLauncherMode then
			enterLauncherMode()
		end
	end
	return false
end)

function enterLauncherMode()
	inLauncherMode = true
	sequence = ""
	keyInterceptor:start()
	resetLauncherTimer()
	hs.alert.show("Launcher Mode")
end

function exitLauncherMode()
	inLauncherMode = false
	sequence = ""
	keyInterceptor:stop()
	if launcherTimer then
		launcherTimer:stop()
		launcherTimer = nil
	end
end

function resetLauncherTimer()
	if launcherTimer then
		launcherTimer:stop()
	end
	launcherTimer = hs.timer.doAfter(launcherTimeout, function()
		exitLauncherMode()
	end)
end

capsWatcher:start()

local leaderTap = hs.eventtap.new({ hs.eventtap.event.types.flagsChanged }, function(event)
	local flags = event:getFlags()
	local keycode = event:getKeyCode()

	if keycode == hs.keycodes.map["capslock"] and not flags["capslock"] then
		-- Caps Lock released
		leaderActive = true

		if leaderTimer then
			leaderTimer:stop()
		end

		leaderTimer = hs.timer.doAfter(leaderTimeoutSecond, function()
			leaderActive = false
		end)

		return true
	end

	return false
end)

leaderTap:start()

-- Function to active or launch an app
function activateApp(appName)
	hs.application.launchOrFocus(appName)
end

local appTriggers = {
	ch = "Google Chrome",
	br = "Brave Browser",
	vs = "Visual Studio Code",
	it = "iterm",
	ds = "discord",
}

local keyTap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
	if not leaderActive then
		return false
	end

	local char = event:getCharacters()
	local currentTime = hs.timer.secondsSinceEpoch()

	-- Reset buffer if too much time has pressed
	if currentTime - lastKeyTime > timeout then
		inputBuffer = ""
	end

	-- Append the new character to the buffer
	inputBuffer = inputBuffer .. char
	lastKeyTime = currentTime

	-- Check if the buffer matches any trigger
	for trigger, appName in pairs(appTriggers) do
		if inputBuffer == trigger then
			activateApp(appName)
			inputBuffer = "" -- Reset buffer after match
			leaderActive = false
			return true
		end
	end

	-- Reset buffer if it gets too long
	if #inputBuffer > 2 then
		inputBuffer = char
	end

	return false
end)

-- Start the event tap
keyTap:start()

-- Helper to check if Shift is pressed
local function isShiftPressed()
	return hs.eventtap.checkKeyboardModifiers()["shift"]
end

KEYMAP = {
	-- Original mappings for directional movement (excluding J and L with Cmd/Shift)
	{ "leftCmd", "i", nil, "up" },
	{ "leftCmd+leftShift", "i", "cmd+shift", "up" },
	{ "leftCmd+rightShift", "i", "shift", "up" },
	{ "leftCmd+leftShift+rightShift", "i", "shift", "up" },

	-- RESTORED: Cmd + H now for LINE left (was word left)
	{ "leftCmd", "h", "cmd", "left" },
	{ "leftCmd+leftShift", "h", "cmd+shift", "left" }, -- Selection for line left

	-- Cmd + K remains for down
	{ "leftCmd", "k", nil, "down" },
	{ "leftCmd+leftShift", "k", "cmd+shift", "down" },
	{ "leftCmd+rightShift", "k", "shift", "down" },
	{ "leftCmd+leftShift+rightShift", "k", "shift", "down" },

	-- RESTORED: Cmd + ; now for LINE right (was word right)
	{ "leftCmd", ";", "cmd", "right" },
	{ "leftCmd+leftShift", ";", "cmd+shift", "right" }, -- Selection for line right

	-- RESTORED: Cmd + ' now for LINE right (was word right, redundant but kept if you prefer)
	{ "leftCmd", "'", "cmd", "right" },
	{ "leftCmd+leftShift", "'", "cmd+shift", "right" },
}

local scrollAmount = 5
hotkeyGroups = {}

-- Scroll Up → Cmd + u
local scrollUp = hs.hotkey.new(
	{ "cmd" },
	"u",
	function()
		hs.eventtap.event.newScrollEvent({ 0, scrollAmount }, {}, "line"):post()
	end,
	nil,
	function()
		hs.eventtap.event.newScrollEvent({ 0, scrollAmount }, {}, "line"):post()
	end
)

-- Scroll Down → Cmd + o
local scrollDown = hs.hotkey.new(
	{ "cmd" },
	"o",
	function()
		hs.eventtap.event.newScrollEvent({ 0, -scrollAmount }, {}, "line"):post()
	end,
	nil,
	function()
		hs.eventtap.event.newScrollEvent({ 0, -scrollAmount }, {}, "line"):post()
	end
)

table.insert(hotkeyGroups, scrollUp)
table.insert(hotkeyGroups, scrollDown)

---
-- Custom Hotkeys for Cmd + J/L (with double-tap logic)
---

-- Hotkey for Cmd + J (and Cmd + Shift + J) for character/word left
local cmdJHotkey = hs.hotkey.new(
	{ "cmd" },
	"j",
	function()
		local currentTime = hs.timer.secondsSinceEpoch()

		if (currentTime - sequence_last_cmd_j_press_time) < sequenceTimeout then
			-- This is the second 'j' in a quick sequence (Cmd + J + J)
			if isShiftPressed() then
				hs.eventtap.keyStroke({ "alt", "shift" }, "left", 0) -- Select word left
			else
				hs.eventtap.keyStroke({ "alt" }, "left", 0) -- Move word left
			end
			sequence_last_cmd_j_press_time = 0 -- Reset for next sequence
		else
			-- This is the first 'j' in a potential sequence (Cmd + J)
			-- Perform single character move/select immediately
			if isShiftPressed() then
				hs.eventtap.keyStroke({ "shift" }, "left", 0) -- Select character left
			else
				hs.eventtap.keyStroke(nil, "left", 0) -- Move character left
			end
			sequence_last_cmd_j_press_time = currentTime
		end
	end,
	nil,
	function()
		-- This function runs when Cmd + J is held down (auto-repeat)
		-- We want it to continue moving/selecting characters
		if isShiftPressed() then
			hs.eventtap.keyStroke({ "shift" }, "left", 0) -- Select character left (on repeat)
		else
			hs.eventtap.keyStroke(nil, "left", 0) -- Move character left (on repeat)
		end
	end
)

-- Hotkey for Cmd + L (and Cmd + Shift + L) for character/word right
local cmdLHotkey = hs.hotkey.new(
	{ "cmd" },
	"l",
	function()
		local currentTime = hs.timer.secondsSinceEpoch()

		if (currentTime - sequence_last_cmd_l_press_time) < sequenceTimeout then
			-- This is the second 'l' in a quick sequence (Cmd + L + L)
			if isShiftPressed() then
				hs.eventtap.keyStroke({ "alt", "shift" }, "right", 0) -- Select word right
			else
				hs.eventtap.keyStroke({ "alt" }, "right", 0) -- Move word right
			end
			sequence_last_cmd_l_press_time = 0 -- Reset for next sequence
		else
			-- This is the first 'l' in a potential sequence (Cmd + L)
			-- Perform single character move/select immediately
			if isShiftPressed() then
				hs.eventtap.keyStroke({ "shift" }, "right", 0) -- Select character right
			else
				hs.eventtap.keyStroke(nil, "right", 0) -- Move character right
			end
			sequence_last_cmd_l_press_time = currentTime
		end
	end,
	nil,
	function()
		-- This function runs when Cmd + L is held down (auto-repeat)
		if isShiftPressed() then
			hs.eventtap.keyStroke({ "shift" }, "right", 0) -- Select character right (on repeat)
		else
			hs.eventtap.keyStroke(nil, "right", 0) -- Move character right (on repeat)
		end
	end
)

-- Hotkey for Cmd + / (and Cmd + Shift + /) for paragraph start (double-tap only)
local cmdSlashHotkey = hs.hotkey.new(
	{ "cmd" },
	"/",
	function()
		local currentTime = hs.timer.secondsSinceEpoch()

		if (currentTime - sequence_last_cmd_slash_press_time) < sequenceTimeoutTwo then
			-- This is the second '/' in a quick sequence (Cmd + / + /)
			if isShiftPressed() then
				hs.eventtap.keyStroke({ "cmd", "shift" }, "up", 0) -- Select to paragraph start
			else
				hs.eventtap.keyStroke({ "cmd" }, "up", 0) -- Move to paragraph start
			end
			sequence_last_cmd_slash_press_time = 0 -- Reset for next sequence
		else
			-- This is the first '/' in a potential sequence (Cmd + /)
			-- Do nothing on single press
			sequence_last_cmd_slash_press_time = currentTime
		end
	end,
	nil,
	function()
		-- This function runs when Cmd + / is held down (auto-repeat)
		-- Do nothing on repeat
	end
)

-- Hotkey for Cmd + . (and Cmd + Shift + .) for paragraph end (double-tap only)
local cmdPeriodHotkey = hs.hotkey.new(
	{ "cmd" },
	".",
	function()
		local currentTime = hs.timer.secondsSinceEpoch()

		if (currentTime - sequence_last_cmd_period_press_time) < sequenceTimeoutTwo then
			-- This is the second '.' in a quick sequence (Cmd + . + .)
			if isShiftPressed() then
				hs.eventtap.keyStroke({ "cmd", "shift" }, "down", 0) -- Select to paragraph end
			else
				hs.eventtap.keyStroke({ "cmd" }, "down", 0) -- Move to paragraph end
			end
			sequence_last_cmd_period_press_time = 0 -- Reset for next sequence
		else
			-- This is the first '.' in a potential sequence (Cmd + .)
			-- Do nothing on single press
			sequence_last_cmd_period_press_time = currentTime
		end
	end,
	nil,
	function()
		-- This function runs when Cmd + . is held down (auto-repeat)
		-- Do nothing on repeat
	end
)

-- Add the new custom hotkeys to the group
table.insert(hotkeyGroups, cmdJHotkey)
table.insert(hotkeyGroups, cmdLHotkey)
table.insert(hotkeyGroups, cmdSlashHotkey)
table.insert(hotkeyGroups, cmdPeriodHotkey)

-- Helper to split string modifiers like "leftCmd+leftShift"
local function splitMods(mods)
	if not mods then
		return {}
	end

	local t = {}

	for mod in string.gmatch(mods, "[^%+]+") do
		if mod == "leftCmd" or mod == "rightCmd" then
			mod = "cmd"
		end

		if mod == "leftShift" or mod == "rightShift" then
			mod = "shift"
		end

		table.insert(t, mod)
	end

	return t
end

-- Bind key remaps from KEYMAP
for _, hotkeyVals in ipairs(KEYMAP) do
	local fromMods, fromKey, toMods, toKey = table.unpack(hotkeyVals)

	local toKeyStroke = function()
		hs.eventtap.keyStroke(toMods, toKey, 0)
	end

	local hotkey = hs.hotkey.new(splitMods(fromMods), fromKey, toKeyStroke, nil, toKeyStroke)

	table.insert(hotkeyGroups, hotkey)
end

-- Enable all hotkeys
for _, hotkey in ipairs(hotkeyGroups) do
	hotkey:enable()
end

-- Optional: auto-reload config on save
hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", hs.reload):start()

hs.alert.show("Hammerspoon config loaded")

-- --- ChatGPT pop-in window setup on launch ---
local function positionChatGPTWindow()
	local app = hs.application.get("ChatGPT")
	if not app then
		return
	end

	local win = app:mainWindow()
	if not win then
		return
	end

	local screen = win:screen()
	local screenFrame = screen:frame()
	local width, height = 500, 600
	local x = screenFrame.x + screenFrame.w - width - 20
	local y = screenFrame.y + screenFrame.h - height - 40

	win:setFrame(hs.geometry.rect(x, y, width, height))
end

local chatGPTWatcher = hs.application.watcher.new(function(appName, eventType, appObject)
	if appName == "ChatGPT" and eventType == hs.application.watcher.launched then
		-- hs.timer.doAfter(1, positionChatGPTWindow)
		hs.timer.waitUntil(function()
			return hs.application.get("ChatGPT") ~= nil
		end, positionChatGPTWindow)
	end
end)
chatGPTWatcher:start()

local function moveFocusedWindow(xAlign, yAlign)
	local win = hs.window.focusedWindow()
	if not win then
		return
	end

	local screen = win:screen()
	local screenFrame = screen:frame()

	local width, height = 500, 600
	local x = screenFrame.x + (screenFrame.w - width) * xAlign
	local y = screenFrame.y + (screenFrame.h - height) * yAlign

	win:setFrame(hs.geometry.rect(x, y, width, height))
end

-- Bottom Left
hs.hotkey.bind({ "cmd", "shift" }, "j", function()
	moveFocusedWindow(0, 1)
end)

-- Bottom Right
hs.hotkey.bind({ "cmd", "shift" }, "l", function()
	moveFocusedWindow(1, 1)
end)

-- Middle Right
hs.hotkey.bind({ "cmd", "shift" }, "o", function()
	moveFocusedWindow(1, 0.5)
end)

-- Middle Left
hs.hotkey.bind({ "cmd", "shift" }, "u", function()
	moveFocusedWindow(0, 0.5)
end)

-- Center
hs.hotkey.bind({ "cmd", "shift" }, "k", function()
	moveFocusedWindow(0.5, 0.5)
end)

-- Periodically restart keyTap to keep it alive
hs.timer.doEvery(60, function()
	if keyTap:isEnabled() then
		keyTap:stop()
	end
	keyTap:start()
end)

-- For moving cursor to the windon where that we just opened using keyTap
function focusAppAndMoveCursor(bundleId, position)
	local app = hs.application.get(bundleId)
	if app then
		-- app:active()
		app:activate()
		hs.timer.doAfter(0.3, function()
			local win = app:mainWindow()
			if win and win:isStandard() and win:isVisible() and win:isFocused() then
				hs.mouse.absolutePosition(position)
			end
		end)
	end
end
