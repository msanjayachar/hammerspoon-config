-- Hammerspoon configuration entry point
---@diagnostic disable-next-line: undefined-global
local hs = hs

-- Load modules
local keyMappings = require("key_mappings")
local windowManagement = require("window_management")
local appWatcher = require("app_watcher")
local leaderKeys = require("leader_key")

-- Initialize modules
keyMappings.init()
windowManagement.init()
appWatcher.init()
leaderKeys.init()

-- Optional: auto-reload config on save
hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", hs.reload):start()

hs.alert.show("Hammerspoon config loaded")
