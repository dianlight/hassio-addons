#!/usr/bin/env bash
# ==============================================================================
# Regression check for stale bashio API caches in the sambanas2 image
# ==============================================================================
# Verifies that no bashio cache can be baked into the image and that every s6
# service which reads ingress/options from Supervisor flushes stale caches
# before doing so. See dianlight/hassio-addons#818.

set -uo pipefail

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

ADDON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

test_section "Dockerfile removes baked-in bashio caches"

if grep -qE '^RUN rm -rf /tmp/\.bashio$' "${ADDON_DIR}/Dockerfile"; then
  test_pass "Dockerfile removes /tmp/.bashio at build time"
else
  test_fail "Dockerfile must remove /tmp/.bashio at build time"
fi

test_section "s6 services flush stale bashio caches at startup"

SCRIPTS=(
  "srat/run"
  "socat/run"
  "modprobe/run"
  "check-srat-update/run"
)

for script in "${SCRIPTS[@]}"; do
  path="${ADDON_DIR}/rootfs/etc/s6-overlay/s6-rc.d/${script}"
  if [[ ! -f "$path" ]]; then
    test_fail "Missing service script: ${script}"
    continue
  fi
  if grep -q 'bashio::cache.flush_all' "$path" && grep -q 'rm -f /tmp/.bashio/\*.cache' "$path"; then
    test_pass "${script} flushes stale bashio caches"
  else
    test_fail "${script} must flush stale bashio caches"
  fi
done

echo -e "\n${YELLOW}=== Test Summary ===${NC}"
echo "Passed: ${TESTS_PASSED}"
echo "Failed: ${TESTS_FAILED}"

if (( TESTS_FAILED > 0 )); then
  exit 1
fi

echo -e "${GREEN}All bashio cache regression checks passed!${NC}"
