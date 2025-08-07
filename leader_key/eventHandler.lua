---@diagnostic disable-next-line: undefined-global
local hs = hs

local config = require("leader_key.config")
local actions = require("leader_key.actions")

local eventHandler = {}

-- Leader state
local leaderState = false
local leaderSequence = ""
local leaderTimer = nil
local windowSelectionTimer = nil

local function resetLeader()
	leaderState = false
	leaderSequence = ""
	if leaderTimer then
		leaderTimer:stop()
	end
	leaderTimer = nil
end

local function handleKey(event)
	local key = event:getCharacters(true)
	local keyCode = event:getKeyCode()

	if not leaderState then
		if hs.keycodes.map[keyCode] == "f18" then
			leaderState = true
			leaderSequence = ""
			if leaderTimer then
				leaderTimer:stop()
			end
			leaderTimer = hs.timer.doAfter(config.sequenceTimeout, resetLeader)
			return true
		end
		return false
	end

	if actions.windowSelectionMode() then
		-- Handle window selection mode...
		return true
	end

	if leaderTimer then
		leaderTimer:stop()
	end
	leaderTimer = hs.timer.doAfter(config.sequenceTimeout, resetLeader)

	if key and key:match("%a") then
		leaderSequence = leaderSequence .. key:lower()
		if #leaderSequence == 1 then
			actions.perform(leaderSequence, resetLeader)
			return true
		end
	end

	resetLeader()
	return false
end

function eventHandler.start()
	hs.eventtap.new({ hs.eventtap.event.types.keyDown }, handleKey):start()
end

return eventHandler
