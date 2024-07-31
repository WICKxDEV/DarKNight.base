local minGangMemberConnected = 0
local QBCore = exports['qb-core']:GetCoreObject()

function checkGroup(table, val)
    for k, v in pairs(table) do
        if val == v.label then
            return true
        end
    end
    return false
end

function removeGroup(tab, val)
    for k, v in pairs(tab) do
        if v.label == val then
            tab[k] = nil
        end
    end
end

function isContested(tab)
    local count = 0
    for _, _ in pairs(tab) do
        count = count + 1
    end

    return count > 1 and "contested" or ""
end

function sendTerritoryData(src)
    local territories = Zones["Territories"]
    TriggerClientEvent("qb-gangs:client:receiveTerritories", src, territories)
end

RegisterNetEvent("qb-gangs:server:updateterritories")
AddEventHandler("qb-gangs:server:updateterritories", function(zone, inside)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local Gang = Player.PlayerData.gang
    local gangMemberConnected = 0
    local Territory = Zones["Territories"][zone]

    if Territory ~= nil then
        -- If they're not in a gang or they're not a cop just ignore them
        if Gang.name ~= "none" then
            if inside then
                if not checkGroup(Territory.occupants, Gang.label) then
                    Territory.occupants[Gang.label] = {
                        label = Gang.label,
                        score = 0
                    }
                else
                    for _, playerId in pairs(QBCore.Functions.GetPlayers()) do
                        local Player = QBCore.Functions.GetPlayer(playerId)
                        if Player ~= nil and Player.PlayerData.gang.name == Gang.name then
                            gangMemberConnected = gangMemberConnected + 1
                        end
                    end

                    if gangMemberConnected >= minGangMemberConnected then
                        local score = Territory.occupants[Gang.label].score
                        if score < Zones["Config"].minScore and Territory.winner ~= Gang.label then
                            if isContested(Territory.occupants) == "" then
                                Territory.occupants[Gang.label].score = Territory.occupants[Gang.label].score + 1
                                TriggerClientEvent('QBCore:Notify', src, "Taking Zone Progress " .. Territory.occupants[Gang.label].score .. "/" .. Zones["Config"].minScore, "success")
                            end
                        else
                            Territory.winner = Gang.label
                            TriggerClientEvent("qb-gangs:client:updateblips", -1, zone, Gang.label)
                            TriggerClientEvent("qb-gangs:client:updateBlipRadius", -1, zone, gangMemberConnected)
                            Wait(1000)
                        end
                    else
                        --TriggerClientEvent('QBCore:Notify', src, Lang:t("error.member_not_connected"), "error")
                    end
                end
            else
                removeGroup(Territory.occupants, Gang.label)
            end
        end
    end
end)

AddEventHandler('QBCore:Server:OnPlayerLoaded', function(playerId)
    sendTerritoryData(playerId)
end)
