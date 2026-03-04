# Ralph Loop (`ralphloop.sh`)

A generic wrapper that runs Claude in a loop until it signals completion by creating a done file. Useful for any long, iterative task — bug fixing, refactoring, writing tests, documentation passes, etc.

---

## How It Works

```
┌─────────────────────────────────────────┐
│  Read .ralphloop_prompt from project dir │
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
3. Create the done file (`.ralphloop-done`) when everything is finished

---

## Prerequisites

- [`claude`](https://claude.ai/code) CLI installed and authenticated
- `ralphloop.sh` on your `$PATH` (see [Installation](#installation))

---

## Installation

The script lives in your dotfiles and is deployed by chezmoi. To make it available as `ralphloop`:

```bash
# Option A: symlink into a bin directory on your PATH
ln -s ~/.local/share/chezmoi/private_dot_shell/scripts/ralph_loop/ralphloop.sh ~/bin/ralphloop

# Option B: add an alias in your shell config
alias ralphloop="~/.shell/scripts/ralph_loop/ralphloop.sh"
```

---

## Quick Start

```bash
# 1. Navigate to your project
cd ~/projects/my-project

# 2. Create the prompt file
cat > .ralphloop_prompt << 'EOF'
You are part of an automated loop. Your task:

1. <describe what Claude should do each iteration>
2. <be specific about what files to read, what to change, etc.>

When ALL work is complete, create a file named ".ralphloop-done"
with the content "Done". Otherwise just finish — the loop will
call you again.

Only do ONE unit of work per run to keep context manageable.
EOF

# 3. Run the loop
ralphloop --task my-task
```

---

## Options

| Flag | Short | Default | Description |
|------|-------|---------|-------------|
| `--task NAME` | `-t` | `task` | Label used for display and log file naming |
| `--prompt FILE` | `-p` | `.ralphloop_prompt` | Path to the Claude prompt file |
| `--log FILE` | `-l` | `ralphloop-<task>.log` | Path to the log file |
| `--done FILE` | `-d` | `.ralphloop-done` | Path to the done file |
| `--sleep SECONDS` | `-s` | `2` | Delay between iterations |
| `--help` | `-h` | — | Show usage |

Relative file paths are resolved from the **current working directory** (not the script location). Absolute paths are used as-is.

---

## Prompt Writing Tips

**Always include the done file instruction.** Claude must know what file to create and when:
```
When ALL tasks are complete, create ".ralphloop-done" with content "All done".
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

**`.ralphloop_prompt`:**
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
   - If YES: create file ".ralphloop-done" with content "All bugs resolved"
   - If NO: just end (the loop will call you again)

Only fix ONE bug per run to keep context manageable.
```

**Run it:**
```bash
ralphloop --task bug-fix
```

---

## Stopping the Loop

| Method | When to use |
|--------|-------------|
| Claude creates `.ralphloop-done` | Normal — task is complete |
| `touch .ralphloop-done` | Manual — stop after current iteration finishes |
| `Ctrl+C` | Immediate — kills mid-iteration |

---

## Long-Running Sessions

For tasks that may run for hours, consider running inside `tmux` so the loop survives terminal disconnects:

```bash
tmux new-session -s ralphloop
ralphloop --task refactor --sleep 5
# Detach with Ctrl+B, D
# Reattach later: tmux attach -t ralphloop
```

---

## Multiple Tasks in One Project

You can run different loops for different concerns in the same project:

```bash
# Different prompt files, different logs
ralphloop --task tests    --prompt .ralphloop_tests
ralphloop --task docs     --prompt .ralphloop_docs
```

---

## `.gitignore` Recommendations

Add the following to your project's `.gitignore`:

```gitignore
.ralphloop-done
.ralphloop_prompt
ralphloop-*.log
```

The prompt file often contains project-specific instructions you may not want committed. The log files can grow large.

---

## Troubleshooting

**Loop runs forever / never stops**
Claude is not creating the done file. Check your prompt — make sure the instruction to create `.ralphloop-done` is explicit and unambiguous. Verify the path matches (the done file is resolved relative to `pwd`).

**`Error: Prompt file not found`**
You either haven't created `.ralphloop_prompt` yet, or you're running `ralphloop` from the wrong directory. The prompt file is looked up in your **current working directory**.

**Iterations complete instantly without doing anything**
Check the log file (`ralphloop-<task>.log`) for Claude's output. Claude may be miscounting remaining work and creating the done file prematurely — tighten the completion condition in your prompt.

**Claude crashes or returns an error mid-loop**
The loop will not die. If Claude exits with a non-zero status, a warning is printed to both the terminal and the log file, and the loop continues to the next iteration after the sleep delay. Check the log to diagnose what went wrong.
