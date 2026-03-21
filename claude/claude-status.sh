#!/usr/bin/env bash
# Claude Code status line script — Mac/Linux
# Reads JSON from stdin, outputs a 2-line formatted status line

# 1. Read stdin
raw_input=$(cat)

if [[ -z "$raw_input" ]]; then
    printf "[Claude] | Waiting..."
    exit 0
fi

# 2. Parse JSON fields via python3 (built into macOS, no deps needed)
parse() {
    echo "$raw_input" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print($1)
except:
    print('')
" 2>/dev/null
}

model=$(parse "d.get('model', {}).get('display_name', 'Claude')")
input_tokens=$(parse "d.get('context_window', {}).get('total_input_tokens', 0) or 0")
output_tokens=$(parse "d.get('context_window', {}).get('total_output_tokens', 0) or 0")
tokens=$(( input_tokens + output_tokens ))
percent=$(parse "round(d.get('context_window', {}).get('used_percentage', 0) or 0)")
cwd=$(parse "d.get('workspace', {}).get('current_dir', '') or d.get('cwd', '')")

[[ -z "$cwd" ]] && cwd="$PWD"

# 3. ANSI colors
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[1;31m'
CYAN='\033[36m'
RESET='\033[0m'

# Helper: pick color based on percentage
pct_color() {
    local pct=$1
    if   (( pct < 50 )); then echo "$GREEN"
    elif (( pct < 80 )); then echo "$YELLOW"
    else echo "$RED"
    fi
}

# 4. Git branch detection using CWD from JSON
branch_segment=""
branch=$(git --no-optional-locks -C "$cwd" branch --show-current 2>/dev/null)
if [[ -n "$branch" ]]; then
    branch_segment=" (${CYAN}${branch}${RESET})"
fi

# 5. Shorten home directory to ~
display_cwd="${cwd/#$HOME/\~}"

# 6. Rate limit segment
rate_limit_segment=""
five_pct=$(parse "round(d.get('rate_limits', {}).get('five_hour', {}).get('used_percentage', -1) or -1)")
week_pct=$(parse "round(d.get('rate_limits', {}).get('seven_day', {}).get('used_percentage', -1) or -1)")
rate_parts=()
if (( five_pct >= 0 )); then
    color=$(pct_color "$five_pct")
    rate_parts+=("5h:${color}${five_pct}%${RESET}")
fi
if (( week_pct >= 0 )); then
    color=$(pct_color "$week_pct")
    rate_parts+=("7d:${color}${week_pct}%${RESET}")
fi
if (( ${#rate_parts[@]} > 0 )); then
    rate_limit_segment=" | $(IFS=' '; echo "${rate_parts[*]}")"
fi

# 7. Context percentage color
ctx_color=$(pct_color "$percent")

# 8. Two-line output
#    Line 1 — path + git branch
#    Line 2 — model, tokens, context %, rate limits
line1="${display_cwd}${branch_segment}"
line2="[${GREEN}${model}${RESET}] | Tokens: ${YELLOW}${tokens}${RESET} | Context: ${ctx_color}${percent}%${RESET}${rate_limit_segment}"

printf "%b\n%b" "$line1" "$line2"
