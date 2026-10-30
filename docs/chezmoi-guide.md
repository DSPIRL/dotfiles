---
id: chezmoi-guide
aliases: []
tags: []
---

# Chezmoi Guide

Reference guide for advanced chezmoi features used in this dotfiles repository.

## First-Time Setup (New Machine)

This repository enables age encryption and KeePassXC only on personal machines with the password database present.

### Prerequisites

1. Install chezmoi
2. For personal secrets, install keepassxc-cli and make your KeePassXC database available (e.g., via Syncthing)

### Bootstrap Steps

```bash
# 1. Initialize chezmoi with this repo
chezmoi init <your-repo-url>

# 2. Choose personal or work (default: work); WSL is always work, without a prompt

# 3. Apply the dotfiles (prompts for the KeePassXC password and extracts the age key
#    only when personal and the database is present)
chezmoi apply
```

Work machines, including WSL, do not require KeePassXC or the database.

On CachyOS, install the base packages and optional components with:

```bash
bash ~/.local/share/chezmoi/install_scripts/executable_cachyos_install.sh
```

The base setup installs Nix, enables `nix-daemon.service`, and updates the user's `nixpkgs` channel, defaulting new setups to `nixpkgs-unstable`. Start a new login shell afterward so `/etc/profile.d/nix-daemon.sh` adds Nix profiles to the environment.

On hosts whose names contain `laptop`, the installer also offers fingerprint setup for Hyprlock and KeePassXC Quick Unlock. The setup creates `/etc/pam.d/polkit-1`, making one fingerprint scan sufficient for all Polkit authentication requests, with the normal `system-auth` password path as fallback after three failed scans or a thirty-second timeout. It does not enable fingerprints for `sudo`, `su`, login, or global PAM authentication. The managed Polkit override must be reviewed against `/usr/lib/pam.d/polkit-1` after major Polkit/PAM packaging changes.

The optional rootless Podman setup installs `podman` and `podman-compose` and explicitly selects the same provider packages used on this machine: `crun` for the OCI runtime, Netavark/Aardvark DNS for container networking, and Pasta (from `passt`) for rootless networking. Pacman installs required dependencies such as Conmon and Catatonit transitively. The setup allocates subordinate UID/GID ranges when needed, enables unprivileged user namespaces when the kernel disables them, enables the user's `podman.socket`, and verifies rootless mode, Overlay storage, and the selected runtime/network stack. `runc`, CNI plugins, Slirp4netns, and Fuse OverlayFS are not part of this setup. Enabling unprivileged user namespaces increases kernel attack surface, as noted by the Arch Wiki. The setup must run from an active login session so the user systemd manager and runtime directory are available.

The optional Minikube setup reproduces this machine's separate VM-based cluster rather than using Podman. It installs `minikube`, `kubectl`, and the packages in `cachyosVMPackages.txt`, configures the libvirt host, and persists KVM2 with Docker, 2 CPUs, 6144 MiB RAM, and a 20000 MB disk as the Minikube defaults. Docker runs inside the Minikube VM; no host Docker package is installed. The setup does not create or start a cluster; log out and back in if libvirt group membership was newly added, then run `minikube start`. Existing clusters retain their profile settings until deleted and recreated.

For CachyOS desktop installation, control-panel usage, runtime preferences, and recovery commands, see [Hyprland desktop controls](hyprland-desktop.md).

---

## How Chezmoi Commands Work

### `chezmoi init`

Processes `.chezmoi.toml.tmpl` and generates `~/.config/chezmoi/chezmoi.toml`.

**What happens:**

1. Reads `.chezmoi.toml.tmpl` from source directory
2. Evaluates template variables (`.chezmoi.os`, `.chezmoi.homeDir`, etc.)
3. Loads or prompts for machine policy, detects platform/software facts, and checks for the KeePassXC database
4. Writes the result to `~/.config/chezmoi/chezmoi.toml`
5. Sets up data variables and, when enabled, age encryption and KeePassXC paths

**When to run:** After cloning, changing `.chezmoi.toml.tmpl`, installing/removing detected software, or making the password database available/unavailable.

### Machine Policy and Detection

- **Classification:** `promptChoiceOnce` persists `machineType` as `personal` or `work` (default: `work`). Normal reinitialization reuses that choice; run `chezmoi init --prompt` to change it. WSL always uses `work`, regardless of a saved choice.
- **Detected facts:** Each `chezmoi init` refreshes `isLinux`, `isMacOS`, `isCachyOS`, and `isWSL`, plus boolean `hasHyprland` (`Hyprland` or `hyprctl` on `PATH`) and `hasFish` (`fish` on `PATH`). These are saved facts, not live checks during `apply`.
- **Deployment:** Work machines exclude personal configs (`~/.config/containers/`, `~/.config/chezmoi/`, `~/.ssh/`) and Neovim OpenCode. Hyprland implies Linux; its desktop/theme configs and `wallust-refresh` require detected Hyprland and non-WSL. Kanata's mixed directory is filtered by platform: macOS config/launcher on macOS, Linux configs on Linux, and no Kanata files on WSL. Nushell helpers and aliases match deployment: `mac-kanata` is macOS-only; `modstat` (GNU `stat`) and `flatpak-alias` are Linux-only. Wayland helpers (`cliphist-rofi`, `cliphist-rofi-img`, `setmpv`, `setwal`) and the Linux Resolve launcher (`startResolve`) are excluded on macOS and WSL. Fish config is managed only on Linux with Fish installed. Outside the Hyprland desktop, Ghostty uses Carbonfox, Nushell uses the static Spaceship prompt, and Alacritty omits the Wallust palette import. WSL excludes GUI configs and Neovim silicon because this setup has no clipboard support there.
- **Secrets:** Personal classification is independent of database presence. `useKeePassXC` is true only for a personal machine with `~/Documents/Syncs/KeePass/Databases/Passwords/Passwords.kdbx` present. Otherwise age/KeePassXC configuration is omitted and `~/.config/chezmoi/` is ignored, protecting any existing age key from an empty key template.

### `chezmoi apply`

Deploys files from source state to your home directory.

**What happens:**

1. Reads config from `~/.config/chezmoi/chezmoi.toml`
2. Reads `.chezmoiignore` and excludes matching files
3. For each managed file:
   - If `.tmpl`: evaluates the template
   - If `encrypted_`: decrypts using age/gpg
   - If `private_`: sets permissions to 600
   - Transforms `dot_` prefix to `.`
4. Compares result to target file in `~`
5. Writes files that differ (creates/updates)

**Example transformation:**

```
Source: encrypted_dot_gitconfig.tmpl.age
  → decrypt → evaluate template → write to ~/.gitconfig
```

### Order of Operations

```
chezmoi init   →  .chezmoi.toml.tmpl  →  ~/.config/chezmoi/chezmoi.toml
chezmoi apply  →  reads config        →  processes source files  →  writes to ~/
```

**Important:** Always run `chezmoi init` after modifying `.chezmoi.toml.tmpl`, otherwise the config will be stale and templates may reference undefined variables.

---

## OS-Specific Configurations

Chezmoi provides several methods for handling platform differences.

### Method 1: `.chezmoiignore` with Templates

Exclude entire files or directories using the generated policy and detected facts. All ignore patterns use destination paths relative to `~`, not source names such as `dot_config/`.

```
# macOS only
{{ if not .isMacOS }}
.config/aerospace/
.config/karabiner/
{{ end }}

# Hyprland desktop only; never WSL
{{ if or (not .hasHyprland) .isWSL }}
.config/hypr/
.config/quickshell/
{{ end }}

# Fish installed on Linux only
{{ if or (not .isLinux) (not .hasFish) }}
.config/fish/
{{ end }}
```

Ignoring prevents deployment; it does not remove already-deployed files. After changing classification, review and manually remove any previously deployed configs that no longer belong.

### Method 2: Template Files (`.tmpl` suffix)

For files that need different _content_ per OS, add `.tmpl` to the filename. Chezmoi processes the template before deploying.

```bash
# File: dot_gitconfig.tmpl
[core]
{{ if eq .chezmoi.os "darwin" }}
    editor = /opt/homebrew/bin/nvim
{{ else }}
    editor = /usr/bin/nvim
{{ end }}

[user]
    name = {{ .name }}
    email = {{ .email }}
```

### Method 3: OS-Specific File Variants

Use OS suffixes for completely different file versions:

```
dot_bashrc_darwin      # Applied only on macOS
dot_bashrc_linux       # Applied only on Linux
```

Chezmoi automatically selects the correct variant.

### Method 4: OS-Specific Scripts

Prefix scripts with the target OS:

```
run_once_darwin_setup.sh     # Runs only on macOS
run_once_linux_setup.sh      # Runs only on Linux
run_onchange_install.sh      # Runs on any OS when content changes
```

### Available Template Variables

```
{{ .chezmoi.os }}              # "darwin", "linux", "windows"
{{ .chezmoi.arch }}            # "amd64", "arm64"
{{ .chezmoi.hostname }}        # Machine hostname
{{ .chezmoi.username }}        # Current user
{{ .chezmoi.homeDir }}         # Home directory path
```

Boolean comparisons:

```
{{ if eq .chezmoi.os "darwin" }}...{{ end }}
{{ if ne .chezmoi.os "linux" }}...{{ end }}
```

### Custom Data Variables

Define reusable variables in `.chezmoi.toml.tmpl` (source) or `~/.config/chezmoi/chezmoi.toml` (local):

```toml
[data]
    name = "Your Name"
    email = "you@example.com"
    work_machine = true
```

Use in templates with dot prefix:

```
{{ .name }}
{{ if .work_machine }}
# work-specific config
{{ end }}
```

### WSL Detection

`.chezmoi.toml.tmpl` detects WSL when the OS is Linux and the lowercased kernel release contains `microsoft`, then saves the boolean as `isWSL` in `[data]`.

Use in templates:

```
{{- if .isWSL }}
# WSL-specific config
{{- else }}
# Regular Linux/macOS config
{{- end }}
```

**Note:** Other templates use `.isWSL`; `.chezmoi.toml.tmpl` computes and uses the local `$isWSL` variable.

---

## Encryption for Secrets

Chezmoi supports encrypting sensitive files using **age** (recommended) or **GPG**. Encrypted files are stored in the source state and automatically decrypted when applying.

### Age Encryption (Recommended)

Age is simpler and more modern than GPG. It's the recommended choice for new setups.

#### Step 1: Generate a Key

```bash
# Generate key pair (store securely - this is your decryption key)
chezmoi age-keygen --output ~/.config/chezmoi/key.txt

# Protect the key file
chmod 600 ~/.config/chezmoi/key.txt
```

This outputs a public key (starts with `age1...`) and creates a private key file.

#### Step 2: Configure Chezmoi

Add to `~/.config/chezmoi/chezmoi.toml`:

```toml
encryption = "age"

[age]
    identity = "~/.config/chezmoi/key.txt"
    recipient = "age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p"
```

Replace the `recipient` with your actual public key from step 1.

#### Step 3: Add Encrypted Files

```bash
# Add a file with encryption
chezmoi add --encrypt ~/.gitconfig

# The file is stored as: encrypted_dot_gitconfig.age
```

#### Multiple Machines

For syncing across machines, you need the key file on each machine. Options:

1. **Store in KeePassXC** (recommended) - See "Password Manager Integration" section below. The key is extracted automatically during setup.

2. **Copy manually** - Securely copy `key.txt` to each machine.

3. **Multiple recipients** - Use one key per machine (all can decrypt):

```toml
[age]
    identity = "~/.config/chezmoi/key.txt"
    recipients = [
        "age1abc...",  # Desktop
        "age1def...",  # Laptop
        "age1ghi..."   # Server
    ]
```

### GPG Encryption

Alternative if you already use GPG or want YubiKey/smartcard support.

#### Configuration

```toml
encryption = "gpg"

[gpg]
    recipient = "your-gpg-key-id"
```

For symmetric (passphrase) encryption:

```toml
encryption = "gpg"

[gpg]
    symmetric = true
```

Encrypted files are stored with `.asc` suffix.

### Encrypted File Naming

Chezmoi uses these conventions:

- `encrypted_` prefix marks files for encryption
- `.age` suffix for age-encrypted files
- `.asc` suffix for GPG-encrypted files

Example: `~/.gitconfig` becomes `encrypted_dot_gitconfig.age` in the source state.

### Templating with Secrets

For files that need both templating AND encryption, combine them:

```bash
# File: encrypted_dot_gitconfig.tmpl.age
```

Or use chezmoi's secret management to pull values from password managers instead of encrypting entire files.

### Password Manager Integration

Instead of encrypting files, you can pull secrets from password managers.

#### KeePassXC

Configure the database path in `~/.config/chezmoi/chezmoi.toml`:

```toml
[keepassxc]
    database = "/path/to/your/database.kdbx"
```

Use in templates:

```
# Basic entry lookup
username = {{ (keepassxc "example.com").UserName }}
password = {{ (keepassxc "example.com").Password }}

# Custom attributes
api_key = {{ keepassxcAttribute "MyService" "api-key" }}

# Attachments (requires keepassxc-cli 2.7.0+)
{{ keepassxcAttachment "SSH Keys" "id_ed25519" }}
```

The database password is prompted on first access and cached in memory until chezmoi exits.

#### Storing the Age Key in KeePassXC

Instead of copying your age key file to each machine, store it in KeePassXC:

1. Create a KeePassXC entry (e.g., "Chezmoi")
2. Add a custom attribute (e.g., "key") containing the full age private key
3. Create a template to extract it:

```
# dot_config/private_chezmoi/private_key.txt.tmpl
{{ keepassxcAttribute "Chezmoi" "key" }}
```

This way, the key is securely stored in your password database and automatically deployed during `chezmoi apply`.

#### Other Password Managers

```
# 1Password
{{ (onepassword "GitHub").email }}

# Bitwarden
{{ (bitwarden "item" "gpg-key").notes }}

# pass (passwordstore.org)
{{ (pass "services/github/token") }}
```

Supported: 1Password, Bitwarden, LastPass, pass, macOS Keychain, KeePassXC, Vault, and more.

---

## Shell Startup Benchmarks

`bench-shell` is available from bash, zsh, and fish via `~/.local/scripts` and requires `hyperfine`.

```sh
bench-shell                 # Compare all installed bash/zsh/fish shells
bench-shell zsh             # Test one shell
bench-shell bash zsh        # Compare selected shells
bench-shell --login zsh     # Include login-shell initialization
```

Each benchmark uses two warmups and ten timed runs with the shell's normal interactive configuration. Missing shells are skipped by default; explicitly requesting a missing shell is an error. Measurements include initialization and exit hooks, but not first-prompt rendering, Ghostty shell integration, or terminal window creation. Run from the same directory and environment for useful before/after comparisons; startup scripts execute on every run.

### CLI Benchmarks

`bench-cli` uses the same two warmups and ten timed runs to benchmark or compare CLI commands:

```sh
bench-cli 'git status --short'
bench-cli 'rg --files' 'fd --type f'
```

Quote each complete command as one argument. Commands run directly, without interpreting pipes, redirects, variables, or wildcards; output is suppressed. Every run executes the command's actual work and side effects, so avoid destructive commands. Results reflect the current directory, environment, and warmed filesystem caches. Use `hyperfine` directly for custom run counts, shell expressions, or export options.

---

## Quick Reference

| Task                               | Command                                              |
| ---------------------------------- | ---------------------------------------------------- |
| Add encrypted file                 | `chezmoi add --encrypt ~/.secrets`                   |
| Edit encrypted file                | `chezmoi edit ~/.secrets`                            |
| View diff (decrypts automatically) | `chezmoi diff`                                       |
| Apply (decrypts automatically)     | `chezmoi apply`                                      |
| Re-encrypt with new key            | `chezmoi forget <file>` then `chezmoi add --encrypt` |

---

## Resources

- [Age Encryption - chezmoi docs](https://www.chezmoi.io/user-guide/encryption/age/)
- [GPG Encryption - chezmoi docs](https://www.chezmoi.io/user-guide/encryption/gpg/)
- [Encryption FAQ - chezmoi docs](https://www.chezmoi.io/user-guide/frequently-asked-questions/encryption/)
- [KeePassXC - chezmoi docs](https://www.chezmoi.io/user-guide/password-managers/keepassxc/)
- [KeePassXC functions - chezmoi docs](https://www.chezmoi.io/reference/templates/keepassxc-functions/)
