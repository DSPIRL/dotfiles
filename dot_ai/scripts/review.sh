#!/bin/sh
# One review request. The calling agent owns the review loop.
set -eu

usage() {
    printf '%s\n' 'Usage: sh review.sh <claude|codex> --model MODEL_ID --repo PATH < brief.md'
}

fail() {
    printf 'review: %s\n' "$*" >&2
    exit 2
}

case "${1-}" in
    -h|--help) usage; exit 0 ;;
    claude|codex) reviewer=$1; shift ;;
    *) usage >&2; fail 'choose claude or codex' ;;
esac

model=
repo=
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
        *) fail "unknown argument: $1" ;;
    esac
done
[ -n "$model" ] || fail '--model is required'
[ -n "$repo" ] || fail '--repo is required'
command -v "$reviewer" >/dev/null 2>&1 || fail "$reviewer is not installed or not on PATH"
case "$repo" in /*) ;; *) repo=$PWD/$repo ;; esac
[ -d "$repo" ] || fail "repository directory not found: $repo"
[ ! -t 0 ] || fail 'provide a review brief on stdin'

umask 077
# Keep review material outside the workspace, even if TMPDIR points inside it.
tmp=$(mktemp -d /tmp/ai-review.XXXXXXXX) || exit 1
trap 'rm -rf "$tmp"' 0
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM
cat > "$tmp/brief"
[ -s "$tmp/brief" ] || fail 'review brief is empty'
CDPATH= cd -P "$repo" || exit 1

case "$reviewer" in
    claude)
        # Only repository-confined file-reading tools; no shell, agents, or MCP.
        if claude --print --output-format text \
            --model "$model" --effort high \
            --safe-mode --restricted \
            --tools 'Read,Glob,Grep' --allowedTools 'Read,Glob,Grep' \
            --permission-mode dontAsk \
            --strict-mcp-config --mcp-config '{"mcpServers":{}}' \
            --no-session-persistence \
            < "$tmp/brief" > "$tmp/result"; then
            :
        else
            status=$?
            printf 'review: claude failed (exit %s)\n' "$status" >&2
            exit "$status"
        fi
        ;;
    codex)
        # Shell sandbox only: remaining managed/project configuration must be trusted.
        if codex exec --model "$model" --cd "$PWD" \
            --sandbox read-only --config 'approval_policy="never"' \
            --config 'model_reasoning_effort="high"' \
            --ignore-user-config --ephemeral \
            --disable hooks --disable plugins --disable apps \
            --config 'web_search="disabled"' \
            --output-last-message "$tmp/result" - \
            < "$tmp/brief" > /dev/null; then
            :
        else
            status=$?
            printf 'review: codex failed (exit %s)\n' "$status" >&2
            exit "$status"
        fi
        ;;
esac

if [ ! -s "$tmp/result" ] || ! grep -q '[^[:space:]]' "$tmp/result"; then
    printf 'review: %s returned no review\n' "$reviewer" >&2
    exit 1
fi
cat "$tmp/result"
