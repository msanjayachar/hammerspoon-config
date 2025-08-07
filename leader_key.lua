--- Leader keys module for Hammerspoon
---@diagnostic disable-next-line: undefined-global
local hs = hs

local leaderKeys = {}
local windowIndexMap = {}
local windowSelectionMode = false
local windowSelectionMap = {
	a = "1",
	s = "2",
	d = "3",
	f = "4",
}

local appMappings = {
	["c"] = { name = "Google Chrome", bundleID = "com.google.Chrome" },
	["h"] = { name = "Chromium", bundleID = "org.chromium.Chromium" },
	["b"] = { name = "Brave Browser", bundleID = "com.brave.Browser" },
	["i"] = { name = "iTerm", bundleID = "com.googlecode.iterm2" },
	["a"] = { name = "Arc", bundleID = "company.thebrowser.Browser" },
	["d"] = { name = "Discord", bundleID = "com.hnc.Discord" },
	["v"] = { name = "Visual Studio Code", bundleID = "com.microsoft.VSCode" },
	["g"] = { name = "ChatGPT", bundleID = "com.openai.chat" },
	["o"] = { name = "Obsidian", bundleID = "md.obsidian" },
	["k"] = { name = "Docker", bundleID = "com.docker.docker" },
	["t"] = { name = "Postman", bundleID = "com.postmanlabs.mac" },
}

local leaderState = false
local leaderSequence = ""
local leaderTimer = nil
-- local sequenceTimeout = 0.6 -- seconds
local sequenceTimeout = 1.6 -- seconds

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

-- Function to perform application action or window switching
local function performAction(sequence)
	local appEntry = appMappings[sequence]
	if not appEntry then
		hs.alert.show("Unknown sequence: " .. sequence)
		return
	end

	local appName = appEntry.name
	local bundleID = appEntry.bundleID
	print("appName: ", appName)

	-- don't think this is the best way to get the currentApp
	local currentApp = hs.application.frontmostApplication()
	local targetApp = hs.application.get(bundleID)

	print("currentApp: ", currentApp)
	print("targetApp: ", targetApp)

	-- local currentAppWindows = currentApp:allWindows()
	local currentAppWindows = hs.fnutils.filter(currentApp:allWindows(), function(win)
		return win:title() ~= "" and not win:isMinimized() and win:isVisible()
	end)

	table.sort(currentAppWindows, function(a, b)
		return a:id() < b:id()
	end)

	-- If we're already in the target app, cycle to next window
	if currentApp and targetApp and currentApp:bundleID() == targetApp:bundleID() then
		-- local windows = targetApp:allWindows()
		local windows = hs.fnutils.filter(targetApp:allWindows(), function(win)
			return win:title() ~= "" and not win:isMinimized() and win:isVisible()
		end)

		-- First, try to unminimize if all windows are minimized
		local allMinimized = hs.fnutils.every(windows, function(win)
			return win:isMinimized()
		end)

		if allMinimized and #windows > 0 then
			print("All windows minimized, unminimizing first window")
			local win = windows[1]
			hs.timer.doAfter(0.1, function()
				moveCursorToCenter(win)
			end)
			return
		end

		if windows and #windows > 0 then
			table.sort(windows, function(a, b)
				return a:id() < b:id()
			end)
			-- if #currentAppWindows > 1 then
			-- 	windowIndexMap = {}
			-- 	for index, win in ipairs(currentAppWindows) do
			-- 		local title = win:title()
			-- 		windowIndexMap[tostring(index)] = win
			-- 		hs.alert.show(index .. ": " .. title)
			-- 	end
			-- end
			if #currentAppWindows > 1 then
				windowIndexMap = {}
				for index, win in ipairs(currentAppWindows) do
					if index > 4 then
						break
					end
					windowIndexMap[tostring(index)] = win
				end
				windowSelectionMode = true
				hs.alert.show("Select window: a(1) s(2) d(3) f(4)")
				return
			end
		end

		-- Log window count and details
		print("Found " .. #windows .. " windows for " .. appName)
		for i, win in ipairs(windows) do
			print("  Window " .. i .. ": " .. win:title() .. " (ID: " .. win:id() .. ")")
		end

		local validWindows = hs.fnutils.filter(windows, function(win)
			return win:title() ~= "" and not win:isMinimized()
		end)

		table.sort(validWindows, function(a, b)
			return a:id() < b:id()
		end)

		if #validWindows > 1 then
			local currentWin = hs.window.focusedWindow()
			local currentIndex = 1

			-- Find current window index
			for i, win in ipairs(validWindows) do
				if currentWin and win:id() == currentWin:id() then
					currentIndex = i
					local spaceID = getWindowSpace(win) or "unknown"
					print(
						"DEBUG: Current window '"
							.. win:title()
							.. "' (ID: "
							.. win:id()
							.. ", Space: "
							.. spaceID
							.. ") at index "
							.. i
					)
					break
				end
			end

			-- Get next window (cycle back to 1 if at end)
			local nextIndex = currentIndex == #validWindows and 1 or currentIndex + 1
			local nextWin = validWindows[nextIndex]
			if nextWin then
				local currentSpace = hs.spaces.focusedSpace()
				local nextSpaceID = getWindowSpace(nextWin)
				if nextSpaceID and nextSpaceID ~= currentSpace then
					print(
						"DEBUG: Switching to space "
							.. nextSpaceID
							.. " for window '"
							.. nextWin:title()
							.. "' (ID: "
							.. nextWin:id()
							.. ")"
					)
					hs.spaces.gotoSpace(nextSpaceID)
					hs.timer.doAfter(0.3, function()
						nextWin:becomeMain()
						nextWin:focus()
						targetApp:activate()
						moveCursorToCenter(nextWin)
						print("DEBUG: Focused window '" .. nextWin:title() .. "' (ID: " .. nextWin:id() .. ")")
					end)
				else
					print(
						"DEBUG: Staying on current space for window '"
							.. nextWin:title()
							.. "' (ID: ) "
							.. nextWin:id()
							.. ")"
					)
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
		-- Switch to the app (will focus last focused window)
		if not targetApp then
			-- hs.application.launchOrFocus(appName)
			hs.application.launchOrFocusByBundleID(bundleID)

			hs.timer.doAfter(0.5, function()
				local launchedApp = hs.application.get(bundleID)
				if launchedApp and launchedApp:isRunning() then
					launchedApp:activate()

					local win = hs.window.focusedWindow()
					if win then
						moveCursorToCenter(win)
					end
				else
					hs.alert.show("Failed to launch: " .. appName)
				end
			end)
		else
			local windows = targetApp:allWindows()
			if #windows == 0 then
				hs.alert.show(appName .. " had no windows. ")
				targetApp:kill()
				hs.alert.show(appName .. " killed. ")
				return
			end

			-- Try to find a non-minimized window, or fallback to the first one
			table.sort(windows, function(a, b)
				return a:id() < b:id()
			end)
			local targetWindow = hs.fnutils.find(windows, function(win)
				return not win:isMinimized() and win:title() ~= ""
			end) or windows[1]

			-- Unminimize if necessary
			if targetWindow:isMinimized() then
				targetWindow:unminimize()
			end

			targetApp:activate()
			targetWindow:focus()

			hs.timer.doAfter(0.1, function()
				moveCursorToCenter(targetWindow)
			end)
		end
	end
end

-- local windowWatcher = hs.window.filter.new():subscribe(hs.window.filter.windowDestroyed, function(win, appName)
-- 	print("[Watcher] Auto-kill window watcher active")
-- 	local app = win:application()
-- 	if not app then
-- 		return
-- 	end
--
-- 	-- Only auto-kill for apps in your mapping
-- 	for _, entry in pairs(appMappings) do
-- 		if entry.bundleID == app:bundleID() then
-- 			local visibleWindows = hs.fnutils.filter(app:allWindows(), function(w)
-- 				return w:title() ~= "" and not w:isMinimized() and w:isVisible()
-- 			end)
--
-- 			if #visibleWindows == 0 then
-- 				app:kill()
-- 			end
--
-- 			break
-- 		end
-- 	end
-- end)
--
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
		if windowSelectionMode then
			local idx = windowSelectionMap[key]
			local win = idx and windowIndexMap[idx]
			if win then
				local spaceID = getWindowSpace(win)
				if spaceID and spaceID ~= hs.spaces.focusedSpace() then
					hs.spaces.gotoSpace(spaceID)
					hs.timer.doAfter(0.3, function()
						win:focus()
						moveCursorToCenter(win)
						resetLeader()
						windowSelectionMode = false
					end)
				else
					win:focus()
					moveCursorToCenter(win)
					resetLeader()
					windowSelectionMode = false
				end
			else
				hs.alert.show("Invalid selection")
				resetLeader()
				windowSelectionMode = false
			end
			return true
		end
		-- Reset timer on every keystroke
		if leaderTimer then
			leaderTimer:stop()
		end
		leaderTimer = hs.timer.doAfter(sequenceTimeout, resetLeader)

		if key and key:match("%a") then
			leaderSequence = leaderSequence .. key:lower()
			if #leaderSequence == 1 then
				performAction(leaderSequence)
				-- resetLeader()
				return true
			end
			return true
		elseif key and windowIndexMap[key] then
			local win = windowIndexMap[key]
			if win then
				local spaceID = getWindowSpace(win)
				if spaceID and spaceID ~= hs.spaces.focusedSpace() then
					hs.spaces.gotoSpace(spaceID)
					hs.timer.doAfter(0.3, function()
						win:focus()
						moveCursorToCenter(win)
						resetLeader()
					end)
				else
					win:focus()
					moveCursorToCenter(win)
					resetLeader()
				end
			end
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
