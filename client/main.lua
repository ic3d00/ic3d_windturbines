ESX = exports["es_extended"]:getSharedObject()

local jobs = {}
local showJobs = false
local repairCooldowns = {}

-- Function to create blips and spawners
local function createStationBlips()
    for k, v in ipairs(Config.Station) do
        -- SPAWNER BLIP
        local blip = AddBlipForCoord(v.pedcoords)
        SetBlipSprite(blip, 422)
        SetBlipColour(blip, 60)
        SetBlipScale(blip, 0.95)
        SetBlipAsShortRange(blip, true)

        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Wind Turbine Worker")
        EndTextCommandSetBlipName(blip)
        -- SPAWNER BLIP END --

        -- SPAWNER
        local sphere = lib.zones.sphere({
            coords = v.zone,
            radius = 1.5,
            debug = false,
            inside = function()
                if IsControlJustPressed(38, 38) and not showJobs and ESX.Game.IsSpawnPointClear(v.spawnPoint, 6.0) then
                    ESX.Game.SpawnVehicle(v.carModel, v.spawnPoint, v.heading)
                    showJobs = true
                    works()
                    local alert = lib.alertDialog({
                        header = 'Welcome!',
                        content = 'Fix the wind turbines for good rewards!',
                        centered = true,
                        cancel = false,
                    })
                elseif IsControlJustPressed(38, 38) and not ESX.Game.IsSpawnPointClear(v.spawnPoint, 6.0) then
                    lib.notify({
                        title = 'Wind Turbine Worker',
                        description = 'There is something blocking the vehicle spawn!',
                        type = 'error',
                        position = 'center-left'
                    })
                end
            end,

            onEnter = function()
                if not showJobs then
                    lib.showTextUI('[E] - Spawn Vehicle')
                end
            end,
            onExit = function()
                lib.hideTextUI()
            end,
        })
        -- SPAWNER END --

        -- PED
        lib.RequestModel(v.model)
        local ped = CreatePed(1, v.model, v.pedcoords, false, false)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        -- PED END --
    end
end

-- Function to handle repairs
function works()
    if showJobs then
        for k, v in ipairs(Config.Points) do
            -- Create a blip for the repair point
            local blip = AddBlipForCoord(v.coords)
            SetBlipSprite(blip, 761)
            SetBlipColour(blip, 46)
            SetBlipScale(blip, 0.45)
            SetBlipAsShortRange(blip, true)

            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString("Repair Point")
            EndTextCommandSetBlipName(blip)

            -- Create the repair point (interactive area)
            local point = lib.points.new({
                coords = v.coords,
                distance = 20,
            })

            -- Create the marker
            local marker = lib.marker.new({
                type = 42,
                coords = v.coords,
                height = 1,
                width = 1,
                color = { r = 0, g = 255, b = 0, a = 50 },
            })

            -- This will handle the interactions and cooldown check
            function point:nearby()
                marker:draw()

                if self.currentDistance < 1.5 then
                    local lastRepairTime = repairCooldowns[v.coords]
                    local currentTime = GetGameTimer()

                    if lastRepairTime and currentTime - lastRepairTime < 300000 then
                        lib.showTextUI('[E] - Repair (Wait ' .. math.ceil((300000 - (currentTime - lastRepairTime)) / 1000) .. 's)')
                        marker.color = { r = 255, g = 0, b = 0, a = 50 }
                    else
                        lib.showTextUI('[E] - Repair')
                        marker.color = { r = 0, g = 255, b = 0, a = 50 }
                    end

                    if IsControlJustPressed(0, 51) then
                        if not lastRepairTime or currentTime - lastRepairTime >= 300000 then
                            TriggerEvent("myAnimation")
                            local success = lib.skillCheck(Config.skillDifficulty, { 'w', 'a', 's', 'd' })
                            if success then
                                repairCooldowns[v.coords] = currentTime
                                if lib.progressBar({
                                    duration = 5000,
                                    label = "Repairing Generator...",
                                    useWhileDead = false,
                                    canCancel = false,
                                    disable = {
                                        car = true,
                                    },
                                    anim = {
                                        dict = 'amb@world_human_welding@male@base',
                                        clip = 'base',
                                    },
                                    prop = {
                                        model = `prop_weld_torch`,
                                        pos = vec3(0.03, 0.03, 0.02),
                                        rot = vec3(5.0, 0.0, 0.0),
                                    },
                                }) then
                                    TriggerServerEvent('ic3d_windturbines:eletrico-eletrocutar', success)

                                    lib.notify({
                                        title = 'Wind Turbine Worker',
                                        description = 'The problem has been resolved successfully!',
                                        type = 'success',
                                        position = 'center-left'
                                    })
                                else
                                    lib.notify({
                                        title = 'Wind Turbine Worker',
                                        description = 'You canceled the repair.',
                                        type = 'error',
                                        position = 'center-left'
                                    })
                                end
                            else
                                lib.notify({
                                    title = 'Wind Turbine Worker',
                                    description = 'You failed the repair.',
                                    type = 'error',
                                    position = 'center-left'
                                })
                                lib.hideTextUI()
                            end
                        else
                            lib.notify({
                                title = 'Wind Turbine Worker',
                                description = 'You are still in cooldown, try again later!',
                                type = 'error',
                                position = 'center-left'
                            })
                        end
                    end
                else
                    lib.hideTextUI()
                end
            end
        end
    end
end

-- Event handlers for resource and player load
RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(playerData)
    createStationBlips()
    works()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    createStationBlips()
    works()
end)
