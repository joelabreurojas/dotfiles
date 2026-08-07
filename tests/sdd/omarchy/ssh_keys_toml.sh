#!/usr/bin/env bash
# OMARCHY-SSH-01..04: ssh_keys must render as a valid TOML table, not JSON.
# Static checks run with no tool deps; live render runs only if chezmoi is present.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
TPL="$REPO_ROOT/home/.chezmoi.toml.tmpl"
PASS=0
FAIL=0

ok() { PASS=$((PASS + 1)); echo "  ✓ $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  ✗ $1"; }

echo "=== ssh_keys TOML rendering tests ==="
echo ""

# (a) Old invalid pattern must be gone.
if grep -qE 'ssh_keys *= *\{\{.*toJson' "$TPL"; then
  fail "still uses toJson on ssh_keys (pre-fix invalid TOML)"
else
  ok "no 'toJson' ssh_keys pattern in template"
fi

# (b) Guard + [data.ssh_keys] table via range must be present.
if grep -qE 'if gt \(len \$ssh_keys\) 0' "$TPL" && grep -q '\[data.ssh_keys\]' "$TPL" && grep -qE 'range \$k, \$v := \$ssh_keys' "$TPL"; then
  ok "empty-guard and [data.ssh_keys] range block present"
else
  fail "missing empty-guard or [data.ssh_keys] table block"
fi

# (c) Live render + parse. Prefer local chezmoi; fall back to a Docker build
#     that pulls the pinned GitHub release tarball (same source get.chezmoi.io).
echo ""
render_toml() {
  if command -v chezmoi >/dev/null 2>&1; then
    chezmoi execute-template < "$TPL"
  elif command -v docker >/dev/null 2>&1; then
    # Fallback: ephemeral container builds the exact release binary.
    docker run --rm -i -v "$REPO_ROOT:/df" -w /df python:3.11-slim bash -c '
      set -euo pipefail
      apt-get update -qq >/dev/null 2>&1 && apt-get install -y -qq curl tar >/dev/null 2>&1
      curl -4 -fsSL -o /tmp/cz.tgz https://github.com/twpayne/chezmoi/releases/latest/download/chezmoi_2.72.0_linux_amd64.tar.gz
      tar -xzf /tmp/cz.tgz -C /usr/local/bin chezmoi
      chezmoi execute-template < /df/home/.chezmoi.toml.tmpl
    ' 2>/dev/null
  else
    return 2
  fi
}

if ! render_toml | python3 -c 'import sys,tomllib; tomllib.load(sys.stdin.buffer)' 2>/dev/null; then
  if command -v chezmoi >/dev/null 2>&1 || command -v docker >/dev/null 2>&1; then
    fail "rendered ssh_keys is invalid TOML"
  else
    echo "  ⚠ neither chezmoi nor docker installed; skipping live TOML parse."
    [ "$FAIL" -gt 0 ] && exit 1
    exit 0
  fi
else
  ok "rendered output parses as valid TOML (OMARCHY-SSH-01/02/03)"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1