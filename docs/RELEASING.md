# Food Guardian Releases

- Stable version: `1.0.0` (tag `forever-1.0.0`).
- Beta pattern: `1.0b1` (tag `forever-1.0b1`).
- Installable archive: `FoodGuardian-Forever-<version>.zip`, root folder `FoodGuardian/`.

## Publishing
1. Create a release PR to `main` and require passing CI.
2. Title stable release PRs `Release: Food Guardian 1.0.0`. Put Markdown player-facing release notes in the PR body.
3. Squash-merge the PR to trigger GitHub release publishing. Stable releases are not GitHub prereleases.
4. Automatic CurseForge uploads require GitHub Actions secret `CURSEFORGE_TOKEN`, variable `CURSEFORGE_PROJECT_ID`, and opt-in variable `CURSEFORGE_AUTO_PUBLISH=true`.
5. The CurseForge project ID is **1810129** (Food Guardian, not WayForth). Upload as type **release** for stable builds targeting WoW Forever **1.60.1**, with interface **16001**.
6. A manual upload to the CurseForge project using the resulting GitHub release ZIP is also supported.

Do not publish a build unless the same source has passed Lua 5.1 parsing, mocked runtime tests, package integrity checks, and in-game acceptance testing.
