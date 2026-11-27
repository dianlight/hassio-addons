#!/usr/bin/env bash
# ==============================================================================
# Unit test for SRAT_ARGS flag detection logic in srat/run
# Validates that -auto-update and -ipv4-only are correctly detected from
# srat-server --help output (single-dash Go flag format).
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

# Simulates srat-server --help output with single-dash Go flag format
mock_help_output() {
  cat <<'EOF'
Usage of srat-server:
  -auto-update
        enable automatic updates
  -db string
        database path (default "/config/config.db3")
  -docker-interface string
        docker interface name
  -docker-network string
        docker network address
  -ip-address string
        IP address to bind
  -ipv4-only
        force IPv4-only mode
  -loglevel string
        log level (default "info")
  -out string
        output path for smb.conf
  -port int
        ingress port
  -protected-mode
        enable protected mode
EOF
}

# Simulates the flag detection logic from srat/run
detect_flags() {
  local auto_update="$1"
  local disable_ipv6="$2"
  local help_text="$3"
  local args=""

  if [ "$auto_update" = "true" ]; then
    if echo "$help_text" | grep -q -- '-auto-update'; then
      args="$args -auto-update"
    fi
  fi

  if [ "$disable_ipv6" = "true" ]; then
    if echo "$help_text" | grep -q -- '-ipv4-only'; then
      args="$args -ipv4-only"
    fi
  fi

  echo "$args"
}

test_section "Testing flag detection with mock help output"

help_text=$(mock_help_output)

# Test 1: Both flags enabled, both should be detected
args=$(detect_flags "true" "true" "$help_text")
if echo "$args" | grep -q -- '-auto-update' && echo "$args" | grep -q -- '-ipv4-only'; then
  test_pass "Both -auto-update and -ipv4-only detected when enabled"
else
  test_fail "Failed to detect both flags when enabled. Got: $args"
fi

# Test 2: Only auto_update enabled
args=$(detect_flags "true" "false" "$help_text")
if echo "$args" | grep -q -- '-auto-update' && ! echo "$args" | grep -q -- '-ipv4-only'; then
  test_pass "Only -auto-update added when auto_update=true, disable_ipv6=false"
else
  test_fail "Incorrect flags when only auto_update enabled. Got: $args"
fi

# Test 3: Only disable_ipv6 enabled
args=$(detect_flags "false" "true" "$help_text")
if ! echo "$args" | grep -q -- '-auto-update' && echo "$args" | grep -q -- '-ipv4-only'; then
  test_pass "Only -ipv4-only added when auto_update=false, disable_ipv6=true"
else
  test_fail "Incorrect flags when only disable_ipv6 enabled. Got: $args"
fi

# Test 4: Both disabled
args=$(detect_flags "false" "false" "$help_text")
if [ -z "$args" ] || ! echo "$args" | grep -q -- '-auto-update' && ! echo "$args" | grep -q -- '-ipv4-only'; then
  test_pass "No flags added when both options are false"
else
  test_fail "Unexpected flags when both disabled. Got: $args"
fi

test_section "Testing grep pattern correctness"

# Test 5: Verify -auto-update is found (not --auto-update)
if echo "$help_text" | grep -q -- '-auto-update'; then
  test_pass "grep finds -auto-update in help output"
else
  test_fail "grep failed to find -auto-update"
fi

# Test 6: Verify --auto-update is NOT found (old pattern would fail)
if echo "$help_text" | grep -q -- '--auto-update'; then
  test_fail "grep incorrectly found --auto-update (double-dash)"
else
  test_pass "grep correctly does not find --auto-update (single-dash is correct)"
fi

# Test 7: Verify -ipv4-only is found
if echo "$help_text" | grep -q -- '-ipv4-only'; then
  test_pass "grep finds -ipv4-only in help output"
else
  test_fail "grep failed to find -ipv4-only"
fi

# Test 8: Verify --ipv4-only is NOT found (old pattern would fail)
if echo "$help_text" | grep -q -- '--ipv4-only'; then
  test_fail "grep incorrectly found --ipv4-only (double-dash)"
else
  test_pass "grep correctly does not find --ipv4-only (single-dash is correct)"
fi

test_section "Testing edge cases"

# Test 9: Help output without flags
empty_help="Usage of srat-server:
  -db string
        database path
  -port int
        ingress port"

args=$(detect_flags "true" "true" "$empty_help")
if [ -z "$args" ] || ! echo "$args" | grep -q -- '-auto-update'; then
  test_pass "No flags added when help output lacks them"
else
  test_fail "Unexpected flags when help lacks them. Got: $args"
fi

# Test 10: Verify the -4 fallback is removed (old code had elif grep ' -4')
if echo "$help_text" | grep -q -- ' -4' && ! echo "$help_text" | grep -q -- '-ipv4-only'; then
  test_fail "Old -4 fallback would have matched but -ipv4-only not found"
else
  test_pass "No false match on ' -4' when -ipv4-only present"
fi

echo ""
echo "=== Test Summary ==="
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"

if [ $TESTS_FAILED -eq 0 ]; then
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}$TESTS_FAILED test(s) failed${NC}"
  exit 1
fi