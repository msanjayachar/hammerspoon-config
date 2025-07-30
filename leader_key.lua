--- Leader keys module for Hammerspoon
---@diagnostic disable-next-line: undefined-global
local hs = hs

local leaderKeys = {}

local appMappings = {
	["ch"] = "Google Chrome",
	["br"] = "Brave Browser",
	["it"] = "iTerm",
	["ar"] = "Arc",
	["ds"] = "Discord",
	["vs"] = "Visual Studio Code",
	["ct"] = "ChatGPT",
	["ob"] = "Obsidian",
}

local leaderState = false
local leaderSequence = ""
local leaderTimer = nil
local sequenceTimeout = 0.6 -- seconds

local function resetLeader()
	leaderState = false
	leaderSequence = ""
	if leaderTimer then
		leaderTimer:stop()
	end
	leaderTimer = nil
end

-- Function to move the cursor to the center of the focused window
local function moveCursorToCenter(win)
	local frame = win:frame()
	local centerPoint = hs.geometry.point(frame.x + frame.w / 2 - 65, frame.y + frame.h / 2)
	-- hs.mouse.setAbsolutePosition(centerPoint)
	hs.mouse.absolutePosition(centerPoint)
end

-- Function to perform application action or window switching
local function performAction(sequence, windowIndex)
	if windowIndex then
		-- Window switching for the current application
		local app = hs.application.frontmostApplication()
		if app then
			local windows = app:allWindows()
			if #windows >= windowIndex then
				local win = windows[windowIndex]
				win:focus()
				moveCursorToCenter(win)
			end
		end
	else
		-- Application launching or focusing
		local appName = appMappings[sequence]
		if not appName then
			hs.alert.show("Unknown sequence: " .. sequence)
			return
		end
		local app = hs.application.get(appName)
		if not app then
			hs.application.launchOrFocus(appName)
			hs.timer.doAfter(0.5, function()
				local win = hs.window.focusedWindow()
				if win then
					moveCursorToCenter(win)
				end
			end)
		else
			local windows = app:allWindows()
			if #windows == 0 then
				hs.application.launchOrFocus(appName)
				hs.timer.doAfter(0.5, function()
					local win = hs.window.focusedWindow()
					if win then
						moveCursorToCenter(win)
					end
				end)
			else
				app:activate()
				local win = hs.window.focusedWindow()
				if win then
					moveCursorToCenter(win)
				end
			end
		end
	end
end

hs.hotkey.bind({}, "f18", function()
	hs.alert.show("F18 triggered")
end)

-- Event tap to handle key presses
local eventTap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
	-- local keyCode = event:getKeyCode()
	-- local key = hs.keycodes.map[keyCode]
	local key = event:getCharacters(true) -- Handles upper/lowercase properly

	print("key pressed:", key)

	-- Start leader sequence
	if not leaderState then
		local keyCode = event:getKeyCode()
		if hs.keycodes.map[keyCode] == "f18" then
			leaderState = true
			leaderSequence = ""
			if leaderTimer then
				leaderTimer:stop()
			end
			leaderTimer = hs.timer.doAfter(sequenceTimeout, resetLeader)
			print("Leader mode triggered")
			return true
		end
	end
	if leaderState then
		-- Reset timer on every keystroke
		if leaderTimer then
			leaderTimer:stop()
		end
		leaderTimer = hs.timer.doAfter(sequenceTimeout, resetLeader)

		if key:match("%a") then
			leaderSequence = leaderSequence .. key:lower()
			print("Leader sequence:", leaderSequence)

			if #leaderSequence == 2 then
				performAction(leaderSequence)
				resetLeader()
			end
			return true
		elseif key:match("%d") then
			performAction(leaderSequence, tonumber(key))
			resetLeader()
			return true
		else
			resetLeader()
			return false
		end
	end
	return false
end)

-- Initialize the leader key functionality
function leaderKeys.init()
	eventTap:start()
end

return leaderKeys
