--- Leader keys module for Hammerspoon
---@diagnostic disable-next-line: undefined-global
local hs = hs

local leaderKeys = {}

local appMappings = {
	["c"] = "Google Chrome",
	["b"] = "Brave Browser", 
	["i"] = "iTerm",
	["a"] = "Arc",
	["d"] = "Discord",
	["v"] = "Visual Studio Code",
	["g"] = "ChatGPT",
	["o"] = "Obsidian",
	["k"] = "Docker",
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
	hs.mouse.absolutePosition(centerPoint)
end

-- Function to perform application action or window switching
local function performAction(sequence)
	local appName = appMappings[sequence]
	if not appName then
		hs.alert.show("Unknown sequence: " .. sequence)
		return
	end

	local currentApp = hs.application.frontmostApplication()
	local targetApp = hs.application.get(appName)
	
	-- If we're already in the target app, cycle to next window
	if currentApp and targetApp and currentApp:bundleID() == targetApp:bundleID() then
		local windows = targetApp:allWindows()
		
		-- Filter for valid windows and sort by ID for consistent ordering
		windows = hs.fnutils.filter(windows, function(win)
			return win:title() ~= "" and not win:isMinimized()
		end)
	
  -- Log window count and details
		print("Found " .. #windows .. " windows for " .. appName)
		for i, win in ipairs(windows) do
			print("  Window " .. i .. ": " .. win:title() .. " (ID: " .. win:id() .. ")")
		end    

		-- Sort by window ID for consistent ordering
		table.sort(windows, function(a, b) return a:id() < b:id() end)
		
		if #windows > 1 then
			local currentWin = hs.window.focusedWindow()
			local currentIndex = 1
			
			-- Find current window index
			for i, win in ipairs(windows) do
				if win:id() == currentWin:id() then
					currentIndex = i
					break
				end
			end
			
			-- Get next window (cycle back to 1 if at end)
			local nextIndex = currentIndex == #windows and 1 or currentIndex + 1
			local nextWin = windows[nextIndex]
			
			-- Force focus and bring to front
			nextWin:becomeMain()
			nextWin:focus()
			targetApp:activate()
			
			hs.timer.doAfter(0.1, function()
				moveCursorToCenter(nextWin)
			end)
		end
	else
		-- Switch to the app (will focus last focused window)
		if not targetApp then
			hs.application.launchOrFocus(appName)
			hs.timer.doAfter(0.5, function()
				local win = hs.window.focusedWindow()
				if win then
					moveCursorToCenter(win)
				end
			end)
		else
			targetApp:activate()
			hs.timer.doAfter(0.1, function()
				local win = hs.window.focusedWindow()
				if win then
					moveCursorToCenter(win)
				end
			end)
		end
	end
end

-- Event tap to handle key presses
local eventTap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
	local keyCode = event:getKeyCode()
	local key = event:getCharacters(true)

 
	-- Start leader sequence
	if not leaderState then
		if hs.keycodes.map[keyCode] == "f18" then
			leaderState = true
			leaderSequence = ""
			if leaderTimer then
				leaderTimer:stop()
			end
			leaderTimer = hs.timer.doAfter(sequenceTimeout, resetLeader)
			return true
		end
		return false
	end
	
	if leaderState then
		-- Reset timer on every keystroke
		if leaderTimer then
			leaderTimer:stop()
		end
		leaderTimer = hs.timer.doAfter(sequenceTimeout, resetLeader)

		if key and key:match("%a") then
			leaderSequence = leaderSequence .. key:lower()

			if #leaderSequence == 1 then
				performAction(leaderSequence)
				resetLeader()
				return true
			end
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