-- Weather checking functionality for Legendary Animals

-- Initialize global variables
local currentWeather = nil -- Default to a valid weather type
local weatherUpdateInProgress = false -- Flag to prevent multiple simultaneous requests

-- Function to translate weathersync weather types to our format
function TranslateWeathersyncWeather(weathersyncType)
    -- Map weathersync weather types to our weather types
    local weatherMap = {
        ["sunny"] = "Clear Weather",
        ["clear"] = "Clear Weather",
        ["clouds"] = "Partly Cloudy Weather",
        ["overcast"] = "Overcast Weather",
        ["fog"] = "Foggy Weather",
        ["rain"] = "Rainy Weather",
        ["thunder"] = "Thunderstorm Weather",
        ["thunderstorm"] = "Thunderstorm Weather",
        ["hurricane"] = "Hurricane Weather",
        ["misty"] = "Foggy Weather",
        ["snow"] = "Snowy Weather",
        ["blizzard"] = "Blizzard Weather",
        ["snowlight"] = "Snowy Weather",
        ["xmas"] = "Snowy Weather",
        ["halloween"] = "Foggy Weather",
        ["neutral"] = "Cloudy Weather",
        ["smog"] = "Cloudy Weather",
        ["sandstorm"] = "Sandstorm Weather"
    }
    
    -- Return mapped weather WITH FALLBACK to "Clear Weather" if type is unknown
    return weatherMap[weathersyncType] or "Clear Weather"
end

-- Register client event to receive weather from server
RegisterNetEvent('nt_legendary:receiveServerWeather')
AddEventHandler('nt_legendary:receiveServerWeather', function(weathersyncWeather)
    -- FALLBACK: If server sends nil or empty weather, use "clear" as fallback
    if not weathersyncWeather or weathersyncWeather == "" then
        weathersyncWeather = "clear"
        if Config.DebugMode then
            print("WARNING: Received empty weather from server, using fallback: clear")
        end
    end
    
    -- Translate the weather type (TranslateWeathersyncWeather already has a fallback)
    local translatedWeather = TranslateWeathersyncWeather(weathersyncWeather)
    
    -- Update currentWeather global variable (no need to check if translatedWeather exists since we have fallback)
    currentWeather = translatedWeather
    
    -- Debug output
    if Config.DebugMode then
        print("Current weather updated to: " .. currentWeather .. " (from server: " .. weathersyncWeather .. ")")
    end
    
    -- Reset the flag to allow new requests
    weatherUpdateInProgress = false
end)

-- Function to update current weather
function UpdateCurrentWeather()
    -- Prevent multiple simultaneous requests
    if weatherUpdateInProgress then
        if Config.DebugMode then
            print("Weather update already in progress, skipping request")
        end
        return currentWeather
    end
    
    -- Set flag to prevent multiple requests
    weatherUpdateInProgress = true
    
    -- FALLBACK: Set a timeout to reset the flag in case the server never responds
    CreateThread(function()
        Wait(10000) -- 10 second timeout
        if weatherUpdateInProgress then
            weatherUpdateInProgress = false
            if Config.DebugMode then
                print("WARNING: Weather update request timed out after 10 seconds")
            end
        end
    end)
    
    -- Request weather from server
    TriggerServerEvent('nt_legendary:getServerWeather')
    
    -- Debug output
    if Config.DebugMode then
        print("Requested weather update from server")
    end
    
    return currentWeather
end

-- Function to check if current weather matches animal's preferred weather
function IsPreferredWeather(animalData)
    -- If animal has no weather preference or accepts any weather, return true
    if not animalData.BestWeather or animalData.BestWeather == "Any Weather" then
        return true
    end
    
    -- If weather hasn't been initialized yet, request an update
    if currentWeather == nil then
        UpdateCurrentWeather()
        return false -- Don't spawn until we have valid weather
    end
    
    -- Check if current weather matches the preferred weather
    return currentWeather == animalData.BestWeather
end

-- Initialize weather tracking
CreateThread(function()
    while true do
        Wait(60000) -- Update every minute
        UpdateCurrentWeather()
    end
end)

-- Initial weather update - reduced delay to get weather faster
CreateThread(function()
    Wait(1000) -- Short delay to ensure weathersync is initialized
    UpdateCurrentWeather()
end)