#!/usr/bin/env bash

set -euo pipefail

pamFile="/etc/pam.d/greetd"
pamModule="/usr/lib/security/pam_kwallet5.so"
configHome="${XDG_CONFIG_HOME:-${HOME}/.config}"
editedFile=""

cleanup() {
    [[ -z "${editedFile}" ]] || rm -f -- "${editedFile}"
}
trap cleanup EXIT

if [[ ! -f "${pamModule}" ]]; then
    echo "KWallet PAM module is missing; install kwallet-pam first." >&2
    exit 1
fi

if [[ ! -f "${pamFile}" ]]; then
    echo "Expected greetd PAM configuration does not exist: ${pamFile}" >&2
    exit 1
fi

editedFile="$(mktemp)"
awk '
{
    lines[NR] = $0
    type = $1
    sub(/^-/, "", type)

    if (type == "auth" && $0 ~ /pam_kwallet5\.so/) {
        haveAuth = 1
    } else if (type == "auth" && $2 == "include" && $3 == "system-local-login") {
        authAnchor = NR
    }

    if (type == "session" && $0 ~ /pam_kwallet5\.so/) {
        haveSession = 1
    } else if (type == "session" && $2 == "include" && $3 == "system-local-login") {
        sessionAnchor = NR
    }
}
END {
    if ((!haveAuth && !authAnchor) || (!haveSession && !sessionAnchor)) {
        exit 1
    }

    for (line = 1; line <= NR; line++) {
        print lines[line]
        if (!haveAuth && line == authAnchor) {
            print "auth       optional     pam_kwallet5.so"
        }
        if (!haveSession && line == sessionAnchor) {
            print "session    optional     pam_kwallet5.so auto_start"
        }
    }
}
' "${pamFile}" >"${editedFile}" || {
    echo "Could not find the expected system-local-login entries in ${pamFile}." >&2
    exit 1
}

if ! cmp -s "${pamFile}" "${editedFile}"; then
    if ! sudo test -e "${pamFile}.pre-kwallet"; then
        sudo cp --preserve=all -- "${pamFile}" "${pamFile}.pre-kwallet"
    fi

    stagedFile="${pamFile}.kwallet.$$"
    sudo install -o root -g root -m 0644 "${editedFile}" "${stagedFile}"
    sudo mv -f -- "${stagedFile}" "${pamFile}"
    echo "Configured greetd to unlock KWallet at login."
else
    echo "greetd PAM is already configured for KWallet."
fi

if ! grep -Eq '^[[:space:]]*-?auth[[:space:]].*pam_kwallet5\.so' "${pamFile}" ||
    ! grep -Eq '^[[:space:]]*-?session[[:space:]].*pam_kwallet5\.so.*auto_start' "${pamFile}"; then
    echo "KWallet PAM configuration validation failed." >&2
    exit 1
fi

if ! command -v kwriteconfig6 >/dev/null 2>&1; then
    echo "kwriteconfig6 is required to configure KWallet." >&2
    exit 1
fi

mkdir -p "${configHome}/keepassxc"
kwriteconfig6 --file "${configHome}/kwalletrc" --group Wallet --key Enabled --type bool true
kwriteconfig6 --file "${configHome}/kwalletrc" --group Wallet --key "Default Wallet" kdewallet
kwriteconfig6 --file "${configHome}/kwalletrc" --group KSecretD --key Enabled --type bool true
kwriteconfig6 --file "${configHome}/kwalletrc" --group org.freedesktop.secrets --key apiEnabled --type bool true
kwriteconfig6 --file "${configHome}/keepassxc/keepassxc.ini" --group FdoSecrets --key Enabled --type bool false

echo "Enabled KWallet and disabled KeePassXC's conflicting Secret Service provider."
echo "KeePassXC browser integration remains unchanged."
echo "If KWallet prompts on next login, create kdewallet with standard password encryption and your login password."
