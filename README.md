# Food Guardian

**Food Guardian** is an upcoming standalone World of Warcraft: Forever addon for tracking food buffs, sleeping-bag benefits, and campfire-related effects in a compact movable window with configurable low-duration warnings.

> **Status:** Repository and release automation setup only. Addon gameplay code has **not** been added and no build is ready to publish.

## Development

- `main` is the release source.
- Changes should enter through pull requests with validation checks.
- Installable archives will contain `FoodGuardian/FoodGuardian.toc` and supporting files.
- The initial game target follows WayForth's WoW Forever `1.60.1` client, interface `16001`.
- Beta tags use `forever-1.0b1`, `forever-1.0b2`, etc.

## Release and CurseForge preparation

The GitHub Actions pipeline validates Lua 5.1, packages an addon ZIP, publishes GitHub prereleases, and optionally uploads betas to CurseForge.

**Nothing uploads to CurseForge until the project exists and publishing is enabled.**

See [setup instructions](docs/SETUP.md) and [release procedure](docs/RELEASING.md). The `addon/` folder will be introduced once implementation begins; its absence is intentional.
