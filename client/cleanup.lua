-- Cleanup functionality for Legendary Animals

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
    
    if Config.CleanupDebugMode then
        if animalName then
            print("Legendary animal " .. animalName .. " is being removed - blip will be automatically removed")
        else
            print("Legendary animal is being removed - blip will be automatically removed")
        end
    end
end

-- Function to start centralized cleanup monitor
function StartCleanupMonitor(animalData)
    if Config.CleanupDebugMode then
        print("Starting centralized cleanup monitor for " .. animalData.BlipName)
    end
    
    Citizen.CreateThread(function()
        -- Initialize flags
        local livingFlag = true
        local playersInAreaFlag = false
        local pedsExistFlag = true
        local missionActive = true
        
        -- Initialize timers (in milliseconds) - count down to 0
        local liveAbandonmentTimer = Config.Cleanup.Timers.LiveAbandonmentTimeout
        local deadAbandonmentTimer = Config.Cleanup.Timers.DeadAbandonmentTimeout
        local deadNonAbandonmentTimer = Config.Cleanup.Timers.DeadExpiryTimeout
        local maxMissionTimer = Config.Cleanup.Timers.GlobalTimeout
        
        -- Timer management
        local timerAddInterval = 1000
        local monitorInterval = Config.Cleanup.MonitorCheckInterval
        local lastMMTFloor = math.floor(maxMissionTimer / timerAddInterval)
        
        local deathTime = nil
        local triggerReason = ""
        local lastDebugPrint = 0
        local debugPrintInterval = 5000
        
        while missionActive do
            Wait(Config.Cleanup.MonitorCheckInterval)
            local now = GetGameTimer()
            
            -- Check if peds still exist
            if #spawnedPeds == 0 or not DoesEntityExist(spawnedPeds[1]) then
                pedsExistFlag = false
                triggerReason = livingFlag and "peds_disappeared_living" or "skinned"
                missionActive = false
            else
                local legendaryPed = spawnedPeds[1]
                
                -- Update living flag
                if livingFlag and IsEntityDead(legendaryPed) then
                    livingFlag = false
                    deathTime = now
                    legendaryDeathCoords = GetEntityCoords(legendaryPed)
                    TriggerServerEvent('nt_legendary:animalKilled', animalData.BlipName)
                    RemoveLegendaryBlip()
                end
                
                -- Update players in area flag
                if livingFlag then
                    playersInAreaFlag = CheckPlayerInRange(Config.Cleanup.Proximity.Escape)
                else
                    playersInAreaFlag = CheckPlayerInRange(Config.Cleanup.Proximity.DeadBody, legendaryDeathCoords)
                end
            end
            
            -- Add timer seconds every 5 seconds when conditions are not active
            local currentMMTFloor = math.floor(maxMissionTimer / monitorInterval)
            if currentMMTFloor ~= lastMMTFloor then
                lastMMTFloor = currentMMTFloor
                
                if livingFlag and playersInAreaFlag and liveAbandonmentTimer > 0 then
                    liveAbandonmentTimer = math.min(liveAbandonmentTimer + timerAddInterval, Config.Cleanup.Timers.LiveAbandonmentTimeout)
                end
                
                if not livingFlag then
                    if playersInAreaFlag and deadAbandonmentTimer > 0 then
                        deadAbandonmentTimer = math.min(deadAbandonmentTimer + timerAddInterval, Config.Cleanup.Timers.DeadAbandonmentTimeout)
                    end
                    if not playersInAreaFlag and deadNonAbandonmentTimer > 0 then
                        deadNonAbandonmentTimer = math.min(deadNonAbandonmentTimer + timerAddInterval, Config.Cleanup.Timers.DeadExpiryTimeout)
                    end
                end
            end
            
            -- Decrement timers based on conditions
            if livingFlag and not playersInAreaFlag then
                liveAbandonmentTimer = liveAbandonmentTimer - monitorInterval
            end
            
            if not livingFlag then
                if not playersInAreaFlag then
                    deadAbandonmentTimer = deadAbandonmentTimer - monitorInterval
                else
                    deadNonAbandonmentTimer = deadNonAbandonmentTimer - monitorInterval
                end
            end
            
            maxMissionTimer = maxMissionTimer - monitorInterval
            
            -- Check cleanup triggers
            if liveAbandonmentTimer <= 0 then
                triggerReason = "escaped_abandoned"
                TriggerServerEvent('nt_legendary:animalEscaped', animalData.BlipName)
                TriggerEvent('nt_legendary:notify', 'The legendary animal has escaped!')
                missionActive = false
            end
            
            if deadAbandonmentTimer <= 0 then
                triggerReason = "dead_abandoned"
                missionActive = false
            end
            
            if deadNonAbandonmentTimer <= 0 then
                triggerReason = "dead_expiry"
                missionActive = false
            end
            
            if maxMissionTimer <= 0 then
                triggerReason = "escaped_expiry"
                TriggerServerEvent('nt_legendary:animalEscaped', animalData.BlipName)
                missionActive = false
            end
            
            -- Debug output
            if Config.CleanupDebugMode and (now - lastDebugPrint) > debugPrintInterval then
                lastDebugPrint = now
                print("Living: " .. tostring(livingFlag) .. " | PlayersInArea: " .. tostring(playersInAreaFlag) ..
                      " | LAT: " .. string.format("%.1f", liveAbandonmentTimer / 1000) .. "s | DAT: " .. string.format("%.1f", deadAbandonmentTimer / 1000) .. "s | " ..
                      "DNAT: " .. string.format("%.1f", deadNonAbandonmentTimer / 1000) .. "s | MMT: " .. string.format("%.1f", maxMissionTimer / 1000) .. "s")
            end
        end
        
        -- Final Cleanup Phase
        ClearSpawnedPeds()
        RemoveLegendaryBlip()
        
        if globalCooldown <= 0 then
            playerState = "tracking"
        end
        legendaryDeathCoords = nil
        
        if Config.CleanupDebugMode then
            print("Final cleanup complete for " .. animalData.BlipName .. " (Reason: " .. triggerReason .. ")")
        end
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