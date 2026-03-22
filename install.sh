#!/usr/bin/env bash
# ──────────────────────────────────────────────
# aaronauld/dotfiles — Mac/Linux install script
# Usage: bash install.sh
# ──────────────────────────────────────────────

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  aaronauld dotfiles — Mac setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── 1. Homebrew ────────────────────────────────
if ! command -v brew &>/dev/null; then
    echo "▶ Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Add to PATH for Apple Silicon
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    echo "✓ Homebrew already installed"
fi

# ── 2. Core tools ──────────────────────────────
echo ""
echo "▶ Installing core tools..."
brew install git git-lfs node

# ── 3. Git LFS ─────────────────────────────────
git lfs install
echo "✓ Git LFS configured"

# ── 4. Git config ──────────────────────────────
echo ""
echo "▶ Linking git config..."
cp "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"

# Prompt for git identity (skip if already set)
CURRENT_NAME=$(git config --global user.name 2>/dev/null || true)
CURRENT_EMAIL=$(git config --global user.email 2>/dev/null || true)
if [ -z "$CURRENT_NAME" ] || [ -z "$CURRENT_EMAIL" ]; then
  echo ""
  echo "  Git identity not set. Enter your details:"
  read -p "  Name  : " GIT_NAME
  read -p "  Email : " GIT_EMAIL
  git config --global user.name "$GIT_NAME"
  git config --global user.email "$GIT_EMAIL"
  echo "✓ Git identity set"
else
  echo "✓ Git identity already set ($CURRENT_NAME <$CURRENT_EMAIL>) — skipping"
fi

# ── 5. Shell config ────────────────────────────
echo ""
echo "▶ Linking shell config..."
cp "$DOTFILES_DIR/shell/.zshrc" "$HOME/.zshrc"
echo "✓ ~/.zshrc"

# ── 6. Global npm packages ─────────────────────
echo ""
echo "▶ Installing global npm packages..."
npm install -g typescript nodemon yarn shadcn-ui npx
echo "✓ Global npm packages installed"

# ── 7. VS Code ─────────────────────────────────
echo ""
if command -v code &>/dev/null; then
    echo "▶ Installing VS Code extensions..."
    grep -v '^#' "$DOTFILES_DIR/vscode/extensions.txt" | grep -v '^$' | while read -r ext; do
        echo "  installing $ext..."
        code --install-extension "$ext" --force &>/dev/null
    done
    echo "✓ VS Code extensions installed"

    echo "▶ Copying VS Code settings..."
    VSCODE_SETTINGS_DIR="$HOME/Library/Application Support/Code/User"
    mkdir -p "$VSCODE_SETTINGS_DIR"
    cp "$DOTFILES_DIR/vscode/settings.json" "$VSCODE_SETTINGS_DIR/settings.json"
    echo "✓ VS Code settings copied"
else
    echo "⚠ VS Code CLI (code) not found — skipping extensions"
    echo "  Install VS Code then run: bash $DOTFILES_DIR/install.sh"
fi

# ── 8. Claude Code setup ───────────────────────────────────────────
echo ""
echo "▶ Setting up Claude Code..."

CLAUDE_DIR="$HOME/.claude"
CLAUDE_REPO="git@github-personal:aaronauld/claude-config.git"

# Check SSH access to GitHub before attempting clone
if ! ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
  echo ""
  echo "  ⚠ SSH key not authenticated with GitHub."
  echo "  To set up: https://docs.github.com/en/authentication/connecting-to-github-with-ssh"
  echo "  Skipping claude-config clone — re-run install.sh once SSH is configured."
  echo ""
else

if [ -d "$CLAUDE_DIR/.git" ]; then
  echo "  ~/.claude is already a git repo — pulling latest."
  git -C "$CLAUDE_DIR" pull --quiet
elif [ -d "$CLAUDE_DIR" ]; then
  echo "  ⚠ ~/.claude exists but is not a git repo."
  echo "  Back it up first: mv ~/.claude ~/.claude.bak"
  echo "  Then re-run install.sh"
else
  echo "  Cloning claude-config into ~/.claude..."
  git clone "$CLAUDE_REPO" "$CLAUDE_DIR"
fi

# Install pre-commit hook
if [ -f "$CLAUDE_DIR/hooks/pre-commit" ]; then
  cp "$CLAUDE_DIR/hooks/pre-commit" "$CLAUDE_DIR/.git/hooks/pre-commit"
  chmod +x "$CLAUDE_DIR/.git/hooks/pre-commit"
  echo "✓ Pre-commit hook installed"
fi

# Status line script — ensure it's executable (runs directly from dotfiles, no copy needed)
chmod +x "$DOTFILES_DIR/claude/claude-status.sh"

# Merge statusLine into settings.local.json (preserves existing keys like permissions)
# Uses python3 (built into macOS) for safe JSON merge
SETTINGS_LOCAL="$CLAUDE_DIR/settings.json"
python3 - "$SETTINGS_LOCAL" "$DOTFILES_DIR/claude/claude-status.sh" <<'PYEOF'
import json, sys, os

settings_path = sys.argv[1]
script_path   = sys.argv[2]

try:
    with open(settings_path) as f:
        data = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    data = {}

data["statusLine"] = {"type": "command", "command": f"bash {script_path}"}

with open(settings_path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PYEOF
echo "✓ Claude settings.json statusLine updated"

echo "✓ Claude Code ready"

fi # end SSH check

# ── 9. FiraCode Nerd Font ──────────────────────
echo ""
echo "▶ Installing FiraCode Nerd Font..."
brew install --cask font-fira-code-nerd-font 2>/dev/null && echo "✓ FiraCode Nerd Font installed" || echo "⚠ Font install failed — install manually from https://www.nerdfonts.com"

# ── Done ───────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Setup complete!"
echo ""
echo "  Next steps:"
echo "  1. Restart your terminal (or run: source ~/.zshrc)"
echo "  2. Set VS Code terminal font to 'FiraCode Nerd Font'"
echo "  3. Restart Claude Code to activate the status line"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
