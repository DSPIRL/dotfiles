#!/usr/bin/env bash

set -u

sudo install -d -m 0755 /etc/greetd

sudo tee /etc/greetd/config.toml >/dev/null <<'EOF'
[terminal]
vt = 1

[default_session]
command = "/usr/bin/tuigreet --time --remember --remember-session --sessions /usr/share/wayland-sessions --xsessions /usr/share/xsessions"
user = "greeter"
EOF

sudo systemctl disable plasmalogin.service >/dev/null 2>&1 || true
sudo systemctl disable sddm.service >/dev/null 2>&1 || true
sudo systemctl set-default graphical.target
sudo systemctl enable greetd.service
