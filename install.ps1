$ErrorActionPreference = "Stop"
$SOURCE = "https://github.com/joelabreurojas/dotfiles.git"

if (Get-Command chezmoi -ErrorAction SilentlyContinue) {
    chezmoi init --apply $SOURCE
    exit
}

if (Get-Command mise -ErrorAction SilentlyContinue) {
    mise use -g -q chezmoi && chezmoi init --apply $SOURCE
    exit
}

irm https://get.chezmoi.io/ps1 | iex && chezmoi init --apply $SOURCE

