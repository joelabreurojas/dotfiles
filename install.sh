#!/bin/bash
set -euo pipefail

SOURCE="https://github.com/joelabreurojas/dotfiles.git"

if ! command -v mise >/dev/null; then
	echo "⚡ Installing mise..."
	(curl -fsSL https://mise.jdx.dev/install.sh | sh) >/dev/null 2>&1
	export PATH="$HOME/.local/bin:$HOME/.local/share/mise/bin:$PATH"
fi

echo "📦 Setting up chezmoi..."
mise use -g -q chezmoi >/dev/null 2>&1
mise exec chezmoi -- chezmoi init --apply -q "$SOURCE"

echo "✅ Dotfiles applied!"
exec "$SHELL"
