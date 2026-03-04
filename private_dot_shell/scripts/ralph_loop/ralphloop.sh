#!/bin/bash
# Ralph Loop - Generic iterative Claude automation
#
# Usage: ralphloop [OPTIONS]
#
# Options:
#   -t, --task NAME        Task name used for log/done file naming (default: "task")
#   -p, --prompt FILE      File containing the Claude prompt
#                          (default: .ralphloop_prompt in current dir)
#   -l, --log FILE         Log file path (default: ralphloop-<task>.log)
#   -d, --done FILE        Done file path (default: .ralphloop-done)
#   -s, --sleep SECONDS    Delay between iterations (default: 2)
#   -h, --help             Show this help
#
# The prompt file can contain placeholders. Create a .ralphloop_prompt
# file in your project directory with the Claude instructions for your task.
# At the end of your prompt, instruct Claude to create the done file when
# finished (default: .ralphloop-done).

set -euo pipefail

# Defaults
TASK_NAME="task"
PROMPT_FILE=".ralphloop_prompt"
LOG_FILE=""
DONE_FILE=".ralphloop-done"
SLEEP_SECONDS=2

usage() {
    grep '^#' "$0" | sed 's/^# \{0,1\}//' | tail -n +2
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -t|--task)    TASK_NAME="$2"; shift 2 ;;
        -p|--prompt)  PROMPT_FILE="$2"; shift 2 ;;
        -l|--log)     LOG_FILE="$2"; shift 2 ;;
        -d|--done)    DONE_FILE="$2"; shift 2 ;;
        -s|--sleep)   SLEEP_SECONDS="$2"; shift 2 ;;
        -h|--help)    usage ;;
        *) echo "Unknown option: $1" >&2; usage ;;
    esac
done

# Default log file name uses task name
if [[ -z "$LOG_FILE" ]]; then
    LOG_FILE="ralphloop-${TASK_NAME}.log"
fi

# Resolve paths relative to current working directory (not script location)
WORK_DIR="$(pwd)"

if [[ ! "$DONE_FILE" = /* ]]; then
    DONE_FILE="${WORK_DIR}/${DONE_FILE}"
fi
if [[ ! "$LOG_FILE" = /* ]]; then
    LOG_FILE="${WORK_DIR}/${LOG_FILE}"
fi
if [[ ! "$PROMPT_FILE" = /* ]]; then
    PROMPT_FILE="${WORK_DIR}/${PROMPT_FILE}"
fi

# Validate prompt file
if [[ ! -f "$PROMPT_FILE" ]]; then
    echo "Error: Prompt file not found: $PROMPT_FILE" >&2
    echo "" >&2
    echo "Create a prompt file at '$PROMPT_FILE' with instructions for Claude." >&2
    echo "The prompt should tell Claude to create '${DONE_FILE##*/}' when the task is complete." >&2
    exit 1
fi

PROMPT="$(cat "$PROMPT_FILE")"

# Clean up any previous done file
rm -f "$DONE_FILE"

# Initialize log file
echo "=== Ralph Loop Started: $(date) ===" >"$LOG_FILE"
echo "Task: $TASK_NAME" | tee -a "$LOG_FILE"
echo "Prompt file: $PROMPT_FILE" | tee -a "$LOG_FILE"

echo ""
echo "Starting Ralph Loop - ${TASK_NAME}"
echo "To stop: create file '${DONE_FILE##*/}' or press Ctrl+C"
echo "Log file: $LOG_FILE"
echo "==========================================="

iteration=1

while [[ ! -f "$DONE_FILE" ]]; do
    echo ""
    echo "=== Iteration $iteration ===" | tee -a "$LOG_FILE"
    echo "Started: $(date)" | tee -a "$LOG_FILE"

    claude --print --dangerously-skip-permissions -p "$PROMPT" 2>&1 | tee -a "$LOG_FILE" || {
        echo "Warning: Claude exited with a non-zero status on iteration $iteration — retrying." | tee -a "$LOG_FILE"
    }

    echo "Completed: $(date)" | tee -a "$LOG_FILE"
    ((iteration++))

    sleep "$SLEEP_SECONDS"
done

echo "" | tee -a "$LOG_FILE"
echo "=== Ralph Loop Complete: $(date) ===" | tee -a "$LOG_FILE"
echo "Total iterations: $((iteration - 1))" | tee -a "$LOG_FILE"
