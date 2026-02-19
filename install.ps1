$ErrorActionPreference = "Stop"
$ProgressPreference = 'SilentlyContinue'

$SOURCE = "https://github.com/joelabreurojas/dotfiles.git"

if (-not (Get-Command mise -ErrorAction SilentlyContinue)) {
    Write-Host "⚡ Installing mise..." -ForegroundColor Cyan
    irm https://mise.jdx.dev/install.ps1 | iex *> $null
    $env:Path += ";$HOME\AppData\Local\mise\bin"
}

Write-Host "📦 Setting up chezmoi..." -ForegroundColor Cyan
& mise use -g -q chezmoi *> $null
& mise exec chezmoi -- chezmoi init --apply -q $SOURCE *> $null

Write-Host "✅ Dotfiles applied!" -ForegroundColor Green

$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
