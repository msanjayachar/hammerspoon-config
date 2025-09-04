--- Application watcher module for Hammerspoon
local appWatcher = {}

---@diagnostic disable-next-line: undefined-global
local hs = hs

-- Position ChatGPT window on launch
local function positionChatGPTWindow()
	hs.printf("[DEBUG] positionChatGPTWindow called")
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

-- Initialize application watcher
function appWatcher.init()
	local chatGPTWatcher = hs.application.watcher.new(function(appName, eventType, appObject)
		if appName == "ChatGPT" and eventType == hs.application.watcher.launched then
			hs.timer.waitUntil(function()
				return hs.application.get("ChatGPT") ~= nil
			end, positionChatGPTWindow)
		end
	end)
	chatGPTWatcher:start()
end

return appWatcher
