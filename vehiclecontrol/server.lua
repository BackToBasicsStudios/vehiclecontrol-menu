local alarms = {}
local locked_vehicles = {}
locked_vehicles["police3"] = 0
locked_vehicles["police4"] = 0
locked_vehicles["police7"] = 0
locked_vehicles["sheriff"] = 1
locked_vehicles["policeb"] = 1
locked_vehicles["sheriff2"] = 2
locked_vehicles["sheriff3"] = 2
locked_vehicles["police5"] = 3
locked_vehicles["fbi2"] = 4
locked_vehicles["police2"] = 5
locked_vehicles["fbi"] = 6
locked_vehicles["police9"] = 7
locked_vehicles["fbi3"] = 8

locked_vehicles["lykan"] = 30

-- code
RegisterServerEvent("vc:startalarm")
AddEventHandler("vc:startalarm", function(vehicle)
    -- alarms[] = true
    TriggerClientEvent("vc:alarmstarted", -1, source)
end)

RegisterServerEvent("vc:stopalarm")
AddEventHandler("vc:stopalarm", function(vehicle)
    -- alarms[] = false
    TriggerClientEvent("vc:alarmstopped", -1, source)
end)

RegisterServerEvent("vc:createalarmsystem")
AddEventHandler("vc:createalarmsystem", function()
    TriggerClientEvent("vc:newalarmsystem", -1, source)
end)

RegisterServerEvent("v:init")
AddEventHandler("v:init", function()
    local Source = source
    local vehicles = {}
    TriggerEvent("es:getPlayerFromId", source, function(user)
        if user ~= nil then
            increment = 0
            for i,v in pairs(locked_vehicles) do
                local userident = user.getBank()
                if userident < v then
                    vehicles[increment] = i
                    increment = increment + 1
                end
            end
            TriggerClientEvent("v:init_c", Source, vehicles)
        end
    end)
end)
