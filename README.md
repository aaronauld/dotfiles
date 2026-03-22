# aaronauld/dotfiles

Personal development environment for Mac and Windows. One command installs and configures everything — VS Code, Git, shell, Claude Code, fonts, and npm tooling.

---

## What's included

| Tool | What gets configured |
|---|---|
| **Claude Code** | Custom 2-line status line, agents, commands, secret-scanning hook |
| **VS Code** | Tokyo Night theme, FiraCode Nerd Font, 28 extensions, format on save |
| **Git** | LFS, autocrlf, pull strategy — identity prompted at install time |
| **Shell** | `.zshrc` with git aliases, nvm support, branch-aware prompt |
| **npm** | `typescript`, `nodemon`, `yarn`, `shadcn-ui`, `npx` installed globally |
| **Font** | FiraCode Nerd Font (used by both VS Code and terminal) |

---

## Prerequisites

### SSH key for personal GitHub

The install script clones [`claude-config`](https://github.com/aaronauld/claude-config) (a private repo) using the `github-personal` SSH alias. This must be set up before running the install.

**1. Generate a personal SSH key**
```bash
ssh-keygen -t ed25519 -C "your@email.com" -f ~/.ssh/id_personal
```

**2. Add to `~/.ssh/config`**
```
# Personal GitHub
Host github-personal
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_personal
```

If you also have a work GitHub account, add a second entry:
```
# Work GitHub
Host github-work
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_work
```

**3. Add the public key to your personal GitHub account**
```bash
cat ~/.ssh/id_personal.pub
# Copy the output → github.com → Settings → SSH and GPG keys → New SSH key
```

**4. Test the connection**
```bash
ssh -T git@github-personal
# Expected: Hi aaronauld! You've successfully authenticated...
```

---

## Install

### Mac

```bash
git clone https://github.com/aaronauld/dotfiles.git ~/dotfiles && bash ~/dotfiles/install.sh
```

### Windows (PowerShell as Administrator)

```powershell
git clone https://github.com/aaronauld/dotfiles.git $HOME\dotfiles; powershell -ExecutionPolicy Bypass -File $HOME\dotfiles\install.ps1
```

> Or run directly without cloning first:
> ```powershell
> irm https://raw.githubusercontent.com/aaronauld/dotfiles/main/install.ps1 | iex
> ```

---

## What the installer does

The script runs in order and is safe to re-run — each step checks before overwriting.

| Step | Mac | Windows |
|---|---|---|
| Package manager | Installs Homebrew if missing | Requires winget (from Microsoft Store) |
| Core tools | `brew install git git-lfs node` | `winget install Git.Git`, `OpenJS.NodeJS.LTS` |
| Git LFS | `git lfs install` | `git lfs install` |
| Git config | Copies `.gitconfig`, prompts for name + email if not set | Same |
| Shell config | Copies `.zshrc` to `~/` | — |
| npm globals | `typescript nodemon yarn shadcn-ui npx` | Same |
| VS Code | Installs 28 extensions + copies settings (skips if `code` CLI not found) | Same |
| Claude Code | Clones `claude-config` into `~/.claude` via SSH, installs pre-commit hook, copies status line script, writes `settings.json` if missing | Same |
| Font | `brew install --cask font-fira-code-nerd-font` | `winget install` |

**Git identity** — the installer prompts for your name and email if they aren't already set globally. This means the same dotfiles work for both personal and work machines without hardcoding either identity.

**SSH check** — before attempting the `claude-config` clone, the installer tests SSH auth against GitHub. If it fails, it prints instructions and skips that step rather than erroring out. You can re-run the installer once SSH is configured.

**Existing `~/.claude`** — if the directory already exists as a git repo, the installer pulls the latest instead of re-cloning. If it exists but isn't a git repo, it stops and asks you to back it up first.

---

## Post-install steps

1. Restart your terminal (or `source ~/.zshrc` on Mac)
2. In VS Code: set the terminal font to `FiraCode Nerd Font`
3. Restart Claude Code to activate the status line

---

## Claude Code status line

A custom 2-line display replaces the default Claude Code status bar:

```
~/Projects/my-app (feature/login)
[claude-sonnet-4-6] | Tokens: 4,521 | Context: 23%
```

- **Line 1** — current directory (home-abbreviated) + git branch
- **Line 2** — model name, token count, context window percentage
- **Colours** — green under 50%, yellow 50–80%, red above 80%
- Also shows rate limit windows when applicable

The script lives at `~/scripts/claude-status.sh` (Mac) or `~\scripts\ClaudeStatus.ps1` (Windows) and is called by `~/.claude/settings.json`.

---

## Updating

To pull the latest dotfiles and re-apply:
```bash
cd ~/dotfiles && git pull && bash install.sh
```

To update your Claude config separately:
```bash
cd ~/.claude && git pull
```

---

## Structure

```
dotfiles/
├── claude/
│   ├── claude-status.sh       # Mac/Linux status line script
│   ├── ClaudeStatus.ps1       # Windows status line script
│   └── settings.json          # Claude Code settings template
├── git/
│   └── .gitconfig             # Git config (no identity — set at install time)
├── shell/
│   └── .zshrc                 # Zsh config: PATH, nvm, aliases, prompt
├── vscode/
│   ├── extensions.txt         # List of extensions to install
│   └── settings.json          # VS Code preferences
├── install.sh                 # Mac/Linux installer
└── install.ps1                # Windows installer
```
