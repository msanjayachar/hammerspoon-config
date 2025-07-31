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

-- Function to get space ID for a window
local function getWindowSpace(win)
	local screen = win:screen()
	if not screen then
		return nil
	end
	local screenUUID = screen:getUUID()
	local spaces = hs.spaces.allSpaces()
	local spaceList = spaces[screenUUID]
	if not spaceList then
		return nil
	end
	for _, spaceID in ipairs(spaceList) do
		local spaceWindows = hs.spaces.windowsForSpace(spaceID)
		if spaceWindows then
			for _, winID in ipairs(spaceWindows) do
				if winID == win:id() then
					return spaceID
				end
			end
		end
	end
	return nil
end

-- Function to log space and application info
local function logSpaceInfo()
	local spaces = hs.spaces.allSpaces()
	if not spaces then
		return
	end
	local totalSpaces = 0
	for _, spaceList in pairs(spaces) do
		totalSpaces = totalSpaces + #spaceList
	end
	print("Number of spaces: " .. totalSpaces)

	-- Track apps per space
	local spaceAppMap = {}
	for screenUUID, spaceList in pairs(spaces) do
		for _, spaceID in ipairs(spaceList) do
			spaceAppMap[spaceID] = {}
			local spaceWindows = hs.spaces.windowsForSpace(spaceID) or {}
			for _, winID in ipairs(spaceWindows) do
				local win = hs.window.get(winID)
				if win and win:application() then
					local appName = win:application():name()
					if appName then
						spaceAppMap[spaceID][appName] = true
						print("Window in space " .. spaceID .. ": '" .. win:title() .. "' (App: " .. appName .. ", ID: " .. win:id() .. ", Minimized: " .. tostring(win:isMinimized()) .. ", Visible: " .. tostring(win:isVisible()) .. ")")
					end
				end
			end
		end
	end

	-- Fallback: Check all windows
	local allWindows = hs.window.allWindows()
	for _, win in ipairs(allWindows) do
		local appName = win:application() and win:application():name()
		if appName then
			local spaceID = getWindowSpace(win)
			if spaceID and not spaceAppMap[spaceID][appName] then
				spaceAppMap[spaceID][appName] = true
				print("Fallback window in space " .. spaceID .. ": '" .. win:title() .. "' (App: " .. appName .. ", ID: " .. win:id() .. ", Minimized: " .. tostring(win:isMinimized()) .. ", Visible: " .. tostring(win:isVisible()) .. ")")
			end
		end
	end

	-- Log app counts and names
	for screenUUID, spaceList in pairs(spaces) do
		for _, spaceID in ipairs(spaceList) do
			local appCount = 0
			local appList = {}
			for appName, _ in pairs(spaceAppMap[spaceID] or {}) do
				appCount = appCount + 1
				table.insert(appList, appName)
			end
			print("Number of applications on space " .. spaceID .. " (screen " .. screenUUID .. "): " .. appCount)
			print("Applications on space " .. spaceID .. ": " .. (#appList > 0 and table.concat(appList, ", ") or "None"))
		end
	end
end

-- Function to perform application action or window switching
local function performAction(sequence)
	local appName = appMappings[sequence]
	if not appName then
		hs.alert.show("Unknown sequence: " .. sequence)
		return
	end

	-- Log space and application info
	logSpaceInfo()

	local currentApp = hs.application.frontmostApplication()
	local targetApp = hs.application.get(appName)
	if not targetApp then
		hs.application.launchOrFocus(appName)
		hs.timer.doAfter(0.5, function()
			local win = hs.window.focusedWindow()
			if win then
				moveCursorToCenter(win)
			end
		end)
		return
	end

	-- If we're already in the target app, cycle to next window
	if currentApp and currentApp:bundleID() == targetApp:bundleID() then
		-- Collect windows from allWindows()
		local allWindows = targetApp:allWindows()
		local validWindows = {}
		for _, win in ipairs(allWindows) do
			local notMinimized = not win:isMinimized()
			local hasValidFrame = win:frame().w > 0 and win:frame().h > 0
			if notMinimized and hasValidFrame then
				table.insert(validWindows, win)
				local spaceID = getWindowSpace(win) or "unknown"
				print("DEBUG: Found window '" .. win:title() .. "' (ID: " .. win:id() .. ", Space: " .. spaceID .. ", Minimized: " .. tostring(win:isMinimized()) .. ", Visible: " .. tostring(win:isVisible()) .. ")")
			else
				print("DEBUG: Skipped window '" .. win:title() .. "' (ID: " .. win:id() .. ", Minimized: " .. tostring(win:isMinimized()) .. ", Visible: " .. tostring(win:isVisible()) .. ", notMinimized: " .. tostring(notMinimized) .. ", hasValidFrame: " .. tostring(hasValidFrame) .. ")")
			end
		end

		-- Sort by window ID for consistent ordering
		table.sort(validWindows, function(a, b) return a:id() < b:id() end)

		if #validWindows > 1 then
			local currentWin = hs.window.focusedWindow()
			local currentIndex = 1

			-- Find current window index
			for i, win in ipairs(validWindows) do
				if currentWin and win:id() == currentWin:id() then
					currentIndex = i
					local spaceID = getWindowSpace(win) or "unknown"
					print("DEBUG: Current window '" .. win:title() .. "' (ID: " .. win:id() .. ", Space: " .. spaceID .. ") at index " .. i)
					break
				end
			end

			-- Get next window (cycle back to 1 if at end)
			local nextIndex = currentIndex == #validWindows and 1 or currentIndex + 1
			local nextWin = validWindows[nextIndex]
			if nextWin then
				local nextSpaceID = getWindowSpace(nextWin)
				if nextSpaceID then
					print("DEBUG: Switching to space " .. nextSpaceID .. " for window '" .. nextWin:title() .. "' (ID: " .. nextWin:id() .. ")")
					hs.spaces.gotoSpace(nextSpaceID)
					hs.timer.doAfter(0.3, function()
						nextWin:becomeMain()
						nextWin:focus()
						targetApp:activate()
						moveCursorToCenter(nextWin)
						print("DEBUG: Focused window '" .. nextWin:title() .. "' (ID: " .. nextWin:id() .. ")")
					end)
				else
					-- Fallback: focus without space switch
					print("DEBUG: No space ID for window '" .. nextWin:title() .. "' (ID: " .. nextWin:id() .. "), focusing without space switch")
					nextWin:becomeMain()
					nextWin:focus()
					targetApp:activate()
					hs.timer.doAfter(0.1, function()
						moveCursorToCenter(nextWin)
						print("DEBUG: Focused window '" .. nextWin:title() .. "' (ID: " .. nextWin:id() .. ")")
					end)
				end
			else
				print("DEBUG: No next window found")
			end
		else
			print("DEBUG: Only one or no valid windows found, no cycling needed")
		end
	else
		-- Switch to the app
		targetApp:activate()
		hs.timer.doAfter(0.3, function()
			local win = hs.window.focusedWindow()
			if win then
				moveCursorToCenter(win)
			end
		end)
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