{{ template "pwsh_helpers" . }}
$ErrorActionPreference = "Stop"
$ProgressPreference = 'SilentlyContinue'

$SOURCE = "https://github.com/joelabreurojas/dotfiles.git"

if (-not (Get-Command mise -ErrorAction SilentlyContinue)) {
    Log-Working "Installing mise..."
    irm https://mise.jdx.dev/install.ps1 | iex *> $null
    $env:Path += ";$HOME\AppData\Local\mise\bin"
}

Log-Working "Setting up chezmoi..."
& mise use -g -q chezmoi *> $null
& mise exec chezmoi -- chezmoi init --apply -q $SOURCE *> $null

Log-Success "Dotfiles applied!"

$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
