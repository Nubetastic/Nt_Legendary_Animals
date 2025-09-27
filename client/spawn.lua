-- Spawn functionality for Legendary Animals

-- Function to spawn legendary animal and companions
function SpawnLegendaryAnimal(animalData, spawnLocation)
    -- Spawn legendary animal and companions
    
    -- Clear any existing spawned peds
    ClearSpawnedPeds()
    
    if Config.DebugMode then
        print("Spawning legendary animal: " .. animalData.BlipName .. " at location: " .. tostring(spawnLocation))
    end
    
    -- Spawn the legendary animal
    local legendaryHash = animalData.LegendaryHash
    
    -- Request the model
    RequestModel(legendaryHash)
    local timeout = 0
    while not HasModelLoaded(legendaryHash) and timeout < 30 do
        Wait(100)
        timeout = timeout + 1
    end
    
    if not HasModelLoaded(legendaryHash) then
        if Config.DebugMode then
            print("Failed to load legendary animal model")
        end
        return false
    end
    
    -- Create the legendary animal ped
    local x, y, z, heading = table.unpack(spawnLocation)
    -- Use true for the isNetwork parameter (5th parameter) to ensure it's networked from creation
    local legendaryPed = CreatePed(legendaryHash, x, y, z, heading, true, true, true, false)
    
    -- Apply wandering behavior to the legendary animal
    -- TASK_WANDER_IN_AREA (0xE054346CA3A0F315)
    -- Parameters: ped, x, y, z, radius, p5, p6, p7
    local wanderRadius = Config.SpawnDistance / 3 -- Use 1/3 of the spawn distance as wander radius
    Citizen.InvokeNative(0xE054346CA3A0F315, legendaryPed, x, y, z, wanderRadius, 0.0, 0, 0)
    
    -- Set outfit variant if specified
    if animalData.Legendaryoutfit then
        SetPedOutfitPreset(legendaryPed, animalData.Legendaryoutfit)
    end
    
    -- Set as mission entity so it doesn't despawn
    SetEntityAsMissionEntity(legendaryPed, true, true)
    
    -- Add to spawnedPeds table as first entry
    table.insert(spawnedPeds, legendaryPed)
    
    -- Spawn companion animals
    local companionHash = animalData.CompanionHash
    local companionCount = animalData.CompanionCount or 0
    
    if companionHash and companionCount > 0 then
        -- Request the companion model
        RequestModel(companionHash)
        local timeout = 0
        while not HasModelLoaded(companionHash) and timeout < 30 do
            Wait(100)
            timeout = timeout + 1
        end
        
        if HasModelLoaded(companionHash) then
            -- Spawn the specified number of companions
            for i = 1, companionCount do
                -- Calculate spawn position (random offset from legendary animal)
                local spawnOffsetX = math.random(-10, 10)
                local spawnOffsetY = math.random(-10, 10)
                -- Use true for the isNetwork parameter (5th parameter) to ensure it's networked from creation
                local companionPed = CreatePed(companionHash, x + spawnOffsetX, y + spawnOffsetY, z, heading, true, true, true, false)
                
                -- Apply follow behavior to the companion animal
                -- TASK_FOLLOW_TO_OFFSET_OF_ENTITY (0x304AE42E357B8C7E)
                -- Parameters: ped, entity, offsetX, offsetY, offsetZ, movementSpeed, timeout, stoppingRange, persistFollowing
                local offsetX = math.random( 15, 60)
                local offsety = math.random( 15, 60)
                local timeout = -1 -- Never timeout
                local stoppingRange = math.random(10.0, 60.0) -- How close the companion gets before stopping
                local persistFollowing = true -- Continue following even after reaching the target
                Citizen.InvokeNative(0x304AE42E357B8C7E, companionPed, legendaryPed, offsetX, offsety, 0.0, 2, timeout, stoppingRange, persistFollowing)
                
                
                -- Set random outfit variant if specified
                if animalData.CompanionOutfit and #animalData.CompanionOutfit > 0 then
                    local outfitIndex = math.random(1, #animalData.CompanionOutfit)
                    local outfitVariant = animalData.CompanionOutfit[outfitIndex]
                    SetPedOutfitPreset(companionPed, outfitVariant)
                end
                
                -- Set as mission entity
                SetEntityAsMissionEntity(companionPed, true, true)
                
                -- Ensure companion is networked
                if not Citizen.InvokeNative(0x0991549DE4D64762, companionPed) then
                    Citizen.InvokeNative(0x06FAACD625D80CAA, companionPed)
                end
                
                -- Add to spawnedPeds table
                table.insert(spawnedPeds, companionPed)
            end
        else
            if Config.DebugMode then
                print("Failed to load companion animal model")
            end
        end
    end
    
    -- Set as mission entity so it doesn't despawn
    -- ENTITY::SET_ENTITY_AS_MISSION_ENTITY (0xAD738C3085FE7E11)
    Citizen.InvokeNative(0xAD738C3085FE7E11, legendaryPed, true, true)
    
    -- Wait a moment for the entity to be fully created
    Wait(100)
    
    -- Check if the entity is already networked (it should be since we created it with CreatePed)
    -- NETWORK::NETWORK_GET_ENTITY_IS_NETWORKED (0x0991549DE4D64762)
    local isNetworked = Citizen.InvokeNative(0x0991549DE4D64762, legendaryPed)
    
    if not isNetworked then
        -- If not networked, try to register it
        -- NETWORK::NETWORK_REGISTER_ENTITY_AS_NETWORKED (0x06FAACD625D80CAA)
        Citizen.InvokeNative(0x06FAACD625D80CAA, legendaryPed)
        
        -- Wait a moment for networking to take effect
        Wait(100)
        
        -- Check again if it's networked
        isNetworked = Citizen.InvokeNative(0x0991549DE4D64762, legendaryPed)
    end
    
    -- Get the network ID directly from the entity
    -- NETWORK::NETWORK_GET_NETWORK_ID_FROM_ENTITY (0xA11700682F3AD45C)
    local netId = Citizen.InvokeNative(0xA11700682F3AD45C, legendaryPed)
    
    -- Log the network ID
    if Config.DebugMode then
        print("^3Legendary animal network ID: " .. tostring(netId) .. "^7")
    end
    
    -- Ensure the network ID is valid
    if netId and netId ~= 0 then
        -- Set this entity as visible to network (not invisible)
        -- NETWORK::SET_ENTITY_INVISIBLE_TO_NETWORK (0xF1CA12B18AEF5298)
        Citizen.InvokeNative(0xF1CA12B18AEF5298, legendaryPed, false)
        
        -- Use native calls for network ID configuration
        -- NETWORK::SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES (0xE05E81A888FA63C8)
        Citizen.InvokeNative(0xE05E81A888FA63C8, netId, true)
        
        -- NETWORK::SET_NETWORK_ID_CAN_MIGRATE (0x299EEB23175895FC)
        Citizen.InvokeNative(0x299EEB23175895FC, netId, false) -- Changed to false to prevent migration
        
        -- Networking is complete
        Wait(500)
        if Config.DebugMode then
            print("^2Legendary animal network ID: " .. netId .. "^7")
        end
    else
        if Config.DebugMode then
            print("^1ERROR: Failed to get network ID for legendary animal^7")
        end
        
        -- Try multiple times to get a valid network ID
        local attempts = 0
        local maxAttempts = 5
        
        while (not netId or netId == 0) and attempts < maxAttempts do
            Wait(500 * (attempts + 1))
            
            -- Try to force network the entity again
            if not Citizen.InvokeNative(0x0991549DE4D64762, legendaryPed) then
                Citizen.InvokeNative(0x06FAACD625D80CAA, legendaryPed)
            end
            
            -- Get network ID again
            netId = Citizen.InvokeNative(0xA11700682F3AD45C, legendaryPed)
            attempts = attempts + 1
            
            if Config.DebugMode then
                print("^3Networking attempt " .. attempts .. ": Network ID = " .. tostring(netId) .. "^7")
            end
        end
        
        if netId and netId ~= 0 then
            if Config.DebugMode then
                print("^2Got network ID after " .. attempts .. " attempts: " .. netId .. "^7")
            end
            
            -- Configure network ID and sync with server
            Citizen.InvokeNative(0xF1CA12B18AEF5298, legendaryPed, false)
            Citizen.InvokeNative(0xE05E81A888FA63C8, netId, true)
            Citizen.InvokeNative(0x299EEB23175895FC, netId, false) -- Changed to false to prevent migration
            
            if Config.DebugMode then
                print("^2Legendary animal " .. animalData.BlipName .. " network ID: " .. netId .. "^7")
            end
        else
            if Config.DebugMode then
                print("^1CRITICAL ERROR: Failed to get network ID after " .. maxAttempts .. " attempts^7")
            end
        end
    end
    
    -- Start monitoring threads
    StartMonitoringThreads(animalData)
    
    -- Notify player
    TriggerEvent('nt_legendary:notify', 'You have discovered a ' .. animalData.BlipName .. '!')
    
    -- Notify all clients to attach a blip to the legendary animal
    NotifyLegendarySpawn(animalData.BlipName, legendaryPed)
    
    if Config.DebugMode then
        print("^2Legendary animal spawn complete: " .. animalData.BlipName .. "^7")
    end
    
    return true
end

-- Function to clear any existing spawned peds
function ClearSpawnedPeds()
    -- Clear any existing spawned peds
    for i, ped in ipairs(spawnedPeds) do
        if DoesEntityExist(ped) then
            -- Delete the ped
            DeleteEntity(ped)
            DeletePed(ped)
        end
    end
    
    -- Clear the spawnedPeds table
    spawnedPeds = {}
    playerCache = nil
    
    if Config.DebugMode then
        print("Cleared all spawned peds")
    end
end

-- Function to start monitoring threads
function StartMonitoringThreads(animalData)
    -- Start escape timer thread
    Citizen.CreateThread(function()
        -- Monitor for escape conditions
        local escapeTimer = Config.EscapeTimer
        local checkInterval = Config.PlayerCheckInterval
        
        if Config.DebugMode then
            print("Starting monitoring thread for legendary animal")
        end
        
        while #spawnedPeds > 0 and spawnedPeds[1] ~= nil do
            Wait(checkInterval * 1000)
            
            -- Check if legendary animal is dead
            if DoesEntityExist(spawnedPeds[1]) and IsEntityDead(spawnedPeds[1]) then
                if Config.DebugMode then
                    print("Legendary animal is dead, starting cleanup")
                end
                -- Start cleanup process
                TriggerEvent('nt_legendary:startCleanup')
                break
            end
            
            -- Check if any player is in range
            local playerInRange = CheckPlayerInRange(Config.DistanceEscape)
            
            if not playerInRange then
                -- No player in range, increment escape timer
                escapeTimer = escapeTimer - checkInterval
                
                if escapeTimer <= 0 then
                    -- Animal escapes
                    if Config.DebugMode then
                        print("No players in range for too long, animal escaping")
                    end
                    TriggerEvent('nt_legendary:animalEscaped')
                    break
                end
                
                -- Debug output for escape timer
                if Config.DebugMode and escapeTimer % 60 == 0 then
                    print("Animal escape timer: " .. escapeTimer .. " seconds remaining")
                end
            else
                -- Reset timer if player in range
                if escapeTimer < Config.EscapeTimer and Config.DebugMode then
                    print("Player in range, resetting escape timer")
                    escapeTimer = Config.EscapeTimer
                end
            end
        end
    end)
end

-- Function to check if any player is in range
function CheckPlayerInRange(range)
    -- Check if any player is in range
    
    -- If no legendary animal exists, return false
    if #spawnedPeds == 0 or not DoesEntityExist(spawnedPeds[1]) then
        return false
    end
    
    -- Get legendary animal position
    local animalCoords = GetEntityCoords(spawnedPeds[1])
    
    -- First check cached player if exists
    if playerCache ~= nil then
        -- Check if cached player is still valid
        if GetPlayerFromServerId(playerCache) ~= -1 then
            local playerPed = GetPlayerPed(GetPlayerFromServerId(playerCache))
            
            if DoesEntityExist(playerPed) then
                local playerCoords = GetEntityCoords(playerPed)
                local distance = #(animalCoords - playerCoords)
                
                if distance <= range then
                    -- Cached player is still in range
                    return true
                end
            end
        end
        
        -- Cached player is no longer valid or in range
        playerCache = nil
    end
    
    -- If no cached player or cached player not in range, scan for players
    local players = GetActivePlayers()
    for _, playerId in ipairs(players) do
        local playerPed = GetPlayerPed(playerId)
        local playerCoords = GetEntityCoords(playerPed)
        local distance = #(animalCoords - playerCoords)
        
        if distance <= range then
            -- Player is in range, cache this player
            playerCache = GetPlayerServerId(playerId)
            return true
        end
    end
    
    -- No players in range
    return false
end

-- Event handler for resource stop
AddEventHandler('onResourceStop', function(resourceName)
    -- Check if this resource is the one being stopped
    if GetCurrentResourceName() == resourceName then
        print("^3Resource " .. resourceName .. " is stopping, cleaning up peds...^7")
        -- Clean up all spawned peds when the resource stops
        ClearSpawnedPeds()
    end
end)