# Food Guardian Releases

- Stable version: `1.0.0` (tag `forever-1.0.0`).
- Beta pattern: `1.0b1` (tag `forever-1.0b1`).
- Installable archive: `FoodGuardian-Forever-<version>.zip`, root folder `FoodGuardian/`.

## Standard release path (matches WayForth)

**"Publish to CurseForge" means use the GitHub Actions workflow, never manually upload a local ZIP.**

1. Finish gameplay development and in-game QA on a branch, with passing CI.
2. Open a PR to `main` titled `Release: Food Guardian <version>` for stable releases or `Release beta: Food Guardian <version>` for betas. Put formatted Markdown release notes in the PR body.
3. Squash-merge the approved release PR. `.github/workflows/release-on-merge.yml` calls `release.yml` with `curseforge: true`.
4. GitHub Actions selects/stamps the version, validates all Lua 5.1 files, runs game-runtime mock tests, and packages the installable ZIP.
5. The workflow creates or checks the GitHub release and submits **the same validated ZIP** and Markdown release notes to CurseForge through `scripts/upload-forever.sh`. Stable versions use CurseForge type **release**; beta versions use **beta**.

**Required GitHub Actions configuration:** secret `CURSEFORGE_TOKEN` and variable `CURSEFORGE_PROJECT_ID=1810129` in **Settings → Secrets and variables → Actions**. These settings must be configured in Food Guardian, not inherited from WayForth. If missing, CurseForge submission fails and must be retried after configuring them.

## Publish an existing GitHub release to CurseForge

For existing versions already released on GitHub (such as `forever-1.0.0`), use the dedicated **Publish Food Guardian to CurseForge** workflow:
https://github.com/PhatZero/Food-Guardian/actions/workflows/publish-curseforge.yml

1. Open **Actions → Publish Food Guardian to CurseForge → Run workflow**.
2. Choose `main`. Leave **Existing release tag** empty for the latest stable GitHub release, or enter an exact tag such as `forever-1.0.0` or `forever-1.0b1`.
3. The workflow downloads that **existing tested ZIP** from the GitHub release, checks archive integrity, reads GitHub Markdown release notes, and uploads it to project `1810129` with the correct Forever game version mapping.

This on-demand workflow does not make a new GitHub release, commit addon code, or rebuild the archive. Do not run it for an already uploaded version unless an earlier upload failed; duplicate submissions may be rejected.

## Publishing safeguards

- Target game: WoW Forever **1.60.1**, interface **16001** (verify against the game client before future releases).
- Install directory: `Interface/AddOns/FoodGuardian/`.
- No release should be shipped without source validation, package checks, and in-game testing.
- Do not place CurseForge credentials in repository source, issues, or release notes.

## GitHub connector limitation

The connected GitHub integration can create and merge release PRs, so **new release PR merges** can publish through the Actions workflow. It does not currently expose a way to dispatch a workflow directly or edit Actions secrets/variables. Existing-release re-uploads require starting the dedicated workflow from GitHub's Actions UI. Always confirm the actual workflow result and returned CurseForge file ID; a GitHub release alone does not prove a CurseForge upload.
