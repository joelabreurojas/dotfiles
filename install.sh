#!/bin/bash
set -euo pipefail

SOURCE="https://github.com/joelabreurojas/dotfiles.git"
BRANCH="omarchy"

if command -v chezmoi >/dev/null; then
	chezmoi init --apply --branch="$BRANCH" $SOURCE
	exit 0
fi

if command -v mise >/dev/null; then
	mise use -g -q && chezmoi init --apply --branch="$BRANCH" $SOURCE
	exit 0
fi

sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply --branch="$BRANCH" $SOURCE
exit 0
