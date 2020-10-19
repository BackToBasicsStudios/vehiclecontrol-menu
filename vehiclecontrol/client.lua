
local parkKey = 199
local saveKey = 303
local lastvehicle = nil
local savedvehicle = nil
local engine = true -- Keep Engine Running on exit
local alarm = true -- only changes to false when you save a vehicle that has no alarm.
local sentalert = false
local recentupdate = false -- for preventing opening of vehicle menu on first save
local preventstart = false -- Whitelisting ;) (Prevents the engine from being started if the user isn't authorized to.). Unused.
local bcactivated = false --Prevent car from running if baitcar is activated
local message = 0
local counter = 0
local playeralarms = {}
local serveralarms = {}
local unauthorized_vehicles = {}
local noalarmclasses = {
    10, 11, 13, 14, 15, 16, 17, 21
}
local noalarmnames = {
    1762279763,
    -667151410,
    -1311240698,
    1876516712,
    1951180813,
    -120287622,
    850991848,
    -1705304628,
    904750859,
    -1700801569,
    -1323100960,
    -442313018,
    523724515,
    -1205801634,
    -2039755226,
    -1883002148,
    -1207771834,
    -- "REBEL01",
}

TriggerServerEvent("v:init")
RegisterNetEvent("v:init_c")
AddEventHandler("v:init_c", function(vehicles)
    for i,v in pairs(vehicles) do
        unauthorized_vehicles[i] = GetHashKey(v)
    end
end)

RegisterNetEvent("v:baitcarlock")
AddEventHandler("v:baitcarlock", function()
    engine = false
    bcactivated = true
    Citizen.Trace("Baitcar deactivated!")
end)

RegisterNetEvent("v:baitcarunlock")
AddEventHandler("v:baitcarunlock", function()
    bcactivated = false
    Citizen.Trace("Baitcar reactivated!")
end)

Citizen.CreateThread(function()

    while true do
        Citizen.Wait(0)

        DisableControlAction(27, parkKey, true)
        if DoesEntityExist(GetVehiclePedIsIn(GetPlayerPed(-1))) then
            if DoesBlipExist(blip) and GetVehiclePedIsIn(GetPlayerPed(-1)) == savedvehicle then
                if sentalert == true then
                    sentalert = false
                    DecorSetBool(savedvehicle, "vehicle-alarm", false)
                    -- TriggerServerEvent("vc:stopalarm", savedvehicle)
                end
                RemoveBlip(blip)
                if DoesBlipExist(radius) then
                    RemoveBlip(radius)
                end
            end

            if message ~= 3 then
                if counter < 2000 then
                    counter = counter + 1
                end

                if counter > 1000 then
                    message = 3
                elseif counter > 600 then
                    message = 2
                elseif counter > 200 then
                    message = 1
                end

                -- SetTextComponentFormat("STRING")
                if message == 1 then
                    -- AddTextComponentString("Hit ~INPUT_FRONTEND_PAUSE~ to turn your vehicle on and off.")
                    ctrlmessage = "Hit ~INPUT_FRONTEND_PAUSE~ to turn your vehicle on and off."
                    SetIbuttons({
                        {GetControlInstructionalButton(1,parkKey,0),"To turn your vehicle on and off press"},
                        }, 0)
                elseif message == 2 then
                    -- AddTextComponentString("Press ~INPUT_REPLAY_SCREENSHOT~ to activate an alarm system on your vehicle.")
                    ctrlmessage = "Press ~INPUT_REPLAY_SCREENSHOT~ to activate an alarm system on your vehicle."
                    SetIbuttons({
                        {GetControlInstructionalButton(1,saveKey,0),"To activate an alarm system on your vehicle, press"},
                        }, 0)
                end

                if lastmessage ~= message then
                    lastmessage = message
                    if ctrlmessage ~= nil and message ~= 3 then
                        SendNotification("~y~Helpful Information", "Some help text is being displayed in the bottom right of your screen.")
                    end
                end

                DrawIbuttons()

                -- DisplayHelpTextFromStringLabel(0, 0, 1, 32)
            end

            if lastvehicle ~= GetVehiclePedIsIn(GetPlayerPed(-1)) then
                lastvehicle = GetVehiclePedIsIn(GetPlayerPed(-1)) --update lastvehicle
                --if (not bcactivated) then --If not locked down by bait car
                    if engine == true then
                        Citizen.Trace("engine = true")
                        if GetIsVehicleEngineRunning(lastvehicle) == false then --If engine is true but engine is not running, make engine false.
                            Citizen.Trace("running = false")
                            engine = false
                        else
                            Citizen.Trace("running = true")
                        end
                    else
                        Citizen.Trace("engine = false")
                        if GetIsVehicleEngineRunning(lastvehicle) == false then
                            Citizen.Trace("running = false")
                        else
                            Citizen.Trace("running = true") --If engine is running and engine is false, set engine to true
                            engine = true
                        end
                    end
                -- elseif bcactivated then
                --     engine = false
                --     Citizen.Trace("Baitcar is locked, engine cannot start.")
                -- end
            end

            -- SetVehicleFuelLevel(lastvehicle, 7.0) -- Allows forcing the script to see a different fuel
            -- DrawTxt(0.9, 0.8, "~r~"..GetVehicleFuelLevel(lastvehicle))

            maxfuel = GetVehicleHandlingFloat(lastvehicle, "CHandlingData", "fPetrolTankVolume")
            -- DrawTxt(0.9, 0.825, tostring(GetVehicleFuelLevel(lastvehicle)))
            -- DrawTxt(0.9, 0.85, tostring(maxfuel))

            if maxfuel ~= 0.0 then
                percent = (GetVehicleFuelLevel(lastvehicle) * 100) / maxfuel
                opercent = (GetVehicleFuelLevel(lastvehicle) * 100) / maxfuel
                if opercent < 20 then
                    percent = 20 - ((20 - opercent) * 2)
                end

                -- DrawTxt(0.9, 0.6, tostring(opercent))
                -- DrawTxt(0.9, 0.625, tostring(percent))

                percent = tonumber(round(percent, 0))
                if percent < 20 then
                    if percent < 1 then
                        engine = false
                    end
                    DrawLowFuel()
                end

                -- FRFuel starts flashing indicator after 9 fuel level left,
                --   no matter the tank percentage.
                if GetVehicleFuelLevel(lastvehicle) < 9 then
                    -- Maybe we can do something here?
                end
            end

            if engine == false then -- if engine is off and vehicle is moving, lightly apply the breaks to make the vehicle come to a complete stop.
                if not IsVehicleStopped(lastvehicle) then
                    DisableControlAction(27, 71, true)
                    SetControlNormal(27, 72, 0.7)
                else
                    EnableControlAction(27, 71, true)
                end
            end

            -- DrawTxt(0.9, 0.9, "~o~Debug: "..GetVehicleColor(lastvehicle))
            -- DrawTxt(0.9, 0.8, tostring(getColorOfVehicle(lastvehicle)))
            TriggerEvent("debug:fetch", "Vehicle Control Debug", function(debug)
                if debug == true then
                    DrawTxt(0.85, 0.8, "Model: "..tostring(GetEntityModel(lastvehicle)))
                    DrawTxt(0.85, 0.825, "Class: "..tostring(GetVehicleClass(lastvehicle)))
                    DrawTxt(0.85, 0.85, "Fuel Percent: "..tostring((GetVehicleFuelLevel(lastvehicle) * 100) / maxfuel))
                    DrawTxt(0.85, 0.875, "Fuel Level: "..tostring(GetVehicleFuelLevel(lastvehicle)))
                    DrawTxt(0.85, 0.9, "Max Fuel Level: "..tostring(maxfuel))
                    DrawTxt(0.85, 0.925, "Fuel Tank Health: "..tostring(GetVehiclePetrolTankHealth(lastvehicle)))

                    DrawTxt(0.85, 0.75, "Fake Fuel Percent: "..tostring(percent))
                end
            end)

            SetDisableVehiclePetrolTankDamage(lastvehicle, true)
            SetDisableVehiclePetrolTankFires(lastvehicle, true)

            label = GetEntityModel(lastvehicle)
            if IsDisabledControlJustPressed(27,parkKey) then
                -- if not has_value(unauthorized_vehicles, label) then
                    if (not bcactivated) then
                        if engine == true then
                            engine = false
                            SetVehicleEngineOn(lastvehicle, false, false)
                            SetVehiclePetrolTankHealth(lastvehicle, 0.0)
                        else
                            engine = true
                            SetVehicleEngineOn(lastvehicle, true, false)
                            SetVehiclePetrolTankHealth(lastvehicle, 1000.0)
                        end
                    else
                        Citizen.Trace("Baitcar Successfully Disabled")
                    end
                -- else
                --     SendNotification("~r~You cannot start this vehicle", "~y~This vehicle requires a higher rank to start the engine.")
                -- end
            end
            if IsControlJustPressed(27, saveKey) then
                if GetPedInVehicleSeat(lastvehicle, -1) == GetPlayerPed(-1) then
                    if not has_value(unauthorized_vehicles, label) then
                        if lastvehicle ~= savedvehicle then
                            if savedvehicle ~= nil then
                                if sentalert == true then
                                    DecorSetBool(savedvehicle, "vehicle-alarm", false)
                                    -- TriggerServerEvent("vc:stopalarm", savedvehicle)
                                end
                                SetEntityAsNoLongerNeeded(savedvehicle)
                            end
                            SetEntityAsMissionEntity(lastvehicle, true, true)
                            savedvehicle = lastvehicle
                            SendNotification("~b~Vehicle Saved!")
                            recentupdate = true
                            TriggerServerEvent("vc:createalarmsystem")
                            DecorRegister("vehicle-alarm", 2)
                            alarm = true
                            for _,class in ipairs(noalarmclasses) do
                                if class == GetVehicleClass(savedvehicle) then
                                    alarm = false
                                end
                            end
                            if alarm == true then
                                local currentname = GetEntityModel(lastvehicle)
                                for _,name in ipairs(noalarmnames) do
                                    if name == currentname then
                                        alarm = false
                                    end
                                end
                            end
                            if alarm == false then
                                SendNotification("~r~Warning", "~y~This vehicle does not have an alarm system installed.")
                            end
                        end
                    else
                        SendNotification("~r~You cannot save this vehicle", "~y~This vehicle requires a higher rank to save.")
                    end
                else
                    SendNotification("~r~You cannot save this vehicle", "~y~You must be the driver of the vehicle to save it.")
                end
            end
            if GetIsVehicleEngineRunning(lastvehicle) == false and engine == true then
                SetVehicleEngineOn(lastvehicle, true, true)
                SetVehiclePetrolTankHealth(lastvehicle, 1000.0)
            elseif GetIsVehicleEngineRunning(lastvehicle) ~= false and engine == false then
                SetVehicleEngineOn(lastvehicle, false, true)
                SetVehiclePetrolTankHealth(lastvehicle, 0.0)
            end
        else
            if lastvehicle ~= nil and DoesEntityExist(lastvehicle) then
                if GetIsVehicleEngineRunning(lastvehicle) == false and engine == true then
                    SetVehicleEngineOn(lastvehicle, true, true)
                    SetVehiclePetrolTankHealth(lastvehicle, 1000.0)
                elseif GetIsVehicleEngineRunning(lastvehicle) ~= false and engine == false then
                    SetVehicleEngineOn(lastvehicle, false, true)
                    SetVehiclePetrolTankHealth(lastvehicle, 0.0)
                end
                -- keep helicopters in a hover when you bail out of them
                -- if engine == true and GetVehicleClass(lastvehicle) == 15 then
                --     -- SetHeliBladesFullSpeed(lastvehicle)
                --     -- SetEntityInvincible(lastvehicle, true)
                --     -- SetEntityCanBeDamaged(lastvehicle, false)
                --     -- SetEntityProofs(lastvehicle, false, false, true, true, false, true, 1, true)
                --     -- Citizen.Wait(2)
                --     -- FreezeEntityPosition(lastvehicle, true)
                --     CreatePedInsideVehicle(lastvehicle, 4, GetHashKey("s_m_m_chemsec_01"), -1, true, 1)
                -- end

                -- -- SetEntityRotation(lastvehicle, 0.0, 0.0, 0.0, 1, true)
                -- x,y,z = table.unpack(GetEntityCoords(lastvehicle))
                -- if keepz == nil then
                --     keepz = z
                -- elseif keepy == nil then
                --     keepy = z
                -- else
                --     DrawTxt(0.5, 0.7, keepz.."\n"..keepy.."")
                -- end
                -- SetEntityCoords(lastvehicle, x, y, z - 1.718021392823, false, false, false, false)
                -- DrawTxt(0.5, 0.75, x.."\n"..y.."\n"..z.."")
                -- -- SetEntityMaxSpeed(lastvehicle, 0.000001)

            end
        end
        if savedvehicle ~= nil then
            if DoesEntityExist(savedvehicle) then
                if recentupdate == false then
                    if IsControlJustPressed(0, saveKey) then
                        if menuopen == nil then
                            menuopen = false
                        end
                        if menuopen == true then
                            SendNUIMessage("closemenu")
                            menuopen = false
                        else
                            SendNUIMessage("openmenu")
                            menuopen = true
                        end
                    end
                    if IsControlJustPressed(0, 172) then
                        if menuopen == true then
                            SendNUIMessage("moveup")
                        end
                    end
                    if IsControlJustPressed(0, 173) then
                        if menuopen == true then
                            SendNUIMessage("movedown")
                        end
                    end
                    if IsControlJustPressed(0, 201) then
                        if menuopen == true then
                            SendNUIMessage("execute")
                        end
                    end
                else
                    recentupdate = false
                end

                if GetVehiclePedIsIn(GetPlayerPed(-1)) ~= savedvehicle then
                    if DoesBlipExist(blip) == false then
                        blip = AddBlipForCoord(0.0, 0.0, 0.0)
                        SetBlipSprite(blip, 227)
                        SetBlipColour(blip, 2)
                        if alarm == false then
                            radius = AddBlipForRadius(2033.0, 3760.0, 32.0, 75.0)
                            SetBlipColour(radius, 3)
                            SetBlipColour(blip, 17)
                            SetBlipAlpha(radius, 75)
                            SetBlipCoords(radius, 0.0, 0.0, 0.0)
                        end
                        -- SetBlipRoute(blip, true)
                        -- SetBlipRouteColour(blip, 2)
                        if alarm == true then
                            if GetEntitySpeed(savedvehicle) ~= 0 then
                                resyncspeed = true
                            else
                                resyncspeed = false
                                SendNotification("~g~Alarm Activated")
                            end
                        end
                        opos = GetEntityCoords(savedvehicle)
                        ox = round(opos.x, 0)
                        oy = round(opos.y, 0)
                        oz = round(opos.z, 0)
                        -- tx = round(opos.x, 2)
                        -- ty = round(opos.y, 2)
                        -- tz = round(opos.z, 2)
                        sentalert = false
                        damaged = IsVehicleDamaged(savedvehicle)
                    else
                        if resyncspeed == true then
                            opos = GetEntityCoords(savedvehicle)
                            ox = round(opos.x, 0)
                            oy = round(opos.y, 0)
                            oz = round(opos.z, 0)
                            if GetEntitySpeed(savedvehicle) == 0 then
                                resyncspeed = false
                                SendNotification("~g~Alarm Activated")
                            end
                        end
                        local pos = GetEntityCoords(savedvehicle)
                        local tpos = pos
                        tx = round(tpos.x, 0)
                        ty = round(tpos.y, 0)
                        tz = round(tpos.z, 0)
                        -- DrawTxt(0.5, 0.5, "x1: "..tx.." x2: "..ox)
                        -- DrawTxt(0.5, 0.5, "\ny1: ".. ty .." y2: "..oy)
                        -- DrawTxt(0.5, 0.5, "\n\nz1: "..tz.." z2: "..oz)
                        if alarm == true then
                            if tx ~= ox or ty ~= oy or tz ~= oz then
                                SetBlipColour(blip, 1)
                                if sentalert == false then
                                    sentalert = true
                                    SendNotification("~r~Alarm Triggered", "Possible Theft in progress")
                                    DecorSetBool(savedvehicle, "vehicle-alarm", true)
                                    -- TriggerServerEvent("vc:startalarm", savedvehicle)
                                end
                            end
                            if damaged == false and IsVehicleDamaged(savedvehicle) then
                                SetBlipColour(blip, 1)
                                if sentalert == false then
                                    sentalert = true
                                    SendNotification("~r~Alarm Triggered", "Vehicle has been damaged")
                                    DecorSetBool(savedvehicle, "vehicle-alarm", true)
                                    -- TriggerServerEvent("vc:startalarm", savedvehicle)
                                end
                            end
                        end
                        if DoesBlipExist(radius) then
                            if offsetxaxis == 1 then
                                rx = pos.x + offsetindex
                            else
                                rx = pos.x - offsetindex
                            end
                            if offsetyaxis == 1 then
                                ry = pos.y + offsetindex
                            else
                                ry = pos.y - offsetindex
                            end
                            if offsetzaxis == 1 then
                                rz = pos.z + offsetindex
                            else
                                rz = pos.z - offsetindex
                            end
                            SetBlipCoords(blip, rx, ry, rz)
                            SetBlipCoords(radius, rx, ry, rz)
                        else
                            SetBlipCoords(blip, pos.x, pos.y, pos.z)
                        end
                    end
                end
            else
                if DoesBlipExist(blip) then
                    RemoveBlip(blip)
                    if DoesBlipExist(radius) then
                        RemoveBlip(radius)
                    end
                end
            end
        end
    end
end)


-- launch control
Citizen.CreateThread(function()
    launch = false
    launchcount = 0
    while true do
        Citizen.Wait(0)
        local vehicle = GetVehiclePedIsIn(GetPlayerPed(-1))
        if DoesEntityExist(vehicle) then
                if launchready == true then
                    DrawTxt(0.0525, 0.81, "~g~Launch Control Ready!")
                    if not IsVehicleStopped(vehicle) or not IsControlPressed(27, 76) then
                        launch = true
                    end
                end
                if launch == true then
                    DrawTxt(0.017, 0.95, "~b~*")
                    launchready = false
                    SetVehicleEngineTorqueMultiplier(vehicle, 2.0)
                    launchcount = launchcount + 1
                    if launchcount > 400 then
                        launch = false
                        launchcount = 0
                    end
                    if not IsControlPressed(27, 71) then
                        launch = false
                        launchcount = 0
                    end
                    -- DrawTxt(0.9, 0.9, launchcount)
                else
                    if IsVehicleStopped(vehicle) then
                        if IsControlPressed(27, 71) then
                            if IsControlPressed(27, 76) then
                                launchcount = launchcount + 1
                                if launchcount > 50 then
                                    launchready = true
                                    launchcount = 0
                                end
                            end
                        else
                            launchready = false
                            launchcount = 0
                        end
                    else
                        launchready = false
                        launchcount = 0
                    end
                end
        end
    end
end)

-- Alarm offsetting
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        if alarm == false then
            offsetindex = math.random(5, 35)
            offsetxaxis = math.random(0,2)
            offsetyaxis = math.random(0,2)
            offsetzaxis = math.random(0,2)
        end
        if flash == true then
            flash = false
        else
            flash = true
        end
    end
end)

-- Don't close door on exit
-- Citizen.CreateThread(function()
--     while true do
--         Citizen.Wait(0)

--         vehicle = GetVehiclePedIsIn(GetPlayerPed(-1))
--         if DoesEntityExist(vehicle) then
--             TaskLeaveVehicle(GetPlayerPed(-1), vehicle, 256)
--         end
--     end
-- end)

-- Brake lights when stopped.
Citizen.CreateThread(function()
    -- if DoesEntityExist(GetVehiclePedIsIn(GetPlayerPed(-1))) then
    --     SetPedIntoVehicle(GetPlayerPed(-1), GetVehiclePedIsIn(GetPlayerPed(-1)), 0)
    -- end
    while true do
        Citizen.Wait(0)

        for _,i in ipairs(GetPlayers()) do
            local vehicle = GetVehiclePedIsIn(GetPlayerPed(i))
            if DoesEntityExist(vehicle) then
                _, lights, highbeams = GetVehicleLightsState(vehicle)
                if IsVehicleStopped(vehicle) then
                    SetVehicleBrakeLights(vehicle, true)
                end
            end
        end
    end
end)

-- Stuck in passenger
-- if GetPedInVehicleSeat(vehicle, 0) == GetPlayerPed(-1) then
--     if GetIsTaskActive(GetPlayerPed(-1), 165) then
--         -- ClearPedTasksImmediately(GetPlayerPed(-1))
--         if not IsControlPressed(0, 38) then
--             SetPedIntoVehicle(GetPlayerPed(-1), vehicle, 0)
--         end
--         -- TaskEnterVehicle(GetPlayerPed(-1), vehicle, 1, 0, 1.0, 0, 0)
--     end
-- end

-- Citizen.CreateThread(function()
--     while true do
--         Citizen.Wait(500)
--         -- local a,b,c,d,e,f = GetAllVehicles()
--         -- print(a..", "..b..", "..c..", "..d..", "..e..", "..f.."")
--         -- for i,v in pairs(vehicles) do
--         --     print(i)
--         --     print(v)
--         -- end
--         -- for veh,alrm in pairs(serveralarms) do
--         --     if DoesEntityExist(veh) then
--         --         if alrm == true then
--         --             SetVehicleAlarmTimeLeft(veh, 1000)
--         --         end
--         --     end
--         -- end
--     end
-- end)

Citizen.CreateThread(function()
    TriggerEvent("debug:update", "Vehicle Control Debug", false)
end)

RegisterNetEvent("vc:alarmstarted")
RegisterNetEvent("vc:alarmstopped")
RegisterNetEvent("vc:newalarmsystem")
AddEventHandler("vc:alarmstarted", function(player)
    if DoesEntityExist(playeralarms[player]) then
        serveralarms[playeralarms[player]] = true
        Citizen.Trace("Alarm triggered")
    end
end)
AddEventHandler("vc:alarmstopped", function(player)
    if DoesEntityExist(playeralarms[player]) then
        serveralarms[playeralarms[player]] = false
    end
end)
AddEventHandler("vc:newalarmsystem", function(player)
    local player_s = GetPlayerFromServerId(player)
    local ped_s = GetPlayerPed(player_s)
    if DoesEntityExist(ped_s) and not IsEntityDead(ped_s) then
        if IsPedInAnyVehicle(ped_s, false) then
            playeralarms[player] = GetVehiclePedIsIn(ped_s)
        end
    end
end)

RegisterNUICallback("nuiexecute", function(nui)
    if nui.data == "hood" then
        if GetVehicleDoorAngleRatio(savedvehicle, 4) == 0 then
            SetVehicleDoorOpen(savedvehicle, 4, false, false)
        else
            SetVehicleDoorShut(savedvehicle, 4, false)
        end
    elseif nui.data == "trunk" then
        if GetVehicleDoorAngleRatio(savedvehicle, 5) == 0 then
            SetVehicleDoorOpen(savedvehicle, 5, true, false)
        else
            SetVehicleDoorShut(savedvehicle, 5, false)
        end
    elseif nui.data == "engine" then
        if GetIsVehicleEngineRunning(savedvehicle) == false then
            Citizen.Trace("false")
            engine = not engine
            SetVehicleEngineOn(savedvehicle, true, true)
        else
            Citizen.Trace("true")
            engine = not engine
            SetVehicleEngineOn(savedvehicle, false, true)
        end
    elseif nui.data == "window1" then
        if IsVehicleWindowIntact(savedvehicle, 0) then
            RollDownWindow(savedvehicle, 0)
        else
            RollUpWindow(savedvehicle, 0)
        end
    elseif nui.data == "window2" then
        if IsVehicleWindowIntact(savedvehicle, 1) then
            RollDownWindow(savedvehicle, 1)
        else
            RollUpWindow(savedvehicle, 1)
        end
    elseif nui.data == "alarmon" then
        DecorSetBool(savedvehicle, "vehicle-alarm", true)
        -- TriggerServerEvent("vc:startalarm", savedvehicle)
    elseif nui.data == "alarmoff" then
        DecorSetBool(savedvehicle, "vehicle-alarm", false)
        -- TriggerServerEvent("vc:stopalarm", savedvehicle)
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
            if DoesBlipExist(radius) then
                RemoveBlip(radius)
            end
        end
    else
        Citizen.Trace("TODO: Write execution code for: "..nui.data)
    end
end)


function round(num, dec)
    return string.format("%."..(dec or 0).."f", num)
end

function GetPlayers()
    local players = {}

    for i = 0, 31 do
        if NetworkIsPlayerActive(i) then
            table.insert(players, i)
        end
    end

    return players
end
flash = true
function DrawLowFuel()
    DrawRect(0.935, 0.92, 0.1, 0.05, 0, 0, 0, 150)
	SetTextFont(0)
	SetTextProportional(1)
	SetTextScale(0.0, 0.5)
	SetTextColour(255, 255, 255, 255)
	SetTextDropshadow(0, 0, 0, 0, 255)
	SetTextEdge(1, 0, 0, 0, 255)
	SetTextDropShadow()
	SetTextOutline()
    SetTextEntry("STRING")
    if flash == true then
        AddTextComponentString("~o~Low Fuel!")
    else
        AddTextComponentString("~r~Low Fuel!")
    end
	DrawText(0.9, 0.9)
end

function DrawTxt(x,y,text)
	SetTextFont(0)
	SetTextProportional(1)
	SetTextScale(0.0, 0.3)
	SetTextColour(255, 255, 255, 255)
	SetTextDropshadow(0, 0, 0, 0, 255)
	SetTextEdge(1, 0, 0, 0, 255)
	SetTextDropShadow()
	SetTextOutline()
	SetTextEntry("STRING")
	AddTextComponentString(text)
	DrawText(x, y)
end

local carcols = {
[0]="Black",
[1]="Graphite Black",
[2]="Black Steal",
[3]="Dark Silver",
[4]="Silver",
[5]="Blue Silver",
[6]="Steel Gray",
[7]="Shadow Silver",
[8]="Stone Silver",
[9]="Midnight Silver",
[10]="Gun Metal",
[11]="Anthracite Grey",
[12]="Black",
[13]="Gray",
[14]="Light Grey",
[15]="Util Black",
[16]="Util Black Poly",
[17]="Util Dark silver",
[18]="Util Silver",
[19]="Util Gun Metal",
[20]="Util Shadow Silver",
[21]="Worn Black",
[22]="Worn Graphite",
[23]="Worn Silver Grey",
[24]="Worn Silver",
[25]="Worn Blue Silver",
[26]="Worn Shadow Silver",
[27]="Red",
[28]="Torino Red",
[29]="Formula Red",
[30]="Blaze Red",
[31]="Graceful Red",
[32]="Garnet Red",
[33]="Desert Red",
[34]="Cabernet Red",
[35]="Candy Red",
[36]="Sunrise Orange",
[37]="Classic Gold",
[38]="Orange",
[39]="Red",
[40]="Dark Red",
[41]="Orange",
[42]="Yellow",
[43]="Util Red",
[44]="Util Bright Red",
[45]="Util Garnet Red",
[46]="Worn Red",
[47]="Worn Golden Red",
[48]="Worn Dark Red",
[49]="Dark Green",
[50]="Racing Green",
[51]="Sea Green",
[52]="Olive Green",
[53]="Green",
[54]="Gasoline Blue Green",
[55]="Lime Green",
[56]="Util Dark Green",
[57]="Util Green",
[58]="Worn Dark Green",
[59]="Worn Green",
[60]="Worn Sea Wash",
[61]="Midnight Blue",
[62]="Dark Blue",
[63]="Saxony Blue",
[64]="Blue",
[65]="Mariner Blue",
[66]="Harbor Blue",
[67]="Diamond Blue",
[68]="Surf Blue",
[69]="Nautical Blue",
[70]="Bright Blue",
[71]="Purple",
[72]="Spinnaker Purple",
[73]="Ultra Blue",
[74]="Bright Blue",
[75]="Util Dark Blue",
[76]="Util Midnight Blue",
[77]="Util Blue",
[78]="Util Sea Foam Blue",
[79]="Uil Lightning blue",
[80]="Util Maui Blue Poly",
[81]="Util Bright Blue",
[82]="Dark Blue",
[83]="Blue",
[84]="Midnight Blue",
[85]="Worn Dark blue",
[86]="Worn Blue",
[87]="Worn Light blue",
[88]="Taxi Yellow",
[89]="Race Yellow",
[90]="Bronze",
[91]="Yellow Bird",
[92]="Lime",
[93]="Champagne",
[94]="Pueblo Beige",
[95]="Dark Ivory",
[96]="Choco Brown",
[97]="Golden Brown",
[98]="Light Brown",
[99]="Straw Beige",
[100]="Moss Brown",
[101]="Biston Brown",
[102]="Beechwood",
[103]="Dark Beechwood",
[104]="Choco Orange",
[105]="Beach Sand",
[106]="Sun Bleeched Sand",
[107]="Cream",
[108]="Util Brown",
[109]="Util Medium Brown",
[110]="Util Light Brown",
[111]="White",
[112]="Frost White",
[113]="Worn Honey Beige",
[114]="Worn Brown",
[115]="Worn Dark Brown",
[116]="Worn straw beige",
[117]="Brushed Steel",
[118]="Brushed Black steel",
[119]="Brushed Aluminium",
[120]="Chrome",
[121]="Worn Off White",
[122]="Util Off White",
[123]="Worn Orange",
[124]="Worn Light Orange",
[125]="Securicor Green",
[126]="Worn Taxi Yellow",
[127]="police car blue",
[128]="Green",
[129]="Brown",
[130]="Worn Orange",
[131]="White",
[132]="Worn White",
[133]="Worn Olive Army Green",
[134]="Pure White",
[135]="Hot Pink",
[136]="Salmon pink",
[137]="Vermillion Pink",
[138]="Orange",
[139]="Green",
[140]="Blue",
[141]="Mettalic Black Blue",
[142]="Black Purple",
[143]="Black Red",
[144]="hunter green",
[145]="Purple",
[146]="Metaillic V Dark Blue",
[147]="Carbon Black",
[148]="Purple",
[149]="Dark Purple",
[150]="Lava Red",
[151]="Forest Green",
[152]="Olive Drab",
[153]="Desert Brown",
[154]="Desert Tan",
[155]="Foilage Green",
[156]="DEFAULT ALLOY COLOR",
[157]="Epsilon Blue",
[158]="Gold",
[159]="Gold"
}

function has_value (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

function getColorOfVehicle(veh)
    local carcols = { [0]="Black", [1]="Graphite Black", [2]="Black Steal", [3]="Dark Silver", [4]="Silver", [5]="Blue Silver", [6]="Steel Gray", [7]="Shadow Silver", [8]="Stone Silver", [9]="Midnight Silver", [10]="Gun Metal", [11]="Anthracite Grey", [12]="Black", [13]="Gray", [14]="Light Grey", [15]="Util Black", [16]="Util Black Poly", [17]="Util Dark silver", [18]="Util Silver", [19]="Util Gun Metal", [20]="Util Shadow Silver", [21]="Worn Black", [22]="Worn Graphite", [23]="Worn Silver Grey", [24]="Worn Silver", [25]="Worn Blue Silver", [26]="Worn Shadow Silver", [27]="Red", [28]="Torino Red", [29]="Formula Red", [30]="Blaze Red", [31]="Graceful Red", [32]="Garnet Red", [33]="Desert Red", [34]="Cabernet Red", [35]="Candy Red", [36]="Sunrise Orange", [37]="Classic Gold", [38]="Orange", [39]="Red", [40]="Dark Red", [41]="Orange", [42]="Yellow", [43]="Util Red", [44]="Util Bright Red", [45]="Util Garnet Red", [46]="Worn Red", [47]="Worn Golden Red", [48]="Worn Dark Red", [49]="Dark Green", [50]="Racing Green", [51]="Sea Green", [52]="Olive Green", [53]="Green", [54]="Gasoline Blue Green", [55]="Lime Green", [56]="Util Dark Green", [57]="Util Green", [58]="Worn Dark Green", [59]="Worn Green", [60]="Worn Sea Wash", [61]="Midnight Blue", [62]="Dark Blue", [63]="Saxony Blue", [64]="Blue", [65]="Mariner Blue", [66]="Harbor Blue", [67]="Diamond Blue", [68]="Surf Blue", [69]="Nautical Blue", [70]="Bright Blue", [71]="Purple", [72]="Spinnaker Purple", [73]="Ultra Blue", [74]="Bright Blue", [75]="Util Dark Blue", [76]="Util Midnight Blue", [77]="Util Blue", [78]="Util Sea Foam Blue", [79]="Uil Lightning blue", [80]="Util Maui Blue Poly", [81]="Util Bright Blue", [82]="Dark Blue", [83]="Blue", [84]="Midnight Blue", [85]="Worn Dark blue", [86]="Worn Blue", [87]="Worn Light blue", [88]="Taxi Yellow", [89]="Race Yellow", [90]="Bronze", [91]="Yellow Bird", [92]="Lime", [93]="Champagne", [94]="Pueblo Beige", [95]="Dark Ivory", [96]="Choco Brown", [97]="Golden Brown", [98]="Light Brown", [99]="Straw Beige", [100]="Moss Brown", [101]="Biston Brown", [102]="Beechwood", [103]="Dark Beechwood", [104]="Choco Orange", [105]="Beach Sand", [106]="Sun Bleeched Sand", [107]="Cream", [108]="Util Brown", [109]="Util Medium Brown", [110]="Util Light Brown", [111]="White", [112]="Frost White", [113]="Worn Honey Beige", [114]="Worn Brown", [115]="Worn Dark Brown", [116]="Worn straw beige", [117]="Brushed Steel", [118]="Brushed Black steel", [119]="Brushed Aluminium", [120]="Chrome", [121]="Worn Off White", [122]="Util Off White", [123]="Worn Orange", [124]="Worn Light Orange", [125]="Securicor Green", [126]="Worn Taxi Yellow", [127]="police car blue", [128]="Green", [129]="Brown", [130]="Worn Orange", [131]="White", [132]="Worn White", [133]="Worn Olive Army Green", [134]="Pure White", [135]="Hot Pink", [136]="Salmon pink", [137]="Vermillion Pink", [138]="Orange", [139]="Green", [140]="Blue", [141]="Mettalic Black Blue", [142]="Black Purple", [143]="Black Red", [144]="hunter green", [145]="Purple", [146]="Metaillic V Dark Blue", [147]="Carbon Black", [148]="Purple", [149]="Dark Purple", [150]="Lava Red", [151]="Forest Green", [152]="Olive Drab", [153]="Desert Brown", [154]="Desert Tan", [155]="Foilage Green", [156]="DEFAULT ALLOY COLOR", [157]="Epsilon Blue", [158]="Pure Gold", [159]="Brushed Gold" }
    if carcols[GetVehicleColours(veh)] ~= nil then
        return carcols[GetVehicleColours(veh)]
    else
        return GetVehicleColours(veh)
    end
end

function SendNotification(text, text2) -- Do not ever edit this!
	SetNotificationTextEntry("STRING")
	if text2 ~= nil then
        AddTextComponentString(text2)
    end
    Citizen.InvokeNative(0x1E6611149DB3DB6B, "CHAR_LIFEINVADER", "CHAR_LIFEINVADER", true, 1, "Vehicle Alarm System", text, 0.5)
	DrawNotification_4(false, true)
	-- DrawNotification(false, false)
end

local Ibuttons = nil
function SetIbuttons(buttons, layout) --Layout: 0 - Horizontal, 1 - vertical
	Citizen.CreateThread(function()
		if not HasScaleformMovieLoaded(Ibuttons) then
			Ibuttons = RequestScaleformMovie("INSTRUCTIONAL_BUTTONS")
			while not HasScaleformMovieLoaded(Ibuttons) do
				Citizen.Wait(0)
			end
		end
		local sf = Ibuttons
		local w,h = GetScreenResolution()
		PushScaleformMovieFunction(sf,"INSTRUCTIONAL_BUTTONS")
		PopScaleformMovieFunction()
		PushScaleformMovieFunction(sf,"SET_DISPLAY_CONFIG")
		PushScaleformMovieFunctionParameterInt(w)
		PushScaleformMovieFunctionParameterInt(h)
		PushScaleformMovieFunctionParameterFloat(0.02)
		PushScaleformMovieFunctionParameterFloat(0.98)
		PushScaleformMovieFunctionParameterFloat(0.02)
		PushScaleformMovieFunctionParameterFloat(0.98)
		PushScaleformMovieFunctionParameterBool(true)
		PushScaleformMovieFunctionParameterBool(false)
		PushScaleformMovieFunctionParameterBool(false)
		PushScaleformMovieFunctionParameterInt(w)
		PushScaleformMovieFunctionParameterInt(h)
		PopScaleformMovieFunction()
		PushScaleformMovieFunction(sf,"SET_MAX_WIDTH")
		PushScaleformMovieFunctionParameterInt(1)
		PopScaleformMovieFunction()
		--PushScaleformMovieFunction(sf,"SET_BACKGROUND_COLOUR")
		--PushScaleformMovieFunctionParameterInt(0)
		--PushScaleformMovieFunctionParameterInt(0)
		--PushScaleformMovieFunctionParameterInt(0)
		--PushScaleformMovieFunctionParameterInt(100)
		--PopScaleformMovieFunction()

		for i,btn in pairs(buttons) do
			PushScaleformMovieFunction(sf,"SET_DATA_SLOT")
			PushScaleformMovieFunctionParameterInt(i-1)
			PushScaleformMovieFunctionParameterString(btn[1])
			PushScaleformMovieFunctionParameterString(btn[2])
			PopScaleformMovieFunction()

		end
		if layout ~= 1 then
			PushScaleformMovieFunction(sf,"SET_PADDING")
			PushScaleformMovieFunctionParameterInt(10)
			PopScaleformMovieFunction()
		end
		PushScaleformMovieFunction(sf,"DRAW_INSTRUCTIONAL_BUTTONS")
		PushScaleformMovieFunctionParameterInt(layout)
		PopScaleformMovieFunction()
	end)
end
function DrawIbuttons() -- Layout: 1 - vertical,0 - horizontal
	if HasScaleformMovieLoaded(Ibuttons) then
		DrawScaleformMovie(Ibuttons, 0.5, 0.5, 1.0, 1.0, 255, 255, 255, 255)
	end
end

local Keys = {
	["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
	["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
	["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
	["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
	["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
	["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
	["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
	["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
	["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}
