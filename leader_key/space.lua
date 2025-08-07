---@diagnostic disable-next-line: undefined-global
local hs = hs

local space = {}

function space.getWindowSpace(win)
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

return space
