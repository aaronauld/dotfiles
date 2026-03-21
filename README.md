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

### Mac (one command)

```bash
git clone https://github.com/aaronauld/dotfiles.git ~/dotfiles && bash ~/dotfiles/install.sh
```

### Windows (one command, run in PowerShell as Administrator)

```powershell
git clone https://github.com/aaronauld/dotfiles.git $HOME\dotfiles; powershell -ExecutionPolicy Bypass -File $HOME\dotfiles\install.ps1
```

> Or if the repo is already public, run directly without cloning:
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
