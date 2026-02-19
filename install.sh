#!/bin/bash

{{ template "bash_helpers" . }}

set -euo pipefail

SOURCE="https://github.com/joelabreurojas/dotfiles.git"

if ! command -v mise >/dev/null; then
	log_working "Installing mise..."
	(curl -fsSL https://mise.jdx.dev/install.sh | sh) >/dev/null 2>&1
	export PATH="$HOME/.local/bin:$HOME/.local/share/mise/bin:$PATH"
fi

log_working "Setting up chezmoi..."
mise use -g -q chezmoi >/dev/null 2>&1
mise exec chezmoi -- chezmoi init --apply -q "$SOURCE"

log_success "Dotfiles applied!"
exec "$SHELL"
