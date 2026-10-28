-- PowerMoves RP medical-service duty blips.
-- The server decides which responders qualify; clients only render the list.
local QBCore = exports['qb-core']:GetCoreObject({ 'Functions' })

local function IsResponder(job)
    return job and job.onduty and Config.DutyBlips.Services[job.type] ~= nil
end

local function BuildDutyBlips()
    local responders = {}
    for _, player in pairs(QBCore.Functions.GetQBPlayers()) do
        local data = player.PlayerData
        if data and IsResponder(data.job) then
            local ped = GetPlayerPed(data.source)
            if ped and ped ~= 0 then
                local pos = GetEntityCoords(ped)
                local vehicle = GetVehiclePedIsIn(ped, false)
                local mode = 'foot'
                if vehicle and vehicle ~= 0 then
                    -- Server-side vehicle type is authoritative and does not need client reports.
                    local kind = GetVehicleType(vehicle)
                    if kind == 'heli' then
                        mode = 'helicopter'
                    elseif kind == 'plane' then
                        mode = 'plane'
                    elseif kind == 'bike' then
                        mode = 'motorcycle'
                    else
                        mode = 'vehicle'
                    end
                end
                responders[#responders + 1] = {
                    source = data.source,
                    job = data.job.name,
                    agency = data.job.label or data.job.name,
                    service = data.job.type,
                    callsign = data.metadata and data.metadata.callsign or '',
                    x = pos.x, y = pos.y, z = pos.z,
                    heading = GetEntityHeading(ped),
                    mode = mode
                }
            end
        end
    end
    return responders
end

CreateThread(function()
    while true do
        local responders = BuildDutyBlips()
        for _, player in pairs(QBCore.Functions.GetQBPlayers()) do
            local data = player.PlayerData
            if data then
                if IsResponder(data.job) then
                    TriggerClientEvent('ambulance:client:UpdateDutyBlips', data.source, responders)
                else
                    TriggerClientEvent('ambulance:client:UpdateDutyBlips', data.source, {})
                end
            end
        end
        Wait(Config.DutyBlips.RefreshMs)
    end
end)
