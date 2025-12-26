local QBCore = exports['qb-core']:GetCoreObject()

local function HasPermission(source)
    for _, group in ipairs(Config.AllowedGroups) do
        if IsPlayerAceAllowed(source, group) then
            return true
        end
    end
    return false
end

QBCore.Commands.Add('givecar', 'Give a vehicle to a player', {
    {name = 'id', help = 'Player ID'},
    {name = 'vehicle', help = 'Vehicle spawn name (e.g., adder)'}
}, true, function(source, args)
    local src = source
    
    if not HasPermission(src) then
        TriggerClientEvent('QBCore:Notify', src, 'You do not have permission to use this command!', 'error')
        return
    end
    
    local targetId = tonumber(args[1])
    local vehicleModel = args[2]
    
    if not targetId or not vehicleModel then
        TriggerClientEvent('QBCore:Notify', src, 'Invalid usage! Use: /givecar [ID] [vehicle]', 'error')
        return
    end
    
    local targetPlayer = QBCore.Functions.GetPlayer(targetId)
    
    if not targetPlayer then
        TriggerClientEvent('QBCore:Notify', src, 'Player not found or offline!', 'error')
        return
    end
    
    local plate = GeneratePlate()
    
    MySQL.insert('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
        targetPlayer.PlayerData.license,
        targetPlayer.PlayerData.citizenid,
        vehicleModel,
        GetHashKey(vehicleModel),
        '{}',
        plate,
        Config.DefaultGarage,
        0
    }, function(rowsChanged)
        if rowsChanged > 0 then
            TriggerClientEvent('QBCore:Notify', src, 'Vehicle given successfully!', 'success')
            TriggerClientEvent('QBCore:Notify', targetId, 'You received a new vehicle! Check your garage', 'success')
            
            local adminName = GetPlayerName(src)
            local targetName = targetPlayer.PlayerData.name
            local logMessage = string.format(
                "**Admin:** %s\n**Target:** %s\n**Vehicle:** %s\n**Plate:** %s\n**Garage:** %s",
                adminName,
                targetName,
                vehicleModel,
                plate,
                Config.DefaultGarage
            )
            SendDiscordLog('Vehicle Given', logMessage)
        else
            TriggerClientEvent('QBCore:Notify', src, 'Error adding vehicle to database!', 'error')
        end
    end)
    
end)

QBCore.Commands.Add('givecarfull', 'Give a fully upgraded vehicle', {
    {name = 'id', help = 'Player ID'},
    {name = 'vehicle', help = 'Vehicle spawn name'},
    {name = 'garage', help = 'Garage name'}
}, true, function(source, args)
    local src = source
    
    if not HasPermission(src) then
        TriggerClientEvent('QBCore:Notify', src, 'You do not have permission!', 'error')
        return
    end
    
    local targetId = tonumber(args[1])
    local vehicleModel = args[2]
    local garage = args[3]
    
    if not targetId or not vehicleModel or not garage then
        TriggerClientEvent('QBCore:Notify', src, 'Invalid usage! Use: /givecarfull [ID] [vehicle] [garage]', 'error')
        return
    end
    
    local targetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not targetPlayer then
        TriggerClientEvent('QBCore:Notify', src, 'Player not online!', 'error')
        return
    end
    
    local plate = GeneratePlate()
    
    MySQL.insert('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
        targetPlayer.PlayerData.license,
        targetPlayer.PlayerData.citizenid,
        vehicleModel,
        GetHashKey(vehicleModel),
        json.encode(Config.FullUpgrades),
        plate,
        garage,
        0
    }, function(result)
        if result then
            TriggerClientEvent('QBCore:Notify', src, 'Fully upgraded vehicle given!', 'success')
            TriggerClientEvent('QBCore:Notify', targetId, 'You received a fully upgraded vehicle! Check garage: ' .. garage, 'success')
            
            local adminName = GetPlayerName(src)
            local targetName = targetPlayer.PlayerData.name
            local logMessage = string.format(
                "**Admin:** %s\n**Target:** %s\n**Vehicle:** %s (Fully Upgraded)\n**Plate:** %s\n**Garage:** %s",
                adminName,
                targetName,
                vehicleModel,
                plate,
                garage
            )
            SendDiscordLog('Fully Upgraded Vehicle Given', logMessage)
        end
    end)
end)

function GeneratePlate()
    local plate = QBCore.Shared.RandomInt(1) .. QBCore.Shared.RandomStr(2) .. QBCore.Shared.RandomInt(3) .. QBCore.Shared.RandomStr(2)
    local result = MySQL.scalar.await('SELECT plate FROM player_vehicles WHERE plate = ?', {plate})
    if result then
        return GeneratePlate()
    else
        return plate:upper()
    end
end

function SendDiscordLog(title, message)
    if Config.Webhook == '' or Config.Webhook == 'YOUR_DISCORD_WEBHOOK_URL_HERE' then
        return
    end
    
    local embed = {
        {
            ["title"] = title,
            ["description"] = message,
            ["footer"] = {
                ["text"] = os.date("%Y-%m-%d %H:%M:%S"),
            },
        }
    }
    
    PerformHttpRequest(Config.Webhook, function(err, text, headers) end, 'POST', json.encode({
        username = 'GiveCar System',
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end

