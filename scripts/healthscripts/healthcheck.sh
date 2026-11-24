#!/usr/bin/env bash
# Health check for the Campus Events app.
# Exit 0: every check passed. Exit 1: at least one check failed.

set -u

BASE_URL="${BASE_URL:-http://127.0.0.1:8093}"
failures=0

pass() { printf 'PASS  %s\n' "$1"; }
fail() {
  printf 'FAIL  %s\n' "$1" >&2
  failures=$((failures + 1))
}

# Check 1: the app's own tests
if docker compose exec -T app npm test --silent > /dev/null 2>&1; then
  pass "app tests"
else
  fail "app tests failed (run: docker compose exec app npm test)"
fi

# Checks 2 and 3: HTTP endpoints
check_endpoint() {
  local path="$1"
  local url="${BASE_URL}${path}"
  local status
  local curl_exit

  status=$(curl --silent --output /dev/null --write-out '%{http_code}' \
    --connect-timeout 2 --max-time 5 "$url")
  curl_exit=$?

  if [ "$curl_exit" -ne 0 ]; then
    fail "${path}: no response (curl exit ${curl_exit})"
  elif [ "$status" != "200" ]; then
    fail "${path}: returned ${status}, expected 200"
  else
    pass "${path}: returned 200"
  fi
}

check_endpoint /health
check_endpoint /api/events

if [ "$failures" -gt 0 ]; then
  printf '%s check(s) failed\n' "$failures" >&2
  exit 1
fi
printf 'All checks passed\n'
exit 0
