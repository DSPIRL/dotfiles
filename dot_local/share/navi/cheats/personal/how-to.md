# navi: writing your own cheats

Cheats live in `~/.local/share/navi/cheats/` (check with `navi info cheats-path`).
Any `*.cheat` file in any subdirectory is picked up automatically. This `personal/`
tree is managed by chezmoi (`dot_local/share/navi/cheats/personal/`), so edit here and
`chezmoi add` the file, or edit in the chezmoi source and `chezmoi apply`.

## Syntax

| Prefix | Meaning |
|--------|---------|
| `% tag1, tag2` | Start a section; tags are searchable |
| `# text` | Description of the command below (what you search for) |
| `; text` | Comment, ignored |
| (plain line) | The command itself; consecutive lines run as one snippet |
| `<name>` | Variable; navi prompts for it |
| `$ name: cmd` | Populate `<name>` choices from the output of `cmd` |
| `@ tag` | Reuse `$` variable definitions from another section with that tag |

`$` lines accept `--- <options>` at the end. Common options:

| Option | Effect |
|--------|--------|
| `--multi` | Allow selecting several items (joined by space) |
| `--column N` | Use only column N of each selected line |
| `--delimiter RE` | Regex delimiter for `--column` (default: whitespace) |
| `--header TEXT` | Header shown in the picker |
| `--preview CMD` | Preview command; `{}` is the highlighted line |
| `--map CMD` | Pipe the selected value through a shell command |
| `--expand` | Split multi-select into one invocation per item |
| `--fzf-overrides ARGS` | Raw fzf flags for this variable |

## Examples

### 1. Plain variable (free-text prompt)

```
% git

# Set global git user name
git config --global user.name <name>
```

### 2. Choices from a command

```
% git

# Check out a local branch
git checkout <branch>

$ branch: git branch --format='%(refname:short)'
```

### 3. Fixed list of choices

```
% git

# Interactive rebase onto the last N commits
git rebase -i HEAD~<n>

$ n: echo -e "3\n5\n10\n20"
```

### 4. Pick a column from tabular output

```
% docker

# Stop a running container
docker stop <container_id>

$ container_id: docker ps --- --column 1 --header-lines 1 --header "Running containers"
```

`--header-lines 1` skips the `CONTAINER ID ...` header line in the picker.

### 5. Multi-select

```
% git

# Delete several local branches
git branch -D <branches>

$ branches: git branch --format='%(refname:short)' --- --multi
```

Result: `git branch -D feature-a feature-b`.

### 6. Multi-select, one command per item

```
% docker

# Remove images one at a time
docker rmi <image>

$ image: docker images --format '{{.Repository}}:{{.Tag}}' --- --multi --expand
```

Result: `docker rmi a:1; docker rmi b:2`.

### 7. Dependent variables

Earlier variables can be used inside later `$` commands.

```
% kubernetes, k8s

# Tail logs of a pod in a namespace
kubectl logs -f -n <namespace> <pod>

$ namespace: kubectl get namespaces --- --column 1 --header-lines 1
$ pod: kubectl get pods -n <namespace> --- --column 1 --header-lines 1
```

### 8. Preview pane

```
% systemctl

# Show status of a unit
systemctl status <unit>

$ unit: systemctl list-units --type=service --no-legend --plain --- --column 1 --preview 'systemctl status {1}'
```

### 9. Transform the selected value with `--map`

```
% files

# Open a file's directory
cd <dir>

$ dir: fd --type f --- --map 'xargs dirname'
```

### 10. Multi-line snippet

Consecutive non-blank lines after a `#` are run together.

```
% git

# Sync local master with upstream
git fetch <remote>
git checkout master
git rebase <remote>/master

$ remote: git remote
```

### 11. Reuse variables from another section

```
% git, common

$ remote: git remote
$ branch: git branch --format='%(refname:short)'
```

```
% git, push

@ common

# Push a branch to a remote
git push -u <remote> <branch>
```

### 12. Comments and search hints

```
% ssh

; Only works if the host is in ~/.ssh/config
# Open an SSH tunnel to a configured host
ssh -N -L <local_port>:localhost:<remote_port> <host>

$ host: grep -E '^Host ' ~/.ssh/config | awk '{print $2}' | grep -v '\*'
```

## Check it works

```sh
navi --query "merged"      # search directly
navi                       # interactive
navi --print               # print the resolved command instead of running it
navi --tag-rules git       # restrict to a tag
```

Reference: https://github.com/denisidoro/navi/blob/master/docs/cheatsheet-syntax.md
