## 1.1b1 — Class buff QA preview

- Optional per-character class, external and custom helpful aura tracking.
- Group alternative buffs, track temporary weapon enhancements per hand, and configure missing/expiration warnings.
- Extend all three display modes with cached combat timers.
- Add class buff mock coverage; live Forever QA pending.

# Food Guardian 1.0.3: Combat-Safe Countdown (QA)

- Keep the tracker visible during combat using cached buff expiration times.
- Pause aura and inventory scans, minimap refreshes, and configuration changes until combat ends.
- Continue countdowns, progress bars and warnings, then rescan on leaving combat.
- Keep the existing Hide in combat setting; new installations default to visible timers. Existing users can select /fg combat off.
- Cached buffs cannot reflect mid-combat refreshes or removals until resync. No native secret duration object integration is included in this build.

---

# Food Guardian 1.0.2: EllesmereUI Compatibility

**World of Warcraft: Forever (1.60.1)**

## Fixes
- Improved minimap shield compatibility with EllesmereUI's addon-button row and grouped flyout.
- Prevented routine buff refreshes from overriding externally managed button placement or visibility.
- Exposed the shield texture for correct sizing by compatible minimap managers.
- Restored native minimap placement and dragging when EllesmereUI's minimap module is disabled.
- Preserved combat-hide and minimap visibility preferences.

## Testing
- Added automated regression coverage for external minimap ownership, visibility, resizing, combat hiding, and native fallback.
- Lua syntax, runtime mock tests, and package validation passed on the compatibility build.

Existing settings and all three tracker modes are preserved.

---

# Food Guardian 1.0.1 — Stability & Combat Compatibility

**World of Warcraft: Forever (1.60.1)**

## Fixes
- **Combat-safe tracker:** Food Guardian now hides its tracker, settings, and minimap launcher when combat starts and restores the appropriate windows when combat ends.
- **Fewer UI conflicts:** Buff scans and tracker refreshes pause while combat hiding is active; movement and resizing are guarded during combat.
- **Minimap edge alignment:** The shield launcher now follows the minimap's actual size and shape, including resized or square minimaps.
- **Protected-action diagnostics:** Added support for recording Blizzard blocked/forbidden-action events and reporting the protected function with `/fg protected`.
- **Safer slash-command setup:** No longer reassigns Blizzard's global slash-command registry.

## Settings & Commands
- New **Hide Food Guardian during combat** option, enabled by default.
- `/fg combat on` and `/fg combat off` toggle automatic combat hiding.
- `/fg protected` displays the most recently reported protected-action information.
- All three display modes (Full Window, Compact Bar, Icon Mode) remain supported.

## Verification
- Automated Lua 5.1 validation, WoW runtime mock tests, and package checks.
- In-game testing reported no further protected-action errors with the QA build.

**Existing settings are preserved.** Food Guardian only monitors buffs and reminders; it does not automatically use items or cast spells.

---

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
