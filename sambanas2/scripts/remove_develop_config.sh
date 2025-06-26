#!/bin/bash
# This script processes a config.yaml file to validate its version
# and update srat_update_channel based on the version type.

set -e          # Exit immediately if a command exits with a non-zero status.
set -u          # Treat unset variables as an error and exit.
set -o pipefail # Causes a pipeline to return the exit status of the last command in the pipe that returned a non-zero status.

CONFIG_FILE="${1:-$(dirname "$0")/../config.yaml}"

# Check if yq is installed
if ! command -v yq &>/dev/null; then
    echo "Error: yq is not installed. Please install yq (v4+) to proceed." >&2
    exit 1
fi

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file '$CONFIG_FILE' not found." >&2
    exit 1
fi

echo "Processing configuration file: $CONFIG_FILE"

# 1. Read version from config.yaml
# yq e '.version' outputs the value, or the string 'null' if not found/YAML null.
# IMPORTANT FIX: Pipe to 'tr -d '\n'' to remove potential trailing newlines from yq output.
version_str=$(yq e '.version' "$CONFIG_FILE" | tr -d '\n')

if [ "$version_str" = "null" ]; then
    echo "Error: 'version' key not found or is YAML null in '$CONFIG_FILE'." >&2
    exit 1
fi
if [ -z "$version_str" ]; then # Handles case where version is an empty string ""
    echo "Error: 'version' key is an empty string in '$CONFIG_FILE'." >&2
    exit 1
fi

echo "Found version: '$version_str'"
# Optional: For debugging, you can check the length to see if any hidden characters remain:
# echo "Version string length: ${#version_str}"

# 2. Validate SemVer
# Regex for SemVer: Major.Minor.Patch[-prerelease][+buildmetadata]
# Based on https://semver.org/spec/v2.0.0.html
# Core: (0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)
# Pre-release: -((0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*)
# Build metadata: \+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*)
semver_regex='^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(?:-((?:0|[1-9][0-9]*|[0-9]*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9][0-9]*|[0-9]*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$'

if ! [[ "$version_str" =~ $semver_regex ]]; then # Quote version_str for safety, though [[ does word splitting
    echo "Error: Version '$version_str' in '$CONFIG_FILE' is not a valid semantic version." >&2
    echo "A valid semantic version typically looks like MAJOR.MINOR.PATCH (e.g., 1.2.3), " >&2
    echo "optionally followed by a pre-release identifier (e.g., -alpha.1) " >&2
    echo "and/or build metadata (e.g., +build.456)." >&2
    exit 1
fi

echo "Version '$version_str' is SemVer valid."

# 3. Check if version is a pre-release
# A version is a pre-release if the pre-release segment (captured by BASH_REMATCH[4]) is present.
# The regex match `[[ "$version_str" =~ $semver_regex ]]` populates BASH_REMATCH.
is_prerelease=false
prerelease_segment="${BASH_REMATCH[4]}" # Group 4 from the regex captures the pre-release identifiers (e.g., "alpha.1")

if [ -n "$prerelease_segment" ]; then
    is_prerelease=true
    echo "Version '$version_str' is a pre-release (pre-release part: '$prerelease_segment')."
else
    echo "Version '$version_str' is not a pre-release."
fi

# 4. If version is not a pre-release, remove "develop" from srat_update_channel
if [ "$is_prerelease" = false ]; then
    echo "Version is not a pre-release. Attempting to update 'srat_update_channel'..."

    # Check if srat_update_channel key exists
    srat_channel_exists=$(yq e 'has("srat_update_channel")' "$CONFIG_FILE" | tr -d '\n')

    if [ "$srat_channel_exists" = "true" ]; then
        # Check if srat_update_channel is an array (YAML sequence)
        srat_channel_type=$(yq e '.srat_update_channel | type' "$CONFIG_FILE" | tr -d '\n')

        if [ "$srat_channel_type" = "!!seq" ]; then
            # Check if "develop" is present in the array
            contains_develop=$(yq e '.srat_update_channel | contains(["develop"])' "$CONFIG_FILE" | tr -d '\n')

            if [ "$contains_develop" = "true" ]; then
                echo "Removing 'develop' from 'srat_update_channel' in '$CONFIG_FILE'."
                # yq command to delete the 'develop' string from the array.
                # The -i flag modifies the file in-place.
                yq e 'del(.srat_update_channel[] | select(. == "develop"))' -i "$CONFIG_FILE"
                echo "'develop' removed from 'srat_update_channel'."
            else
                echo "'develop' not found in 'srat_update_channel' array. No changes made."
            fi
        else
            echo "Warning: 'srat_update_channel' in '$CONFIG_FILE' is present but not an array (actual type: $srat_channel_type). Cannot remove 'develop'." >&2
        fi
    else
        echo "Warning: 'srat_update_channel' key not found in '$CONFIG_FILE'. Cannot remove 'develop'." >&2
    fi
else
    echo "Version is a pre-release. 'srat_update_channel' will not be modified."
fi

echo "Script finished successfully."
