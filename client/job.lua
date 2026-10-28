local PlayerJob = {}
local onDuty = false
local currentHospital

local function CanUseStash(index)
    local allowed = Config.StashJobs[index]
    return allowed and PlayerJob and PlayerJob.onduty and allowed[PlayerJob.name] == true
end

-- Functions

local function GetClosestPlayer()
    local closestPlayers = QBCore.Functions.GetPlayersFromCoords()
    local closestDistance = -1
    local closestPlayer = -1
    local coords = GetEntityCoords(PlayerPedId())

    for i = 1, #closestPlayers, 1 do
        if closestPlayers[i] ~= PlayerId() then
            local pos = GetEntityCoords(GetPlayerPed(closestPlayers[i]))
            local distance = #(pos - coords)

            if closestDistance == -1 or closestDistance > distance then
                closestPlayer = closestPlayers[i]
                closestDistance = distance
            end
        end
    end
    return closestPlayer, closestDistance
end

RegisterNetEvent('QBCore:Client:OnPlayerUpdated', function(key, val)
    if key == 'job' then
        PlayerJob = val
        onDuty = val.onduty
        RefreshHospitalStaff()
    elseif key == 'all' and val.job then
        PlayerJob = val.job
        onDuty = val.job.onduty
        RefreshHospitalStaff()
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    exports.spawnmanager:setAutoSpawn(false)
    local ped = PlayerPedId()
    local player = PlayerId()
    CreateThread(function()
        Wait(5000)
        SetEntityMaxHealth(ped, 200)
        SetEntityHealth(ped, 200)
        SetPlayerHealthRechargeMultiplier(player, 0.0)
        SetPlayerHealthRechargeLimit(player, 0.0)
    end)
    CreateThread(function()
        Wait(1000)
        QBCore.Functions.GetPlayerData(function(PlayerData)
            PlayerJob = PlayerData.job
            onDuty = PlayerData.job.onduty
            SetPedArmour(PlayerPedId(), PlayerData.metadata['armor'])
            if (not PlayerData.metadata['inlaststand'] and PlayerData.metadata['isdead']) then
                deathTime = Config.ReviveInterval
                OnDeath()
                DeathTimer()
            elseif (PlayerData.metadata['inlaststand'] and not PlayerData.metadata['isdead']) then
                SetLaststand(true)
            else
                TriggerServerEvent('hospital:server:SetDeathStatus', false)
                TriggerServerEvent('hospital:server:SetLaststandStatus', false)
            end
            RefreshHospitalStaff()
        end)
    end)
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerJob = {}
    onDuty = false
    TriggerServerEvent('hospital:server:RemoveDoctor')
end)

RegisterNetEvent('QBCore:Client:SetDuty', function(duty)
    onDuty = duty
    -- QBCore may update the authoritative job just after this event.
    SetTimeout(250, RefreshHospitalStaff)
end)

function Status()
    if isStatusChecking then
        local statusMenu = {
            {
                header = Lang:t('menu.status'),
                isMenuHeader = true
            }
        }
        for _, v in pairs(statusChecks) do
            statusMenu[#statusMenu + 1] = {
                header = v.label,
                txt = '',
                params = {
                    event = 'hospital:client:TreatWounds',
                }
            }
        end
        statusMenu[#statusMenu + 1] = {
            header = Lang:t('menu.close'),
            txt = '',
            params = {
                event = 'qb-menu:client:closeMenu'
            }
        }
        exports['qb-menu']:openMenu(statusMenu)
    end
end

RegisterNetEvent('hospital:client:CheckStatus', function()
    local player, distance = GetClosestPlayer()
    if player ~= -1 and distance < 5.0 then
        local playerId = GetPlayerServerId(player)
        QBCore.Functions.TriggerCallback('hospital:GetPlayerStatus', function(result)
            if result then
                for k, v in pairs(result) do
                    if k ~= 'BLEED' and k ~= 'WEAPONWOUNDS' then
                        statusChecks[#statusChecks + 1] = {
                            bone = Config.BoneIndexes[k],
                            label = v.label .. ' (' .. Config.WoundStates[v.severity] .. ')'
                        }
                    elseif result['WEAPONWOUNDS'] then
                        for _, v2 in pairs(result['WEAPONWOUNDS']) do
                            TriggerEvent('chat:addMessage', {
                                color = { 255, 0, 0 },
                                multiline = false,
                                args = { Lang:t('info.status'), QBCore.Shared.Weapons[v2].damagereason }
                            })
                        end
                    elseif result['BLEED'] > 0 then
                        TriggerEvent('chat:addMessage', {
                            color = { 255, 0, 0 },
                            multiline = false,
                            args = { Lang:t('info.status'),
                                Lang:t('info.is_status', { status = Config.BleedingStates[v].label }) }
                        })
                    else
                        QBCore.Functions.Notify(Lang:t('success.healthy_player'), 'success')
                    end
                end
                isStatusChecking = true
                Status()
            end
        end, playerId)
    else
        QBCore.Functions.Notify(Lang:t('error.no_player'), 'error')
    end
end)

RegisterNetEvent('hospital:client:RevivePlayer', function()
    local hasItem = QBCore.Functions.HasItem('firstaid')
    if hasItem then
        local player, distance = GetClosestPlayer()
        if player ~= -1 and distance < 5.0 then
            local playerId = GetPlayerServerId(player)
            QBCore.Functions.Progressbar('hospital_revive', Lang:t('progress.revive'), 5000, false, true, {
                disableMovement = false,
                disableCarMovement = false,
                disableMouse = false,
                disableCombat = true,
            }, {
                animDict = healAnimDict,
                anim = healAnim,
                flags = 33,
            }, {}, {}, function() -- Done
                StopAnimTask(PlayerPedId(), healAnimDict, 'exit', 1.0)
                QBCore.Functions.Notify(Lang:t('success.revived'), 'success')
                TriggerServerEvent('hospital:server:RevivePlayer', playerId)
            end, function() -- Cancel
                StopAnimTask(PlayerPedId(), healAnimDict, 'exit', 1.0)
                QBCore.Functions.Notify(Lang:t('error.canceled'), 'error')
            end)
        else
            QBCore.Functions.Notify(Lang:t('error.no_player'), 'error')
        end
    else
        QBCore.Functions.Notify(Lang:t('error.no_firstaid'), 'error')
    end
end)

RegisterNetEvent('hospital:client:TreatWounds', function()
    local hasItem = QBCore.Functions.HasItem('bandage')
    if hasItem then
        local player, distance = GetClosestPlayer()
        if player ~= -1 and distance < 5.0 then
            local playerId = GetPlayerServerId(player)
            QBCore.Functions.Progressbar('hospital_healwounds', Lang:t('progress.healing'), 5000, false, true, {
                disableMovement = false,
                disableCarMovement = false,
                disableMouse = false,
                disableCombat = true,
            }, {
                animDict = healAnimDict,
                anim = healAnim,
                flags = 33,
            }, {}, {}, function() -- Done
                StopAnimTask(PlayerPedId(), healAnimDict, 'exit', 1.0)
                QBCore.Functions.Notify(Lang:t('success.helped_player'), 'success')
                TriggerServerEvent('hospital:server:TreatWounds', playerId)
            end, function() -- Cancel
                StopAnimTask(PlayerPedId(), healAnimDict, 'exit', 1.0)
                QBCore.Functions.Notify(Lang:t('error.canceled'), 'error')
            end)
        else
            QBCore.Functions.Notify(Lang:t('error.no_player'), 'error')
        end
    else
        QBCore.Functions.Notify(Lang:t('error.no_bandage'), 'error')
    end
end)

local check = false
local function EMSControls(variable)
    CreateThread(function()
        check = true
        while check do
            if IsControlJustPressed(0, 38) then
                exports['qb-core']:KeyPressed(38)
                if variable == 'sign' then
                    TriggerEvent('EMSToggle:Duty')
                elseif variable == 'stash' then
                    TriggerServerEvent('qb-ambulancejob:server:stash')
                elseif variable == 'storeheli' then
                    TriggerEvent('qb-ambulancejob:storeheli')
                elseif variable == 'takeheli' then
                    TriggerEvent('qb-ambulancejob:pullheli')
                elseif variable == 'roof' then
                    TriggerEvent('qb-ambulancejob:elevator_main')
                elseif variable == 'main' then
                    TriggerEvent('qb-ambulancejob:elevator_roof')
                end
            end
            Wait(1)
        end
    end)
end

RegisterNetEvent('qb-ambulancejob:elevator_roof', function()
    local ped = PlayerPedId()
    for i = 1, #Config.Locations['roof'] do
        DoScreenFadeOut(500)
        while not IsScreenFadedOut() do Wait(10) end
        currentHospital = i
        local coords = Config.Locations['main'][currentHospital]
        SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
        SetEntityHeading(ped, coords.w)
        Wait(100)
        DoScreenFadeIn(1000)
    end
end)

RegisterNetEvent('qb-ambulancejob:elevator_main', function()
    local ped = PlayerPedId()
    for i = 1, #Config.Locations['main'] do
        DoScreenFadeOut(500)
        while not IsScreenFadedOut() do Wait(10) end
        currentHospital = i
        local coords = Config.Locations['roof'][currentHospital]
        SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
        SetEntityHeading(ped, coords.w)
        Wait(100)
        DoScreenFadeIn(1000)
    end
end)

RegisterNetEvent('EMSToggle:Duty', function()
    onDuty = not onDuty
    TriggerServerEvent('QBCore:ToggleDuty')
    TriggerServerEvent('police:server:UpdateBlips')
end)

-- Convar turns into a boolean
if Config.UseTarget then
    CreateThread(function()
        for i = 1, #Config.Locations['duty'] do
            local v = Config.Locations['duty'][i]
            exports['qb-target']:AddBoxZone('duty' .. i, vector3(v.x, v.y, v.z), 1.5, 1, {
                name = 'duty' .. i,
                debugPoly = false,
                heading = -20,
                minZ = v.z - 2,
                maxZ = v.z + 2,
            }, {
                options = {
                    {
                        type = 'client',
                        event = 'EMSToggle:Duty',
                        icon = 'fa fa-clipboard',
                        label = 'Sign In/Off duty',
                        job = 'ambulance'
                    }
                },
                distance = 1.5
            })
        end
        for i = 1, #Config.Locations['stash'] do
            local v = Config.Locations['stash'][i]
            exports['qb-target']:AddBoxZone('stash' .. i, vector3(v.x, v.y, v.z), 1, 1, {
                name = 'stash' .. i,
                debugPoly = false,
                heading = -20,
                minZ = v.z - 2,
                maxZ = v.z + 2,
            }, {
                options = {
                    {
                        type = 'server',
                        event = 'qb-ambulancejob:server:stash',
                        icon = 'fa fa-hand',
                        label = 'Open Stash',
                        job = 'pillboxmed'
                    }
                },
                distance = 1.5
            })
        end
        for i = 1, #Config.Locations['roof'] do
            local v = Config.Locations['roof'][i]
            exports['qb-target']:AddBoxZone('roof' .. i, vector3(v.x, v.y, v.z), 2, 2, {
                name = 'roof' .. i,
                debugPoly = false,
                heading = -20,
                minZ = v.z - 2,
                maxZ = v.z + 2,
            }, {
                options = {
                    {
                        type = 'client',
                        event = 'qb-ambulancejob:elevator_roof',
                        icon = 'fas fa-hand-point-up',
                        label = 'Take Elevator',
                        job = 'ambulance'
                    },
                },
                distance = 8
            })
        end
        for i = 1, #Config.Locations['main'] do
            local v = Config.Locations['main'][i]
            exports['qb-target']:AddBoxZone('main' .. i, vector3(v.x, v.y, v.z), 1.5, 1.5, {
                name = 'main' .. i,
                debugPoly = false,
                heading = -20,
                minZ = v.z - 2,
                maxZ = v.z + 2,
            }, {
                options = {
                    {
                        type = 'client',
                        event = 'qb-ambulancejob:elevator_main',
                        icon = 'fas fa-hand-point-up',
                        label = 'Take Elevator',
                        job = 'ambulance'
                    },
                },
                distance = 8
            })
        end
    end)
else
    CreateThread(function()
        local signPoly = {}
        for i = 1, #Config.Locations['duty'] do
            local v = Config.Locations['duty'][i]
            signPoly[#signPoly + 1] = BoxZone:Create(vector3(v.x, v.y, v.z), 1.5, 1, {
                name = 'sign' .. i,
                debugPoly = false,
                heading = -20,
                minZ = v.z - 2,
                maxZ = v.z + 2,
            })
        end

        local signCombo = ComboZone:Create(signPoly, { name = 'signcombo', debugPoly = false })
        signCombo:onPlayerInOut(function(isPointInside)
            if isPointInside and PlayerJob.name == 'ambulance' then
                if not onDuty then
                    exports['qb-core']:DrawText(Lang:t('text.onduty_button'), 'left')
                    EMSControls('sign')
                else
                    exports['qb-core']:DrawText(Lang:t('text.offduty_button'), 'left')
                    EMSControls('sign')
                end
            else
                check = false
                exports['qb-core']:HideText()
            end
        end)

        local stashPoly = {}
        for i = 1, #Config.Locations['stash'] do
            local v = Config.Locations['stash'][i]
            stashPoly[#stashPoly + 1] = BoxZone:Create(vector3(v.x, v.y, v.z), 1, 1, {
                name = 'stash' .. i,
                debugPoly = false,
                heading = -20,
                minZ = v.z - 2,
                maxZ = v.z + 2,
            })
        end

        local stashCombo = ComboZone:Create(stashPoly, { name = 'stashCombo', debugPoly = false })
        stashCombo:onPlayerInOut(function(isPointInside)
            if isPointInside and CanUseStash(i) then
                if onDuty then
                    exports['qb-core']:DrawText(Lang:t('text.pstash_button'), 'left')
                    EMSControls('stash')
                end
            else
                check = false
                exports['qb-core']:HideText()
            end
        end)

        local roofPoly = {}
        for i = 1, #Config.Locations['roof'] do
            local v = Config.Locations['roof'][i]
            roofPoly[#roofPoly + 1] = BoxZone:Create(vector3(v.x, v.y, v.z), 2, 2, {
                name = 'roof' .. i,
                debugPoly = false,
                heading = 70,
                minZ = v.z - 2,
                maxZ = v.z + 2,
            })
        end

        local roofCombo = ComboZone:Create(roofPoly, { name = 'roofCombo', debugPoly = false })
        roofCombo:onPlayerInOut(function(isPointInside)
            if isPointInside and PlayerJob.name == 'ambulance' then
                if onDuty then
                    exports['qb-core']:DrawText(Lang:t('text.elevator_main'), 'left')
                    EMSControls('main')
                else
                    exports['qb-core']:DrawText(Lang:t('error.not_ems'), 'left')
                end
            else
                check = false
                exports['qb-core']:HideText()
            end
        end)

        local mainPoly = {}
        for i = 1, #Config.Locations['main'] do
            local v = Config.Locations['main'][i]
            mainPoly[#mainPoly + 1] = BoxZone:Create(vector3(v.x, v.y, v.z), 1.5, 1.5, {
                name = 'main' .. i,
                debugPoly = false,
                heading = 70,
                minZ = v.z - 2,
                maxZ = v.z + 2,
            })
        end

        local mainCombo = ComboZone:Create(mainPoly, { name = 'mainPoly', debugPoly = false })
        mainCombo:onPlayerInOut(function(isPointInside)
            if isPointInside and PlayerJob.name == 'ambulance' then
                if onDuty then
                    exports['qb-core']:DrawText(Lang:t('text.elevator_roof'), 'left')
                    EMSControls('roof')
                else
                    exports['qb-core']:DrawText(Lang:t('error.not_ems'), 'left')
                end
            else
                check = false
                exports['qb-core']:HideText()
            end
        end)
    end)
end
