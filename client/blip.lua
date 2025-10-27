-- Blip functionality for Legendary Animals

-- Table to track legendary blips
local legendaryBlips = {}

-- Table to track legendary animal entities and their blips
local legendaryEntities = {}

-- Table to track if an entity has a visible blip
local entityHasBlip = {}

-- Register client event for attaching a blip to an entity
RegisterNetEvent('nt_legendary:attachBlipToEntity')
AddEventHandler('nt_legendary:attachBlipToEntity', function(animalName, netId)
    -- Try to resolve the network ID robustly
    Citizen.CreateThread(function()
        local attempts = 0
        local maxAttempts = 120 -- up to ~60s if 500ms per attempt
        local entity = 0

        while attempts < maxAttempts do
            if NetworkDoesNetworkIdExist(netId) then
                entity = NetworkGetEntityFromNetworkId(netId)
                if entity ~= 0 and DoesEntityExist(entity) then
                    CreateLegendaryBlip(animalName, entity)
                    return
                end
            end

            if Config.DebugMode and attempts % 10 == 0 then
                print("^3Waiting for entity for legendary " .. animalName .. " (Network ID: " .. tostring(netId) .. ") attempt " .. attempts .. "/" .. maxAttempts .. "^7")
            end

            attempts = attempts + 1
            Wait(500)
        end

        if Config.DebugMode then
            print("^1Failed to resolve entity for legendary " .. animalName .. " with Network ID: " .. tostring(netId) .. " after " .. attempts .. " attempts^7")
        end
    end)
end)

-- Function to create a blip for legendary animal
function CreateLegendaryBlip(animalName, entity)
    -- Remove any existing blip for this animal
    if entityHasBlip[animalName] then
        RemoveEntityBlip(animalName)
    end
    
    -- Store the entity reference
    legendaryEntities[animalName] = entity
    
    -- Start a thread to monitor entity existence and handle blip creation/removal based on distance
    StartBlipMonitorThread(animalName, entity)
    
    -- Notify player
    TriggerEvent('nt_legendary:notify', 'A Legendary ' .. animalName .. ' has been spotted!')
    
    if Config.DebugMode then
        local coords = GetEntityCoords(entity)
        print("^2Tracking legendary " .. animalName .. " at coordinates: " .. coords.x .. ", " .. coords.y .. ", " .. coords.z .. "^7")
    end
end

-- Function to create a blip attached to the entity
function CreateEntityBlip(animalName, entity)
    -- Create a blip attached to the entity
    local blip = Citizen.InvokeNative(0x23F74C2FDA6E7C61, 1664425300, entity)
    
    -- Make the blip visible on networked entities
    Citizen.InvokeNative(0xE37287EE358939C3, entity)
    
    -- Set the sprite (hash)
    SetBlipSprite(blip, Config.BlipSprite, true)
    
    -- Set blip properties
    Citizen.InvokeNative(0x9CB1A1623062F402, blip, "Legendary " .. animalName) -- Set name
    
    -- Set blip color
    Citizen.InvokeNative(0x662D364ABF16DE2F, blip, GetHashKey(Config.BlipColor))
	Citizen.InvokeNative(0x662D364ABF16DE2F, blip, GetHashKey("BLIP_MODIFIER_RADAR_EDGE_ALWAYS"))
    
    -- Set blip scale
    SetBlipScale(blip, Config.BlipScale)
    
    -- Store the blip reference
    legendaryBlips[animalName] = blip
    entityHasBlip[animalName] = true
    
    if Config.DebugMode then
        print("^2Created entity-attached blip " .. blip .. " for Legendary " .. animalName .. "^7")
    end
    
    return blip
end

-- Function to add a blip to an entity
function AddBlip(animalName, entityId)
    -- Only create a blip if one doesn't already exist
    if not entityHasBlip[animalName] then
        CreateEntityBlip(animalName, entityId)
        
        if Config.DebugMode then
            local distance = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(entityId))
            print("^2Added blip for Legendary " .. animalName .. " (Distance: " .. string.format("%.1f", distance) .. ")^7")
        end
    end
end

-- Function to remove a blip from an entity
function RemoveEntityBlip(animalName)
    if entityHasBlip[animalName] and legendaryBlips[animalName] then
        if DoesBlipExist(legendaryBlips[animalName]) then
            -- Use native RemoveBlip function for the blip object
            RemoveBlip(legendaryBlips[animalName])
            
            if Config.DebugMode then
                print("^3Removed blip for Legendary " .. animalName .. "^7")
            end
        end
        
        legendaryBlips[animalName] = nil
        entityHasBlip[animalName] = false
    end
end

-- Function to monitor entity existence and handle blip creation/removal
function StartBlipMonitorThread(animalName, entityId)
    -- Only call LegendaryNotify if it exists
    if LegendaryNotify then
        LegendaryNotify()
    end
    
    Citizen.CreateThread(function()
        local blinkState = true -- Start with blip visible
        local lastToggleTime = 0
        local currentInterval = Config.BlipVisibleRate -- Start with visible interval
        
        while DoesEntityExist(entityId) do
            -- Get the animal's current position
            local animalCoords = GetEntityCoords(entityId)
            
            -- Get player position
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            
            -- Calculate distance between player and animal
            local distance = #(playerCoords - animalCoords)
            
            -- Handle blip visibility and blinking based on distance
            -- Check if player is within maximum blip visibility distance
            if distance <= Config.BlipDistanceMax then
                -- Handle blinking based on distance
                if distance > Config.BlipDistanceMin then
                    -- Get current time for blinking logic
                    local currentTime = GetGameTimer()
                    
                    -- Check if it's time to toggle the blink state
                    if currentTime - lastToggleTime > currentInterval then
                        -- Toggle the blink state
                        blinkState = not blinkState
                        lastToggleTime = currentTime
                        
                        -- Set the next interval based on the new state
                        if blinkState then
                            -- Blip is now visible, use visible rate
                            currentInterval = Config.BlipVisibleRate
                            
                            -- Add the blip if it doesn't exist
                            if not entityHasBlip[animalName] then
                                AddBlip(animalName, entityId)
                            end
                        else
                            -- Blip is now hidden, use blink rate
                            -- Calculate blink rate based on distance
                            local hideInterval = math.floor((distance - Config.BlipDistanceMin) / 25) * Config.BlipBlinkRate
                            
                            -- Ensure minimum hide interval
                            currentInterval = math.max(hideInterval, Config.BlipBlinkRate)
                            
                            -- Remove the blip
                            if entityHasBlip[animalName] then
                                RemoveEntityBlip(animalName)
                            end
                        end
                        
                        if Config.DebugMode then
                            if GetGameTimer() % 5000 < 50 then  -- Only log occasionally to avoid spam
                                local stateText = blinkState and "visible" or "hidden"
                                print("^2Blinking blip for Legendary " .. animalName .. " (Distance: " .. string.format("%.1f", distance) .. 
                                      ", Current interval: " .. currentInterval .. "ms, State: " .. stateText .. ")^7")
                            end
                        end
                    end
                else
                    -- Within minimum distance, ensure blip is always visible (no blinking)
                    if not entityHasBlip[animalName] then
                        AddBlip(animalName, entityId)
                        
                        if Config.DebugMode then
                            if GetGameTimer() % 5000 < 50 then  -- Only log occasionally to avoid spam
                                print("^2Blip for Legendary " .. animalName .. " is within minimum distance, always visible (Distance: " .. string.format("%.1f", distance) .. ")^7")
                            end
                        end
                    end
                end
            else
                -- Beyond maximum visibility distance, hide the blip
                if entityHasBlip[animalName] then
                    RemoveEntityBlip(animalName)
                    
                    if Config.DebugMode then
                        if GetGameTimer() % 5000 < 50 then  -- Only log occasionally to avoid spam
                            print("^3Blip for Legendary " .. animalName .. " is beyond maximum visibility distance (Distance: " .. string.format("%.1f", distance) .. ")^7")
                        end
                    end
                end
            end
            
            -- Periodically refresh the sonar blip effect (every 30 seconds)
            if entityHasBlip[animalName] and math.random(1, 30) == 1 then
                -- Refresh sonar blip effect
                Citizen.InvokeNative(0x0C7A2289A5C4D7C9, -1949395924, entityId)
                if Config.DebugMode then
                    print("^2Refreshed sonar blip for Legendary " .. animalName .. "^7")
                end
            end
            
            Wait(1000) -- Check every second
        end
        
        -- Entity no longer exists, clean up
        if entityHasBlip[animalName] then
            RemoveEntityBlip(animalName)
        end
        
        legendaryEntities[animalName] = nil
        
        if Config.DebugMode then
            print("^3Stopped blip monitor thread for Legendary " .. animalName .. " (entity no longer exists)^7")
        end
    end)
    
    if Config.DebugMode then
        print("^2Started blip monitor thread for Legendary " .. animalName .. "^7")
    end
end

-- Function to clean up all blips
function CleanupAllBlips()
    if Config.DebugMode then
        print("^3Cleaning up all legendary animal blips...^7")
    end
    
    local count = 0
    for animalName, _ in pairs(entityHasBlip) do
        if entityHasBlip[animalName] then
            RemoveEntityBlip(animalName)
            count = count + 1
        end
    end
    
    -- Clear the tables
    legendaryBlips = {}
    legendaryEntities = {}
    entityHasBlip = {}
    
    if Config.DebugMode then
        print("^2Removed " .. count .. " legendary animal blips during cleanup^7")
    end
end

-- Register resource stop handler to clean up all blips
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        CleanupAllBlips()
    end
end)