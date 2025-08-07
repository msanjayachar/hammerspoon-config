---@diagnostic disable-next-line: undefined-global
local hs = hs

local config = require("leader_key.config")
local cursor = require("leader_key.cursor")
local space = require("leader_key.space")
local utils = require("leader_key.utils")

local actions = {}

-- Map to store windows and leader state
local windowIndexMap = {}
local windowSelectionMode = false

-- Exported flags and maps to allow interaction from event handler
actions.windowIndexMap = windowIndexMap
actions.windowSelectionMode = function()
	return windowSelectionMode
end
actions.setWindowSelectionMode = function(val)
	windowSelectionMode = val
end

function actions.perform(sequence, resetLeaderCallback)
	local appEntry = config.appMappings[sequence]
	if not appEntry then
		hs.alert.show("Unknown sequence: " .. sequence)
		return
	end

	-- Most of the original `performAction` logic goes here,
	-- using helper modules like `cursor`, `space`, and `utils`.

	-- Call `resetLeaderCallback()` when needed.
end

return actions
