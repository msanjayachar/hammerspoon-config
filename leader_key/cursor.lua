---@diagnostic disable-next-line: undefined-global
local hs = hs

local cursor = {}

function cursor.moveToCenter(win)
	local frame = win:frame()
	local centerPoint = hs.geometry.point(frame.x + frame.w / 2 - 65, frame.y + frame.h / 2)
	hs.mouse.absolutePosition(centerPoint)
end

return cursor
