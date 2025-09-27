-- Time checking functionality for Legendary Animals

-- Initialize global variables
local currentTime = 0 -- Default value until first update

-- Function to check if current time matches animal's preferred time
function IsPreferredTime(animalData)
    -- If animal has no time preference, return true
    if not animalData.BestTimeRange then
        return true
    end
    
    -- Get current hour
    local currentHour = currentTime
    
    -- Check if the time range is a table of tables (multiple ranges)
    if type(animalData.BestTimeRange[1]) == "table" then
        -- Multiple time ranges
        for _, timeRange in ipairs(animalData.BestTimeRange) do
            local startHour = timeRange[1]
            local endHour = timeRange[2]
            
            if startHour <= endHour then
                -- Simple range (e.g., 9 to 17)
                if currentHour >= startHour and currentHour <= endHour then
                    return true
                end
            else
                -- Overnight range (e.g., 22 to 5)
                if currentHour >= startHour or currentHour <= endHour then
                    return true
                end
            end
        end
    else
        -- Single time range
        local startHour = animalData.BestTimeRange[1]
        local endHour = animalData.BestTimeRange[2]
        
        if startHour <= endHour then
            -- Simple range (e.g., 9 to 17)
            if currentHour >= startHour and currentHour <= endHour then
                return true
            end
        else
            -- Overnight range (e.g., 22 to 5)
            if currentHour >= startHour or currentHour <= endHour then
                return true
            end
        end
    end
    
    -- If no matching time range found, return false
    return false
end

-- Function to get current time from weathersync resource
function GetCurrentTimeFromWeathersync()
    
    -- Use native method as fallback
    return GetClockHours()
end

-- Function to update current time
function UpdateCurrentTime()
    -- Get time from weathersync
    local hour = GetCurrentTimeFromWeathersync()
    
    -- Update currentTime global variable
    currentTime = hour
    
    -- Debug output
    if Config.DebugMode then
        print("Current game time updated to: " .. hour)
    end
    
    return hour
end

-- Initialize time tracking
Citizen.CreateThread(function()
    while true do
        Wait(60000) -- Update every minute
        UpdateCurrentTime()
    end
end)

-- Initial time update
Citizen.CreateThread(function()
    Wait(5000) -- Longer delay on startup to ensure weathersync is initialized
    UpdateCurrentTime()
end)