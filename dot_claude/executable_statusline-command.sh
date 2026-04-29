#!/usr/bin/env sh

input=$(cat)

green=$(printf '\033[32m')
yellow=$(printf '\033[33m')
orange=$(printf '\033[38;5;214m')
red=$(printf '\033[31m')
reset=$(printf '\033[0m')

remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')
session_id=$(echo "$input" | jq -r '.session_id // .sessionId // empty')
in_tokens=$(echo "$input" | jq -r '
  .context_window.current_usage |
  if . == null then empty
  else
    ((.input_tokens // 0) + (.cache_read_input_tokens // 0) + (.cache_creation_input_tokens // 0)) |
    tostring
  end
')
out_tokens=$(echo "$input" | jq -r '.context_window.current_usage.output_tokens // empty')

if [ -n "$session_id" ]; then
    session_file=$(rg --files "$HOME/.claude/projects" 2>/dev/null | rg "/${session_id}\\.jsonl$" | rg -v '/subagents/' | head -n 1)

    if [ -n "$session_file" ] && [ -f "$session_file" ]; then
        thread_usage=$(jq -rs '
          [
            .[]
            | select(.type == "assistant" and (.isSidechain != true) and .message.usage != null)
            | {
                id: (.requestId // .message.id // .uuid),
                in_tokens: ((.message.usage.input_tokens // 0) + (.message.usage.cache_read_input_tokens // 0) + (.message.usage.cache_creation_input_tokens // 0)),
                out_tokens: (.message.usage.output_tokens // 0)
              }
          ]
          | unique_by(.id)
          | {
              in_tokens: (map(.in_tokens) | add // 0),
              out_tokens: (map(.out_tokens) | add // 0)
            }
          | "\(.in_tokens) \(.out_tokens)"
        ' "$session_file" 2>/dev/null)

        if [ -n "$thread_usage" ]; then
            in_tokens=$(printf '%s\n' "$thread_usage" | cut -d' ' -f1)
            out_tokens=$(printf '%s\n' "$thread_usage" | cut -d' ' -f2)
        fi
    fi
fi

parts=""

if [ -n "$remaining" ]; then
    parts="Context: $(printf '%.0f' "$remaining")% remaining"
fi

if [ -n "$in_tokens" ] && [ -n "$out_tokens" ]; then
    total_tokens=$((in_tokens + out_tokens))

    if [ "$total_tokens" -le 50000 ]; then
        total_color=$green
    elif [ "$total_tokens" -le 80000 ]; then
        total_color=$yellow
    elif [ "$total_tokens" -le 99999 ]; then
        total_color=$orange
    else
        total_color=$red
    fi

    token_part="Tokens: ${in_tokens} in / ${out_tokens} out | ${total_color}${total_tokens}${reset} total"
    if [ -n "$parts" ]; then
        parts="$parts | $token_part"
    else
        parts="$token_part"
    fi
fi

echo "$parts"
