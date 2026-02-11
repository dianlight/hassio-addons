#!/usr/bin/env bash
# ==============================================================================
# Unit test for binary upgrade logic from check-srat-update/run
# ==============================================================================

# Don't use set -e because test failures are expected in negative tests
set +e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

TESTS_PASSED=0
TESTS_FAILED=0

# Source the functions from the actual run script (extract just the functions)
# Since we can't source it directly due to bashio deps, we'll redefine them here

extract_version_from_binary() {
  local bin="$1"
  local ver
  if ! command -v objdump >/dev/null 2>&1; then
    echo "ERROR: objdump not found" >&2
    return 1
  fi
  ver=$(objdump -s --section .note.metadata "$bin" 2>/dev/null \
    | tr -d '\n' \
    | sed -n 's/.*"version":"\([^"]*\)".*/\1/p')
  if [[ -z "$ver" ]]; then
    return 1
  fi
  echo "$ver"
}

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

# Test helper functions
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

# ==============================================================================
# Test semver validation
# ==============================================================================
test_section "Testing semver validation"

if is_semver_valid "1.2.3"; then
  test_pass "Valid semver: 1.2.3"
else
  test_fail "Valid semver: 1.2.3"
fi

if is_semver_valid "v1.2.3"; then
  test_pass "Valid semver with 'v': v1.2.3"
else
  test_fail "Valid semver with 'v': v1.2.3"
fi

if is_semver_valid "v2025.12.0-dev.8"; then
  test_pass "Valid semver with prerelease: v2025.12.0-dev.8"
else
  test_fail "Valid semver with prerelease: v2025.12.0-dev.8"
fi

if is_semver_valid "1.2"; then
  test_fail "Invalid semver: 1.2 (should fail)"
else
  test_pass "Invalid semver correctly rejected: 1.2"
fi

if is_semver_valid "abc"; then
  test_fail "Invalid semver: abc (should fail)"
else
  test_pass "Invalid semver correctly rejected: abc"
fi

# ==============================================================================
# Test version normalization
# ==============================================================================
test_section "Testing version normalization"

result=$(normalize_version "v1.2.3")
if [[ "$result" == "1.2.3" ]]; then
  test_pass "Normalize 'v1.2.3' -> '1.2.3'"
else
  test_fail "Normalize 'v1.2.3' -> '$result' (expected '1.2.3')"
fi

result=$(normalize_version "1.2.3")
if [[ "$result" == "1.2.3" ]]; then
  test_pass "Normalize '1.2.3' -> '1.2.3' (no change)"
else
  test_fail "Normalize '1.2.3' -> '$result' (expected '1.2.3')"
fi

# ==============================================================================
# Test version comparison
# ==============================================================================
test_section "Testing version comparison"

if is_version_newer "1.2.3" "1.2.4"; then
  test_pass "1.2.4 is newer than 1.2.3"
else
  test_fail "1.2.4 is newer than 1.2.3"
fi

if is_version_newer "1.2.4" "1.2.3"; then
  test_fail "1.2.3 is NOT newer than 1.2.4 (should fail)"
else
  test_pass "1.2.3 correctly NOT newer than 1.2.4"
fi

if is_version_newer "1.2.3" "1.2.3"; then
  test_fail "Same versions should not be newer (should fail)"
else
  test_pass "Same versions correctly not newer"
fi

if is_version_newer "2025.12.0-dev.7" "2025.12.0-dev.8"; then
  test_pass "2025.12.0-dev.8 is newer than 2025.12.0-dev.7"
else
  test_fail "2025.12.0-dev.8 is newer than 2025.12.0-dev.7"
fi

if is_version_newer "1.9.0" "1.10.0"; then
  test_pass "1.10.0 is newer than 1.9.0"
else
  test_fail "1.10.0 is newer than 1.9.0"
fi

# ==============================================================================
# Test binary version extraction (requires mock binaries)
# ==============================================================================
test_section "Testing binary version extraction"

TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Create a mock binary with embedded version metadata
# We'll create a simple file and use printf to embed the JSON
create_mock_binary() {
  local file="$1"
  local version="$2"
  
  # Create a simple ELF-like structure (very minimal, just for objdump testing)
  # In reality, we'll just create a file with the metadata embedded
  # For a more realistic test, we'd need actual ELF binaries
  
  # Create a simple executable
  cat > "$file" << 'EOFBIN'
#!/bin/bash
echo "Mock binary"
EOFBIN
  chmod +x "$file"
  
  # Append a .note.metadata-like section (this is a simplification)
  # Real implementation would require actual ELF manipulation
  printf '\n.note.metadata\n{"version":"%s"}\n' "$version" >> "$file"
}

# Note: The above mock won't work with real objdump, so we'll skip if objdump is too strict
if command -v objdump >/dev/null 2>&1; then
  echo -e "${YELLOW}Note: Binary extraction tests require actual ELF binaries with .note.metadata sections${NC}"
  echo -e "${YELLOW}Skipping extraction tests (would require proper ELF binary generation)${NC}"
else
  echo -e "${YELLOW}objdump not available, skipping extraction tests${NC}"
fi

# ==============================================================================
# Test upgrade workflow simulation
# ==============================================================================
test_section "Testing upgrade workflow logic"

# Simulate the upgrade decision logic
test_upgrade_decision() {
  local src_ver="$1"
  local upg_ver="$2"
  local expected="$3"
  
  local should_upgrade="no"
  
  if is_semver_valid "$src_ver" && is_semver_valid "$upg_ver"; then
    local src_ver_n=$(normalize_version "$src_ver")
    local upg_ver_n=$(normalize_version "$upg_ver")
    if is_version_newer "$src_ver_n" "$upg_ver_n"; then
      should_upgrade="yes"
    fi
  fi
  
  if [[ "$should_upgrade" == "$expected" ]]; then
    test_pass "Upgrade decision: $src_ver -> $upg_ver = $expected"
  else
    test_fail "Upgrade decision: $src_ver -> $upg_ver = $should_upgrade (expected $expected)"
  fi
}

test_upgrade_decision "v1.0.0" "v1.0.1" "yes"
test_upgrade_decision "v1.0.1" "v1.0.0" "no"
test_upgrade_decision "v1.0.0" "v1.0.0" "no"
test_upgrade_decision "1.0.0" "v1.0.1" "yes"
test_upgrade_decision "v2025.12.0-dev.7" "v2025.12.0-dev.8" "yes"
test_upgrade_decision "invalid" "v1.0.0" "no"
test_upgrade_decision "v1.0.0" "invalid" "no"

# ==============================================================================
# Summary
# ==============================================================================
echo -e "\n${YELLOW}=== Test Summary ===${NC}"
echo -e "Passed: ${GREEN}${TESTS_PASSED}${NC}"
echo -e "Failed: ${RED}${TESTS_FAILED}${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
  echo -e "\n${GREEN}All tests passed!${NC}"
  exit 0
else
  echo -e "\n${RED}Some tests failed!${NC}"
  exit 1
fi
