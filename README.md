# Food Guardian

A standalone World of Warcraft: Forever 1.60.1 addon for food, sleeping-bag and campfire buff tracking.

**Version 1.0.1** · [Release notes](CHANGELOG.md)

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

## Installation
Extract the official ZIP under WoW Forever's `Interface/AddOns/` directory so that `FoodGuardian/FoodGuardian.toc` exists, then restart.

## Release pipeline
Source is stored in `addon/` and GitHub Actions packages the same installable `FoodGuardian/` structure. CI runs Lua 5.1 syntax and mocked runtime tests. GitHub releases can optionally upload to CurseForge when Actions credentials are configured. See [publishing instructions](docs/RELEASING.md).
