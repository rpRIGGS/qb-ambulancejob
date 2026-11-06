# Parsons integration — qb-policejob code reference

**Status:** Development reference only. Verified against public upstream `qbcore-fivem/qb-policejob` on 2026-11-06. PowerMoves' customized policejob may differ. No gameplay changes are implemented by this document.

**Purpose:** Reuse the existing QBCore command, client dialog, server validation and event patterns inside the PowerMoves `qb-ambulancejob` fork for Parsons `/commit` and `/uncommit`. **Do not modify, disable, rename or replace `qb-policejob`'s `/jail`, `/unjail`, criminal records or prison translations.**

## 1. Upstream jail command pattern

Source: [qb-policejob/server/commands.lua#L126-L145](https://github.com/qbcore-fivem/qb-policejob/blob/main/server/commands.lua#L126-L145)

```lua
QBCore.Commands.Add('jail', Lang:t('commands.jail_player'), {}, false, function(source)
    local src = source
    local Player = exports['qb-core']:GetPlayer(src)
    if Player.PlayerData.job.type == 'leo' and Player.PlayerData.job.onduty then
        TriggerClientEvent('police:client:JailPlayer', src)
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.on_duty_police_only'), 'error')
    end
end)
```

The existing `/unjail` command (lines 136–145) accepts a player ID and triggers `prison:client:UnjailPerson`. It uses the same on-duty LEO check.

**Parsons adaptation:** Register new `commit` and `uncommit` commands in the ambulance fork, using on-duty `ems` **or** `leo`, and send to newly namespaced Parsons events. Keep jail and prison events entirely separate.

```lua
-- Illustrative authorization pattern only, not an implemented command.
local job = Player.PlayerData.job
if job.onduty and (job.type == 'ems' or job.type == 'leo') then
    -- Launch qb-parsons commitment request.
end
```

Do not grant all ambulance functions to LEO or all Parsons functions to FIRE. Distinguish command access from the lawful grounds for each admission/discharge; server-side authorization and audit trails remain required.

## 2. Lawyer-payment mixed job-type example

Source: [qb-policejob/server/commands.lua#L331-L348](https://github.com/qbcore-fivem/qb-policejob/blob/main/server/commands.lua#L331-L348)

```lua
if Player.PlayerData.job.type == 'leo' or Player.PlayerData.job.name == 'judge' then
```

This is the **upstream** condition. PowerMoves previously changed the judge-name comparison to a DOJ **job type** check in its own server version; do not assume that change exists upstream. It demonstrates that `or` conditions are already standard in QBCore.

## 3. Jail dialog and client-to-server flow

Source: [qb-policejob/client/interactions.lua#L140-L161](https://github.com/qbcore-fivem/qb-policejob/blob/main/client/interactions.lua#L140-L161)

- `police:client:JailPlayer` identifies the nearby target.
- It opens a `qb-input` dialog for the time value.
- It calls `TriggerServerEvent('police:server:JailPlayer', playerId, tonumber(dialog['jailtime']))`.

**Parsons adaptation:** Separate patient-selection and commitment-request UI. A psychiatric hold uses an appropriate admission type and legal basis; do not copy prison sentence units, UI wording or prison-time decrement logic. Consider a 72-hour hold with a persisted start/end timestamp, subject to authorized extensions/orders.

## 4. Server-side jail enforcement and state changes

Source: [qb-policejob/server/interactions.lua#L128-L152](https://github.com/qbcore-fivem/qb-policejob/blob/main/server/interactions.lua#L128-L152)

```lua
if #(playerCoords - targetCoords) > 2.5 then return DropPlayer(src, 'Attempted exploit abuse') end
local Player = exports['qb-core']:GetPlayer(src)
local OtherPlayer = exports['qb-core']:GetPlayer(playerId)
if not Player or not OtherPlayer or Player.PlayerData.job.type ~= 'leo' then return end
```

The original event then sets `injail` metadata and `criminalrecord` and fires `police:client:SendToJail`. **Do not copy those state changes into Parsons.** The original handler does not itself check `onduty`; ensure the new Parsons server handler validates its intended duty policy and job types even if the command already did.

For Parsons, implement independent server-validated commitment requests, patient/hold records, timestamps, clinical/legal basis, patient handoff and discharge. Do not trust a client-initiated event to authorize a hold by itself. Transport and custody coordination may be handled by LEO or EMS as appropriate, while clinical determinations remain separate.

## 5. Client transition

Source: [qb-policejob/client/main.lua#L211](https://github.com/qbcore-fivem/qb-policejob/blob/main/client/main.lua#L211)

`police:client:SendToJail` invokes `prison:client:Enter`. For Parsons, replace this **only in the new integration** with an explicit `qb-parsons` admission/handoff event. Do not invoke the prison event or alter existing jail behavior.

## 6. English language reference

Source: [qb-policejob/locales/en.lua](https://github.com/qbcore-fivem/qb-policejob/blob/main/locales/en.lua)

Relevant upstream keys:
- `info.jail_time` / `info.jail_time_no` (verify exact section nesting before implementation)
- `info.sent_jail_for`
- `info.jail_time_input`
- `commands.jail_player` / `commands.unjail_player`
- `commands.paylawyer`

Keep **all** existing policejob prison/jail translations. Create **new ambulancejob** English keys for commitment request, release, admission type, hold duration, court order, transport, acceptance and denial messages. Review all supported locales before release.

## 7. Related ambulancejob and Parsons considerations

- The original ambulance resource can resume an existing jail sentence after hospital-bed release by reading `injail`. This is not EMS authority to jail someone; preserve the criminal jail continuity behavior.
- Existing PowerMoves ambulance development already plans medical treatment support for both `ems` and `fire`; do not accidentally remove this.
- Parsons commitment command access is proposed for `ems` or `leo`, **not** blanket `fire` access.
- Do not assume every EMS employee is legally qualified to make a psychiatric commitment. Follow PowerMoves law, roleplay policy and applicable clinical authorizations.
- Medical transport is not always required for courtroom commitments; an authorized officer may coordinate or conduct transport according to the situation.
- Keep the ambulance fork's existing multi-agency EMS/FIRE scope and integrations intact.

## 8. Development checklist

- [ ] Inspect this fork's current `server/commands.lua`, `server/main.lua`, `client/main.lua`, `client/job.lua` (where present), `config.lua`, `fxmanifest.lua`, and `locales/en.lua` before modifying.
- [ ] Compare upstream patterns with the actual PowerMoves policejob customization and confirm desired command UX.
- [ ] Agree on a stable `qb-parsons` event/export contract before implementation.
- [ ] Add separate `/commit` and `/uncommit` command handlers, with on-duty EMS/LEO access.
- [ ] Add distinct patient selection and request/response UI and language keys.
- [ ] Add server-side job/duty validation and audit records; distinguish authorization to use a command from legal justification.
- [ ] Wire to qb-parsons patient records, real-time hold timestamps, transport/handoff and discharge.
- [ ] Preserve policejob jail commands, prison metadata and criminal incarceration.
- [ ] Verify existing EMS/FIRE treatment functions, hospital functions and ambulance transport are unaffected.
- [ ] Test EMS commitment, LEO courtroom commitment, medical and officer transport, uncommit, unauthorized attempts, and server restart/reconnect.

**No production commands or integrations have been implemented yet.**
