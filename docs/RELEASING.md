# Food Guardian Releases

- Stable version: `1.0.0` (tag `forever-1.0.0`).
- Beta pattern: `1.0b1` (tag `forever-1.0b1`).
- Installable archive: `FoodGuardian-Forever-<version>.zip`, root folder `FoodGuardian/`.

## Publishing to CurseForge (preferred)

**"Publish to CurseForge" means run GitHub Actions, not manually upload a local ZIP.**

Use the dedicated **Publish Food Guardian to CurseForge** workflow at:
https://github.com/PhatZero/Food-Guardian/actions/workflows/publish-curseforge.yml

1. Confirm the stable or beta version already exists as a **GitHub release** with a validated ZIP attached.
2. Go to **Actions → Publish Food Guardian to CurseForge → Run workflow**, selecting `main`.
3. Leave **Existing release tag** empty to publish the **latest stable GitHub release**, or specify an exact tag such as `forever-1.0.0` or `forever-1.0b1`.
4. The job downloads **that exact existing tested ZIP**, rechecks its archive integrity, uses the GitHub release notes as CurseForge Markdown, and calls `scripts/upload-forever.sh`.
5. The upload script selects CurseForge **Release** for stable semver or **Beta** for beta versions, targets WoW Forever **1.60.1** (interface **16001**), and reports CurseForge's returned file ID.

**Required GitHub Actions configuration:** secret `CURSEFORGE_TOKEN` and variable `CURSEFORGE_PROJECT_ID=1810129` in **Settings → Secrets and variables → Actions**. These are **repository-specific**; do not copy WayForth's project ID. The workflow fails before upload if either is missing or the project ID is not Food Guardian's.

The workflow deliberately performs **no source modifications**, **no build**, and **no GitHub release creation**. It may be run for an existing release after that release has been approved. CurseForge may reject duplicate submissions of the same artifact; do not run the same tag twice unnecessarily.

## Creating a new GitHub release

1. Develop and QA code in a branch, run CI, and open a release PR into `main`.
2. Title stable release PRs `Release: Food Guardian 1.0.0` and place Markdown player-facing release notes in the PR body.
3. Merge the release PR. The existing `release-on-merge.yml` and `release.yml` publish a tested ZIP to a GitHub release.
4. After the GitHub release exists, use the **Publish Food Guardian to CurseForge** workflow above.
5. **Optional:** If `CURSEFORGE_AUTO_PUBLISH=true` is configured, a release PR merge may upload to CurseForge within the release workflow too. Prefer one publishing mechanism per version to avoid duplicates.

Do not publish unless the same source has passed Lua 5.1 parsing, mocked runtime tests, package integrity checks, and in-game acceptance testing.

## Permissions and limitations

The connected GitHub integration can manage repository source files but does not currently expose **workflow-dispatch** or **Actions secret / variable write** operations. If these actions are unavailable, the workflow must be triggered from GitHub's Actions UI; do not claim the upload occurred until the run reports success and CurseForge returns a file ID.
