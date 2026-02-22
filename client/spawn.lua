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
    local legendaryPed = Citizen.InvokeNative(0xD49F9B0955C367DE, legendaryHash, x, y, z, heading, true, false, false, false)
    
    if not DoesEntityExist(legendaryPed) then
        if Config.DebugMode then
            print("Failed to create legendary animal entity")
        end
        return false
    end
    
    -- Set as mission entity so it doesn't despawn
    SetEntityAsMissionEntity(legendaryPed, true, true)
    
    -- Ensure the entity is networked
    if not NetworkGetEntityIsNetworked(legendaryPed) then
        NetworkRegisterEntityAsNetworked(legendaryPed)
        
        -- Wait for network registration
        local netRegTimeout = 0
        while not NetworkGetEntityIsNetworked(legendaryPed) and netRegTimeout < 30 do
            Wait(100)
            netRegTimeout = netRegTimeout + 1
        end
        
        if not NetworkGetEntityIsNetworked(legendaryPed) then
            if Config.DebugMode then
                print("Failed to register legendary animal as networked entity")
            end
            DeleteEntity(legendaryPed)
            return false
        end
    end
    
    -- Get the network ID
    local legendaryNetId = NetworkGetNetworkIdFromEntity(legendaryPed)
    
    -- Validate network ID
    if not legendaryNetId or legendaryNetId == 0 then
        if Config.DebugMode then
            print("Failed to get valid network ID for legendary animal")
        end
        DeleteEntity(legendaryPed)
        return false
    end
    
    -- Set network ID to exist on all machines
    SetNetworkIdExistsOnAllMachines(legendaryNetId, true)
    -- Ensure stable migration and non-dynamic ownership
    --NetworkSetNetworkIdDynamic(legendaryNetId, false)
    --SetNetworkIdCanMigrate(legendaryNetId, true)
    
    -- Apply wandering behavior to the legendary animal
    -- TASK_WANDER_IN_AREA (0xE054346CA3A0F315)
    -- Parameters: ped, x, y, z, radius, p5, p6, p7
    local wanderRadius = Config.SpawnDistance / 3 -- Use 1/3 of the spawn distance as wander radius
    Citizen.InvokeNative(0xE054346CA3A0F315, legendaryPed, x, y, z, wanderRadius, 0.0, 0, 0)
    
    -- Set outfit variant if specified
    if animalData.Legendaryoutfit then
        SetPedOutfitPreset(legendaryPed, animalData.Legendaryoutfit)
    end
    
    -- Add to spawnedPeds table as first entry
    table.insert(spawnedPeds, legendaryPed)
    
    -- Table to store companion network IDs
    local companionNetIds = {}
    
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
                
                -- Create the companion ped with network flag
                local companionPed = Citizen.InvokeNative(0xD49F9B0955C367DE, companionHash, 
                    x + spawnOffsetX, y + spawnOffsetY, z, heading, true, false, false, false)
                
                if DoesEntityExist(companionPed) then
                    -- Set as mission entity
                    SetEntityAsMissionEntity(companionPed, true, true)
                    
                    -- Ensure the entity is networked
                    if not NetworkGetEntityIsNetworked(companionPed) then
                        NetworkRegisterEntityAsNetworked(companionPed)
                        
                        -- Wait for network registration
                        local netRegTimeout = 0
                        while not NetworkGetEntityIsNetworked(companionPed) and netRegTimeout < 30 do
                            Wait(100)
                            netRegTimeout = netRegTimeout + 1
                        end
                    end
                    
                    -- Get and validate network ID
                    local companionNetId = NetworkGetNetworkIdFromEntity(companionPed)
                    if companionNetId and companionNetId > 0 then
                        -- Set network ID to exist on all machines
                        SetNetworkIdExistsOnAllMachines(companionNetId, true)
                        -- Ensure stable migration and non-dynamic ownership
                        --NetworkSetNetworkIdDynamic(companionNetId, false)
                        --SetNetworkIdCanMigrate(companionNetId, true)
                        
                        -- Store the network ID
                        table.insert(companionNetIds, companionNetId)
                    end
                    
                    -- Apply follow behavior to the companion animal
                    -- TASK_FOLLOW_TO_OFFSET_OF_ENTITY (0x304AE42E357B8C7E)
                    -- Parameters: ped, entity, offsetX, offsetY, offsetZ, movementSpeed, timeout, stoppingRange, persistFollowing
                    local offsetX = math.random(15, 60)
                    local offsetY = math.random(15, 60)
                    local timeout = -1 -- Never timeout
                    local stoppingRange = math.random(10.0, 60.0) -- How close the companion gets before stopping
                    local persistFollowing = true -- Continue following even after reaching the target
                    Citizen.InvokeNative(0x304AE42E357B8C7E, companionPed, legendaryPed, offsetX, offsetY, 0.0, 2, timeout, stoppingRange, persistFollowing)
                    
                    -- Set random outfit variant if specified
                    if animalData.CompanionOutfit and #animalData.CompanionOutfit > 0 then
                        local outfitIndex = math.random(1, #animalData.CompanionOutfit)
                        local outfitVariant = animalData.CompanionOutfit[outfitIndex]
                        SetPedOutfitPreset(companionPed, outfitVariant)
                    end
                    
                    -- Add to spawnedPeds table
                    table.insert(spawnedPeds, companionPed)
                end
            end
        else
            if Config.DebugMode then
                print("Failed to load companion animal model")
            end
        end
    end
    
    -- Cache the network IDs on the server
    TriggerServerEvent('nt_legendary:cacheNetworkIds', animalData.BlipName, legendaryNetId, companionNetIds)
    
    -- Start centralized cleanup monitor
    StartCleanupMonitor(animalData)
    
    -- Notify player
    TriggerEvent('nt_legendary:notify', 'You have discovered a ' .. animalData.BlipName .. '!')
    
    if Config.DebugMode then
        print("^2Legendary animal spawn complete: " .. animalData.BlipName .. " (Network ID: " .. legendaryNetId .. ")^7")
        if #companionNetIds > 0 then
            print("^2Spawned " .. #companionNetIds .. " companion animals^7")
        end
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

-- Function to check if any player is in range of a location or the legendary animal
function CheckPlayerInRange(range, coords)
    -- If no coords provided, try to get legendary animal position
    local targetCoords = coords
    
    if not targetCoords then
        -- If no legendary animal exists and no coords, return false
        if #spawnedPeds == 0 or not DoesEntityExist(spawnedPeds[1]) then
            return false
        end
        targetCoords = GetEntityCoords(spawnedPeds[1])
    end
    
    -- First check cached player if exists
    if playerCache ~= nil then
        -- Check if cached player is still valid
        if GetPlayerFromServerId(playerCache) ~= -1 then
            local playerPed = GetPlayerPed(GetPlayerFromServerId(playerCache))
            
            if DoesEntityExist(playerPed) then
                local playerCoords = GetEntityCoords(playerPed)
                local distance = #(targetCoords - playerCoords)
                
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
        local distance = #(targetCoords - playerCoords)
        
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

-- Request active legendary animals when client starts
CreateThread(function()
    -- Wait for player to fully load
    Wait(5000)
    
    -- Request active legendary animals from server
    TriggerServerEvent('nt_legendary:requestActiveAnimals')
    
    if Config.DebugMode then
        print("Requested active legendary animals from server")
    end
end)