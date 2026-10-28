# ⚠️ POWERMOVES RP — CUSTOM DEVELOPMENT BUILD

**IMPORTANT NOTICE: This repository contains a customized development version of QBCore's qb-ambulancejob, being developed specifically for the PowerMoves RP FiveM roleplay server.**

This version is intended to be modified and expanded to support PowerMoves RP's custom emergency medical services, fire rescue departments, hospitals, agency-specific job structures, ranks, medical qualifications, and integration with our customized dispatch and medical records systems.

## ⚠️ NOT A STANDARD QB-AMBULANCEJOB RELEASE

**This repository is not intended to serve as a standard, general-purpose, or plug-and-play release of QBCore's qb-ambulancejob.**

The planned modifications are designed around PowerMoves RP's custom QBCore environment, including support for three distinct job types:

- **`ems`** — General EMS and legacy compatibility.
- **`fire`** — Fire Rescue agencies, including SAFR, LSFD, LSCFD, and BCFD.
- **`medical`** — Hospitals and medical facilities, including Pillbox, Sandy Shores, Paleto Bay, and Parsons.

Development will focus on preserving the original medical and emergency response functionality while expanding compatibility with multiple agencies and their respective personnel, ranks, certifications, and operational responsibilities.

Planned customization includes medical treatment authorization, emergency response capabilities, hospital operations, on-duty personnel management, agency-specific access permissions, and integration with PowerMoves PSDispatch and PSMDT.

Medical permissions may be determined by an employee's position, rank, or appropriate certification rather than job type alone.

**These modifications are planned development objectives and should not be considered implemented or functional until completed and tested.**

This customized version may not function correctly on other FiveM servers without additional configuration or development.

## Original Project Attribution & Acknowledgment

PowerMoves RP proudly acknowledges and credits the original developers and contributors of **QBCore Framework and qb-ambulancejob**.

**Original Project:** QBCore qb-ambulancejob  
**Original Repository:** https://github.com/qbcore-fivem/qb-ambulancejob  
**Original License:** GNU General Public License, Version 3 (GPL-3.0)  
**License Information:** https://www.gnu.org/licenses/gpl-3.0.html

This repository is an independently maintained modification of the original open-source project.

All original developer credits, copyright notices, and applicable licensing terms are retained and respected. Modifications developed for PowerMoves RP remain subject to the applicable original license requirements.

**PowerMoves RP is not affiliated with, sponsored by, endorsed by, or officially associated with QBCore Framework or its original development team.**

We sincerely appreciate the time, effort, and contributions of the QBCore developers and the open-source FiveM development community. Their work provides the foundation upon which this customized implementation is being developed.

---

## Original QBCore Documentation

*The original QBCore qb-ambulancejob documentation is preserved below for reference, attribution, and compatibility information.*


# qb-ambulancejob
EMS Job and Death/Wound Logic for QB-Core Framework :ambulance:

## Dependencies
- [qb-core](https://github.com/qbcore-framework/qb-core) (Required)
- [qb-phone](https://github.com/qbcore-framework/qb-phone) (Required)
- [qb-target](https://github.com/BerkieBb/qb-target) (Optional)
- [PolyZone](https://github.com/mkafrin/PolyZone) (Required)

# Server.cfg Convar Update
- Global DrawTextUi Option
```
setr UseTarget false
``` 

- Global Target Option
```
setr UseTarget true
```


# Medal Clip Capture

Asks [Medal](https://medal.tv) to save a clip when a player goes down, so players can catch their funny
deaths. **This is enabled by default.** There is nothing to configure to use it.

It only does anything for players who already have Medal installed and running. The clip is cut from the
replay buffer Medal is already keeping and saved to that player's own Medal library, tagged `qbcore` so they
can search for it. Neither your server nor QBCore receives the clip, and this resource uploads nothing
itself, but Medal may sync the clip to its own servers depending on the player's Medal account and settings,
the same as any other clip Medal captures.

To turn it off for your server, set this in `config.lua`:

```lua
Config.Medal = { Enabled = false }
```

Medal listens on the player's own machine, so the request is sent from the client through a hidden NUI frame
(`html/medal.js`) rather than from the server. It is fire and forget, nothing is reported back, and players
without Medal running just get a request that goes nowhere. Everything else is hardcoded in
`client/medal.lua`.

# License

    QBCore Framework
    Copyright (C) 2021 Joshua Eger

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>
