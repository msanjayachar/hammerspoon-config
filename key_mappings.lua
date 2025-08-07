--- Key mappings module for Hammerspoon
local keyMappings = {}

---@diagnostic disable-next-line: undefined-global
local hs = hs
local hotkeyGroups = {}

local windowManagement = require("move_to_other_display")

local sequenceTimeout = 0.15 -- Time for second tap (250ms)
local sequenceTimeoutTwo = 0.30

-- Global state for tracking sequences
local sequence_last_cmd_j_press_time = 0
local sequence_last_cmd_l_press_time = 0
local sequence_last_cmd_slash_press_time = 0
local sequence_last_cmd_period_press_time = 0

-- Helper to check if Shift is pressed
local function isShiftPressed()
	return hs.eventtap.checkKeyboardModifiers()["shift"]
end

-- Key remapping table
local KEYMAP = {
	{ "leftCmd", "i", nil, "up" },
	{ "leftCmd+leftShift", "i", "cmd+shift", "up" },
	{ "leftCmd+rightShift", "i", "shift", "up" },
	{ "leftCmd+leftShift+rightShift", "i", "shift", "up" },
	{ "leftCmd", "h", "cmd", "left" },
	{ "leftCmd+leftShift", "h", "cmd+shift", "left" },
	{ "leftCmd", "k", nil, "down" },
	{ "leftCmd+leftShift", "k", "cmd+shift", "down" },
	{ "leftCmd+rightShift", "k", "shift", "down" },
	{ "leftCmd+leftShift+rightShift", "k", "shift", "down" },
	{ "leftCmd", ";", "cmd", "right" },
	{ "leftCmd+leftShift", ";", "cmd+shift", "right" },
	{ "leftCmd", "'", "cmd", "right" },
	{ "leftCmd+leftShift", "'", "cmd+shift", "right" },
}

local scrollAmount = 5

-- Helper to split string modifiers
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

-- Initialize key mappings
function keyMappings.init()
	local moveWindowHotkey = hs.hotkey.new({ "ctrl" }, "m", function()
		windowManagement.moveWindowToOtherDisplay()
	end)

	table.insert(hotkeyGroups, moveWindowHotkey)

	-- Scroll Up (Cmd + u)
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

	-- Scroll Down (Cmd + o)
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

	-- Cmd + J (character/word left)
	local cmdJHotkey = hs.hotkey.new(
		{ "cmd" },
		"j",
		function()
			local currentTime = hs.timer.secondsSinceEpoch()
			if (currentTime - sequence_last_cmd_j_press_time) < sequenceTimeout then
				if isShiftPressed() then
					hs.eventtap.keyStroke({ "alt", "shift" }, "left", 0)
				else
					hs.eventtap.keyStroke({ "alt" }, "left", 0)
				end
				sequence_last_cmd_j_press_time = 0
			else
				if isShiftPressed() then
					hs.eventtap.keyStroke({ "shift" }, "left", 0)
				else
					hs.eventtap.keyStroke(nil, "left", 0)
				end
				sequence_last_cmd_j_press_time = currentTime
			end
		end,
		nil,
		function()
			if isShiftPressed() then
				hs.eventtap.keyStroke({ "shift" }, "left", 0)
			else
				hs.eventtap.keyStroke(nil, "left", 0)
			end
		end
	)

	-- Cmd + L (character/word right)
	local cmdLHotkey = hs.hotkey.new(
		{ "cmd" },
		"l",
		function()
			local currentTime = hs.timer.secondsSinceEpoch()
			if (currentTime - sequence_last_cmd_l_press_time) < sequenceTimeout then
				if isShiftPressed() then
					hs.eventtap.keyStroke({ "alt", "shift" }, "right", 0)
				else
					hs.eventtap.keyStroke({ "alt" }, "right", 0)
				end
				sequence_last_cmd_l_press_time = 0
			else
				if isShiftPressed() then
					hs.eventtap.keyStroke({ "shift" }, "right", 0)
				else
					hs.eventtap.keyStroke(nil, "right", 0)
				end
				sequence_last_cmd_l_press_time = currentTime
			end
		end,
		nil,
		function()
			if isShiftPressed() then
				hs.eventtap.keyStroke({ "shift" }, "right", 0)
			else
				hs.eventtap.keyStroke(nil, "right", 0)
			end
		end
	)

	-- Cmd + / (paragraph start, double-tap)
	local cmdSlashHotkey = hs.hotkey.new({ "cmd" }, "/", function()
		local currentTime = hs.timer.secondsSinceEpoch()
		if (currentTime - sequence_last_cmd_slash_press_time) < sequenceTimeoutTwo then
			if isShiftPressed() then
				hs.eventtap.keyStroke({ "cmd", "shift" }, "up", 0)
			else
				hs.eventtap.keyStroke({ "cmd" }, "up", 0)
			end
			sequence_last_cmd_slash_press_time = 0
		else
			sequence_last_cmd_slash_press_time = currentTime
		end
	end, nil, function() end)

	-- Cmd + . (paragraph end, double-tap)
	local cmdPeriodHotkey = hs.hotkey.new({ "cmd" }, ".", function()
		local currentTime = hs.timer.secondsSinceEpoch()
		if (currentTime - sequence_last_cmd_period_press_time) < sequenceTimeoutTwo then
			if isShiftPressed() then
				hs.eventtap.keyStroke({ "cmd", "shift" }, "down", 0)
			else
				hs.eventtap.keyStroke({ "cmd" }, "down", 0)
			end
			sequence_last_cmd_period_press_time = 0
		else
			sequence_last_cmd_period_press_time = currentTime
		end
	end, nil, function() end)

	-- Add hotkeys to group
	table.insert(hotkeyGroups, scrollUp)
	table.insert(hotkeyGroups, scrollDown)
	table.insert(hotkeyGroups, cmdJHotkey)
	table.insert(hotkeyGroups, cmdLHotkey)
	table.insert(hotkeyGroups, cmdSlashHotkey)
	table.insert(hotkeyGroups, cmdPeriodHotkey)

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
end

return keyMappings
