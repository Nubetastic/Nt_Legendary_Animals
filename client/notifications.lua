-- Notification system for Legendary Animals

-- Register notification event
function LegendaryNotify()
    -- Use ox_lib notification with config settings
    lib.notify({
        title = 'Legendary Animal',
        description = "Spotted near you!",
        icon = 'map',
        iconAnimation = 'beat',
        iconColor = '#FFE605',
        position = 'top',
        duration = 10000,
    })
end