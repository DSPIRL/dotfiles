---
id: chezmoi-guide
aliases: []
tags: []
---

# Chezmoi Guide

Reference guide for advanced chezmoi features used in this dotfiles repository.

## First-Time Setup (New Machine)

This repository uses age encryption with keys stored in KeePassXC. Follow these steps on a new machine:

### Prerequisites

1. Install chezmoi and keepassxc-cli
2. Have your KeePassXC database available (e.g., via Syncthing)

### Bootstrap Steps

```bash
# 1. Initialize chezmoi with this repo
chezmoi init <your-repo-url>

# 2. This processes .chezmoi.toml.tmpl and prompts for your KeePassXC password
#    The age key is automatically extracted from KeePassXC

# 3. Apply the dotfiles
chezmoi apply
```

On WSL systems, encryption and KeePassXC are disabled automatically - the setup will work without the database.

---

## How Chezmoi Commands Work

### `chezmoi init`

Processes `.chezmoi.toml.tmpl` and generates `~/.config/chezmoi/chezmoi.toml`.

**What happens:**

1. Reads `.chezmoi.toml.tmpl` from source directory
2. Evaluates template variables (`.chezmoi.os`, `.chezmoi.homeDir`, etc.)
3. Runs any template logic (e.g., `stat` check for KeePassXC database)
4. Writes the result to `~/.config/chezmoi/chezmoi.toml`
5. Sets up encryption, KeePassXC paths, and data variables for other templates

**When to run:** After cloning the repo, or after changing `.chezmoi.toml.tmpl`.

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

Exclude entire files or directories based on OS. This is ideal when a config only applies to one platform.

```
# Skip on Linux (macOS only)
{{ if ne .chezmoi.os "darwin" }}
dot_config/aerospace/
dot_config/karabiner/
{{ end }}

# Skip on macOS (Linux only)
{{ if ne .chezmoi.os "linux" }}
dot_config/hypr/
dot_config/quickshell/
{{ end }}
```

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

This repo detects WSL using a computed data variable in `.chezmoi.toml.tmpl`:

```toml
[data]
    isWSL = {{ if and (eq .chezmoi.os "linux") (contains "microsoft" .chezmoi.kernel.osrelease) }}true{{ else }}false{{ end }}
```

Use in templates:

```
{{- if .isWSL }}
# WSL-specific config
{{- else }}
# Regular Linux/macOS config
{{- end }}
```

**Note:** The `.isWSL` variable is only available in other templates, not within `.chezmoi.toml.tmpl` itself. In the config template, use the full condition.

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
