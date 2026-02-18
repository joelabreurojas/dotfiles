#!/bin/bash
set -euo pipefail

SOURCE="https://github.com/joelabreurojas/dotfiles.git"

if ! command -v mise >/dev/null; then
	curl -fsSL https://mise.jdx.dev/install.sh | sh
	export PATH="$HOME/.local/share/mise/bin:$PATH"
fi

mise use -q -g chezmoi && mise exec chezmoi -- chezmoi init --apply "$SOURCE"

exec "$SHELL"
