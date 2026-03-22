# aaronauld/dotfiles

Personal development environment setup for Windows and Mac. One command to get fully configured.

## What's included

| Config | Details |
|---|---|
| **Claude Code** | 2-line status line (path, branch, model, tokens, context %) |
| **VS Code** | Tokyo Night theme, FiraCode Nerd Font, 28 extensions |
| **Git** | User config + Git LFS |
| **Shell** | `.zshrc` for Mac/zsh (aliases, git prompt) |
| **npm** | `typescript`, `nodemon`, `yarn`, `shadcn-ui`, `npx` |

## Setup

### 1. SSH keys (required before running install)

The install script clones `claude-config` (a private repo) from your personal GitHub using the `github-personal` SSH host alias. Set this up first.

**Generate a personal SSH key (skip if you already have one):**
```bash
ssh-keygen -t ed25519 -C "your@email.com" -f ~/.ssh/id_personal
```

**Add to `~/.ssh/config`:**
```
# Personal GitHub
Host github-personal
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_personal

# Work GitHub (if applicable)
Host github-work
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_work
```

**Add the public key to your personal GitHub account:**
```bash
cat ~/.ssh/id_personal.pub   # copy this → github.com → Settings → SSH keys
```

**Test it:**
```bash
ssh -T git@github-personal   # should say: Hi aaronauld! You've successfully authenticated
```

---

### 2. Mac

```bash
git clone https://github.com/aaronauld/dotfiles.git ~/dotfiles && bash ~/dotfiles/install.sh
```

### 2. Windows (run PowerShell as Administrator)

```powershell
git clone https://github.com/aaronauld/dotfiles.git $HOME\dotfiles; powershell -ExecutionPolicy Bypass -File $HOME\dotfiles\install.ps1
```

> Or run directly without cloning:
> ```powershell
> irm https://raw.githubusercontent.com/aaronauld/dotfiles/main/install.ps1 | iex
> ```

## Structure

```
dotfiles/
├── claude/
│   ├── settings.json          # Claude Code settings
│   ├── ClaudeStatus.ps1       # Windows status line script
│   └── claude-status.sh       # Mac/Linux status line script
├── vscode/
│   ├── settings.json          # VS Code settings
│   └── extensions.txt         # Extension list
├── git/
│   └── .gitconfig             # Git config
├── shell/
│   └── .zshrc                 # Mac zsh config
├── install.sh                 # Mac setup script
└── install.ps1                # Windows setup script
```

## Status line

The Claude Code status line shows across 2 lines:

```
~/Projects/my-app (feature/my-branch)
[Claude Sonnet 4.6] | Tokens: 1234 | Context: 12%
```

Colors: green = healthy, yellow = moderate, red = high usage.
