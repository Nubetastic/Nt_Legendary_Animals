-- Cleanup functionality for Legendary Animals

-- Register event for starting cleanup
RegisterNetEvent('nt_legendary:startCleanup')
AddEventHandler('nt_legendary:startCleanup', function()
    -- Start cleanup process
    if Config.DebugMode then
        print("Starting cleanup process for legendary animal")
    end
    
    -- Remove blip immediately
    RemoveLegendaryBlip()
    
    -- Start cleanup timer
    StartCleanupTimer()
    
    -- Notify server that animal was killed
    TriggerServerEvent('nt_legendary:animalKilled')
end)

-- Register event for animal escaped
RegisterNetEvent('nt_legendary:animalEscaped')
AddEventHandler('nt_legendary:animalEscaped', function()
    -- Handle animal escaped
    if Config.DebugMode then
        print("Legendary animal has escaped")
    end
    
    -- Remove blip
    RemoveLegendaryBlip()
    
    -- Notify player
    TriggerEvent('nt_legendary:notify', 'The legendary animal has escaped!')
    
    -- Notify server that animal escaped
    TriggerServerEvent('nt_legendary:animalEscaped')
    
    -- Reset player state
    playerState = "tracking"
end)

-- Function to remove legendary animal blip
function RemoveLegendaryBlip()
    -- The blips are automatically removed when the entity is deleted
    -- This function is kept for compatibility with existing code
    
    -- Find the animal name for logging purposes
    local animalName = nil
    
    -- Try to find the animal name from ConfigAnimals by comparing the model hash
    if #spawnedPeds > 0 and spawnedPeds[1] ~= nil and DoesEntityExist(spawnedPeds[1]) then
        local model = GetEntityModel(spawnedPeds[1])
        
        for name, data in pairs(ConfigAnimals) do
            if data.LegendaryHash == model then
                animalName = data.BlipName or name
                break
            end
        end
    end
    
    if Config.DebugMode then
        if animalName then
            print("Legendary animal " .. animalName .. " is being removed - blip will be automatically removed")
        else
            print("Legendary animal is being removed - blip will be automatically removed")
        end
    end
end

-- Function to start cleanup timer
function StartCleanupTimer()
    -- Start cleanup timer
    if Config.DebugMode then
        print("Starting cleanup timer: " .. Config.CleanupTimer .. " seconds")
    end
    
    Citizen.CreateThread(function()
        -- Wait for cleanup timer duration
        Citizen.Wait(Config.CleanupTimer * 1000)
        
        -- Clean up all spawned peds
        ClearSpawnedPeds()
        
        -- Reset player state
        playerState = "tracking"
        
        -- Notify player
        TriggerEvent('nt_legendary:notify', 'The legendary animal remains have been cleaned up.')
    end)
end

-- Helper function to display notification
RegisterNetEvent('nt_legendary:notify')
AddEventHandler('nt_legendary:notify', function(message)
    -- Display notification to player
    local _src = source
    TriggerEvent("redem_roleplay:ShowObjective", message, 5000)
    if Config.DebugMode then
        print(message)
    end
end)