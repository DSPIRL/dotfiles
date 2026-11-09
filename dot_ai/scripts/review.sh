#!/bin/sh
# One agent request. The calling agent owns the review or discussion loop.
set -eu

usage() {
    printf '%s\n' \
        'Usage: sh review.sh <claude|codex> --model MODEL_ID --repo PATH [--session FILE] < brief.md' \
        '       sh review.sh <claude|codex> --delete-session FILE' \
        '' \
        '--session FILE starts a persistent session and records its ID in FILE,' \
        'or resumes the session already recorded there.'
}

fail() {
    printf 'review: %s\n' "$*" >&2
    exit 2
}

# Print the session ID recorded in a session file, refusing anything but a UUID.
read_id() {
    id=$(cat "$1") || fail "cannot read session file: $1"
    printf '%s\n' "$id" |
        grep -Eq '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' ||
        fail "session file does not hold a session ID: $1"
    printf '%s\n' "$id"
}

new_uuid() {
    if command -v uuidgen >/dev/null 2>&1; then
        uuidgen
    elif [ -r /proc/sys/kernel/random/uuid ]; then
        cat /proc/sys/kernel/random/uuid
    else
        fail 'uuidgen is required for claude sessions'
    fi
}

case "${1-}" in
    -h|--help) usage; exit 0 ;;
    claude|codex) reviewer=$1; shift ;;
    *) usage >&2; fail 'choose claude or codex' ;;
esac

model=
repo=
session=
delete=
while [ "$#" -gt 0 ]; do
    case "$1" in
        --model)
            [ "$#" -ge 2 ] || fail '--model requires a value'
            [ -z "$model" ] || fail 'duplicate --model'
            model=$2
            case "$model" in ''|-*) fail 'provide an explicit model ID' ;; esac
            shift 2
            ;;
        --repo)
            [ "$#" -ge 2 ] || fail '--repo requires a value'
            [ -z "$repo" ] || fail 'duplicate --repo'
            repo=$2
            [ -n "$repo" ] || fail '--repo requires a path'
            shift 2
            ;;
        --session)
            [ "$#" -ge 2 ] || fail '--session requires a file'
            [ -z "$session" ] || fail 'duplicate --session'
            session=$2
            [ -n "$session" ] || fail '--session requires a file'
            shift 2
            ;;
        --delete-session)
            [ "$#" -ge 2 ] || fail '--delete-session requires a file'
            [ -z "$delete" ] || fail 'duplicate --delete-session'
            delete=$2
            [ -n "$delete" ] || fail '--delete-session requires a file'
            shift 2
            ;;
        *) fail "unknown argument: $1" ;;
    esac
done
command -v "$reviewer" >/dev/null 2>&1 || fail "$reviewer is not installed or not on PATH"

if [ -n "$delete" ]; then
    [ -z "$model$repo$session" ] || fail '--delete-session takes no other options'
    id=$(read_id "$delete")
    case "$reviewer" in
        claude)
            # Claude keeps <id>.jsonl, and sometimes an <id>/ directory, per project.
            find "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects" -mindepth 2 -maxdepth 2 \
                \( -name "$id.jsonl" -o -name "$id" \) -exec rm -rf {} +
            ;;
        codex)
            codex delete --force "$id" >/dev/null
            ;;
    esac
    rm -f "$delete"
    exit 0
fi

[ -n "$model" ] || fail '--model is required'
[ -n "$repo" ] || fail '--repo is required'
case "$repo" in /*) ;; *) repo=$PWD/$repo ;; esac
[ -d "$repo" ] || fail "repository directory not found: $repo"
[ ! -t 0 ] || fail 'provide a brief on stdin'

id=
if [ -n "$session" ]; then
    case "$session" in /*) ;; *) session=$PWD/$session ;; esac
    [ -d "$(dirname "$session")" ] || fail "session file directory not found: $session"
    if [ -s "$session" ]; then
        id=$(read_id "$session")
    fi
fi

umask 077
# Keep review material outside the workspace, even if TMPDIR points inside it.
tmp=$(mktemp -d /tmp/ai-review.XXXXXXXX) || exit 1
trap 'rm -rf "$tmp"' 0
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM
cat > "$tmp/brief"
[ -s "$tmp/brief" ] || fail 'brief is empty'
CDPATH= cd -P "$repo" || exit 1

case "$reviewer" in
    claude)
        if [ -z "$session" ]; then
            set -- --no-session-persistence
        elif [ -n "$id" ]; then
            set -- --resume "$id"
        else
            id=$(new_uuid)
            id=$(printf '%s\n' "$id" | tr 'A-F' 'a-f')
            set -- --session-id "$id"
        fi
        # Only repository-confined file-reading tools; no shell, agents, or MCP.
        if claude --print --output-format text \
            --model "$model" --effort high \
            --safe-mode --restricted \
            --tools 'Read,Glob,Grep' --allowedTools 'Read,Glob,Grep' \
            --permission-mode dontAsk \
            --strict-mcp-config --mcp-config '{"mcpServers":{}}' \
            "$@" \
            < "$tmp/brief" > "$tmp/result"; then
            :
        else
            status=$?
            printf 'review: claude failed (exit %s)\n' "$status" >&2
            exit "$status"
        fi
        ;;
    codex)
        if [ -n "$id" ]; then
            # Resume has no --sandbox flag; the config key sets the same mode.
            set -- exec resume "$id" --config 'sandbox_mode="read-only"'
        elif [ -n "$session" ]; then
            set -- exec --cd "$PWD" --sandbox read-only
        else
            set -- exec --cd "$PWD" --sandbox read-only --ephemeral
        fi
        # Shell sandbox only: remaining managed/project configuration must be trusted.
        if codex "$@" --model "$model" \
            --config 'approval_policy="never"' \
            --config 'model_reasoning_effort="high"' \
            --ignore-user-config \
            --disable hooks --disable plugins --disable apps \
            --config 'web_search="disabled"' \
            --json --output-last-message "$tmp/result" - \
            < "$tmp/brief" > "$tmp/events"; then
            :
        else
            status=$?
            printf 'review: codex failed (exit %s)\n' "$status" >&2
            exit "$status"
        fi
        if [ -n "$session" ] && [ -z "$id" ]; then
            id=$(grep -o '"thread_id":"[0-9a-f-]*"' "$tmp/events" | head -n 1 | cut -d '"' -f 4)
            [ -n "$id" ] || fail 'codex did not report a session ID'
        fi
        ;;
esac

if [ ! -s "$tmp/result" ] || ! grep -q '[^[:space:]]' "$tmp/result"; then
    printf 'review: %s returned no review\n' "$reviewer" >&2
    exit 1
fi
if [ -n "$session" ] && [ ! -s "$session" ]; then
    printf '%s\n' "$id" > "$session"
fi
cat "$tmp/result"
