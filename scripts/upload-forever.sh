#!/usr/bin/env bash
set -euo pipefail

: "${CURSEFORGE_TOKEN:?Configure the CURSEFORGE_TOKEN Actions secret}"
: "${CURSEFORGE_PROJECT_ID:?Configure the CURSEFORGE_PROJECT_ID Actions variable}"
: "${CHANGELOG:?Enter Markdown release notes for CurseForge}"

[[ "$CURSEFORGE_PROJECT_ID" =~ ^[1-9][0-9]*$ ]] || { echo "CurseForge project ID must be numeric" >&2; exit 1; }
[[ $# == 1 && -f "$1" ]] || { echo "Expected exactly one tested Food Guardian ZIP" >&2; exit 1; }

archive=$1
toc=$(unzip -p "$archive" "FoodGuardian/FoodGuardian.toc" | tr -d '\r')
interface=$(sed -n 's/^## Interface: //p' <<< "$toc")
version=$(sed -n 's/^## Version: //p' <<< "$toc")
[[ "$interface" == "16001" && "$version" =~ ^[0-9]+\.[0-9]+b[1-9][0-9]*$ ]] || {
  echo "Expected a valid Forever 1.60.1 beta TOC" >&2; exit 1;
}

api=https://wow.curseforge.com/api
header="X-Api-Token: $CURSEFORGE_TOKEN"
versions=$(curl --fail-with-body --silent --show-error --header "$header" "$api/game/versions")
version_id=$(jq -er '[.[] | select(.name == "1.60.1")] |
  if length == 1 and (.[0].id | type) == "number" then .[0].id
  else error("Expected exactly one CurseForge Forever 1.60.1 game version") end' <<< "$versions")

metadata=$(jq -n --arg notes "$CHANGELOG" --arg version "$version" --argjson id "$version_id" \
  '{changelog: $notes, changelogType: "markdown", releaseType: "beta",
    displayName: ("Food Guardian " + $version + " (Forever)"), gameVersions: [$id]}')

response=$(curl --fail-with-body --silent --show-error \
  --header "$header" \
  --form-string "metadata=$metadata" \
  --form "file=@$archive;type=application/zip" \
  "$api/projects/$CURSEFORGE_PROJECT_ID/upload-file")
file_id=$(jq -er '.id | numbers | select(. > 0)' <<< "$response")
echo "Submitted Food Guardian $version to CurseForge (file ID $file_id)."
