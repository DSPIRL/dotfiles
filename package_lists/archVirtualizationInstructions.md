## Service Setup
Setup the service with systemd
```sh
sudo systemctl enable libvirtd
sudo systemctl start libvirtd
```
## Edit the libvirtd.conf
```sh
sudo vim /etc/libvirt/libvirtd.conf
# Confirm the following lines
unix_sock_group = "libvirt"
unix_sock_ro_perms = "0777"
unix_sock_rw_perms = "0770"
```

## Add user to libvirt group
```sh
sudo usermod -aG libvirt $(whoami)
```

## Restart libvirtd service
```sh
sudo systemctl restart libvirtd
```

## Setup Virt Manager settings
- Under Edit > Preferences, enable XML editing
- Under Edit > Connection Details, confirm that the State is active and everything looks right

## Creating VM
- When creating a VM, always select "Customize configuration before install."
- Under the `<clock>` section, delete the `<timer name="rtc">` and `<timer name="pit">` lines
- Change `<timer name="hpet" present="no">` to `<... present="yes">`
- Set number of Sockets to 1
- Set number of Cores to however many cores you want the CPU to have
- Set SATA Disk Bus to VirtIO
- Set NIC Device model to VirtIO

## Windows
- On windows you will need something special for virtualization
- `https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio`
- Download the newest
- Add hardware > CDROM and select downloaded ISO
```
