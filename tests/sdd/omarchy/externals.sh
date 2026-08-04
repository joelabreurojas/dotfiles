#!/usr/bin/env bash
# T_RED3: Externals cache & run_onchange gating tests
# RED phase: these tests should FAIL before T4/T10 are implemented.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
PASS=0
FAIL=0

ok() { PASS=$((PASS + 1)); echo "  ✓ $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  ✗ $1"; }

echo "=== Externals Cache Tests ==="

# --- refreshPeriod: every external must have it to avoid re-download ---
echo ""
echo "refreshPeriod (no re-download on repeat apply):"
for f in "$REPO_ROOT"/home/.chezmoiexternals/*.toml.tmpl; do
  [ -f "$f" ] || { fail "No externals found in home/.chezmoiexternals/"; break; }
  name="$(basename "$f")"
  if grep -q 'refreshPeriod' "$f"; then
    ok "$name has refreshPeriod"
  else
    fail "$name missing refreshPeriod (will re-download every apply)"
  fi
done

# --- run_onchange scripts must have a hash comment for gating ---
echo ""
echo "run_onchange scripts (hash comment for gating):"
find "$REPO_ROOT"/home/.chezmoiscripts -name '*run_onchange*' -type f 2>/dev/null | while read -r script; do
  name="$(basename "$script")"
  if head -20 "$script" | grep -qiE 'hash|sha256|md5|#.*run_onchange'; then
    ok "$name has hash comment"
  else
    fail "$name missing hash comment (run_onchange will re-run on every apply)"
  fi
done

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
