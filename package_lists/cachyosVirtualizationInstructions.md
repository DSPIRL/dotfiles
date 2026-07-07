# CachyOS VM Host Setup

The CachyOS installer can install `cachyosVMPackages.txt` and run `install_scripts/modules/executable_vm_host.sh` when VM host tools are selected.

## Automated Setup

The VM host module runs these steps:

```sh
sudo systemctl enable --now libvirtd.service
sudo usermod -aG libvirt "$USER"
sudo virsh net-autostart default
sudo virsh net-start default
```

Log out and back in after the installer finishes so the new `libvirt` group membership is active.

## Virt Manager Settings

- Under Edit > Preferences, enable XML editing.
- Under Edit > Connection Details, confirm that the default connection is active.

## Creating VMs

- Select "Customize configuration before install."
- Use UEFI firmware when available.
- Set SATA Disk Bus to VirtIO.
- Set NIC Device model to VirtIO.
- For Windows guests, add a TPM if required by the Windows version.

## Windows Guests

- Download the latest VirtIO driver ISO from `https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio`.
- Add the ISO as CDROM hardware before installation.
- Load VirtIO storage and network drivers from the ISO during Windows setup when needed.
