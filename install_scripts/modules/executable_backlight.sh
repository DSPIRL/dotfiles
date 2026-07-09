#!/usr/bin/env bash

set -u

if [[ "$(uname -s)" != "Linux" ]]; then
    echo "Backlight setup is only supported on Linux."
    exit 0
fi

shopt -s nullglob
backlightDevices=(/sys/class/backlight/*)

if ((${#backlightDevices[@]} == 0)); then
    echo "No backlight devices found; skipping backlight setup."
    exit 0
fi

targetUser="${SUDO_USER:-$(id -un)}"

if ! id "${targetUser}" >/dev/null 2>&1; then
    echo "Backlight setup target user does not exist: ${targetUser}" >&2
    exit 1
fi

if ! getent group video >/dev/null 2>&1; then
    sudo groupadd --system video
fi

if [[ " $(id -nG "${targetUser}") " != *" video "* ]]; then
    sudo usermod -aG video "${targetUser}"
    echo "Added ${targetUser} to the video group. Log out and back in before using brightness keys."
fi

sudo install -d -m 0755 /etc/udev/rules.d

{
    for devicePath in "${backlightDevices[@]}"; do
        device="${devicePath##*/}"
        printf 'ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="%s", RUN+="/usr/bin/chgrp video /sys/class/backlight/%s/brightness"\n' "${device}" "${device}"
        printf 'ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="%s", RUN+="/usr/bin/chmod g+w /sys/class/backlight/%s/brightness"\n' "${device}" "${device}"
    done
} | sudo tee /etc/udev/rules.d/90-backlight.rules >/dev/null

if command -v udevadm >/dev/null 2>&1; then
    sudo udevadm control --reload-rules
    sudo udevadm trigger --subsystem-match=backlight --action=add
else
    echo "Skipping udev reload: udevadm is not available." >&2
fi

echo "Backlight setup complete."
