# Legendary Animals for RedM

A comprehensive RedM resource that adds legendary animals to your server with dynamic spawning based on time, weather, and location conditions.
Time and weather for each animal was taken from https://jeanropke.github.io/RDOMap
If the animal is not listed there it was given custom settings.

## Installation

1. Copy the `Nt_Legendary_Animals` folder to your server's resources directory
2. Add `ensure Nt_Legendary_Animals` to your server.cfg
3. Restart your server

## Dependencies

- ox_lib

## How It Works

1. Players enter defined spawn areas
2. System checks if the animal is on cooldown
3. If not on cooldown, system rolls for spawn chance based on time and weather
4. On successful roll, legendary animal and companions spawn
5. Blips are created for all players within range
6. Animals remain until killed or until they escape (when no players are nearby)

This script only spawns legendary animals and some companions with them.