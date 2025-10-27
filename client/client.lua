-- Main client file for Legendary Animals

-- Global variables
spawnedPeds = {} -- List of peds spawned, with legendary animal as first entry
playerCache = nil -- Cached player that is within range of the legendary animal
currentTime = 0 -- Current time of day
currentWeather = "" -- Current weather
playerState = "tracking" -- Current state: tracking, cooldown, or hunting
localCooldowns = {} -- Table to track local cooldowns for specific animals
globalCooldown = 0 -- Cooldown for all legendary animals

-- Initialize the script
Citizen.CreateThread(function()
    -- Wait for player to fully load
    Wait(2000)
    
    -- Set initial values for time and weather
    currentTime = UpdateCurrentTime()
    currentWeather = UpdateCurrentWeather()
    
    if Config.DebugMode then
        print("Legendary Animals script initialized")
        print("Current time: " .. currentTime)
        print("Current weather: " .. currentWeather)
    end
    
    -- Request active legendary animals from server
    Wait(3000) -- Wait a bit more to ensure network is ready
    TriggerServerEvent('nt_legendary:requestActiveAnimals')
    
    if Config.DebugMode then
        print("Requested active legendary animals from server")
    end
end)

-- Main loop to check for legendary animal spawn areas
Citizen.CreateThread(function()
    -- Wait for full initialization
    Wait(5000)
    
    -- Main loop
    while true do
        Wait(1000) -- Check every second
        
        -- If player is not on cooldown
        if playerState == "tracking" then
            -- Check if player is in any spawn area
            local animalData = IsPlayerInSpawnArea()
            
            if animalData then
                local animalName = animalData.BlipName
                
                -- Check if this specific animal is on local cooldown
                if not localCooldowns[animalName] or localCooldowns[animalName] <= 0 then
                    -- Check with server if animal is not on cooldown
                    TriggerServerEvent('nt_legendary:checkAnimalCooldown', animalName)
                end
            end
        end
        
        -- Update cooldown timers
        if globalCooldown > 0 then
            globalCooldown = globalCooldown - 1
            if globalCooldown <= 0 then
                playerState = "tracking"
                if Config.DebugMode then
                    print("Global cooldown expired, now tracking")
                end
            end
        end
        
        -- Update local cooldowns for specific animals
        for animal, time in pairs(localCooldowns) do
            if time > 0 then
                localCooldowns[animal] = time - 1
                if localCooldowns[animal] <= 0 and Config.DebugMode then
                    print("Local cooldown for " .. animal .. " expired")
                end
            end
        end
    end
end)

-- Function to check if player is in a spawn area
function IsPlayerInSpawnArea()
    -- Get player position
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    -- Check each animal's spawn area
    for animalName, animalData in pairs(ConfigAnimals) do
        local spawnAreaCoords = animalData.SpawnArea
        local range = Config.SpawnDistance
        
        -- Calculate distance
        local distance = #(playerCoords - spawnAreaCoords)
        
        -- If player is in range of spawn area
        if distance <= range then
            return animalData
        end
    end
    
    -- Not in any spawn area
    return nil
end

-- Function to attempt spawning a legendary animal
function AttemptSpawn(animalData)
    -- Check time and weather conditions
    local timeBonus = 0
    local weatherBonus = 0
    
    -- Check if current time matches preferred time
    if IsPreferredTime(animalData) then
        timeBonus = Config.SpawnTimeChance
        if Config.DebugMode then
            print("Time bonus applied: " .. timeBonus)
        end
    end
    
    -- Check if current weather matches preferred weather
    if IsPreferredWeather(animalData) then
        weatherBonus = Config.SpawnWeatherChance
        if Config.DebugMode then
            print("Weather bonus applied: " .. weatherBonus)
        end
    end
    
    -- Calculate total spawn chance
    local totalChance = Config.SpawnChance + timeBonus + weatherBonus
    if Config.DebugMode then
        print("Total spawn chance: " .. totalChance)
    end
    
    -- Roll random number
    local roll = math.random(1, 100)
    if Config.DebugMode then
        print("Spawn roll: " .. roll)
    end
   
    
    -- If successful, spawn animal
    if roll <= totalChance then
        if Config.DebugMode then
            print("Spawn roll successful!")
        end
        HandleSuccessfulSpawn(animalData)
        return true
    else
        -- If failed, set cooldown
        if Config.DebugMode then
            print("Spawn roll failed")
        end
        HandleFailedSpawn()
        return false
    end
end

-- Function to handle successful spawn
function HandleSuccessfulSpawn(animalData)
    -- Set player state to hunting
    playerState = "hunting"
    if Config.DebugMode then
        print("Player state changed to hunting")
    end
    
    -- Set global cooldown
    globalCooldown = Config.SpawnCooldownSuccess
    if Config.DebugMode then
        print("Set global cooldown to " .. globalCooldown .. " seconds")
    end
    
    -- Notify server of spawn
    TriggerServerEvent('nt_legendary:animalSpawned', animalData.BlipName)
    
    -- Choose random spawn location
    local randomIndex = math.random(1, #animalData.SpawnCoords)
    local spawnLocation = animalData.SpawnCoords[randomIndex]
    
    -- Call spawn function
    SpawnLegendaryAnimal(animalData, spawnLocation)
end

-- Function to handle failed spawn
function HandleFailedSpawn()
    -- Set player state to cooldown
    playerState = "cooldown"
    if Config.DebugMode then
        print("Player state changed to cooldown")
    end
    
    -- Set global cooldown to fail cooldown
    globalCooldown = Config.SpawnCooldownFail
    if Config.DebugMode then
        print("Set global cooldown to " .. globalCooldown .. " seconds (fail cooldown)")
    end
    
    -- Notify player
    TriggerEvent('nt_legendary:notify', 'You were unable to find any legendary animals in this area.')
end

-- Register event handlers
RegisterNetEvent('nt_legendary:animalOnCooldown')
AddEventHandler('nt_legendary:animalOnCooldown', function(animalName, remainingTime)
    -- Handle animal on cooldown
    if Config.DebugMode then
        print("Animal " .. animalName .. " is on cooldown for " .. remainingTime .. " seconds")
    end
    
    -- Set local cooldown for this specific animal
    localCooldowns[animalName] = remainingTime
    
    -- Notify player
    TriggerEvent('nt_legendary:notify', 'The ' .. animalName .. ' was recently spotted by another hunter.')
end)

-- Register event for animal not on cooldown
RegisterNetEvent('nt_legendary:animalNotOnCooldown')
AddEventHandler('nt_legendary:animalNotOnCooldown', function(animalName)
    -- Handle animal not on cooldown
    if Config.DebugMode then
        print("Animal " .. animalName .. " is not on cooldown, attempting to spawn")
    end
    
    -- Find animal data
    local animalData = nil
    for name, data in pairs(ConfigAnimals) do
        if name == animalName then
            animalData = data
            break
        end
    end
    
    if animalData then
        -- Attempt to spawn
        AttemptSpawn(animalData)
    else
        if Config.DebugMode then
            print("Error: Could not find data for animal " .. animalName)
        end
    end
end)

-- Register event for animal escaped
RegisterNetEvent('nt_legendary:animalEscaped')
AddEventHandler('nt_legendary:animalEscaped', function()
    -- Handle animal escaped
    if Config.DebugMode then
        print("Legendary animal escaped")
    end
    
    -- Clear spawned peds
    ClearSpawnedPeds()
    
    -- Reset player state
    playerState = "tracking"
    
    -- Set global cooldown
    globalCooldown = Config.SpawnCooldownFail
    
    -- Notify player
    TriggerEvent('nt_legendary:notify', 'The legendary animal has escaped!')
end)

-- Register event for starting cleanup
RegisterNetEvent('nt_legendary:startCleanup')
AddEventHandler('nt_legendary:startCleanup', function()
    -- Start cleanup timer
    if Config.DebugMode then
        print("Starting cleanup timer for " .. Config.CleanupTimer .. " seconds")
    end
    
    -- Wait for cleanup timer
    Citizen.CreateThread(function()
        -- Wait for cleanup timer
        Wait(Config.CleanupTimer * 1000)
        
        -- Clear spawned peds
        ClearSpawnedPeds()
        
        -- Reset player state
        playerState = "tracking"
        
        if Config.DebugMode then
            print("Cleanup complete, player state reset to tracking")
        end
    end)
end)