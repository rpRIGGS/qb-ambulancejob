-- PowerMoves RP medical duty blip display.
local QBCore = exports['qb-core']:GetCoreObject({ 'Functions' })
local blips = {}
local sprites = { foot = 1, vehicle = 225, motorcycle = 226, helicopter = 43, plane = 16 }

local function ClearDutyBlips()
    for _, blip in pairs(blips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end
    blips = {}
end

RegisterNetEvent('ambulance:client:UpdateDutyBlips', function(responders)
    local job = QBCore.Functions.GetPlayerData().job
    if not job or not job.onduty or not Config.DutyBlips.Services[job.type] then
        ClearDutyBlips()
        return
    end

    local seen = {}
    for _, responder in ipairs(responders or {}) do
        if responder.source ~= GetPlayerServerId(PlayerId()) then
            seen[responder.source] = true
            local style = Config.DutyBlips.Services[responder.service]
            if style then
                local blip = blips[responder.source]
                if not blip or not DoesBlipExist(blip) then
                    blip = AddBlipForCoord(responder.x, responder.y, responder.z)
                    blips[responder.source] = blip
                    SetBlipDisplay(blip, 4)
                    SetBlipScale(blip, 0.85)
                    SetBlipAsShortRange(blip, false)
                end
                SetBlipCoords(blip, responder.x, responder.y, responder.z)
                SetBlipSprite(blip, sprites[responder.mode] or sprites.foot)
                SetBlipColour(blip, style.color)
                ShowHeadingIndicatorOnBlip(blip, true)
                SetBlipRotation(blip, math.floor(responder.heading or 0))
                local agency = responder.agency or responder.job or responder.service
                local callsign = tostring(responder.callsign or '')
                local label = callsign ~= '' and (agency .. ' | ' .. callsign) or agency
                BeginTextCommandSetBlipName('STRING')
                AddTextComponentSubstringPlayerName(label)
                EndTextCommandSetBlipName(blip)
            end
        end
    end
    for source, blip in pairs(blips) do
        if not seen[source] then
            if DoesBlipExist(blip) then RemoveBlip(blip) end
            blips[source] = nil
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then ClearDutyBlips() end
end)
