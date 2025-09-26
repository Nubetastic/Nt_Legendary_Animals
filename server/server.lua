-- Server-side functionality for Legendary Animals

-- Table to track cooldowns for legendary animals
local animalCooldowns = {}

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
    TriggerClientEvent('nt_legendary:notifyAll', -1, 'A ' .. animalName .. ' has been spotted in the wilderness!')
end)

-- Register server event for when an animal is killed
RegisterServerEvent('nt_legendary:animalKilled')
AddEventHandler('nt_legendary:animalKilled', function()
    local source = source
    
    -- Log the kill
    if Config.DebugMode then
        print("Server: Legendary animal killed by player " .. GetPlayerName(source) .. " (ID: " .. source .. ")")
    end
end)

-- Register server event for when an animal escapes
RegisterServerEvent('nt_legendary:animalEscaped')
AddEventHandler('nt_legendary:animalEscaped', function()
    local source = source
    
    -- Log the escape
    if Config.DebugMode then
        print("Server: Legendary animal escaped from player " .. GetPlayerName(source) .. " (ID: " .. source .. ")")
    end
end)

-- Function to clean up expired cooldowns (run periodically)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(60000) -- Check every minute
        
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

-- Print server startup message
if Config.DebugMode then
    print("^2Legendary Animals^7: Server script initialized")
    print("^2Legendary Animals^7: Server cooldown set to " .. Config.ServerCooldown .. " seconds")
end