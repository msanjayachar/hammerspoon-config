---@diagnostic disable-next-line: undefined-global
local hs = hs

local utils = {}

function utils.sortWindows(windows)
	table.sort(windows, function(a, b)
		return a:id() < b:id()
	end)
end

function utils.getVisibleWindows(app)
	return hs.fnutils.filter(app:allWindows(), function(win)
		return win:title() ~= "" and not win:isMinimized() and win:isVisible()
	end)
end

return utils
