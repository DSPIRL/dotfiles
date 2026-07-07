#!/usr/bin/env bash

set -u

targetUser="${SUDO_USER:-$(id -un)}"

sudo systemctl enable --now libvirtd.service

if getent group libvirt >/dev/null 2>&1; then
    sudo usermod -aG libvirt "${targetUser}"
else
    echo "Skipping libvirt group membership: libvirt group does not exist." >&2
fi

if command -v virsh >/dev/null 2>&1; then
    sudo virsh net-autostart default >/dev/null 2>&1 || true
    sudo virsh net-start default >/dev/null 2>&1 || true
fi

echo "VM host setup complete. Log out and back in before using virt-manager."
