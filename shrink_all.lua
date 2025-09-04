----@diagnostic disable-next-line: undefined-global
local hs = hs
local M = {}
local savedFrames, shrunk = {}, false

-- CONFIG
M.useFixed = true
M.FIXED = { w = 1400, h = 1000 }
M.PCT = { w = 0.7, h = 0.8 }
-- M.hotkey = { mods = {}, key = "F13" }
M.hotkey = { mods = { "ctrl" }, key = "space" }
M.exclude = { "Activity Monitor", "Slack", "Screen Sharing" } -- app names to skip

local wf = hs.window.filter
	.new()
	:setCurrentSpace(true)
	:setDefaultFilter({ allowRoles = { "AXStandardWindow" }, visible = true })

local function targetRect(screen, cfg)
	local f = screen:frame()
	local w, h = cfg.FIXED.w, cfg.FIXED.h
	if not cfg.useFixed then
		w, h = f.w * cfg.PCT.w, f.h * cfg.PCT.h
	end
	return hs.geometry.rect(
		math.floor(f.x + (f.w - w) / 2),
		math.floor(f.y + (f.h - h) / 2),
		math.floor(w),
		math.floor(h)
	)
end

local function isExcluded(win, list)
	local app = win:application()
	local name = app and app:name() or ""
	for _, n in ipairs(list or {}) do
		if n == name then
			return true
		end
	end
	return false
end

-- replace M.shrinkAll() with a toggle
function M.shrinkAll()
	local wins = wf:getWindows()
	if not shrunk then
		savedFrames = {}
		for _, win in ipairs(wins) do
			if win:isStandard() and not win:isFullScreen() and not isExcluded(win, M.exclude) then
				savedFrames[win:id()] = win:frame()
				win:setFrame(targetRect(win:screen(), M), 0)
			end
		end
		shrunk = true
	else
		for _, win in ipairs(wins) do
			local old = savedFrames[win:id()]
			if old then
				win:setFrame(old, 0)
			end
		end
		savedFrames, shrunk = {}, false
	end
end

function M.bind()
	hs.hotkey.bind(M.hotkey.mods, M.hotkey.key, M.shrinkAll)
end

return M
