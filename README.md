# dps-shellbrowser

A staff tool for housing shells. Look at every qs-housing shell one by one, turn a door in the
world into a way into a shell, and furnish that room.

## Status

Not running on DelPerroSands. Replaced by
[dps-studio](https://github.com/DaemonAlex/dps-studio), which does the same jobs from one panel
and can bring in the portals made here. The code is complete (version 1.2.0).

## What it is for

A server collects hundreds of housing shells and nobody remembers what each one looks like. This
script shows them. It also lets staff use a shell as a room behind any door in the city, without
making it a house.

## What it does

- **`/shells [number or name]`.** Shows each shell in the qs-housing list high above the sea, one
  at a time. The camera circles it. Press Enter to walk inside. Press C to copy its name. Other
  players do not see the shell.
- **`/portal name [label]`.** Stand at a door and run the command. Pick a shell, walk in, and
  press G where the way out should be. From then on every player can press E at the door to go
  in and E inside to come out. `/portal list` and `/portal delete name` manage them.
- **`/decorate`.** Inside a portal room, add furniture from the qs-housing catalogue, with
  pictures. Move, turn, edit or remove pieces. Tab switches to fine steps of 1 cm and 1 degree.
  A room holds up to 400 pieces.

Each shell sits 60 m under its door. It is only spawned while a player is within 250 m.

## On its own, and with other scripts

**On its own.** It does not work without qs-housing. It reads the shell list and the furniture
catalogue straight from that script's config files.

**With paid housing (qs-housing).** Staff get the three commands above. Players get doors that
lead into furnished rooms. Shells stay in step with qs-housing because there is no second list
to keep up to date.

**With [dps-studio](https://github.com/DaemonAlex/dps-studio).** dps-studio reads this script's
`portals.json` and turns each portal into a studio room, furniture included. Do that once, then
stop this script.

## Requirements

- `ox_lib`
- `qs-housing` (its `config/main.lua` and `config/furniture.lua`)
- The shell models themselves, streamed by your shell packs

## Install

1. Put the folder in your resources and add `ensure dps-shellbrowser` after `ox_lib` and
   `qs-housing`.
2. Give staff the ace: `add_ace group.admin dps.entityselector allow`.

Portals are saved in `portals.json` inside the resource folder. Back that file up.

## Tests

```sh
lua5.4 tests/run.lua
```

Run it from the resource folder. It checks the code that reads the qs-housing config.

## Recent changes

- **12 November 2026.** README: status, what it is for, how it works alone and with paid scripts, other DPS scripts.
- **30 September 2026.** `/shells` browser, `/portal` doors into shells, `/decorate` furniture in
  portal rooms, and fine tune mode.

## Author

Made by [DaemonAlex](https://github.com/DaemonAlex) for DelPerroSands.

## Other DPS scripts

All of these are made for DelPerroSands and run together on one Qbox server. Each one works on
its own. The ones marked "pairs with" do more when both are running.

| Script | What it does |
|---|---|
| [dps-inventory](https://github.com/DaemonAlex/dps-inventory) | The inventory: ox_inventory with equipment slots, backpacks, armour plates and a self status panel, in the DelPerroSands colours. |
| [dps-medical](https://github.com/DaemonAlex/dps-medical) | Patient records, illness and diagnostic tests. A companion to wasabi_ambulance. Pairs with dps-inventory: symptoms and diagnoses show on the status panel. |
| [dps-insurance](https://github.com/DaemonAlex/dps-insurance) | Ties m-Insurance into the MDT, impound, hospital and medical chart. Pairs with dps-medical. |
| [dps-studio](https://github.com/DaemonAlex/dps-studio) | Build rooms, doors and portals in game from one panel (`/studio`), with owners and managers so staff do not have to support them. |
| [dps-shops](https://github.com/DaemonAlex/dps-shops) | Shop clerks who greet and react to a robbery, then player-owned shops. |
| [dps-fleet](https://github.com/DaemonAlex/dps-fleet) | Vehicle browser and workshop on one panel: extras, liveries and mods for emergency vehicles. |
| [dps-parking](https://github.com/DaemonAlex/dps-parking) | Parking with valet, impound, violations and reserved spots. |
| [dps-vehiclepersistence](https://github.com/DaemonAlex/dps-vehiclepersistence) | Vehicles stay where they were parked. Pairs with dps-parking. |
| [dps-towjob](https://github.com/DaemonAlex/dps-towjob) | Queue-based tow job with jg-mechanic integration. |
| [dps-services](https://github.com/DaemonAlex/dps-services) | Request a tow and follow it live on the lb-phone and lb-tablet. Pairs with dps-towjob. |
| [dps-autoshops](https://github.com/DaemonAlex/dps-autoshops) | Self-service repair shops when no mechanic is on duty. |
| [dps-cityworker](https://github.com/DaemonAlex/dps-cityworker) | City infrastructure job and career. |
| [dps-ainpcs](https://github.com/DaemonAlex/dps-ainpcs) | NPCs you can talk to, with trust, quests and intel. |
| [dps-badpeds](https://github.com/DaemonAlex/dps-badpeds) | Police interaction with NPCs: stops, arrests, intel and jail records. |
| [dps-gangwars](https://github.com/DaemonAlex/dps-gangwars) | Ambient gang NPCs, territory population and war reinforcements. |
| [dps-rotations](https://github.com/DaemonAlex/dps-rotations) | Moves dealers, harvests and other spots on a fixed schedule. |
| [dps-trains](https://github.com/DaemonAlex/dps-trains) | The train system. Pairs with dps-trains-stock, dps-traintools and dps-transitapp. |
| [dps-transitapp](https://github.com/DaemonAlex/dps-transitapp) | Live train arrival boards on the lb-phone. |
| [dps-faceplant](https://github.com/DaemonAlex/dps-faceplant) | City help, reports and staff tools on the lb-phone and lb-tablet. |
| [dps-chat](https://github.com/DaemonAlex/dps-chat) | A command box for voice-only servers. No chat feed. |
| [dps-filmmode](https://github.com/DaemonAlex/dps-filmmode) | One key hides every HUD layer and gives a smooth free camera for recording. |
