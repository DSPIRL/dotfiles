#!/usr/bin/env sh

input=$(cat)

green=$(printf '\033[32m')
yellow=$(printf '\033[33m')
orange=$(printf '\033[38;5;214m')
red=$(printf '\033[31m')
reset=$(printf '\033[0m')

remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')
transcript_path=$(echo "$input" | jq -r '.transcript_path // empty')
session_id=$(echo "$input" | jq -r '.session_id // .sessionId // empty')
context_in_tokens=$(echo "$input" | jq -r '
  .context_window.current_usage |
  if . == null then empty
  else
    ((.input_tokens // 0) + (.cache_read_input_tokens // 0) + (.cache_creation_input_tokens // 0)) |
    tostring
  end
')
context_out_tokens=$(echo "$input" | jq -r '.context_window.current_usage.output_tokens // empty')
session_in_tokens=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
session_out_tokens=$(echo "$input" | jq -r '.context_window.total_output_tokens // empty')

session_file=$transcript_path

if [ -z "$session_file" ] && [ -n "$session_id" ]; then
    session_file=$(rg --files "$HOME/.claude/projects" 2>/dev/null | rg "/${session_id}\\.jsonl$" | rg -v '/subagents/' | head -n 1)
fi

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
        session_in_tokens=$(printf '%s\n' "$thread_usage" | cut -d' ' -f1)
        session_out_tokens=$(printf '%s\n' "$thread_usage" | cut -d' ' -f2)
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

    parts="Context: ${context_color}${remaining_percent}%${reset} remaining"
fi

if [ -n "$context_in_tokens" ] && [ -n "$context_out_tokens" ]; then
    context_total_tokens=$((context_in_tokens + context_out_tokens))

    if [ "$context_in_tokens" -le 50000 ]; then
        input_color=$green
    elif [ "$context_in_tokens" -le 80000 ]; then
        input_color=$yellow
    elif [ "$context_in_tokens" -le 99999 ]; then
        input_color=$orange
    else
        input_color=$red
    fi

    token_part="CtxTok: ${input_color}${context_in_tokens}${reset} in / ${context_out_tokens} out (${context_total_tokens} total)"
    if [ -n "$parts" ]; then
        parts="$parts | $token_part"
    else
        parts="$token_part"
    fi
fi

if [ -n "$session_in_tokens" ] && [ -n "$session_out_tokens" ]; then
    session_total_tokens=$((session_in_tokens + session_out_tokens))
    session_part="Session: ${session_in_tokens} in / ${session_out_tokens} out (${session_total_tokens} total)"

    if [ -n "$parts" ]; then
        parts="$parts | $session_part"
    else
        parts="$session_part"
    fi
fi

echo "$parts"
