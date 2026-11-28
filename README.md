# Food Guardian

A standalone World of Warcraft: Forever 1.60.1 addon for food, sleeping-bag and campfire buff tracking.

**Version 1.0.2** · [Release notes](CHANGELOG.md)

## Features
- Full Window, Compact Bar, and Icon Mode.
- Well Fed, Well-Rested (Cozy Sleeping Bag), Camp Benefits countdowns.
- Sleeping Bag stacks and cooldown, Camp Tent / Boosted Rest lockout.
- Warnings with optional sound, minimap shield, movement/scale/lock controls and settings.

## Commands
- `/fg`: toggle window
- `/fg settings`: options
- `/fg mode full`, `/fg mode compact`, `/fg mode icons`
- `/fg demo healthy`, `/fg demo warning`, `/fg demo off`
- `/fg debug`: diagnostics
- `/fg protected`: last protected-action diagnostic
- `/fg combat on`, `/fg combat off`: automatically hide or show in combat

## EllesmereUI minimap compatibility
When EllesmereUI's minimap module is enabled, EllesmereUI positions Food Guardian's shield launcher in its addon-button row or group. Food Guardian will not move it back onto the minimap rim during timer updates or map resizing. Use **EllesmereUI > Minimap > Ungroup Minimap Buttons** to keep it visible on the row, and EllesmereUI's **Free Move Buttons** option to adjust that row's buttons. In this mode, EllesmereUI owns minimap-button dragging rather than Food Guardian's normal click-and-drag behavior.

Food Guardian's **Show minimap shield launcher** and **Hide in combat** settings continue to control its button. Without EllesmereUI's enabled minimap module, the shield uses its native draggable minimap-rim position. The main tracker remains available with `/fg` if your UI hides addon buttons.

## Installation
Extract the official ZIP under WoW Forever's `Interface/AddOns/` directory so that `FoodGuardian/FoodGuardian.toc` exists, then restart.

## Release pipeline
Source is stored in `addon/` and GitHub Actions packages the same installable `FoodGuardian/` structure. CI runs Lua 5.1 syntax and mocked runtime tests. GitHub releases can optionally upload to CurseForge when Actions credentials are configured. See [publishing instructions](docs/RELEASING.md).

### Combat-safe countdowns (1.0.3)
New installations keep the tracker visible in combat. Existing users can run `/fg combat off` outside combat to enable it, or `/fg combat on` to hide it. Timers use the last readable aura snapshot and resynchronize when combat ends; changes during combat may not appear immediately. Configuration and minimap refreshes pause in combat.
