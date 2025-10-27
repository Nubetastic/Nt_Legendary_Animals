-- Configuration file for Legendary Animals

Config = {}

-- Debug settings
Config.DebugMode = false -- Set to true to enable debug messages

-- Cooldown timers
Config.SpawnCooldownSuccess = 60 * 60 -- 1 hour for success
Config.SpawnCooldownFail = 15 * 60 -- 15 minutes for fail
Config.ServerCooldown = 30 * 60 -- how long until another player can try to spawn an animal that was successfully spawned

-- Spawn settings
Config.SpawnDistance = 600 -- Distance to try to spawn a legendary animal.
Config.DistanceEscape = 250 -- If player is more then this distance it starts escaping.

-- Spawn chances
Config.SpawnChance = 100 -- base chance for spawning a legendary animal. Set to 100 for 100% spawn.
Config.SpawnTimeChance = 5 -- added to spawnchance if the time of day matches range
Config.SpawnWeatherChance = 15 -- added to spawnchance if the weather matches

-- Timers
Config.CleanupTimer = 5 * 60 -- after 5 minutes of the legendary animal being dead, it cleans up the peds
Config.EscapeTimer = 10 * 60 -- If no players in range for this time, animal despawns

-- Check intervals
Config.PlayerCheckInterval = 5 -- seconds between player range checks
Config.CacheRefreshInterval = 30 -- seconds between player cache refreshes

-- Blip settings
Config.BlipSprite = -1646261997
Config.BlipColor = "BLIP_MODIFIER_MP_COLOR_28" -- Red color
Config.BlipScale = 1.5 -- Size of the blip
Config.BlipDistanceMax = 700 -- Distance at which the blip is visible.
Config.BlipDistanceMin = 100 -- stop the blip from blinking.
Config.BlipBlinkRate = 200 -- 50 milliseconds per 25 distance.
Config.BlipVisibleRate = 500 -- How long it is visible at any distance over BlipDistanceMin.
