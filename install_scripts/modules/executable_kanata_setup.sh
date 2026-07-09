#!/usr/bin/env bash

set -u

if [[ "$(uname -s)" != "Linux" ]]; then
    echo "Kanata setup is only supported on Linux."
    exit 1
fi

targetUser="${KANATA_USER:-${SUDO_USER:-$(id -un)}}"

if ! id "${targetUser}" >/dev/null 2>&1; then
    echo "Kanata setup target user does not exist: ${targetUser}" >&2
    exit 1
fi

targetGroup="$(id -gn "${targetUser}")"
targetUid="$(id -u "${targetUser}")"
targetHome="${HOME}"

if command -v getent >/dev/null 2>&1; then
    passwdEntry="$(getent passwd "${targetUser}" || true)"
    if [[ -n "${passwdEntry}" ]]; then
        targetHome="$(printf '%s\n' "${passwdEntry}" | cut -d: -f6)"
    fi
fi

run_user_systemctl() {
    if [[ "$(id -un)" == "${targetUser}" ]]; then
        systemctl --user "$@"
    else
        sudo -u "${targetUser}" XDG_RUNTIME_DIR="/run/user/${targetUid}" systemctl --user "$@"
    fi
}

find_kanata_config() {
    if [[ -n "${KANATA_CONFIG:-}" ]]; then
        printf '%s\n' "${KANATA_CONFIG}"
        return 0
    fi

    if [[ -f "${targetHome}/.config/kanata/config.kbd" ]]; then
        printf '%s\n' "${targetHome}/.config/kanata/config.kbd"
        return 0
    fi

    if [[ -f "${targetHome}/.config/kanata/kanata.kbd" ]]; then
        printf '%s\n' "${targetHome}/.config/kanata/kanata.kbd"
        return 0
    fi

    return 1
}

sudo groupadd --system input 2>/dev/null || true
sudo groupadd --system uinput 2>/dev/null || true

sudo usermod -aG input "${targetUser}"
sudo usermod -aG uinput "${targetUser}"

if sudo modprobe uinput; then
    sudo install -d -m 0755 /etc/modules-load.d
    printf 'uinput\n' | sudo tee /etc/modules-load.d/uinput.conf >/dev/null
else
    echo "Could not load uinput with modprobe. Continuing with udev setup." >&2
fi

sudo install -d -m 0755 /etc/udev/rules.d
printf 'KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"\n' \
    | sudo tee /etc/udev/rules.d/99-kanata-uinput.rules >/dev/null

if command -v udevadm >/dev/null 2>&1; then
    sudo udevadm control --reload-rules
    sudo udevadm trigger
else
    echo "Skipping udev reload: udevadm is not available." >&2
fi

if [[ -e /dev/uinput ]]; then
    ls -l /dev/uinput
else
    echo "Warning: /dev/uinput does not exist yet. A reboot may be required." >&2
fi

if ! command -v kanata >/dev/null 2>&1 && [[ ! -x "${targetHome}/.cargo/bin/kanata" ]]; then
    echo "Kanata binary not found. Permission setup is complete; skipping user service setup."
    echo "Log out and back in before running Kanata so group membership is active."
    exit 0
fi

if ! kanataConfig="$(find_kanata_config)"; then
    echo "No Kanata config found at ~/.config/kanata/config.kbd or ~/.config/kanata/kanata.kbd."
    echo "Permission setup is complete; skipping user service setup."
    echo "Set KANATA_CONFIG=/path/to/config.kbd and rerun this script to create the user service."
    echo "Log out and back in before running Kanata so group membership is active."
    exit 0
fi

serviceConfig="${kanataConfig}"
if [[ "${kanataConfig}" == "${targetHome}/"* ]]; then
    serviceConfig="%h/${kanataConfig#"${targetHome}/"}"
fi

serviceDir="${targetHome}/.config/systemd/user"
serviceFile="${serviceDir}/kanata.service"

sudo install -d -m 0755 -o "${targetUser}" -g "${targetGroup}" "${serviceDir}"
sudo tee "${serviceFile}" >/dev/null <<EOF
[Unit]
Description=Kanata keyboard remapper
Documentation=https://github.com/jtroo/kanata

[Service]
Environment=PATH=%h/.cargo/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/bin
Type=simple
ExecStart=/usr/bin/env kanata --cfg ${serviceConfig} --no-wait
Restart=on-failure
RestartSec=3

[Install]
WantedBy=default.target
EOF
sudo chown "${targetUser}:${targetGroup}" "${serviceFile}"

if command -v systemctl >/dev/null 2>&1 && run_user_systemctl daemon-reload; then
    if run_user_systemctl enable kanata.service; then
        echo "Kanata user service enabled. It will start after the next login."
    else
        echo "Kanata service file created, but enabling it failed." >&2
    fi

    if [[ "${KANATA_START_SERVICE:-N}" == "Y" ]]; then
        run_user_systemctl start kanata.service || echo "Could not start Kanata service now. Log out and back in, then start it manually." >&2
    fi
else
    echo "Kanata service file created at ${serviceFile}."
    echo "Run 'systemctl --user daemon-reload && systemctl --user enable kanata.service' after login."
fi

echo "Kanata setup complete. Log out and back in before using Kanata so group membership is active."
