# ──────────────────────────────────────────────
# aaronauld — .zshrc
# ──────────────────────────────────────────────

# Homebrew (Apple Silicon path — Intel Macs use /usr/local)
export PATH="/opt/homebrew/bin:$PATH"

# Node version manager (nvm)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Aliases
alias ll="ls -la"
alias gs="git status"
alias gp="git push"
alias gl="git pull"
alias gc="git commit -m"
alias gco="git checkout"

# Git branch in prompt
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats ' (%b)'
setopt PROMPT_SUBST
PROMPT='%F{green}%n@%m%f %F{yellow}%~%f%F{cyan}${vcs_info_msg_0_}%f $ '
