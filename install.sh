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
echo "✓ ~/.gitconfig"

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

# ── 8. Claude Code status line ─────────────────
echo ""
echo "▶ Setting up Claude Code status line..."
mkdir -p "$HOME/.claude"
mkdir -p "$HOME/scripts"

cp "$DOTFILES_DIR/claude/claude-status.sh" "$HOME/scripts/claude-status.sh"
chmod +x "$HOME/scripts/claude-status.sh"

# Build settings.json with correct Mac path
cat > "$HOME/.claude/settings.json" <<EOF
{
  "autoUpdatesChannel": "latest",
  "statusLine": {
    "type": "command",
    "command": "bash $HOME/scripts/claude-status.sh"
  }
}
EOF
echo "✓ Claude status line configured"

# ── 9. FiraCode Nerd Font ──────────────────────
echo ""
echo "▶ Installing FiraCode Nerd Font..."
brew tap homebrew/cask-fonts 2>/dev/null || true
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
