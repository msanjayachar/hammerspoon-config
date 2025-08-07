local eventHandler = require("leader_key.eventHandler")

local leaderKeys = {}

function leaderKeys.init()
	eventHandler.start()
end

return leaderKeys
