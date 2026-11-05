#!/bin/sh
# Contract tests with fake CLIs: no authentication, network, or model requests.
set -eu
root=$(CDPATH= cd -P "$(dirname "$0")/.." && pwd)
launcher=$root/dot_ai/scripts/review.sh
umask 077
tmp=$(mktemp -d /tmp/review-launcher-test.XXXXXXXX)
trap 'rm -rf "$tmp"' 0
trap 'exit 130' INT
trap 'exit 143' TERM
mkdir "$tmp/bin" "$tmp/repo with spaces"
export MOCK_DIR=$tmp
export MOCK_STATUS=0 MOCK_RESULT='APPROVE: reviewed'
# A deliberately sparse PATH prevents falling through to real reviewer CLIs.
for tool in cat grep mktemp rm; do
    ln -s "$(command -v "$tool")" "$tmp/bin/$tool"
done
cat > "$tmp/bin/claude" <<'STUB'
#!/bin/sh
printf '%s\n' "$@" > "$MOCK_DIR/args"
pwd > "$MOCK_DIR/cwd"
cat > "$MOCK_DIR/input"
printf 'reviewer diagnostic\n' >&2
printf '%s\n' "$MOCK_RESULT"
exit "$MOCK_STATUS"
STUB
cat > "$tmp/bin/codex" <<'STUB'
#!/bin/sh
printf '%s\n' "$@" > "$MOCK_DIR/args"
pwd > "$MOCK_DIR/cwd"
cat > "$MOCK_DIR/input"
while [ "$#" -gt 0 ]; do
    case "$1" in
        --output-last-message)
            printf '%s\n' "$MOCK_RESULT" > "$2"
            printf '%s\n' "${2%/*}" > "$MOCK_DIR/review-tmp"
            shift 2
            ;;
        *) shift ;;
    esac
done
printf 'reviewer diagnostic\n' >&2
printf 'this CLI stdout must not leak\n'
exit "$MOCK_STATUS"
STUB
chmod +x "$tmp/bin/claude" "$tmp/bin/codex"
printf 'Review only. Here is the diff.\n' > "$tmp/brief"
repo=$tmp/repo\ with\ spaces

run() {
    PATH=$tmp/bin /bin/sh "$launcher" "$@" < "$tmp/brief" > "$tmp/out" 2> "$tmp/err"
}
expect_failure() {
    expected=$1
    shift
    if run "$@"; then
        printf 'Expected failure: %s\n' "$*" >&2
        exit 1
    else
        actual=$?
    fi
    [ "$actual" -eq "$expected" ]
    [ ! -s "$tmp/out" ]
}

# Both backends receive the exact model, brief and working directory.
# Shell-looking model text remains data, not a command to evaluate.
model='literal model; $(touch SHOULD_NOT_EXIST)'
for reviewer in claude codex; do
    run "$reviewer" --model "$model" --repo "$repo"
    [ "$(cat "$tmp/out")" = "$MOCK_RESULT" ]
    grep -F 'reviewer diagnostic' "$tmp/err" > /dev/null
    [ "$(cat "$tmp/input")" = "$(cat "$tmp/brief")" ]
    [ "$(cat "$tmp/cwd")" = "$(CDPATH= cd -P "$repo" && pwd)" ]
    [ ! -e "$repo/SHOULD_NOT_EXIST" ]
    # Match the entire argv, including safety flag/value pairs and no extras.
    if [ "$reviewer" = claude ]; then
        printf '%s\n' --print --output-format text \
            --model "$model" --effort high --safe-mode --restricted \
            --tools Read,Glob,Grep --allowedTools Read,Glob,Grep \
            --permission-mode dontAsk --strict-mcp-config \
            --mcp-config '{"mcpServers":{}}' --no-session-persistence \
            > "$tmp/expected-args"
    else
        printf '%s\n' exec --model "$model" \
            --cd "$(CDPATH= cd -P "$repo" && pwd)" \
            --sandbox read-only --config 'approval_policy="never"' \
            --config 'model_reasoning_effort="high"' --ignore-user-config \
            --ephemeral --disable hooks --disable plugins --disable apps \
            --config 'web_search="disabled"' \
            --output-last-message "$(cat "$tmp/review-tmp")/result" - \
            > "$tmp/expected-args"
        [ ! -e "$(cat "$tmp/review-tmp")" ]
    fi
    cmp "$tmp/args" "$tmp/expected-args"
    # Failed processes must not publish even a plausible review.
    MOCK_STATUS=17
    expect_failure 17 "$reviewer" --model exact-id --repo "$repo"
    MOCK_STATUS=0
    # Empty/whitespace responses are not successful reviews.
    MOCK_RESULT='   '
    expect_failure 1 "$reviewer" --model exact-id --repo "$repo"
    MOCK_RESULT='APPROVE: reviewed'
done

# Relative repository paths also resolve correctly.
(CDPATH= cd "$tmp"; run codex --repo 'repo with spaces' --model exact-id)
[ "$(cat "$tmp/cwd")" = "$(CDPATH= cd -P "$repo" && pwd)" ]

# Both skill-relative paths reach the same shared launcher.
for skill in council sol-loop; do
    (
        launcher=$root/dot_ai/skills/$skill/../../scripts/review.sh
        run codex --model exact-id --repo "$repo"
    )
    [ "$(cat "$tmp/out")" = "$MOCK_RESULT" ]
done

# Bad input fails before invoking either CLI.
rm "$tmp/args"
expect_failure 2
expect_failure 2 other --model exact-id --repo "$repo"
expect_failure 2 claude --model
expect_failure 2 claude --repo
expect_failure 2 claude --repo "$repo"
expect_failure 2 claude --model '' --repo "$repo"
expect_failure 2 claude --model --help --repo "$repo"
expect_failure 2 claude --model exact-id
expect_failure 2 claude --model exact-id --model second --repo "$repo"
expect_failure 2 claude --model exact-id --repo "$repo" --repo "$repo"
expect_failure 2 claude --model exact-id --repo "$tmp/missing"
expect_failure 2 claude --model exact-id --repo "$repo" --unknown
[ ! -e "$tmp/args" ]

# Missing CLI and empty stdin fail without falling back to an installed CLI.
for reviewer in claude codex; do
    mv "$tmp/bin/$reviewer" "$tmp/$reviewer"
    expect_failure 2 "$reviewer" --model exact-id --repo "$repo"
    grep -F 'not installed or not on PATH' "$tmp/err" > /dev/null
    mv "$tmp/$reviewer" "$tmp/bin/$reviewer"
done
: > "$tmp/brief"
expect_failure 2 claude --model exact-id --repo "$repo"
grep -F 'review brief is empty' "$tmp/err" > /dev/null
[ ! -e "$tmp/args" ]

/bin/sh "$launcher" --help > "$tmp/out"
grep -F 'Usage:' "$tmp/out" > /dev/null
printf 'Shared review launcher stub checks passed.\n'
