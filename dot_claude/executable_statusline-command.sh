#!/usr/bin/env sh

input=$(cat)

green=$(printf '\033[32m')
yellow=$(printf '\033[33m')
orange=$(printf '\033[38;5;214m')
red=$(printf '\033[31m')
reset=$(printf '\033[0m')

remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')

# Prompt segment mirroring ~/.config/oh-my-posh/spaceship.omp.json:
# "<user> in <folder> on <branch> [stash count]"
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
[ -n "$cwd" ] || cwd=$(pwd)
lightyellow=$(printf '\033[93m')
cyan=$(printf '\033[36m')
white=$(printf '\033[97m')
pink=$(printf '\033[38;2;255;148;223m')
branch_icon=$(printf '\356\202\240')

prompt="${lightyellow}$(whoami)${reset} ${white}in${reset} ${cyan}$(basename "$cwd")${reset}"

if git --no-optional-locks -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    head=$(git --no-optional-locks -C "$cwd" symbolic-ref --short HEAD 2>/dev/null \
        || git --no-optional-locks -C "$cwd" rev-parse --short HEAD 2>/dev/null)
    if [ -n "$head" ]; then
        prompt="$prompt ${white}on${reset} ${pink}${branch_icon} ${head}${reset}"
        stash_count=$(git --no-optional-locks -C "$cwd" stash list 2>/dev/null | wc -l | tr -d ' ')
        if [ "${stash_count:-0}" -gt 0 ]; then
            prompt="$prompt ${pink}$(printf '\356\255\213') ${stash_count}${reset}"
        fi
    fi
fi

parts=""

if [ -n "$remaining" ]; then
    remaining_percent=$(printf '%.0f' "$remaining")

    if [ "$remaining_percent" -le 60 ]; then
        context_color=$red
    elif [ "$remaining_percent" -le 70 ]; then
        context_color=$orange
    elif [ "$remaining_percent" -le 80 ]; then
        context_color=$yellow
    else
        context_color=$green
    fi

    # 10-cell bar, filled cells = context remaining
    bar_width=10
    filled=$(( (remaining_percent * bar_width + 50) / 100 ))
    bar=""
    i=0
    while [ "$i" -lt "$bar_width" ]; do
        if [ "$i" -lt "$filled" ]; then
            bar="${bar}█"
        else
            bar="${bar}░"
        fi
        i=$((i + 1))
    done

    parts="Context ${context_color}${bar} ${remaining_percent}%${reset}"
fi

cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')

if [ -n "$cost" ]; then
    cost_part="Cost: \$$(printf '%.2f' "$cost")"
    if [ -n "$parts" ]; then
        parts="$parts | $cost_part"
    else
        parts="$cost_part"
    fi
fi

if [ -n "$parts" ]; then
    echo "$prompt | $parts"
else
    echo "$prompt"
fi
