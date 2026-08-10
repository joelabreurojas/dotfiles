#!/usr/bin/env bash
# OMARCHY-SSH-01..04: ssh_keys must render as a valid TOML table, not JSON.
# Static checks run with no tool deps; live render runs if chezmoi or docker is
# present (docker uses the pinned image built from Dockerfile.chezmoi).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
TPL="$REPO_ROOT/home/.chezmoi.toml.tmpl"
IMG="chezmoi-2.72.0:ssh"
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

# Live render via chezmoi (or pinned Docker image).
echo ""
render_toml() {
  local src="$1"
  if command -v chezmoi >/dev/null 2>&1; then
    chezmoi execute-template < "$src"
  elif command -v docker >/dev/null 2>&1; then
    if ! docker image inspect "$IMG" >/dev/null 2>&1; then
      local df_dir
      df_dir="$(cd "$(dirname "$0")" && pwd)"
      docker build -q -t "$IMG" -f "$df_dir/Dockerfile.chezmoi" "$df_dir" >/dev/null 2>&1 || return 2
    fi
    docker run --rm -i "$IMG" execute-template < "$src"
  else
    return 2
  fi
}

# render_check: 0 = render+parse OK (prints output) | 2 = backend unavailable
#              | 1 = render failed | 3 = rendered invalid TOML.
render_check() {
  local src="$1" rc out
  out="$(mktemp)"
  render_toml "$src" > "$out" 2>/dev/null
  rc=$?
  if [ "$rc" -ne 0 ]; then
    rm -f "$out"
    [ "$rc" -eq 2 ] && return 2
    return 1
  fi
  if python3 -c 'import sys,tomllib; tomllib.load(sys.stdin.buffer)' < "$out" 2>/dev/null; then
    cat "$out"
    rm -f "$out"
    return 0
  fi
  rm -f "$out"
  return 3
}

render_out=""
rc=0
if render_out="$(render_check "$TPL")"; then
  ok "rendered output parses as valid TOML (OMARCHY-SSH-01/02/03)"
else
  rc=$?
  case "$rc" in
    1) fail "template render failed (chezmoi/docker error)" ;;
    3) fail "rendered ssh_keys is invalid TOML" ;;
    2)
      echo "  ⚠ no render backend available (chezmoi/docker/docker build); skipping live TOML parse."
      [ "$FAIL" -gt 0 ] && exit 1
      exit 0
      ;;
  esac
fi

# (d) Single-key dict must render as exactly one [data.ssh_keys] pair.
#     Mirrors the committed range block with a 1-entry dict (SSH-01 1-key case).
single_tpl="$(mktemp)"
trap 'rm -f "$single_tpl"' EXIT
cat > "$single_tpl" <<'EOF'
{{- $ssh_keys := dict -}}
{{- $_ := set $ssh_keys "personal" "id_ed25519" -}}
{{- if gt (len $ssh_keys) 0 }}
[data.ssh_keys]
{{- range $k, $v := $ssh_keys }}
    {{ $k }} = {{ $v | quote }}
{{- end }}
{{- end }}
EOF

if render_out="$(render_check "$single_tpl")"; then
  if printf '%s' "$render_out" | python3 -c '
import sys, tomllib
d = tomllib.load(sys.stdin.buffer)
keys = d["data"]["ssh_keys"]
assert keys == {"personal": "id_ed25519"}, keys
' 2>/dev/null; then
    ok "single-key dict renders exactly one pair (OMARCHY-SSH-01 1-key case)"
  else
    fail "single-key dict did not render exactly one pair"
  fi
else
  rc=$?
  case "$rc" in
    1) fail "single-key render failed (chezmoi/docker error)" ;;
    3) fail "single-key dict rendered invalid TOML" ;;
    2) echo "  ⚠ single-key render skipped (no backend available)." ;;
  esac
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
