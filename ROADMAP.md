# Roadmap

**Current Logical State**: Proposed

> Living document, reviewed every sprint (or every two weeks). Status flips
> to `Accepted` when the corresponding PR merges. No module enters technical
> design before it reaches 🟢 NOW (JIT gate).

## 🟢 NOW (Active)

| Module | Description | PRD |
|--------|-------------|-----|
| Test suite + CI | Run `ssh_keys_toml.sh` + `externals.sh` in CI (GitHub Actions) and add `shellcheck`; no CI exists today | — |

## 🟡 NEXT (The Queue)

| Module | Description | PRD |
|--------|-------------|-----|
| Expand test coverage | Cover template renders (`dot_ssh/config.tmpl`, `.chezmoi.toml.tmpl`) across minimal/personal/work profiles — the ssh_keys nil-guard CRITICAL came from a gap | — |
| External integrity | Pin + checksum externals only for versioned releases (fonts, mise); keep unversioned third-party URLs unpinned | — |

## 🔴 LATER (The Horizon)

| Module | Description | PRD |
|--------|-------------|-----|
| Windows parity | Align divergent Linux/Windows scripts (e.g. `setup-bitwarden` headless guard vs non-headless) | — |
| Drop `BW_SESSION` persistence | Replace persisted User env var with inline unlock in the consumer (`setup-ssh-keys.ps1` runs in a separate process and depends on it today) | — |