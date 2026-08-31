#!/bin/bash
# Claude Code status line: <host> <cwd> <git status> <reset time status>
input=$(cat)

# Cache the payload: rate_limits.{five_hour,seven_day}.resets_at reaches the
# statusline command and nowhere else, and /wait-for-reset reads it from here.
printf '%s' "$input" >"$HOME/.claude/statusline-cache.tmp.json"

# --- Segment 0: hostname ---
host_seg=$(printf '\033[38;5;108m%s\033[0m' "${HOSTNAME%%.*}")

# --- Segment 1: cwd (abbreviated with ~ for $HOME) ---
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
cwd_display="$cwd"
case "$cwd" in
    "$HOME") cwd_display="~" ;;
    "$HOME"/*) cwd_display="~${cwd#$HOME}" ;;
esac
cwd_seg=$(printf '\033[1;38;5;33m%s\033[0m' "$cwd_display")

# --- Segment 2: git status ---
git_seg=""
if git -C "$cwd" --no-optional-locks rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
    [ -z "$branch" ] && branch=$(git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)

    dirty=""
    if [ -n "$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null)" ]; then
        dirty="*"
    fi

    ahead_behind=""
    counts=$(git -C "$cwd" --no-optional-locks rev-list --left-right --count 'HEAD...@{upstream}' 2>/dev/null)
    if [ -n "$counts" ]; then
        ahead=$(echo "$counts" | awk '{print $1}')
        behind=$(echo "$counts" | awk '{print $2}')
        [ "$ahead" != "0" ] && ahead_behind="${ahead_behind}↑${ahead}"
        [ "$behind" != "0" ] && ahead_behind="${ahead_behind}↓${behind}"
    fi

    if [ -n "$dirty" ]; then
        git_color='\033[38;5;178m'   # yellow: dirty
    else
        git_color='\033[38;5;71m'    # green: clean
    fi
    git_seg=$(printf "${git_color}%s%s%s\033[0m" "$branch" "$dirty" "$ahead_behind")
fi

# --- Segment 3: context window usage (this session) ---
ctx_seg=""
read -r tokens pct <<<"$(echo "$input" | jq -r '.context_window // empty |
    "\((.total_input_tokens // 0) + (.total_output_tokens // 0)) \(.used_percentage // 0)"')"
if [ -n "$tokens" ]; then
    if [ "$tokens" -ge 1000000 ]; then
        tokens_display=$(awk -v t="$tokens" 'BEGIN{printf "%.1fM", t/1000000}')
    elif [ "$tokens" -ge 1000 ]; then
        tokens_display=$(awk -v t="$tokens" 'BEGIN{printf "%.1fk", t/1000}')
    else
        tokens_display="$tokens"
    fi

    if [ "$pct" -ge 80 ]; then
        ctx_color='\033[38;5;167m'   # red
    elif [ "$pct" -ge 50 ]; then
        ctx_color='\033[38;5;178m'   # yellow
    else
        ctx_color='\033[38;5;71m'    # green
    fi
    ctx_seg=$(printf "${ctx_color}%s tok (%s%%)\033[0m" "$tokens_display" "$pct")
fi

# --- Segment 4: usage-limit reset time ---
# The status line JSON payload exposes `rate_limits.five_hour.resets_at` and
# `rate_limits.seven_day.resets_at` (unix epoch seconds), but only once the
# session is a Claude.ai subscriber session and only after the first API
# response of the session. If absent, we omit this segment.
reset_seg=""
for window in five_hour:5h seven_day:7d; do
    key=${window%%:*}
    label=${window##*:}
    read -r pct resets_at <<<"$(echo "$input" |
        jq -r ".rate_limits.${key} // empty | \"\(.used_percentage | round) \(.resets_at)\"")"
    [ -n "$resets_at" ] || continue

    # today's reset shows a bare clock time; a later day gets a weekday
    [ "$(date -d "@$resets_at" +%j)" = "$(date +%j)" ] && fmt='%H:%M' || fmt='%a %H:%M'
    when=$(date -d "@$resets_at" "+$fmt")

    # highlight on how much of the window is spent, not how soon it resets
    if [ "$pct" -ge 80 ]; then
        pct_color='\033[38;5;167m'   # red
    elif [ "$pct" -ge 50 ]; then
        pct_color='\033[38;5;178m'   # yellow
    else
        pct_color='\033[38;5;71m'    # green
    fi

    [ -n "$reset_seg" ] && reset_seg="$reset_seg$(printf '\033[38;5;240m · \033[0m')"
    reset_seg="$reset_seg$(printf "\033[38;5;244m%s\033[0m ${pct_color}%s%%\033[0m \033[38;5;240m⟳\033[0m \033[38;5;244m%s\033[0m" \
        "$label" "$pct" "$when")"
done

# --- Assemble ---
out="$host_seg  $cwd_seg"
[ -n "$git_seg" ] && out="$out  $git_seg"
[ -n "$ctx_seg" ] && out="$out  $ctx_seg"
[ -n "$reset_seg" ] && out="$out  $reset_seg"

printf '%s' "$out"
