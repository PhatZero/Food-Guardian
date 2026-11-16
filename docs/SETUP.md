# Food Guardian repository setup

This repository was bootstrapped before any addon gameplay code was committed. Follow the WayForth release pattern without copying its credentials or CurseForge project ID.

## GitHub settings to review

1. Under **Settings → General → Pull Requests**, enable **Allow squash merging** and **Automatically delete head branches**. Consider disabling merge commits/rebase merges if a squash-only history is preferred.
2. Under **Settings → Rules → Rulesets**, protect `main`: require pull requests, require the **Validate & Package Food Guardian** check when it becomes available, and block force pushes and branch deletion. Ruleset enforcement availability depends on GitHub plan/repository visibility.
3. Under **Settings → Actions → General**, permit the trusted GitHub Actions used by the workflows. Ensure the workflow's `contents: write` GitHub token permission can publish GitHub releases.
4. Review repository description and topics in **Settings → General**.

The GitHub connector used to bootstrap this repository does **not** expose write access to Actions secrets, repository variables, or rulesets. Those settings must be configured directly in GitHub.

## CurseForge settings to configure later

When a separate Food Guardian CurseForge project exists, open **Settings → Secrets and variables → Actions** in *this repository* and configure:

- **Repository secret** `CURSEFORGE_TOKEN`: the API token that may upload files to the Food Guardian project. Never commit or paste this token into an issue.
- **Repository variable** `CURSEFORGE_PROJECT_ID`: Food Guardian's own numeric CurseForge project ID, **not** WayForth's.
- **Optional repository variable** `CURSEFORGE_AUTO_PUBLISH`: set to `true` only when release PR merges should also upload to CurseForge.
- **Optional repository variable** `CURSEFORGE_PUBLISH_TAGS`: set to `true` only when manually pushed beta tags should also upload to CurseForge.

Before enabling uploads, confirm that CurseForge lists WoW Forever game version `1.60.1`, the same target that the currently deployed WayForth pipeline uses. Update the interface/version mapping if Forever changes.

## Addon source convention (future)

The game install directory will be `Interface/AddOns/FoodGuardian/`. Future sources belong under `addon/`, with a manifest at `addon/FoodGuardian.toc`. The ZIP builder preserves their relative paths under `FoodGuardian/` and validates the manifest. The bootstrap intentionally includes no `addon/` files.

GitHub's built-in `GITHUB_TOKEN` handles GitHub releases. It is not the CurseForge token.
