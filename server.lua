ESX = exports["es_extended"]:getSharedObject()

local PlayerUpgrades = {}

CreateThread(function()
    Wait(2000)

    ESX.RegisterUsableItem('angel', function(source)
        TriggerClientEvent('esx_fishing:startFishing', source)
    end)

    print('[esx_fishing] Angel Item wurde als benutzbar registriert.')
end)

RegisterNetEvent('esx_fishing:giveReward', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    if not xPlayer then return end

    local rod = xPlayer.getInventoryItem('angel')

    if not rod or rod.count <= 0 then
        TriggerClientEvent('esx_fishing:stopFishing', src)
        return
    end

    local reward = GetRandomReward()

    xPlayer.addInventoryItem(reward.item, 1)

    if reward.item == 'fish' then
        exports.oxmysql:execute([[
            INSERT INTO fishing_stats (identifier, name, fish_caught, money_earned, biggest_fish)
            VALUES (?, ?, 1, 0, 0)
            ON DUPLICATE KEY UPDATE
            name = VALUES(name),
            fish_caught = fish_caught + 1
        ]], {
            xPlayer.identifier,
            GetPlayerName(src)
        })
    end

    TriggerClientEvent('esx:showNotification', src, 'Du hast erhalten: 1x ' .. reward.label)
end)

RegisterNetEvent('esx_fishing:useUpgrade', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    if not xPlayer then return end

    local item = xPlayer.getInventoryItem('angel_update')

    if not item or item.count <= 0 then
        TriggerClientEvent('esx:showNotification', src, 'Du hast kein Angel-Upgrade.')
        return
    end

    if PlayerUpgrades[src] then
        TriggerClientEvent('esx:showNotification', src, 'Deine Angel ist bereits verbessert.')
        return
    end

    xPlayer.removeInventoryItem('angel_update', 1)
    PlayerUpgrades[src] = true

    TriggerClientEvent('esx:showNotification', src, 'Angel erfolgreich verbessert.')
end)

RegisterNetEvent('esx_fishing:sellFish', function()

    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    local items = {
        { item = 'fisch', price = 50 },
        { item = 'boot', price = 5 },
        { item = 'kondom', price = 2 }
    }

    local total = 0

    for _, v in pairs(items) do

        local item = xPlayer.getInventoryItem(v.item)

        if item and item.count > 0 then

            total = total + (item.count * v.price)

            xPlayer.removeInventoryItem(v.item, item.count)
        end
    end

    if total <= 0 then
        TriggerClientEvent('esx:showNotification', src, 'Du hast nichts zum Verkaufen.')
        return
    end

    xPlayer.addMoney(total)

    TriggerClientEvent('esx:showNotification', src,
        'Du hast alles für $' .. total .. ' verkauft.'
    )
end)

ESX.RegisterServerCallback('esx_fishing:getLeaderboard', function(source, cb)
    exports.oxmysql:query(
        'SELECT * FROM fishing_stats ORDER BY fish_caught DESC, money_earned DESC LIMIT 10',
        {},
        function(result)
            cb(result or {})
        end
    )
end)

function GetRandomReward()
    local totalChance = 0

    for _, reward in pairs(Config.Rewards) do
        totalChance = totalChance + reward.chance
    end

    local random = math.random(1, totalChance)
    local current = 0

    for _, reward in pairs(Config.Rewards) do
        current = current + reward.chance

        if random <= current then
            return reward
        end
    end

    return Config.Rewards[1]
end
