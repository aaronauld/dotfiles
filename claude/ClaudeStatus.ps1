# 1. Read stdin as a single string
$rawInput = [Console]::In.ReadToEnd()

# 2. Check if we actually got input
if (-not $rawInput.Trim()) {
    [Console]::Write("[Claude] | Waiting...")
    exit
}

# 3. Parse JSON with a try/catch to prevent silent crashes
try {
    $data = $rawInput | ConvertFrom-Json -ErrorAction Stop
}
catch {
    [Console]::Write("JSON Error: $($_.Exception.Message)")
    exit
}

# 4. Extract data using correct field paths from the statusLine JSON spec
$model = if ($data.model.display_name) { $data.model.display_name } else { "Claude" }
$inputTokens = if ($data.context_window.total_input_tokens) { $data.context_window.total_input_tokens } else { 0 }
$outputTokens = if ($data.context_window.total_output_tokens) { $data.context_window.total_output_tokens } else { 0 }
$tokens = $inputTokens + $outputTokens
$percent = if ($null -ne $data.context_window.used_percentage) { [math]::Round($data.context_window.used_percentage) } else { 0 }
$cwd = if ($data.workspace.current_dir) { $data.workspace.current_dir } else { $PWD.Path }

# 5. ANSI color codes via [char]27 (works across all PowerShell versions)
$ESC    = [char]27
$green  = "$ESC[32m"
$yellow = "$ESC[33m"
$red    = "$ESC[1;31m"
$cyan   = "$ESC[36m"
$reset  = "$ESC[0m"

# Helper: green/yellow/red based on usage percentage
function Get-PctColor($pct) {
    if ($pct -lt 50) { return $green }
    if ($pct -lt 80) { return $yellow }
    return $red
}

# 6. Git branch detection using CWD from JSON
$branchSegment = ""
$branch = & git --no-optional-locks -C "$cwd" branch --show-current 2>$null
if ($branch) {
    $branchSegment = " ($cyan$branch$reset)"
}

# 7. Shorten home directory prefix to ~
$homePath = [System.Environment]::GetFolderPath('UserProfile').TrimEnd('\').TrimEnd('/')
$displayCwd = $cwd
if ($displayCwd.StartsWith($homePath, [System.StringComparison]::OrdinalIgnoreCase)) {
    $displayCwd = '~' + $displayCwd.Substring($homePath.Length).Replace('\', '/')
} else {
    $displayCwd = $displayCwd.Replace('\', '/')
}

# 8. Rate limit segment (only shown when data is available)
$rateLimitSegment = ""
$fivePct = $data.rate_limits.five_hour.used_percentage
$weekPct = $data.rate_limits.seven_day.used_percentage
if ($null -ne $fivePct -or $null -ne $weekPct) {
    $parts = @()
    if ($null -ne $fivePct) {
        $fiveRounded = [math]::Round($fivePct)
        $fiveColor   = Get-PctColor $fiveRounded
        $parts += "5h:$fiveColor$fiveRounded%$reset"
    }
    if ($null -ne $weekPct) {
        $weekRounded = [math]::Round($weekPct)
        $weekColor   = Get-PctColor $weekRounded
        $parts += "7d:$weekColor$weekRounded%$reset"
    }
    $rateLimitSegment = " | " + ($parts -join " ")
}

# 9. Context percentage color
$ctxColor = Get-PctColor $percent

# 10. Two-line output
#     Line 1 — path + git branch
#     Line 2 — model, tokens, context %, rate limits
$line1 = "$displayCwd$branchSegment"
$line2 = "[$green$model$reset] | Tokens: $yellow$tokens$reset | Context: $ctxColor$percent%$reset$rateLimitSegment"

[Console]::Write("$line1`n$line2")
