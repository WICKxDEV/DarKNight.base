local Territories = {}
local insidePoint = false
local activeZone = nil

local QBCore = exports['qb-core']:GetCoreObject()

isLoggedIn = false
PlayerGang = {}
PlayerJob = {}

RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    isLoggedIn = true
    PlayerGang = QBCore.Functions.GetPlayerData().gang
    PlayerJob = QBCore.Functions.GetPlayerData().job
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload')
AddEventHandler('QBCore:Client:OnPlayerUnload', function()
    isLoggedIn = false
end)

RegisterNetEvent('QBCore:Client:OnGangUpdate')
AddEventHandler('QBCore:Client:OnGangUpdate', function(GangInfo)
    PlayerGang = GangInfo
    isLoggedIn = true
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate')
AddEventHandler('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo
    isLoggedIn = true
end)

CreateThread(function()
    Wait(500)
    for k, v in pairs(Zones["Territories"]) do
        local zone = CircleZone:Create(v.centre, v.radius, {
            name = "greenzone-"..k,
            debugPoly = Zones["Config"].debug,
        })

        local blip = AddBlipForRadius(v.centre.x, v.centre.y, v.centre.z, v.radius)
        SetBlipAlpha(blip, 80)
        SetBlipColour(blip, Zones["Gangs"][v.winner].color or Zones["Gangs"]["neutral"].color)

        local blip2 = AddBlipForCoord(v.centre.x, v.centre.y, v.centre.z)
        SetBlipSprite(blip2, v.blip)
        SetBlipDisplay(blip2, 4)
        SetBlipScale(blip2, 0.8)
        SetBlipAsShortRange(blip2, true)
        SetBlipColour(blip2, Zones["Gangs"][v.winner].color or Zones["Gangs"]["neutral"].color)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(Zones["Gangs"][v.winner].name)
        EndTextCommandSetBlipName(blip2)

        Territories[k] = {
            zone = zone,
            id = k,
            blip = blip,
            blip2 = blip2,
            baseRadius = v.radius
        }
    end
end)

RegisterNetEvent("qb-gangs:client:updateblips")
AddEventHandler("qb-gangs:client:updateblips", function(zone, winner)
    local colour = Zones["Gangs"][winner].color
    local blip = Territories[zone].blip
    local blip2 = Territories[zone].blip2
    SetBlipColour(blip, colour)
    SetBlipColour(blip2, colour)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName(Zones["Gangs"][winner].name)
    EndTextCommandSetBlipName(blip2)
end)

function isContested(tab)
    local count = 0
    for _, _ in pairs(tab) do
        count = count + 1
    end

    return count > 1 and "contested" or ""
end

function updateBlipRadius(zone, playerCount)
    local newRadius = Territories[zone].baseRadius + (playerCount * 10) -- Adjust multiplier as needed
    SetBlipScale(Territories[zone].blip, newRadius / Territories[zone].baseRadius)
end

CreateThread(function()
    while true do 
        Wait(500)
        if isLoggedIn then
            local PlayerPed = PlayerPedId()
            local pedCoords = GetEntityCoords(PlayerPed)
            
            for _, v in pairs(Zones["Territories"]) do
                while isContested(v.occupants) == "contested" do
                    -- Handle contested territory logic here
                end
            end 

            for k, zone in pairs(Territories) do  
                if Territories[k].zone:isPointInside(pedCoords) then
                    insidePoint = true
                    activeZone = Territories[k].id
                        
                    TriggerEvent("QBCore:Notify", Lang:t("error.enter_gangzone"), "error")
          
                    while insidePoint do   
                        exports['qb-drawtext']:DrawText(Lang:t("error.hostile_zone"), 'right')
                        if PlayerGang.name ~= "none" then
                            TriggerServerEvent("qb-gangs:server:updateterritories", activeZone, true) 
                        end   
                        if not Territories[k].zone:isPointInside(GetEntityCoords(PlayerPed)) then
                            if PlayerGang.name ~= "none" then
                                TriggerServerEvent("qb-gangs:server:updateterritories", activeZone, false)
                            end
                            insidePoint = false
                            activeZone = nil
                            QBCore.Functions.Notify(Lang:t("error.leave_gangzone"), "error")
                        end
                        Wait(1000)
                    end
                    exports['qb-drawtext']:HideText()
                end
            end  
            Wait(2000)
        end
    end
end)

RegisterNetEvent("qb-gangs:client:updateBlipRadius")
AddEventHandler("qb-gangs:client:updateBlipRadius", function(zone, playerCount)
    updateBlipRadius(zone, playerCount)
end)

RegisterNetEvent("qb-gangs:client:receiveTerritories")
AddEventHandler("qb-gangs:client:receiveTerritories", function(territories)
    for k, v in pairs(territories) do
        if Territories[k] then
            Territories[k].zone = CircleZone:Create(v.centre, v.radius, {
                name = "greenzone-" .. k,
                debugPoly = Zones["Config"].debug
            })

            local blip = AddBlipForRadius(v.centre.x, v.centre.y, v.centre.z, v.radius)
            SetBlipAlpha(blip, 80)
            SetBlipColour(blip, Zones["Gangs"][v.winner].color or Zones["Gangs"]["neutral"].color)

            local blip2 = AddBlipForCoord(v.centre.x, v.centre.y, v.centre.z)
            SetBlipSprite(blip2, v.blip)
            SetBlipDisplay(blip2, 4)
            SetBlipScale(blip2, 0.8)
            SetBlipAsShortRange(blip2, true)
            SetBlipColour(blip2, Zones["Gangs"][v.winner].color or Zones["Gangs"]["neutral"].color)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentSubstringPlayerName(Zones["Gangs"][v.winner].name)
            EndTextCommandSetBlipName(blip2)

            Territories[k].blip = blip
            Territories[k].blip2 = blip2
            Territories[k].baseRadius = v.radius
        end
    end
end)
