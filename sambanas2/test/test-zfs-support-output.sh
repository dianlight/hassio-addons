#!/usr/bin/env bash
# ==============================================================================
# Unit test for ZFS support output logic from modprobe/run
# ==============================================================================

set +e

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

# Mirrors the runtime output logic in modprobe/run for deterministic tests.
render_zfs_output() {
  local fs_content="$1"
  local zpool_version="$2"

  if grep -qw zfs <<<"${fs_content}"; then
    if [ -n "${zpool_version}" ]; then
      echo "ZFS support: available (${zpool_version})"
    else
      echo "ZFS support: available (kernel module detected)"
    fi
  else
    echo "ZFS support: not available"
  fi
}

test_section "Testing ZFS output"

result=$(render_zfs_output $'nodev\tsysfs\nzfs' "zfs-2.2.6-1")
if [[ "${result}" == "ZFS support: available (zfs-2.2.6-1)" ]]; then
  test_pass "Reports ZFS as available with zpool version"
else
  test_fail "Unexpected output: ${result}"
fi

result=$(render_zfs_output $'nodev\tsysfs\nzfs' "")
if [[ "${result}" == "ZFS support: available (kernel module detected)" ]]; then
  test_pass "Reports kernel-level ZFS support when zpool version is unavailable"
else
  test_fail "Unexpected output: ${result}"
fi

result=$(render_zfs_output $'nodev\tsysfs\next4' "zfs-2.2.6-1")
if [[ "${result}" == "ZFS support: not available" ]]; then
  test_pass "Reports ZFS as unavailable when filesystem entry is missing"
else
  test_fail "Unexpected output: ${result}"
fi

echo -e "\n${YELLOW}=== Test Summary ===${NC}"
echo -e "Passed: ${GREEN}${TESTS_PASSED}${NC}"
echo -e "Failed: ${RED}${TESTS_FAILED}${NC}"

if [ ${TESTS_FAILED} -eq 0 ]; then
  echo -e "\n${GREEN}All tests passed!${NC}"
  exit 0
else
  echo -e "\n${RED}Some tests failed!${NC}"
  exit 1
fi
