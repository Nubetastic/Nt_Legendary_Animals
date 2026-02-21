-- Configuration file for Legendary Animals

Config = {}

-- Debug settings
Config.DebugMode = false -- Set to true to enable debug messages
Config.CleanupDebugMode = false -- Set to true to enable cleanup debug messages

-- Cooldown timers
Config.SpawnCooldownSuccess = 60 * 60 -- 1 hour for success
Config.SpawnCooldownFail = 15 * 60 -- 15 minutes for fail
Config.ServerCooldown = 30 * 60 -- how long until another player can try to spawn an animal that was successfully spawned

-- Spawn settings
Config.SpawnDistance = 300 -- Distance to try to spawn a legendary animal.

-- Spawn chances
Config.SpawnChance = 5 -- base chance for spawning a legendary animal. Set to 100 for 100% spawn.
Config.SpawnTimeChance = 5 -- added to spawnchance if the time of day matches range
Config.SpawnWeatherChance = 5 -- added to spawnchance if the weather matches

-- Check intervals
Config.PlayerCheckInterval = 5 -- seconds between player range checks
Config.CacheRefreshInterval = 30 -- seconds between player cache refreshes

-- Blip settings
Config.BlipSprite = -1646261997
Config.BlipColor = "BLIP_MODIFIER_MP_COLOR_28" -- Red color
Config.BlipScale = 2 -- Size of the blip
Config.BlipDistanceMax = 700 -- Distance at which the blip is visible.
Config.BlipDistanceMin = 100 -- stop the blip from blinking.
Config.BlipBlinkRate = 200 -- 50 milliseconds per 25 distance.
Config.BlipVisibleRate = 500 -- How long it is visible at any distance over BlipDistanceMin.

-- Cleanup settings
Config.Cleanup = {
    MonitorCheckInterval = 5000, -- Main monitor check interval (s)
    
    Timers = {
        LiveAbandonmentTimeout = 10 * 60 * 1000, -- Time before alive animal escapes if abandoned (s)
        DeadAbandonmentTimeout = 2 * 60 * 1000, -- Time before dead animal despawns if abandoned (s)
        DeadExpiryTimeout = 5 * 60 * 1000, -- Time before dead animal despawns regardless of players (s)
        GlobalTimeout = 30 * 60 * 1000, -- Global timeout for entire mission (s)
    },
    
    FinalCleanup = {
        MaxTime = 1 * 60 * 1000, -- Final cleanup phase max time (ms)
        CheckInterval = 10000, -- Final cleanup check interval (ms)
    },
    
    Proximity = {
        DeadBody = 250.0, -- Distance to check if players are near dead body
        FinalCleanup = 100.0, -- Distance to check if players are near for final cleanup
        Escape = 250, -- Distance at which animal escapes if abandoned
    },
}
