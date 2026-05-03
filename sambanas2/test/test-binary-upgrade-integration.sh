#!/usr/bin/env bash
# ==============================================================================
# Integration test for binary upgrade workflow
# Creates actual mock binaries with .note.metadata and tests the full flow
# ==============================================================================

set +e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

TESTS_PASSED=0
TESTS_FAILED=0

test_pass() {
  echo -e "${GREEN}✓${NC} $1"
  ((TESTS_PASSED++))
}

test_fail() {
  echo -e "${RED}✗${NC} $1"
  ((TESTS_FAILED++))
}

test_section() {
  echo -e "\n${YELLOW}=== $1 ===${NC}"
}

# Check if we can create ELF binaries with embedded metadata
if ! command -v gcc >/dev/null 2>&1; then
  echo -e "${YELLOW}gcc not available - skipping integration tests${NC}"
  echo -e "${YELLOW}Install gcc to run full integration tests${NC}"
  exit 0
fi

if ! command -v objdump >/dev/null 2>&1; then
  echo -e "${YELLOW}objdump not available - skipping integration tests${NC}"
  exit 0
fi

test_section "Creating test environment"

TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

BIN_DIR="$TEMP_DIR/bin"
UPGRADE_DIR="$TEMP_DIR/upgrade"
mkdir -p "$BIN_DIR" "$UPGRADE_DIR"

echo "Test directory: $TEMP_DIR"

# Create a simple C program that we'll compile into binaries
cat > "$TEMP_DIR/test.c" << 'EOF'
#include <stdio.h>

// Embed version metadata in a custom section
__attribute__((section(".note.metadata"))) 
const char metadata[] = "{\"version\":\"VERSION_PLACEHOLDER\"}";

int main() {
    printf("Test binary\n");
    return 0;
}
EOF

# Function to create a binary with embedded version
create_binary_with_version() {
  local output="$1"
  local version="$2"
  
  # Replace the placeholder with actual version
  sed "s/VERSION_PLACEHOLDER/$version/g" "$TEMP_DIR/test.c" > "$TEMP_DIR/test_versioned.c"
  
  # Compile
  if gcc -o "$output" "$TEMP_DIR/test_versioned.c" 2>/dev/null; then
    chmod +x "$output"
    return 0
  else
    return 1
  fi
}

test_section "Creating mock binaries with versions"

# Create source binaries
if create_binary_with_version "$BIN_DIR/srat-cli" "v2025.12.0"; then
  test_pass "Created source binary: srat-cli v2025.12.0"
else
  test_fail "Failed to create source binary"
  exit 1
fi

if create_binary_with_version "$BIN_DIR/srat-server" "v1.5.0"; then
  test_pass "Created source binary: srat-server v1.5.0"
else
  test_fail "Failed to create source binary"
  exit 1
fi

# Create upgrade binaries (some newer, some older)
if create_binary_with_version "$UPGRADE_DIR/srat-cli" "v2025.12.1"; then
  test_pass "Created upgrade binary: srat-cli v2025.12.1 (newer)"
else
  test_fail "Failed to create upgrade binary"
  exit 1
fi

if create_binary_with_version "$UPGRADE_DIR/srat-server" "v1.4.0"; then
  test_pass "Created upgrade binary: srat-server v1.4.0 (older - should not upgrade)"
else
  test_fail "Failed to create upgrade binary"
  exit 1
fi

test_section "Verifying version extraction"

# Source the extraction function
extract_version_from_binary() {
  local bin="$1"
  local ver
  ver=$(objdump -s --section .note.metadata "$bin" 2>/dev/null \
    | tr -d '\n' \
    | sed -n 's/.*"version":"\([^"]*\)".*/\1/p')
  if [[ -z "$ver" ]]; then
    return 1
  fi
  echo "$ver"
}

ver=$(extract_version_from_binary "$BIN_DIR/srat-cli")
if [[ "$ver" == "v2025.12.0" ]]; then
  test_pass "Extracted version from srat-cli: $ver"
else
  test_fail "Failed to extract correct version from srat-cli (got: $ver)"
fi

ver=$(extract_version_from_binary "$UPGRADE_DIR/srat-cli")
if [[ "$ver" == "v2025.12.1" ]]; then
  test_pass "Extracted version from upgrade srat-cli: $ver"
else
  test_fail "Failed to extract correct version from upgrade srat-cli (got: $ver)"
fi

test_section "Simulating upgrade workflow"

# Copy the upgrade function logic here
is_semver_valid() {
  local v="$1"
  [[ "$v" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z\.-]+)?$ ]]
}

normalize_version() {
  local v="$1"
  echo "${v#v}"
}

is_version_newer() {
  local v_old="$1"
  local v_new="$2"
  local newest
  newest=$(printf "%s\n%s\n" "$v_old" "$v_new" | sort -V | tail -n1)
  [[ "$newest" == "$v_new" && "$v_new" != "$v_old" ]]
}

# Simplified upgrade logic
perform_test_upgrade() {
  local upgrade_dir="$UPGRADE_DIR"
  local upgraded_count=0
  local skipped_count=0
  
  for src_bin in "$BIN_DIR"/srat-*; do
    [ -e "$src_bin" ] || continue
    local base=$(basename "$src_bin")
    local upg_bin="${upgrade_dir}/${base}"
    
    if [ ! -f "$upg_bin" ]; then
      continue
    fi
    
    local src_ver=$(extract_version_from_binary "$src_bin") || continue
    local upg_ver=$(extract_version_from_binary "$upg_bin") || continue
    
    if ! is_semver_valid "$src_ver" || ! is_semver_valid "$upg_ver"; then
      continue
    fi
    
    local src_ver_n=$(normalize_version "$src_ver")
    local upg_ver_n=$(normalize_version "$upg_ver")
    
    if is_version_newer "$src_ver_n" "$upg_ver_n"; then
      cp -f "$upg_bin" "$src_bin"
      echo "  Upgraded ${base} from ${src_ver_n} to ${upg_ver_n}"
      ((upgraded_count++))
    else
      echo "  Skipped ${base} (${upg_ver_n} not newer than ${src_ver_n})"
      ((skipped_count++))
    fi
  done
  
  echo "$upgraded_count $skipped_count"
}

result=($(perform_test_upgrade))
upgraded=${result[0]}
skipped=${result[1]}

if [[ $upgraded -eq 1 ]]; then
  test_pass "Correctly upgraded 1 binary (srat-cli)"
else
  test_fail "Expected 1 upgrade, got $upgraded"
fi

if [[ $skipped -eq 1 ]]; then
  test_pass "Correctly skipped 1 binary (srat-server - older version)"
else
  test_fail "Expected 1 skip, got $skipped"
fi

test_section "Verifying upgraded binaries"

ver=$(extract_version_from_binary "$BIN_DIR/srat-cli")
if [[ "$ver" == "v2025.12.1" ]]; then
  test_pass "srat-cli now has upgraded version: $ver"
else
  test_fail "srat-cli has wrong version after upgrade: $ver"
fi

ver=$(extract_version_from_binary "$BIN_DIR/srat-server")
if [[ "$ver" == "v1.5.0" ]]; then
  test_pass "srat-server kept original version (not upgraded): $ver"
else
  test_fail "srat-server has wrong version: $ver"
fi

# ==============================================================================
# Summary
# ==============================================================================
echo -e "\n${YELLOW}=== Integration Test Summary ===${NC}"
echo -e "Passed: ${GREEN}${TESTS_PASSED}${NC}"
echo -e "Failed: ${RED}${TESTS_FAILED}${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
  echo -e "\n${GREEN}All integration tests passed!${NC}"
  exit 0
else
  echo -e "\n${RED}Some integration tests failed!${NC}"
  exit 1
fi
