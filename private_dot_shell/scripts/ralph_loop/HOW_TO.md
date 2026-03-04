# Ralph Loop

Ralph Loop runs Claude iteratively until all tasks are complete. There are two ways
to use it depending on your context:

| | **Skills** (Claude Code session) | **Bash script** (terminal / headless) |
|---|---|---|
| How | `/raphloop` slash command | `raphloop.sh` in your shell |
| Setup | `/raphloop-setup` interviews you | Write `.raphloop_prompt` manually |
| Task tracking | `TASKS.md` with status + logs | Done file only |
| Best for | Interactive projects in Claude Code | CI, tmux, cron, non-interactive use |

---

## Skills Workflow (Claude Code)

The skills approach runs entirely inside a Claude Code session. A coordinator loop
in the main conversation spawns a fresh subagent for each task iteration, then checks
`TASKS.md` to decide whether to continue.

### Skills available

| Command | What it does |
|---------|-------------|
| `/raphloop-setup` | Interview → create `TASKS.md` + `.raphloop_prompt` (fresh start) |
| `/raphloop-update-tasks` | Add new tasks to an existing `TASKS.md` |
| `/raphloop-update-prompt` | Re-interview and rewrite `.raphloop_prompt` only |
| `/raphloop` | Run the loop until all tasks are resolved |

### Typical flow

```
# 1. Set up the project (one-time)
/raphloop-setup

# 2. Run the loop
/raphloop

# 3. Add more tasks any time (loop will pick them up on next run)
/raphloop-update-tasks
/raphloop
```

### TASKS.md format

Each task is a card with status tracking and an agent log:

```markdown
# Tasks

## Summary
| Priority | Open | In Progress | Resolved | Ignored |
|----------|------|-------------|----------|---------|
| Critical | 0    | 0           | 0        | 0       |
| High     | 1    | 0           | 0        | 0       |
| Medium   | 0    | 0           | 0        | 0       |
| Low      | 0    | 0           | 0        | 0       |

---

### TASK-001 | High | Open
**Title:** Fix login redirect
**Description:** Users are redirected to /home instead of /dashboard after login.
**Status:** Open
**Last Updated:** 2026-03-04 14:23
**Agent Log:**
- [2026-03-04 14:23] Task created during setup
```

**Status values:** `Open` → `In Progress` → `Resolved` or `Ignored`  
**Priority order:** `Critical > High > Medium > Low`

Subagents always pick the highest-priority `Open` task. If a task is left `In Progress`
for more than 10 minutes (e.g. from a crashed session), it is automatically reset to
`Open`.

### `.gitignore` recommendations (skills workflow)

```gitignore
.raphloop-done
.raphloop_prompt
TASKS.md
```

Whether to commit `TASKS.md` is up to you — it can serve as a useful project record.

---

## Bash Script Workflow (`raphloop.sh`)

A generic bash wrapper that runs `claude --print` in a loop until a done file is
created. Best for headless environments, tmux sessions, CI pipelines, or when you
want to run the loop outside of an active Claude Code session.

---

## How It Works

```
┌─────────────────────────────────────────┐
│  Read .raphloop_prompt from project dir │
└────────────────────┬────────────────────┘
                     │
             ┌───────▼────────┐
             │  Run Claude     │◄──────────────────────┐
             │  with prompt    │                       │
             └───────┬────────┘                       │
                     │                                │
          ┌──────────▼──────────┐   Claude fails      │
          │  Claude succeeded?  │──── No (warn) ──────┤
          └──────────┬──────────┘                     │
                     │ Yes                            │
          ┌──────────▼──────────┐                     │
          │ Done file exists?   │──── No ─────────────┘
          └──────────┬──────────┘        (sleep N seconds)
                     │ Yes
             ┌───────▼────────┐
             │  Loop complete  │
             └─────────────────┘
```

Each iteration Claude receives the same prompt. It is Claude's responsibility to:
1. Determine what work remains
2. Do one unit of work
3. Create the done file (`.raphloop-done`) when everything is finished

---

## Prerequisites

- [`claude`](https://claude.ai/code) CLI installed and authenticated
- `raphloop.sh` on your `$PATH` (see [Installation](#installation))

---

## Installation

The script lives in your dotfiles and is deployed by chezmoi. To make it available as `raphloop`:

```bash
# Option A: symlink into a bin directory on your PATH
ln -s ~/.local/share/chezmoi/private_dot_shell/scripts/ralph_loop/raphloop.sh ~/bin/raphloop

# Option B: add an alias in your shell config
alias raphloop="~/.shell/scripts/ralph_loop/raphloop.sh"
```

---

## Quick Start

```bash
# 1. Navigate to your project
cd ~/projects/my-project

# 2. Create the prompt file
cat > .raphloop_prompt << 'EOF'
You are part of an automated loop. Your task:

1. <describe what Claude should do each iteration>
2. <be specific about what files to read, what to change, etc.>

When ALL work is complete, create a file named ".raphloop-done"
with the content "Done". Otherwise just finish — the loop will
call you again.

Only do ONE unit of work per run to keep context manageable.
EOF

# 3. Run the loop
raphloop --task my-task
```

---

## Options

| Flag | Short | Default | Description |
|------|-------|---------|-------------|
| `--task NAME` | `-t` | `task` | Label used for display and log file naming |
| `--prompt FILE` | `-p` | `.raphloop_prompt` | Path to the Claude prompt file |
| `--log FILE` | `-l` | `raphloop-<task>.log` | Path to the log file |
| `--done FILE` | `-d` | `.raphloop-done` | Path to the done file |
| `--sleep SECONDS` | `-s` | `2` | Delay between iterations |
| `--help` | `-h` | — | Show usage |

Relative file paths are resolved from the **current working directory** (not the script location). Absolute paths are used as-is.

---

## Prompt Writing Tips

**Always include the done file instruction.** Claude must know what file to create and when:
```
When ALL tasks are complete, create ".raphloop-done" with content "All done".
If work remains, just end — the loop will call you again.
```

**Keep each iteration small.** Instruct Claude to do one unit of work per run:
```
Only fix ONE bug per run to keep context manageable.
```

**Be explicit about priority.** If there are multiple items, tell Claude how to pick:
```
Work on the highest priority item first (Critical > High > Medium > Low).
```

**Reference a state file.** For tasks with a checklist, point Claude at a file it can update to track progress across iterations (e.g., a `TODO.md` or `BUGS.md`).

**Include relevant context.** List the files Claude should read at the start of each iteration so it has the full picture even without session memory:
```
1. READ these files first: README.md, ARCHITECTURE.md, TASKS.md
```

---

## Example: Bug Fix Workflow

This is the original use case that inspired Ralph Loop.

**`.raphloop_prompt`:**
```
You are running as part of an automated bug-fix loop. Your task:

1. READ these files to understand the project:
   - Architecture.md
   - BUGS.md

2. IDENTIFY the highest priority OPEN bug (Critical > High > Medium > Low,
   then by bug number).

3. FIX the bug by editing the relevant source files.

4. MARK the bug as resolved in BUGS.md:
   - Change "Status: Open" to "Status: Resolved"
   - Update the summary table counts

5. CHECK if all bugs are now resolved:
   - If YES: create file ".raphloop-done" with content "All bugs resolved"
   - If NO: just end (the loop will call you again)

Only fix ONE bug per run to keep context manageable.
```

**Run it:**
```bash
raphloop --task bug-fix
```

---

## Stopping the Loop

| Method | When to use |
|--------|-------------|
| Claude creates `.raphloop-done` | Normal — task is complete |
| `touch .raphloop-done` | Manual — stop after current iteration finishes |
| `Ctrl+C` | Immediate — kills mid-iteration |

---

## Long-Running Sessions

For tasks that may run for hours, consider running inside `tmux` so the loop survives terminal disconnects:

```bash
tmux new-session -s raphloop
raphloop --task refactor --sleep 5
# Detach with Ctrl+B, D
# Reattach later: tmux attach -t raphloop
```

---

## Multiple Tasks in One Project

You can run different loops for different concerns in the same project:

```bash
# Different prompt files, different logs
raphloop --task tests    --prompt .raphloop_tests
raphloop --task docs     --prompt .raphloop_docs
```

---

## `.gitignore` Recommendations

Add the following to your project's `.gitignore`:

```gitignore
.raphloop-done
.raphloop_prompt
raphloop-*.log
```

The prompt file often contains project-specific instructions you may not want committed. The log files can grow large.

---

## Troubleshooting

**Loop runs forever / never stops**
Claude is not creating the done file. Check your prompt — make sure the instruction to create `.raphloop-done` is explicit and unambiguous. Verify the path matches (the done file is resolved relative to `pwd`).

**`Error: Prompt file not found`**
You either haven't created `.raphloop_prompt` yet, or you're running `raphloop` from the wrong directory. The prompt file is looked up in your **current working directory**.

**Iterations complete instantly without doing anything**
Check the log file (`raphloop-<task>.log`) for Claude's output. Claude may be miscounting remaining work and creating the done file prematurely — tighten the completion condition in your prompt.

**Claude crashes or returns an error mid-loop**
The loop will not die. If Claude exits with a non-zero status, a warning is printed to both the terminal and the log file, and the loop continues to the next iteration after the sleep delay. Check the log to diagnose what went wrong.
