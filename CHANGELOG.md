# Food Guardian 1.0.0 — First Public Release

**World of Warcraft: Forever (1.60.1)**

## Features
- **Full Window** with detailed countdowns, buff statuses, progress bars, and sleeping bag stack information.
- **Compact Bar** for a streamlined row of three icons and buff timers.
- **Icon Mode** with minimalist status outlines and hover details.
- Tracks **Well Fed**, **Cozy Sleeping Bag / Well-Rested**, and **Camp Benefits**.
- Shows **Camp Tent / Boosted Rest** status in the full tracker.
- **Customizable low-duration warnings** with pulsing indicators and optional sounds.
- Move, scale, or lock the tracker and access it from the minimap shield icon.
- Built-in settings and **healthy/warning demo previews**.

## Commands
- `/fg` — Show or hide the tracker
- `/fg settings` — Open settings
- `/fg mode full` — Detailed view
- `/fg mode compact` — Horizontal timer bar
- `/fg mode icons` — Three-icon view
- `/fg demo healthy` or `/fg demo warning` — Preview visual states
- `/fg demo off` — Return to live tracking
- `/fg debug` — Show diagnostic information

## Installation
Unzip so that `Interface/AddOns/FoodGuardian/FoodGuardian.toc` exists, then restart the game.

## Notes
- The first release targets WoW Forever 1.60.1 only.
- Some aura APIs may report unavailable data while restricted; the addon shows `UNKNOWN` rather than assuming the buff is missing.
- Food Guardian does not automatically use consumables or place camp objects.
