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

    
local sphere = lib.zones.sphere({
    coords = v.zone,
    radius = 1.5,
    debug = false,
    inside = function()
        if IsControlJustPressed(38, 38) and not showJobs and ESX.Game.IsSpawnPointClear(v.spawnPoint, 6.0) then
            ESX.Game.SpawnVehicle(v.carModel, v.spawnPoint, v.heading)
            showJobs = true
            works()
            
            ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
                if skin.sex == 0 then
                    TriggerEvent('skinchanger:loadClothes', skin, Config.Uniforms.male)
                else
                    TriggerEvent('skinchanger:loadClothes', skin, jobSkin.skin_female)
                end
            end)
            
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

		
		
-- DELETER BLIP --
local blip = AddBlipForCoord(v.deletePoint)
SetBlipSprite(blip, 357)
SetBlipColour(blip, 60)
SetBlipScale(blip, 0.5)
SetBlipAsShortRange(blip, true)

BeginTextCommandSetBlipName("STRING")
AddTextComponentString("End Work | Store Vehicle")
EndTextCommandSetBlipName(blip)
-- DELETER BLIP END --



-- DELETER BLIP --
local deleterSphere = lib.zones.sphere({
    coords = v.deletePoint,
    radius = 3,
    debug = false,
    inside = function()
        if cache.vehicle then
            if IsControlJustPressed(38, 38) and showJobs then
                local vehicle = GetVehiclePedIsIn(cache.ped, false)
                ESX.Game.DeleteVehicle(vehicle)
                stopJob()  -- Stop the job and clean up
				   ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
                    TriggerEvent('skinchanger:loadSkin', skin)
                end)
            end
        end
    end,
    onEnter = function()
        if showJobs then
            lib.showTextUI('[E] - Return Vehicle')  -- Show text UI for return vehicle when job is active
        end
    end,
    onExit = function()
        lib.hideTextUI()  -- Hide text UI when exiting the delete point
    end,
})

        -- PED
        lib.RequestModel(v.model)
        local ped = CreatePed(1, v.model, v.pedcoords, false, false)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        -- PED END --
    end
end


-- Store the markers
local markers = {}
-- Function to stop the job and clear markers and blips
function stopJob()
    showJobs = false  -- Stop the job
    
    -- Remove all active repair point blips
    for _, blip in ipairs(jobs) do
        RemoveBlip(blip)
    end
    jobs = {}  -- Clear the jobs list
    
    -- Hide the text UI (for vehicle spawn and repair points)
    lib.hideTextUI()

    -- Set a flag to prevent marker drawing
    for _, marker in ipairs(markers) do
        marker.visible = false  -- Hide marker by setting its visibility to false
    end
    markers = {}  -- Clear the markers list

    -- If there was a deleter marker, remove it
    if deleterMarker then
        deleterMarker.visible = false  -- Hide deleter marker
        deleterMarker = nil  -- Remove the deleter marker
    end

    lib.notify({
        title = 'Wind Turbine Worker',
        description = 'Job stopped, vehicle returned!',
        type = 'success',
        position = 'center-left'
    })
end

-- Function to handle work (job markers and blips)
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

            -- Add blip to jobs table to track it
            table.insert(jobs, blip)

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

            -- Store the marker in the markers list
            table.insert(markers, marker)

            -- This will handle the interactions and cooldown check
            function point:nearby()
                if showJobs then  -- Only draw markers if job is active
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
                                            rot = vec3(0.0, 0.0, 0.0),
                                        }, 
										disable = {
                                            move = true,
                                            car = true,
                                            combat = true,
                                        },
                                    }) then
                                        TriggerServerEvent('ic3d_windturbines:reward', success)

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
