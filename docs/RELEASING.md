# Food Guardian release process

## Versioning

- Beta sequence: `1.0b1`, `1.0b2`, etc.
- Git tags: `forever-1.0b1`, `forever-1.0b2`, etc.
- Downloadable ZIP: `FoodGuardian-Forever-1.0b1.zip`.
- ZIP root: `FoodGuardian/` containing `FoodGuardian.toc` and referenced Lua/XML files.

## Normal development

1. Create a feature branch and pull request into `main`.
2. Validation checks bootstrap tooling and, once present, Lua 5.1 syntax and the installable ZIP.
3. Squash-merge approved changes into `main`.
4. Gameplay releases are **not possible** until `addon/FoodGuardian.toc` and actual addon files exist; the release workflow intentionally fails closed when missing.

## Release options

- **Manual:** Actions → **Release Food Guardian Forever** → Run workflow. Supply formatted release notes and explicitly choose whether to submit to CurseForge.
- **Release PR merge:** Merge a PR with a title starting `Release beta:`. The PR body becomes its release notes. It will publish to GitHub; CurseForge is opt-in using `CURSEFORGE_AUTO_PUBLISH=true`.
- **Tag:** Push a valid `forever-…bN` tag. Tags publish a GitHub prerelease; CurseForge publishing needs `CURSEFORGE_PUBLISH_TAGS=true`.

The release job selects/stamps a beta version in the CI checkout, reruns validation, creates a GitHub prerelease with the tested ZIP and optionally submits that same ZIP to CurseForge. GitHub tags/releases do not change the checked-in TOC version. The upload script explicitly verifies the TOC game interface and obtains CurseForge's version ID at publish time.

## Before submitting to CurseForge

Confirm the addon works in-game in WoW Forever, ZIP installs in the correct addon folder, available game version matches the client, release notes are player-facing Markdown, and the project ID/token are set in this repository.
