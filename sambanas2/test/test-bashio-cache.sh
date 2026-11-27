#!/usr/bin/env bash
# ==============================================================================
# Regression check for stale bashio API caches in the sambanas2 image
# ==============================================================================
# Verifies that no bashio cache is baked into the image and that a single
# startup service flushes caches before any service reads Supervisor data.
# See dianlight/hassio-addons#818.

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
S6_DIR="${ADDON_DIR}/rootfs/etc/s6-overlay/s6-rc.d"

test_section "Dockerfile removes baked-in bashio caches"

if grep -qE '^RUN rm -rf /tmp/\.bashio$' "${ADDON_DIR}/Dockerfile"; then
  test_pass "Dockerfile removes /tmp/.bashio at build time"
else
  test_fail "Dockerfile must remove /tmp/.bashio at build time"
fi

test_section "Centralized bashio-cache oneshot"

CACHE_RUN="${S6_DIR}/bashio-cache/run"
if [[ -f "${CACHE_RUN}" ]] &&
   grep -q 'bashio::cache.flush_all' "${CACHE_RUN}" &&
   grep -q 'rm -rf /tmp/.bashio' "${CACHE_RUN}" &&
   [[ -f "${S6_DIR}/bashio-cache/up" ]] &&
   [[ -f "${S6_DIR}/bashio-cache/dependencies.d/base" ]] &&
   [[ "$(tr -d '[:space:]' <"${S6_DIR}/bashio-cache/type")" == "oneshot" ]]; then
  test_pass "bashio-cache flushes caches once as a base oneshot"
else
  test_fail "bashio-cache must be a base oneshot that flushes caches centrally"
fi

test_section "Startup services wait for bashio-cache"

for service in check-protection-mode check-srat-update clean-config factory-reset init-smbd modprobe; do
  if [[ -f "${S6_DIR}/${service}/dependencies.d/bashio-cache" ]]; then
    test_pass "${service} depends on bashio-cache"
  else
    test_fail "${service} must depend on bashio-cache"
  fi
done

test_section "No service flushes caches on its own"

for script in srat/run socat/run modprobe/run check-srat-update/run; do
  if grep -qE 'bashio::cache\.flush_all|rm -f /tmp/\.bashio/\*\.cache' "${S6_DIR}/${script}"; then
    test_fail "${script} still flushes caches locally"
  else
    test_pass "${script} does not flush caches locally"
  fi
done

echo -e "\n${YELLOW}=== Test Summary ===${NC}"
echo "Passed: ${TESTS_PASSED}"
echo "Failed: ${TESTS_FAILED}"

if (( TESTS_FAILED > 0 )); then
  exit 1
fi

echo -e "${GREEN}All bashio cache regression checks passed!${NC}"
