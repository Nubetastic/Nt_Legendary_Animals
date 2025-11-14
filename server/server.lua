-- Server-side functionality for Legendary Animals

-- Table to track cooldowns for legendary animals
local animalCooldowns = {}

-- Table to store active legendary animals and their network IDs
local activeLegendaryAnimals = {}
local activeCompanionAnimals = {}

-- Register server event for checking if animal is on cooldown
RegisterServerEvent('nt_legendary:checkAnimalCooldown')
AddEventHandler('nt_legendary:checkAnimalCooldown', function(animalName)
    local source = source
    
    -- Check if animal is on cooldown
    if animalCooldowns[animalName] then
        -- Animal is on cooldown
        -- Calculate remaining time
        local remainingTime = animalCooldowns[animalName] - os.time()
        
        if remainingTime > 0 then
            -- Notify client that animal is on cooldown
            if Config.DebugMode then
                print("Server: Animal " .. animalName .. " is on cooldown for " .. remainingTime .. " seconds")
            end
            TriggerClientEvent('nt_legendary:animalOnCooldown', source, animalName, remainingTime)
        else
            -- Cooldown expired, remove from table
            animalCooldowns[animalName] = nil
            -- Notify client that animal is available
            if Config.DebugMode then
                print("Server: Animal " .. animalName .. " cooldown expired, now available")
            end
            TriggerClientEvent('nt_legendary:animalNotOnCooldown', source, animalName)
        end
    else
        -- Animal is not on cooldown
        if Config.DebugMode then
            print("Server: Animal " .. animalName .. " is not on cooldown")
        end
        TriggerClientEvent('nt_legendary:animalNotOnCooldown', source, animalName)
    end
end)

-- Register server event for when an animal is spawned
RegisterServerEvent('nt_legendary:animalSpawned')
AddEventHandler('nt_legendary:animalSpawned', function(animalName)
    local source = source
    
    -- Set cooldown for this animal
    animalCooldowns[animalName] = os.time() + Config.ServerCooldown
    
    -- Log the spawn
    if Config.DebugMode then
        print("Server: Player " .. GetPlayerName(source) .. " (ID: " .. source .. ") spawned a " .. animalName)
        print("Server: " .. animalName .. " is now on cooldown for " .. Config.ServerCooldown .. " seconds")
    end
    
    -- Notify all players that a legendary animal was spotted
    TriggerEvent('nt_legendary:notifyAll', 'A ' .. animalName .. ' has been spotted in the wilderness!')
end)

-- Register server event for when an animal is killed
RegisterServerEvent('nt_legendary:animalKilled')
AddEventHandler('nt_legendary:animalKilled', function(animalName)
    local source = source

    if not animalName or animalName == '' then
        if Config.DebugMode then
            print("Server: animalKilled received without animalName from " .. tostring(source))
        end
        return
    end
    
    -- Remove from active animals
    activeLegendaryAnimals[animalName] = nil
    
    -- Log the kill
    if Config.DebugMode then
        print("Server: Legendary animal " .. animalName .. " killed by player " .. GetPlayerName(source) .. " (ID: " .. source .. ")")
    end
end)

-- Register server event for when an animal escapes
RegisterServerEvent('nt_legendary:animalEscaped')
AddEventHandler('nt_legendary:animalEscaped', function(animalName)
    local source = source

    if not animalName or animalName == '' then
        if Config.DebugMode then
            print("Server: animalEscaped received without animalName from " .. tostring(source))
        end
        return
    end
    
    -- Remove from active animals
    activeLegendaryAnimals[animalName] = nil
    
    -- Log the escape
    if Config.DebugMode then
        print("Server: Legendary animal " .. animalName .. " escaped from player " .. GetPlayerName(source) .. " (ID: " .. source .. ")")
    end
end)

-- Function to clean up expired cooldowns (run periodically)
Citizen.CreateThread(function()
    while true do
        Wait(60000) -- Check every minute
        
        local currentTime = os.time()
        local removedCount = 0
        
        -- Check all cooldowns and remove expired ones
        for animalName, cooldownTime in pairs(animalCooldowns) do
            if currentTime > cooldownTime then
                if Config.DebugMode then
                    print("Server: Cooldown expired for " .. animalName)
                end
                animalCooldowns[animalName] = nil
                removedCount = removedCount + 1
            end
        end
        
        if removedCount > 0 and Config.DebugMode then
            print("Server: Removed " .. removedCount .. " expired animal cooldowns")
        end
    end
end)

-- Broadcast notification to all players
RegisterNetEvent('nt_legendary:notifyAll')
AddEventHandler('nt_legendary:notifyAll', function(message)
    TriggerClientEvent('nt_legendary:notify', -1, message)
end)

-- Register server event for getting current weather
RegisterServerEvent('nt_legendary:getServerWeather')
AddEventHandler('nt_legendary:getServerWeather', function()
    local source = source
    
    -- FALLBACK: Use pcall to safely call the export and handle any errors
    local success, currentWeather = pcall(function()
        return exports["weathersync"]:getWeather()
    end)
    
    -- FALLBACK: If the export call failed or returned nil, use a default weather
    if not success or not currentWeather then
        if Config.DebugMode then
            print("ERROR: Failed to get weather from weathersync export. Using fallback weather.")
        end
        currentWeather = "clear" -- Default fallback weather
    end
    
    -- Send the weather back to the requesting client
    TriggerClientEvent('nt_legendary:receiveServerWeather', source, currentWeather)
    
    -- Debug log
    if Config.DebugMode then
        print("Server: Sent weather '" .. currentWeather .. "' to player " .. GetPlayerName(source) .. " (ID: " .. source .. ")")
    end
end)

-- Register server event for caching network IDs of legendary and companion animals
RegisterServerEvent('nt_legendary:cacheNetworkIds')
AddEventHandler('nt_legendary:cacheNetworkIds', function(animalName, legendaryNetId, companionNetIds)
    local source = source

    -- Validate
    if not animalName or not legendaryNetId or tonumber(legendaryNetId) == 0 then
        if Config.DebugMode then
            print("Server: cacheNetworkIds invalid data from " .. tostring(source) .. ", animal=" .. tostring(animalName) .. ", netId=" .. tostring(legendaryNetId))
        end
        return
    end
    
    -- Store the network IDs
    activeLegendaryAnimals[animalName] = {
        netId = legendaryNetId,
        owner = source,
        timestamp = os.time()
    }
    
    -- Store companion network IDs if provided
    if companionNetIds and #companionNetIds > 0 then
        activeCompanionAnimals[animalName] = {
            netIds = companionNetIds,
            owner = source,
            timestamp = os.time()
        }
    end
    
    if Config.DebugMode then
        print("Server: Cached network ID " .. legendaryNetId .. " for legendary " .. animalName .. " from player " .. source)
        if companionNetIds and #companionNetIds > 0 then
            print("Server: Cached " .. #companionNetIds .. " companion network IDs for " .. animalName)
        end
    end
    
    -- Slight delay to reduce race with replication
    SetTimeout(1500, function()
        TriggerClientEvent('nt_legendary:attachBlipToEntity', -1, animalName, legendaryNetId)
    end)
end)

-- Register server event for notifying all clients about a legendary animal spawn
RegisterServerEvent('nt_legendary:notifyLegendarySpawn')
AddEventHandler('nt_legendary:notifyLegendarySpawn', function(animalName, netId)
    -- Broadcast to all players
    TriggerClientEvent('nt_legendary:attachBlipToEntity', -1, animalName, netId)
    
    -- Log the broadcast
    if Config.DebugMode then
        print("Server: Broadcasting legendary " .. animalName .. " (Network ID: " .. netId .. ") to all players")
    end
end)

-- Handle player joining - notify them of any active legendary animals
AddEventHandler('playerJoining', function(source)
    -- Wait a moment for the player to fully load
    Citizen.Wait(5000)
    
    -- Check if there are any active legendary animals
    local activeCount = 0
    for animalName, data in pairs(activeLegendaryAnimals) do
        -- Only notify about recent spawns (within the last hour)
        if os.time() - data.timestamp < 3600 then
            -- Send notification to the joining player
            TriggerClientEvent('nt_legendary:notify', source, 'A ' .. animalName .. ' was recently spotted in the wilderness!')
            
            -- Send network ID to attach blip
            TriggerClientEvent('nt_legendary:attachBlipToEntity', source, animalName, data.netId)
            
            activeCount = activeCount + 1
        end
    end
    
    if Config.DebugMode and activeCount > 0 then
        print("Server: Notified joining player " .. GetPlayerName(source) .. " (ID: " .. source .. ") about " .. activeCount .. " active legendary animals")
    end
end)

-- Handle player dropping to clean up their animals
AddEventHandler('playerDropped', function()
    local source = source
    
    -- Check if this player owned any legendary animals
    for animalName, data in pairs(activeLegendaryAnimals) do
        if data.owner == source then
            -- This player owned this animal, remove it from active list
            activeLegendaryAnimals[animalName] = nil
            
            if Config.DebugMode then
                print("Server: Removed legendary " .. animalName .. " from active list due to owner disconnect")
            end
        end
    end
    
    -- Check if this player owned any companion animals
    for animalName, data in pairs(activeCompanionAnimals) do
        if data.owner == source then
            -- This player owned these companions, remove them from active list
            activeCompanionAnimals[animalName] = nil
            
            if Config.DebugMode then
                print("Server: Removed companions for " .. animalName .. " from active list due to owner disconnect")
            end
        end
    end
end)

-- Register server event for requesting active legendary animals
RegisterServerEvent('nt_legendary:requestActiveAnimals')
AddEventHandler('nt_legendary:requestActiveAnimals', function()
    local source = source
    
    -- Send active legendary animals to the requesting client
    for animalName, data in pairs(activeLegendaryAnimals) do
        -- Only send recent spawns (within the last hour)
        if os.time() - data.timestamp < 3600 then
            TriggerClientEvent('nt_legendary:attachBlipToEntity', source, animalName, data.netId)
            
            if Config.DebugMode then
                print("Server: Sent active legendary " .. animalName .. " (Network ID: " .. data.netId .. ") to player " .. source)
            end
        end
    end
end)

-- Print server startup message
if Config.DebugMode then
    print("^2Legendary Animals^7: Server script initialized")
    print("^2Legendary Animals^7: Server cooldown set to " .. Config.ServerCooldown .. " seconds")
end