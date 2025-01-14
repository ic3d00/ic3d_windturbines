ESX = exports["es_extended"]:getSharedObject()

RegisterServerEvent('ic3d_windturbines:eletrico-eletrocutar')
AddEventHandler('ic3d_windturbines:eletrico-eletrocutar', function(success)
    local playerId = source
    local ped = ESX.GetPlayerFromId(playerId)

    if not ped then
        print(('[^1ERROR^7] Player with ID ^5%s^7 does not exist.'):format(playerId))
        return
    end

    -- Validate player position
    local playerCoords = GetEntityCoords(GetPlayerPed(playerId))
    local isNearPoint = false

    for _, point in pairs(Config.Points) do
        if #(playerCoords - point.coords) < 5.0 then -- Adjust the distance as needed
            isNearPoint = true
            break
        end
    end

    if not isNearPoint then
        print(('[^1ERROR^7] Player ID ^5%s^7 triggered event outside a valid point.'):format(playerId))
        DropPlayer(playerId, "You were caught cheating.")
        return
    end

    if success then
        -- Rewards
        local reward = math.random(Config.RewardMin, Config.RewardMax)
        local ferro = math.random(1, 2)
        local cobre = math.random(3, 4)

        local moneyAdded = exports.ox_inventory:AddItem(ped.source, 'money', reward)
        local ironAdded = exports.ox_inventory:AddItem(ped.source, 'iron', ferro)
        local copperAdded = exports.ox_inventory:AddItem(ped.source, 'copper', cobre)

        if moneyAdded and ironAdded and copperAdded then
            print(('[^2SUCCESS^7] Rewards successfully given to player ID: ^5%s^7'):format(playerId))
        else
            print(('[^1ERROR^7] Failed to give rewards to player ID: ^5%s^7'):format(playerId))
        end
    else
        print(('[^3WARNING^7] Player ID ^5%s^7 tried to execute electric reward without success!'):format(playerId))
    end
end)
