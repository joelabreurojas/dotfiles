#!/usr/bin/env bash
# OMARCHY-SSH-05..08: template renders across profiles.
# Covers the gap behind the ssh_keys nil-guard CRITICAL: dot_ssh/config.tmpl
# consuming ssh_keys from data, per profile. Runs via the pinned Docker image.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
TPL_TOML="$REPO_ROOT/home/.chezmoi.toml.tmpl"
TPL_SSH="$REPO_ROOT/home/dot_ssh/config.tmpl"
IMG="chezmoi-2.72.0:ssh"
PASS=0
FAIL=0

ok() { PASS=$((PASS + 1)); echo "  ✓ $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  ✗ $1"; }

if ! docker image inspect "$IMG" >/dev/null 2>&1; then
  echo "  ⚠ missing image $IMG; run: docker build -t $IMG -f $REPO_ROOT/tests/sdd/omarchy/Dockerfile.chezmoi $REPO_ROOT/tests/sdd/omarchy"
  exit 2
fi

echo "=== per-profile template renders ==="
echo ""

# .chezmoi.toml.tmpl: work profile (hostname PC-0024) must carry both keys.
work_out="$(mktemp)"
trap 'rm -rf "$work_out" "$min_out" "$d_personal" "$d_work"' EXIT
docker run --rm --hostname PC-0024 -i "$IMG" execute-template < "$TPL_TOML" > "$work_out" 2>/dev/null || {
  fail "work profile render failed (chezmoi/docker error)"
  echo ""
  echo "Results: $PASS passed, $FAIL failed"
  [ "$FAIL" -eq 0 ] && exit 0 || exit 1
}
if python3 -c 'import sys,tomllib; d=tomllib.load(open(sys.argv[1],"rb")); assert d["data"]["environment"]=="work", d["data"]["environment"]; assert set(d["data"]["ssh_keys"])=={"personal","work"}, d["data"]["ssh_keys"]' "$work_out" 2>/dev/null; then
  ok "work: environment=work, ssh_keys has personal+work (OMARCHY-SSH-05)"
else
  fail "work profile did not render expected ssh_keys"
fi

# .chezmoi.toml.tmpl: minimal profile (docker default, /.dockerenv => headless)
# must have NO ssh_keys (the pre-fix template errored here under missingkey=error).
min_out="$(mktemp)"
docker run --rm -i "$IMG" execute-template < "$TPL_TOML" > "$min_out" 2>/dev/null || {
  fail "minimal profile render failed (chezmoi/docker error)"
  echo ""
  echo "Results: $PASS passed, $FAIL failed"
  [ "$FAIL" -eq 0 ] && exit 0 || exit 1
}
if python3 -c 'import sys,tomllib; d=tomllib.load(open(sys.argv[1],"rb")); assert d["data"]["environment"]=="minimal", d["data"]["environment"]; assert "ssh_keys" not in d["data"], d["data"].get("ssh_keys")' "$min_out" 2>/dev/null; then
  ok "minimal: environment=minimal, no ssh_keys in data (OMARCHY-SSH-06)"
else
  fail "minimal profile unexpectedly rendered ssh_keys"
fi

# dot_ssh/config.tmpl: personal (only personal key) => exactly the github.com block.
d_personal="$(mktemp -d)"
mkdir -p "$d_personal/.chezmoidata"
printf '[ssh_keys]\npersonal = "id_ed25519"\n' > "$d_personal/.chezmoidata/keys.toml"
if docker run --rm -v "$d_personal":/root/.local/share/chezmoi -i "$IMG" execute-template < "$TPL_SSH" 2>/dev/null \
   | grep -qE '^Host github\.com$' \
   && ! docker run --rm -v "$d_personal":/root/.local/share/chezmoi -i "$IMG" execute-template < "$TPL_SSH" 2>/dev/null \
   | grep -qE '^Host github\.com-work$'; then
  ok "personal: only Host github.com block (OMARCHY-SSH-07)"
else
  fail "personal profile rendered wrong ssh config blocks"
fi

# dot_ssh/config.tmpl: work (both keys) => both blocks present.
d_work="$(mktemp -d)"
mkdir -p "$d_work/.chezmoidata"
printf '[ssh_keys]\npersonal = "id_ed25519"\nwork = "id_ed25519_work"\n' > "$d_work/.chezmoidata/keys.toml"
if docker run --rm -v "$d_work":/root/.local/share/chezmoi -i "$IMG" execute-template < "$TPL_SSH" 2>/dev/null \
   | grep -qE '^Host github\.com$' \
   && docker run --rm -v "$d_work":/root/.local/share/chezmoi -i "$IMG" execute-template < "$TPL_SSH" 2>/dev/null \
   | grep -qE '^Host github\.com-work$'; then
  ok "work: both Host github.com and github.com-work blocks (OMARCHY-SSH-08)"
else
  fail "work profile rendered wrong ssh config blocks"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1