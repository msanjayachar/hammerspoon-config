--- Leader keys module for Hammerspoon
---@diagnostic disable-next-line: undefined-global
local hs = hs

local leaderKeys = {}

--[[
IN PROGRESS:

- [x] Unable to launch arc browser
- [x] Unable to launch chatgpt application

- [x] Can't bring chatgpt back up from minimized as well
- [x] Can't bring arc back up from minimized as well

At the same time can switch between these two wthen they are already launched

QUESTIONS:
? How is the other applications being launched


HYPOTHESIS:



]]

local appMappings = {
	["c"] = { name = "Google Chrome", bundleID = "com.google.Chrome" },
	["b"] = { name = "Brave Browser", bundleID = "com.brave.Browser" },
	["i"] = { name = "iTerm", bundleID = "com.googlecode.iterm2" },
	["a"] = { name = "Arc", bundleID = "company.thebrowser.Browser" },
	["d"] = { name = "Discord", bundleID = "com.hnc.Discord" },
	["v"] = { name = "Visual Studio Code", bundleID = "com.microsoft.VSCode" },
	["g"] = { name = "ChatGPT", bundleID = "com.openai.chat" },
	["o"] = { name = "Obsidian", bundleID = "md.obsidian" },
	["k"] = { name = "Docker", bundleID = "com.docker.docker" },
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

  -- If we're already in the target app, cycle to next window
	if currentApp and targetApp and currentApp:bundleID() == targetApp:bundleID() then
		local windows = targetApp:allWindows()
		
		-- Filter for valid windows and sort by ID for consistent ordering
		-- windows = hs.fnutils.filter(windows, function(win)
		-- 	return win:title() ~= "" and not win:isMinimized()
		-- end)

    -- First, try to unminimize if all windows are minimized
    local allMinimized = hs.fnutils.every(windows, function(win)
      return win:isMinimized()
    end)

    if allMinimized and #windows > 0 then
      print("All windows minimized, unminimizing first window")
      local win = windows[1]
      win:unminimize()
      win:focus()
      targetApp:activate()
      hs.timer.doAfter(0.1, function()
        moveCursorToCenter(win)
      end)
      return
      -- windows[1]:unminimize()
      -- windows[1]:focus()
      -- targetApp:activate()
      -- moveCursorToCenter(windows[1])
      -- return
    end

    windows = hs.fnutils.filter(windows, function(win)
      return win:title() ~= "" and not win:isMinimized()
    end)

  -- Log window count and details
		print("Found " .. #windows .. " windows for " .. appName)
		for i, win in ipairs(windows) do
			print("  Window " .. i .. ": " .. win:title() .. " (ID: " .. win:id() .. ")")
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
        hs.alert.show(appName .. " has no windows")
        return
      end

      -- Try to find a non-minimized window, or fallback to the first one
      table.sort(windows, function(a, b) return a:id() < b:id() end)
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
		-- targetApp:activate()
			-- hs.timer.doAfter(0.1, function()
			-- 	local win = hs.window.focusedWindow()
			-- 	if win then
			-- 		moveCursorToCenter(win)
			-- 	end
			-- end)
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