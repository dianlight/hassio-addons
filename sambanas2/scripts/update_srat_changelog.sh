#!/bin/bash
#
# This script updates the CHANGELOG.md file by fetching the latest
# changelog for the SRAT component from its own repository.
# It finds the SRAT version from the Dockerfile ARG default, fetches the corresponding
# changelog, and then adds or replaces the SRAT section in the main
# CHANGELOG.md.
#
# Usage: Run this script from the addon's root directory (e.g., ./scripts/update_srat_changelog.sh)

set -e
set -o pipefail

# --- Configuration ---
# Assumes the script is run from the addon root directory (e.g., 'sambanas2/').
CHANGELOG_FILE="$(dirname "$0")/../CHANGELOG.md"
DOCKERFILE="$(dirname "$0")/../Dockerfile"
SRAT_REPO_URL="https://github.com/dianlight/srat"

# The header for the section we are managing in CHANGELOG.md
# The regex will match the static part of the header, allowing the script
# to find and replace the section on subsequent runs.
SECTION_HEADER_REGEX="^### 🐭 Features from SRAT"

# --- Pre-flight checks ---
for cmd in curl awk sed grep; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "Error: Required command '$cmd' is not installed." >&2
        exit 1
    fi
done

if [ ! -f "$DOCKERFILE" ]; then
    echo "Error: Dockerfile '$DOCKERFILE' not found. Are you in the addon root directory?" >&2
    exit 1
fi

if [ ! -f "$CHANGELOG_FILE" ]; then
    echo "Error: Changelog file '$CHANGELOG_FILE' not found. Are you in the addon root directory?" >&2
    exit 1
fi

echo "Starting SRAT changelog update process..."

# 1. Get SRAT_VERSION from Dockerfile ARG default
echo "Reading SRAT version from '$DOCKERFILE'..."
srat_version=$(grep -m1 'ARG SRAT_VERSION=' "$DOCKERFILE" | cut -d= -f2 | tr -d '"')

if [ -z "$srat_version" ] || [ "$srat_version" = "null" ]; then
    echo "Error: Could not read 'ARG SRAT_VERSION=' from '$DOCKERFILE'." >&2
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
# 4.1 add new at the end of change log section
processed_content="${processed_content}\n\n"
# 4.2 Remove 🙏 Thanks and 📅 Roadmap sections
processed_content=$(echo "$processed_content" | awk '
    BEGIN { in_thanks = 0; in_roadmap = 0 }
    /^#### 🙏 Thanks/ { in_thanks = 1; next }
    /^#### 📅 Roadmap/ { in_roadmap = 1; next }
    /^#### / {
        in_thanks = 0
        in_roadmap = 0
    }
    !in_thanks && !in_roadmap { print }
')

# 5. Check if SRAT version already exists in older "### 🐭 Features from SRAT" sections
echo "Checking if SRAT version '$srat_version' already exists in older releases..."
version_exists_in_older_releases=false

# Extract all "### 🐭 Features from SRAT" sections from older releases (everything after the first H2)
if grep -q "^## " "$CHANGELOG_FILE"; then
    srat_sections_in_older_releases=$(awk '
        BEGIN { first_h2_seen = 0; in_srat_section = 0 }
        /^## / {
            if (!first_h2_seen) {
                first_h2_seen = 1
                next
            }
            # We are now in older releases
            in_srat_section = 0
        }
        first_h2_seen {
            if (/^### 🐭 Features from SRAT/) {
                in_srat_section = 1
                print
            } else if (/^### / && !/^### 🐭 Features from SRAT/) {
                in_srat_section = 0
            } else if (in_srat_section) {
                print
            }
        }
    ' "$CHANGELOG_FILE")
    
    if echo "$srat_sections_in_older_releases" | grep -q "$srat_version"; then
        echo "Found SRAT version '$srat_version' in older 🐭 Features from SRAT sections. Skipping insertion/replacement."
        version_exists_in_older_releases=true
    fi
fi

# 6. Add or Replace the section only in the latest release (if version doesn't exist in older releases)
TMP_CHANGELOG=$(mktemp)
trap 'rm -f "$TMP_CHANGELOG"' EXIT

echo "Updating '$CHANGELOG_FILE'..."

if [ "$version_exists_in_older_releases" = true ]; then
    echo "SRAT version already exists in older releases. Not modifying latest release."
    # If version exists in older releases, remove any empty SRAT section from latest release
    awk '
        BEGIN { release_count = 0; in_srat_section = 0; srat_section_empty = 1 }
        /^## / {
            release_count++
            in_srat_section = 0
            srat_section_empty = 1
        }
        /^### 🐭 Features from SRAT/ && release_count == 1 {
            in_srat_section = 1
            next  # Skip the header line
        }
        /^### / && release_count == 1 && in_srat_section {
            in_srat_section = 0
            srat_section_empty = 1
        }
        !in_srat_section { print }
    ' "$CHANGELOG_FILE" >"$TMP_CHANGELOG"
else
    # Version does not exist in older releases, so add/replace it
    # Check only within the latest release (content before the second H2 header)
    latest_release_content=$(awk '/^## /{ if (++h2 == 2) exit } h2 == 1 { print }' "$CHANGELOG_FILE")
    if echo "$latest_release_content" | grep -q "$SECTION_HEADER_REGEX"; then
        echo "SRAT section found in latest release, replacing content..."
        # Use awk to find and replace only in the first release section (before the second H2)
        awk -v header="$SECTION_HEADER" -v content="$processed_content" '
            BEGIN { in_section = 0; replaced = 0; release_count = 0 }
            # Count H2 headers to identify the first release
            /^## / {
                release_count++
                if (release_count > 1) { in_section = 0 } # Exit section modification after first H2
            }
            # Match the start of the section (only in the first release)
            /'"$SECTION_HEADER_REGEX"'/ && release_count == 1 {
                if (!replaced) { print header; if (content) print content; replaced = 1 }
                in_section = 1
                next
            }
            # Match the end of the section (another H3 or we hit the second H2)
            /^(###|##) / && release_count == 1 { in_section = 0 }
            in_section { next } # Skip lines that are part of the old section
            { print } # Print all other lines
        ' "$CHANGELOG_FILE" >"$TMP_CHANGELOG"
    else
        echo "SRAT section not found, adding new section to latest release..."
        # Use awk to add the new section at the end of the latest release (just before the second H2 header).
        awk -v header="$SECTION_HEADER" -v content="$processed_content" '
            BEGIN { h2_count = 0; inserted = 0 }
            /^## / {
                h2_count++
                if (h2_count == 2 && !inserted) {
                    print ""; print header; if (content) print content; inserted = 1
                }
            }
            { print }
        ' "$CHANGELOG_FILE" >"$TMP_CHANGELOG"
    fi
fi

# Overwrite the original file
mv "$TMP_CHANGELOG" "$CHANGELOG_FILE"

echo "Successfully updated '$CHANGELOG_FILE'."
echo "Script finished."
