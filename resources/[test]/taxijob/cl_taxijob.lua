print('Stag Productions V1.0.0 Loaded')

local QBCore = exports['qb-core']:GetCoreObject()
QBCore.Shared = nil

collectgarbage("collect")

local taxi

local meterIsOpen = false
local meterActive = false
local lastLocation = nil

local taxiSpawnLocation = Config.taxiSpawn
local taxiDutyLocation = Config.dutyToggle
local taxiReturnLocation = Config.taxiReturnLocation

local meterData = {
    fareAmount = 0,
    currentFare = 0,
    distanceTravelled = 0,
}

-- Functions
local function resetMeter()
    meterData = {
        fareAmount = 0,
        currentFare = 0,
        distanceTravelled = 0,
        startingLength = 0,
        distanceLeft = 0
    }
end


local function calculateFareAmount()
    if meterIsOpen and meterActive then
        local startPos = lastLocation
        local newPos = GetEntityCoords(PlayerPedId())
        if startPos ~= newPos then
            local newDistance = #(startPos - newPos)
            lastLocation = newPos
            meterData['distanceTravelled'] += (newDistance / 1609)
            meterData.fareAmount = ((meterData['distanceTravelled']) * Config.Meter['defaultPrice']) + Config.Meter['startingPrice']
            SendNUIMessage({
                action = 'updateMeter',
                meterData = meterData
            })
        end
    end
end

local function StartCalc()
    CreateThread(function()
        while taxi do
            Wait(2000)
            calculateFareAmount()
        end
    end)
end

local function IsDriver()
    return GetPedInVehicleSeat(GetVehiclePedIsIn(PlayerPedId(), false), -1) == PlayerPedId()
end

CreateThread(function()
    local taxiBlip = AddBlipForCoord(taxiDutyLocation.x, taxiDutyLocation.y, taxiDutyLocation.z)
    SetBlipSprite(taxiBlip, 198)
    SetBlipDisplay(taxiBlip, 4)
    SetBlipScale(taxiBlip, 0.7)
    SetBlipAsShortRange(taxiBlip, true)
    SetBlipColour(taxiBlip, 29)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Taxi Depot')
    EndTextCommandSetBlipName(taxiBlip)
end)


CreateThread(function()
    exports['qb-target']:AddBoxZone("TaxiDutyZone", taxiDutyLocation, 2.0, 2.0, {
        name = "TaxiDutyZone",
        heading = 0,
        debugPoly = true,
        minZ = 27.6,
        maxZ = 28.6,
    }, {
        options = {
            {
                type = "client",
                event = "stag_taxijob:ToggleDuty",
                icon = "fas fa-clipboard",
                label = "Toggle Taxi Duty",
            },
        },
        distance = 2.5,
    })
end)

CreateThread(function()
    while true do
        if not IsPedInAnyVehicle(PlayerPedId(), false) then
            if meterIsOpen then
                SendNUIMessage({
                    action = 'openMeter',
                    toggle = false
                })
                meterIsOpen = false
            end
        end
        Wait(200)
    end
end)

function SpawnTaxi()
    if taxi then
        QBCore.Functions.Notify("You already have a taxi.")
    else
        local Ped = PlayerPedId()
        local vehicleModel = GetHashKey(Config.taxiModel)

        RequestModel(vehicleModel)
        while not HasModelLoaded(vehicleModel) do
            Citizen.Wait(0)
        end

        local spawnCoords = taxiSpawnLocation
        taxi = CreateVehicle(vehicleModel, spawnCoords.x, spawnCoords.y, spawnCoords.z, GetEntityHeading(Ped), true, false)
        StartCalc()
        TaskWarpPedIntoVehicle(Ped, taxi, -1)
        lastLocation = GetEntityCoords(PlayerPedId())
        TriggerEvent('vehiclekeys:client:SetOwner', QBCore.Functions.GetPlate(taxi))
        Wait(1000)
       TriggerEvent('stag_taxijob:toggleMeter', Ped)
       SetModelAsNoLongerNeeded(vehicleModel)
    end
end

function ReturnTaxi()
    meterIsOpen = false
    meterActive = false
    
    if not taxi then return QBCore.Functions.Notify("You don't have a taxi to return.") end
    TriggerEvent('stag_taxijob:toggleMeter')
    
    if DoesEntityExist(taxi) then
        DeleteEntity(taxi)
    end

    taxi = nil

    QBCore.Functions.Notify("You have returned the taxi.")

    if meterIsOpen then
        SendNUIMessage({
            action = 'toggleMeter'
        })
        SendNUIMessage({
            action = 'resetMeter'
        })
    end
end

-- NUI Callback
RegisterNUICallback('enableMeter', function(data, cb)
    meterActive = data.enabled
    if not meterActive then resetMeter() end
    lastLocation = GetEntityCoords(PlayerPedId())
    cb('ok')
end)

-- PolyZone
local toggle = false
local function toggleOnOff()
    local onDuty = QBCore.Functions.GetPlayerData().job.onduty
    local job = QBCore.Functions.GetPlayerData().job.name
    toggle = not toggle
    CreateThread(function()
        while toggle do
            Wait(0)
            if job == 'taxijob' and onDuty then
                DrawMarker(39, taxiSpawnLocation.x, taxiSpawnLocation.y, taxiSpawnLocation.z + 2, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 2.0, 2.0, 2.0, 0, 100, 0, 50, false, true, 2, nil, nil, false)
            if IsControlJustPressed(0, 38) then
                SpawnTaxi()
            end
        end
    end
    end)
end

local CircleZone = CircleZone:Create(vector3(taxiSpawnLocation.x, taxiSpawnLocation.y, taxiSpawnLocation.z), 10.0, {
    name="circle_zone",
    debugPoly=false,
})

CircleZone:onPointInOut(PolyZone.getPlayerPosition, function(isPointInside)
    if isPointInside then
        toggleOnOff()
    else
        toggleOnOff()
    end
end)

local toggle2 = false
local function toggle2OnOff()
    local job = QBCore.Functions.GetPlayerData().job.name
    toggle2 = not toggle2
    CreateThread(function()
        while toggle2 do
            Wait(0)
            if job == 'taxijob' then
                DrawMarker(39, taxiReturnLocation.x, taxiReturnLocation.y, taxiReturnLocation.z + 2, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 2.0, 2.0, 2.0, 255, 0, 0, 50, false, true, 2, nil, nil, false)
            if IsControlJustPressed(0, 38) then
                ReturnTaxi()
            end
        end
    end
    end)
end

local CircleZone2 = CircleZone:Create(vector3(taxiReturnLocation.x, taxiReturnLocation.y, taxiReturnLocation.z), 10.0, {
    name="circle_zone2",
    debugPoly=false,
})
CircleZone2:onPointInOut(PolyZone.getPlayerPosition, function(isPointInside)
    if isPointInside then
        toggle2OnOff()
    else
        toggle2OnOff()
    end
end)

-- Events
RegisterNetEvent('stag_taxijob:ToggleDuty', function()
    local job = QBCore.Functions.GetPlayerData().job.name
    if job == 'taxijob' then
        TriggerServerEvent('QBCore:ToggleDuty')
    else
        QBCore.Functions.Notify('Not a taxi driver', 'error', 5000)
    end

end)

RegisterNetEvent('stag_taxijob:toggleMeter', function()
    local ped = PlayerPedId()
          print(IsPedInAnyVehicle(ped, false))
        if IsPedInAnyVehicle(ped, false) then
            if not meterIsOpen and IsDriver() then
                SendNUIMessage({
                    action = 'openMeter',
                    toggle = true,
                    meterData = Config.Meter
                })
                meterIsOpen = true
            else
                SendNUIMessage({
                    action = 'openMeter',
                    toggle = false
                })
                meterIsOpen = false
            end
        else
            QBCore.Functions.Notify('Missing Meter', 'error', 5000)
        end
end)

RegisterNetEvent('stag_taxijob:enableMeter', function()
    if meterIsOpen then
        SendNUIMessage({
            action = 'toggleMeter'
        })
        meterActive = true
    else
        QBCore.Functions.Notify('Meter not Active', 'error', 5000)
    end
end)

RegisterNetEvent("stag_taxijob:chargeRider", function()
    local bill = exports['qb-input']:ShowInput({
        header = "Taxi Fare",
        submitText = "Charge",
        inputs = {
            {
                text = "Server ID(#)",
                name = "citizenid", 
                type = "text", 
                isRequired = true
            },
            {
                text = "   Bill Price (£)",
                name = "billprice", 
                type = "number",
                isRequired = false
            }
        }
    })
    if bill ~= nil then
        if bill.citizenid == nil or bill.billprice == nil then 
            return 
        end
        TriggerServerEvent("stag_taxijob:server:billPlayer", bill.citizenid, bill.billprice)
    end
end)

RegisterNetEvent('stag_taxijob:client:taxiAlert', function(coords, text)
    local street1, street2 = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local street1name = GetStreetNameFromHashKey(street1)
    local street2name = GetStreetNameFromHashKey(street2)
    QBCore.Functions.Notify({ text = text, caption = street1name .. ' ' .. street2name }, 'taxi')
    PlaySound(-1, 'Lose_1st', 'GTAO_FM_Events_Soundset', 0, 0, 1)
    local transG = 250
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    local blip2 = AddBlipForCoord(coords.x, coords.y, coords.z)
    local blipText = 'Taxi Alert'
    SetBlipSprite(blip, 198)
    SetBlipSprite(blip2, 161)
    SetBlipColour(blip, 2)
    SetBlipColour(blip2, 2)
    SetBlipDisplay(blip, 4)
    SetBlipDisplay(blip2, 8)
    SetBlipAlpha(blip, transG)
    SetBlipAlpha(blip2, transG)
    SetBlipScale(blip, 0.8)
    SetBlipScale(blip2, 2.0)
    SetBlipAsShortRange(blip, false)
    SetBlipAsShortRange(blip2, false)
    PulseBlip(blip2)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(blipText)
    EndTextCommandSetBlipName(blip)
    while transG ~= 0 do
        Wait(180 * 4)
        transG = transG - 1
        SetBlipAlpha(blip, transG)
        SetBlipAlpha(blip2, transG)
        if transG == 0 then
            RemoveBlip(blip)
            return
        end
    end
end)



-- Commands
RegisterCommand("taxifare", function()
    local job = QBCore.Functions.GetPlayerData().job.name
    if job == 'taxijob' then
        if IsPedInVehicle(PlayerPedId(), taxi, false) then
    TriggerEvent("stag_taxijob:chargeRider")
    else 
        QBCore.Functions.Notify('Not on duty or not in a bus', 'error', 5000)
    end
end
end, false)

RegisterCommand("calltaxi", function()
TriggerServerEvent('stag_taxijob:server:taxiAlert')
QBCore.Functions.Notify('Taxi Service Has Revieved Your Call', 'success', 5000)
end, false)

RegisterCommand("togglemeter", function()
    if IsPedInVehicle(PlayerPedId(), taxi, false) then
    TriggerEvent('stag_taxijob:toggleMeter')
    else 
        QBCore.Functions.Notify('Not in a Taxi', 'error', 5000)
    end
    end, false)

    RegisterCommand("startmeter", function()
        if IsPedInVehicle(PlayerPedId(), taxi, false) then
        TriggerEvent('stag_taxijob:enableMeter')
        else 
            QBCore.Functions.Notify('Not in a Taxi', 'error', 5000)
        end
        end, false)

RegisterCommand('clearmeter', function()
    if meterActive then
        SendNUIMessage({
            action = 'toggleMeter'
        })
        SendNUIMessage({
            action = 'resetMeter'
        })
        meterActive = false
    end
end, false)

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
end)