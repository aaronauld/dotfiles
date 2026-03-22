# ──────────────────────────────────────────────
# aaronauld/dotfiles — Windows install script
# Usage: irm https://raw.githubusercontent.com/aaronauld/dotfiles/main/install.ps1 | iex
#    or: powershell -ExecutionPolicy Bypass -File install.ps1
# ──────────────────────────────────────────────

$ErrorActionPreference = "Stop"
$DOTFILES_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "  aaronauld dotfiles — Windows setup" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

# ── 1. Winget check ────────────────────────────
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "⚠ winget not found. Install from the Microsoft Store (App Installer) then re-run." -ForegroundColor Yellow
    exit 1
}

# ── 2. Git ─────────────────────────────────────
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "▶ Installing Git..."
    winget install --id Git.Git -e --source winget --silent
    $env:PATH += ";C:\Program Files\Git\cmd"
} else {
    Write-Host "✓ Git already installed"
}

# ── 3. Node.js ─────────────────────────────────
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "▶ Installing Node.js (LTS)..."
    winget install --id OpenJS.NodeJS.LTS -e --source winget --silent
    $env:PATH += ";C:\Program Files\nodejs"
} else {
    Write-Host "✓ Node.js already installed"
}

# ── 4. Git LFS ─────────────────────────────────
Write-Host ""
Write-Host "▶ Configuring Git LFS..."
git lfs install
Write-Host "✓ Git LFS configured"

# ── 5. Git config ──────────────────────────────
Write-Host ""
Write-Host "▶ Copying git config..."
Copy-Item "$DOTFILES_DIR\git\.gitconfig" "$HOME\.gitconfig" -Force
Write-Host "✓ $HOME\.gitconfig"

# Prompt for git identity (skip if already set)
$currentName = git config --global user.name 2>$null
$currentEmail = git config --global user.email 2>$null
if (-not $currentName -or -not $currentEmail) {
    Write-Host ""
    Write-Host "  Git identity not set. Enter your details:"
    $gitName = Read-Host "  Name"
    $gitEmail = Read-Host "  Email"
    git config --global user.name $gitName
    git config --global user.email $gitEmail
    Write-Host "✓ Git identity set"
} else {
    Write-Host "✓ Git identity already set ($currentName <$currentEmail>) — skipping"
}

# ── 6. Global npm packages ─────────────────────
Write-Host ""
Write-Host "▶ Installing global npm packages..."
npm install -g typescript nodemon yarn shadcn-ui npx
Write-Host "✓ Global npm packages installed"

# ── 7. VS Code extensions ──────────────────────
Write-Host ""
if (Get-Command code -ErrorAction SilentlyContinue) {
    Write-Host "▶ Installing VS Code extensions..."
    Get-Content "$DOTFILES_DIR\vscode\extensions.txt" |
        Where-Object { $_ -notmatch '^#' -and $_.Trim() -ne '' } |
        ForEach-Object {
            Write-Host "  installing $_..."
            code --install-extension $_ --force 2>$null
        }
    Write-Host "✓ VS Code extensions installed"

    Write-Host "▶ Copying VS Code settings..."
    $vsCodeSettingsDir = "$env:APPDATA\Code\User"
    New-Item -ItemType Directory -Force -Path $vsCodeSettingsDir | Out-Null
    Copy-Item "$DOTFILES_DIR\vscode\settings.json" "$vsCodeSettingsDir\settings.json" -Force
    Write-Host "✓ VS Code settings copied"
} else {
    Write-Host "⚠ VS Code CLI (code) not found — skipping extensions" -ForegroundColor Yellow
    Write-Host "  Install VS Code then re-run this script"
}

# ── Claude Code setup ──────────────────────────────────────────────
Write-Host ""
Write-Host "▶ Setting up Claude Code..."

$claudeDir = "$env:USERPROFILE\.claude"
$claudeRepo = "git@github-personal:aaronauld/claude-config.git"

# Check SSH access to GitHub before attempting clone
$sshTest = ssh -T git@github.com 2>&1
if ($sshTest -notmatch "successfully authenticated") {
    Write-Host ""
    Write-Host "  ⚠ SSH key not authenticated with GitHub." -ForegroundColor Yellow
    Write-Host "  To set up: https://docs.github.com/en/authentication/connecting-to-github-with-ssh"
    Write-Host "  Skipping claude-config clone — re-run install.ps1 once SSH is configured."
    Write-Host ""
} else {

if (Test-Path "$claudeDir\.git") {
    Write-Host "  ~/.claude is already a git repo — pulling latest."
    git -C $claudeDir pull --quiet
} elseif (Test-Path $claudeDir) {
    Write-Host "  ⚠ ~/.claude exists but is not a git repo."
    Write-Host "  Rename it first: Rename-Item $claudeDir $claudeDir.bak"
    Write-Host "  Then re-run install.ps1"
} else {
    Write-Host "  Cloning claude-config into ~/.claude..."
    git clone $claudeRepo $claudeDir
}

# Install pre-commit hook
$hookSrc = "$claudeDir\hooks\pre-commit"
$hookDst = "$claudeDir\.git\hooks\pre-commit"
if (Test-Path $hookSrc) {
    Copy-Item $hookSrc $hookDst -Force
    Write-Host "✓ Pre-commit hook installed"
}

# Status line script runs directly from dotfiles — no copy needed
$scriptPath = "$PSScriptRoot\claude\ClaudeStatus.ps1"

# Merge statusLine into settings.local.json (preserves existing keys like permissions)
$settingsLocalPath = "$claudeDir\settings.json"
if (Test-Path $settingsLocalPath) {
    $data = Get-Content $settingsLocalPath -Raw | ConvertFrom-Json
} else {
    $data = [PSCustomObject]@{}
}
$data | Add-Member -Force -MemberType NoteProperty -Name "statusLine" -Value @{
    type    = "command"
    command = "powershell -File $scriptPath"
}
$data | ConvertTo-Json -Depth 10 | Set-Content $settingsLocalPath
Write-Host "✓ Claude settings.json statusLine updated"

Write-Host "✓ Claude Code ready"

} # end SSH check

# ── 9. FiraCode Nerd Font ──────────────────────
Write-Host ""
Write-Host "▶ Installing FiraCode Nerd Font..."
try {
    winget install --id DEVCOM.JetBrainsMonoNerdFont -e --source winget --silent 2>$null
    # FiraCode via winget
    winget install --id "Fira Code" --source winget --silent 2>$null
    Write-Host "✓ Font install attempted — confirm in Windows Font settings"
} catch {
    Write-Host "⚠ Font install failed — download manually from https://www.nerdfonts.com" -ForegroundColor Yellow
}

# ── Done ───────────────────────────────────────
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host "  Setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "  Next steps:"
Write-Host "  1. Restart your terminal"
Write-Host "  2. Set VS Code terminal font to 'FiraCode Nerd Font'"
Write-Host "  3. Restart Claude Code to activate the status line"
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host ""
