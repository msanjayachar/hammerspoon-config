-- Hammerspoon configuration entry point
---@diagnostic disable-next-line: undefined-global
local hs = hs

-- Load modules
local keyMappings = require("key_mappings")
local leaderKeys = require("app_key_mappings")
local alertTimer = require("alert_timer")
local shrink = require("shrink_all")
shrink.bind()

-- Initialize modules
keyMappings.init()
leaderKeys.init()
alertTimer.start()

-- Optional: auto-reload config on save
hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", hs.reload):start()

hs.alert.show("Hammerspoon config loaded")
