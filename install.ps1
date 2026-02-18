$ErrorActionPreference = "Stop"
$SOURCE = "https://github.com/joelabreurojas/dotfiles.git"

if (-not (Get-Command mise -ErrorAction SilentlyContinue)) {
    irm https://mise.jdx.dev/install.ps1 | iex
    $env:Path += ";$HOME\AppData\Local\mise\bin"
}

& mise use -q -g chezmoi ; & mise exec chezmoi -- chezmoi init --apply $SOURCE

$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
