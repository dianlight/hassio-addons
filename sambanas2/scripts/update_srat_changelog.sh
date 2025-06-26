#!/bin/bash
#
# This script updates the CHANGELOG.md file by fetching the latest
# changelog for the SRAT component from its own repository.
# It finds the SRAT version from build.yaml, fetches the corresponding
# changelog, and then adds or replaces the SRAT section in the main
# CHANGELOG.md.
#
# Usage: Run this script from the addon's root directory (e.g., ./scripts/update_srat_changelog.sh)

set -e
set -o pipefail

# --- Configuration ---
# Assumes the script is run from the addon root directory (e.g., 'sambanas2/').
CHANGELOG_FILE="$(dirname "$0")/../CHANGELOG.md"
BUILD_FILE="$(dirname "$0")/../build.yaml"
SRAT_REPO_URL="https://github.com/dianlight/srat"

# The header for the section we are managing in CHANGELOG.md
# The regex will match the static part of the header, allowing the script
# to find and replace the section on subsequent runs.
SECTION_HEADER_REGEX="^### 🐭 Features from SRAT"

# --- Pre-flight checks ---
for cmd in yq curl awk sed grep; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "Error: Required command '$cmd' is not installed." >&2
        exit 1
    fi
done

if [ ! -f "$BUILD_FILE" ]; then
    echo "Error: Build file '$BUILD_FILE' not found. Are you in the addon root directory?" >&2
    exit 1
fi

if [ ! -f "$CHANGELOG_FILE" ]; then
    echo "Error: Changelog file '$CHANGELOG_FILE' not found. Are you in the addon root directory?" >&2
    exit 1
fi

echo "Starting SRAT changelog update process..."

# 1. Get SRAT_VERSION from build.yaml
echo "Reading SRAT version from '$BUILD_FILE'..."
srat_version=$(yq e '.args.SRAT_VERSION' "$BUILD_FILE")

if [ -z "$srat_version" ] || [ "$srat_version" = "null" ]; then
    echo "Error: Could not read '.args.SRAT_VERSION' from '$BUILD_FILE'." >&2
    exit 1
fi
echo "Found SRAT version: $srat_version"

# Define the dynamic section header now that we have the version and repo URL
SECTION_HEADER="### 🐭 Features from SRAT [v${srat_version}](https://github.com/dianlight/srat)"

# 2. Fetch SRAT CHANGELOG.md for that version tag with retries
srat_changelog_url="https://raw.githubusercontent.com/dianlight/srat/$srat_version/CHANGELOG.md"
echo "Fetching changelog from: $srat_changelog_url"

max_retries=3
retry_delay=5
srat_changelog_content=""
fetch_success=false

for ((i = 1; i <= max_retries; i++)); do
    # Attempt to fetch the content. The 'if' statement checks curl's exit code.
    if srat_changelog_content=$(curl --silent --fail --location "$srat_changelog_url"); then
        echo "Successfully fetched changelog on attempt $i."
        fetch_success=true
        break # Exit loop on success
    fi

    if [ "$i" -lt "$max_retries" ]; then
        echo "Warning: Failed to fetch changelog (attempt $i/$max_retries). Retrying in $retry_delay seconds..." >&2
        sleep "$retry_delay"
    fi
done

if [ "$fetch_success" = false ]; then
    echo "Error: Failed to fetch changelog from '$srat_changelog_url' after $max_retries attempts." >&2
    echo "Please ensure the tag '$srat_version' exists, has a CHANGELOG.md file, and that your network connection is stable." >&2
    exit 1
fi

# 3. Extract the content for the specific version, or fallback to the latest
echo "Extracting changelog section for version '$srat_version'..."
# Attempt to extract content between `## <version>` and the next `## `
changelog_section=$(echo "$srat_changelog_content" | awk -v ver="$srat_version" '
    BEGIN { found = 0 }
    /^## / {
        if (found) { exit } # Exit if we are already past our section
        if ($0 ~ ver) {
            found = 1
            next # Skip the header line itself, start printing content
        }
    }
    found { print }
')

if [ -z "$changelog_section" ]; then
    echo "Warning: No specific changelog content found for version '$srat_version'." >&2
    echo "Attempting to extract the latest (first) section from the fetched changelog as a fallback."
    # Fallback: Extract the content of the first '##' section
    changelog_section=$(echo "$srat_changelog_content" | awk '
        BEGIN { found_first_header = 0 }
        /^\#\# / {
            if (!found_first_header) { found_first_header = 1; next } # Skip the first header itself
            else { exit } # Stop if we encounter a second header
        }
        found_first_header { print }
    ')
    if [ -z "$changelog_section" ]; then
        echo "Warning: No content found in the first section of the fetched changelog either. The SRAT section will be empty." >&2
    else
        echo "Successfully extracted content from the latest available section."
    fi
else
    echo "Successfully extracted changelog section for version '$srat_version'."
fi

# 4. Process the extracted content: add one level to all markdown headers
echo "Processing extracted content..."
processed_content=$(echo "$changelog_section" | sed 's/^#/##/')

# 5. Add or Replace the section in the main CHANGELOG.md
TMP_CHANGELOG=$(mktemp)
trap 'rm -f "$TMP_CHANGELOG"' EXIT

echo "Updating '$CHANGELOG_FILE'..."
if grep -q "$SECTION_HEADER_REGEX" "$CHANGELOG_FILE"; then
    echo "SRAT section found, replacing content..."
    # Use awk to find the section, replace it, and delete the old content.
    awk -v header="$SECTION_HEADER" -v content="$processed_content" '
        BEGIN { in_section = 0; replaced = 0 }
        # Match the start of the section
        /'"$SECTION_HEADER_REGEX"'/ {
            if (!replaced) { print header; if (content) print content; replaced = 1 }
            in_section = 1
            next
        }
        # Match the end of the section (another H2 or H3)
        /^(##|###) / { in_section = 0 }
        in_section { next } # Skip lines that are part of the old section
        { print } # Print all other lines
    ' "$CHANGELOG_FILE" >"$TMP_CHANGELOG"
else
    echo "SRAT section not found, adding new section..."
    # Use awk to add the new section after the first H2 header.
    awk -v header="$SECTION_HEADER" -v content="$processed_content" '
        { print }
        # After printing the first H2 line, insert our block.
        /^## / && !inserted {
            print ""; print header; if (content) print content; inserted = 1
        }
    ' "$CHANGELOG_FILE" >"$TMP_CHANGELOG"
fi

# Overwrite the original file
mv "$TMP_CHANGELOG" "$CHANGELOG_FILE"

echo "Successfully updated '$CHANGELOG_FILE'."
echo "Script finished."
