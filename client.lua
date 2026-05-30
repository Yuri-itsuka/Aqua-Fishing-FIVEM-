ESX = exports["es_extended"]:getSharedObject()

local fishing = false
local fishingRod = nil

function IsAtFishingSpot()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    for _, spot in pairs(Config.FishingSpots) do
        local dist = #(coords - spot)

        if dist <= Config.FishingDistance then
            return true
        end
    end

    return false
end

CreateThread(function()

    -- Fishing Spots Blips
    for _, spot in pairs(Config.FishingSpots) do

        local blip = AddBlipForCoord(spot.x, spot.y, spot.z)

        SetBlipSprite(blip, 68)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.8)
        SetBlipColour(blip, 27)
        SetBlipAsShortRange(blip, true)

        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Angelspot")
        EndTextCommandSetBlipName(blip)
    end

    -- NPC Blip
    local npcBlip = AddBlipForCoord(
        Config.SellNPC.coords.x,
        Config.SellNPC.coords.y,
        Config.SellNPC.coords.z
    )

    SetBlipSprite(npcBlip, 68)
    SetBlipDisplay(npcBlip, 4)
    SetBlipScale(npcBlip, 0.8)
    SetBlipColour(npcBlip, 27)
    SetBlipAsShortRange(npcBlip, true)

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Fischer")
    EndTextCommandSetBlipName(npcBlip)

    -- NPC Spawn
    RequestModel(Config.SellNPC.model)

    while not HasModelLoaded(Config.SellNPC.model) do
        Wait(10)
    end

    local npc = CreatePed(
        4,
        Config.SellNPC.model,
        Config.SellNPC.coords.x,
        Config.SellNPC.coords.y,
        Config.SellNPC.coords.z - 1.0,
        Config.SellNPC.coords.w,
        false,
        true
    )

    FreezeEntityPosition(npc, true)
    SetEntityInvincible(npc, true)
    SetBlockingOfNonTemporaryEvents(npc, true)

    -- NPC Interaction
    while true do

        local sleep = 1000

        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)

        local npcCoords = vector3(
            Config.SellNPC.coords.x,
            Config.SellNPC.coords.y,
            Config.SellNPC.coords.z
        )

        local dist = #(coords - npcCoords)

        if dist < 3.0 then

            sleep = 0

            DrawText3D(
                Config.SellNPC.coords.x,
                Config.SellNPC.coords.y,
                Config.SellNPC.coords.z + 1.0,
                "[E] Fischer-Menü öffnen"
            )

            if IsControlJustReleased(0, 38) then
                OpenFishingMenu()
            end
        end

        Wait(sleep)
    end
end)

function OpenFishingMenu()

    ESX.UI.Menu.CloseAll()

    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'fishing_menu', {
        title = 'Fischer',
        align = 'top-left',
        elements = {
            { label = 'Fisch verkaufen', value = 'sell' },
            { label = 'Angel upgraden', value = 'upgrade' },
            { label = 'Top Angler ansehen', value = 'leaderboard' }
        }

    }, function(data, menu)

        if data.current.value == 'sell' then
            TriggerServerEvent('esx_fishing:sellFish')
        end

        if data.current.value == 'upgrade' then
            TriggerServerEvent('esx_fishing:useUpgrade')
        end

        if data.current.value == 'leaderboard' then
            OpenFishingLeaderboard()
        end

    end, function(data, menu)
        menu.close()
    end)
end

function OpenFishingLeaderboard()

    ESX.TriggerServerCallback('esx_fishing:getLeaderboard', function(data)

        local elements = {}

        for k, v in pairs(data) do

            table.insert(elements, {
                label = k .. '. ' .. v.name ..
                ' | Fische: ' .. v.fish_caught ..
                ' | Geld: $' .. v.money_earned
            })
        end

        if #elements == 0 then
            table.insert(elements, {
                label = 'Noch keine Angler vorhanden.'
            })
        end

        ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'fishing_leaderboard', {
            title = 'Top Angler',
            align = 'top-left',
            elements = elements

        }, function(data, menu)

        end, function(data, menu)
            menu.close()
        end)
    end)
end

RegisterNetEvent('esx_fishing:startFishing', function()

    if fishing then return end

    if not IsAtFishingSpot() then
        ESX.ShowNotification("Du kannst hier nicht angeln.")
        return
    end

    fishing = true

    ESX.ShowNotification("Du hast angefangen zu angeln. Drücke E zum Abbrechen.")

    local ped = PlayerPedId()

    RequestAnimDict("amb@world_human_stand_fishing@idle_a")

    while not HasAnimDictLoaded("amb@world_human_stand_fishing@idle_a") do
        Wait(10)
    end

    local rodModel = `prop_fishing_rod_01`

    RequestModel(rodModel)

    while not HasModelLoaded(rodModel) do
        Wait(10)
    end

    fishingRod = CreateObject(rodModel, 0, 0, 0, true, true, false)

    AttachEntityToEntity(
        fishingRod,
        ped,
        GetPedBoneIndex(ped, 60309),
        0.1, 0.02, 0.0,
        80.0, 120.0, 160.0,
        true, true, false, true, 1, true
    )

    -- Animation nur EINMAL starten
    TaskPlayAnim(
        ped,
        "amb@world_human_stand_fishing@idle_a",
        "idle_c",
        8.0,
        -8.0,
        -1,
        1,
        0,
        false,
        false,
        false
    )

    CreateThread(function()

        local timer = 0

        while fishing do

            local coords = GetEntityCoords(ped)

            DisableControlAction(0, 38, true)

            if IsDisabledControlPressed(0, 38) then

                StopFishing("Angeln abgebrochen.")

                break
            end

            timer = timer + 100

            if timer >= Config.FishingTime then

                TriggerServerEvent('esx_fishing:giveReward')

                timer = 0
            end

            Wait(100)
        end
    end)
end)

RegisterNetEvent('esx_fishing:stopFishing', function()
    StopFishing("Angeln beendet.")
end)

function StopFishing(message)

    fishing = false

    local ped = PlayerPedId()

    ClearPedTasks(ped)

    if fishingRod and DoesEntityExist(fishingRod) then
        DeleteEntity(fishingRod)
    end

    fishingRod = nil

    if message then
        ESX.ShowNotification(message)
    end
end

function DrawText3D(x, y, z, text)

    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextEntry("STRING")
    SetTextCentre(true)

    AddTextComponentString(text)

    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)

    ClearDrawOrigin()
end