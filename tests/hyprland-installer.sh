#!/usr/bin/env bash
# Exercise the real installer with an isolated HOME and mocked system commands.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
# The installer deliberately refuses other distributions.
source /etc/os-release
if [[ "${ID:-}" != cachyos ]]; then
  echo 'Installer checks require CachyOS; OS rejection can be checked separately.'
  exit 0
fi
sandbox=$(mktemp -d)
trap 'rm -rf "$sandbox"' EXIT
export HOME="$sandbox/home" STUB_CALLS="$sandbox/calls"
dots="$HOME/.local/share/chezmoi"
mkdir -p "$sandbox/bin" "$dots/package_lists" "$dots/install_scripts/modules" "$dots/dot_config/hypr/scripts" "$HOME/.config/hypr/scripts" "$HOME/.config/hypr/config"
printf 'return { enabled = true }\n' >"$HOME/.config/hypr/config/opacity-toggle.lua"
cp "$root/package_lists/cachyosHyprlandPackages.txt" "$dots/package_lists/"

for module in backlight greetd kwallet; do
  printf '#!/usr/bin/env bash\nprintf "module %%s\\n" "${0##*/}" >>"$STUB_CALLS"\n' >"$dots/install_scripts/modules/executable_$module.sh"
done
for name in paru sudo chezmoi; do
  printf '#!/usr/bin/env bash\nprintf "%%s %%s\\n" "${0##*/}" "$*" >>"$STUB_CALLS"\nif [[ "${0##*/}" == paru && "${FAIL_INSTALL:-0}" == 1 ]]; then exit 42; fi\n' >"$sandbox/bin/$name"
  chmod +x "$sandbox/bin/$name"
done
for script in desktop-settings quickshell-healthcheck; do
  printf '#!/usr/bin/env bash\nprintf "%%s %%s\\n" "${0##*/}" "$*" >>"$STUB_CALLS"\n' >"$HOME/.config/hypr/scripts/$script.sh"
done
cp "$HOME/.config/hypr/scripts/desktop-settings.sh" "$dots/dot_config/hypr/scripts/executable_desktop-settings.sh"
export PATH="$sandbox/bin:$PATH"
bash "$root/install_scripts/executable_hyprland_install.sh"
grep -q 'paru -S --needed .*blueman' "$STUB_CALLS"
grep -q 'paru -S --needed .*pavucontrol' "$STUB_CALLS"
grep -q 'paru -S --needed .*hypridle' "$STUB_CALLS"
grep -q 'module executable_greetd.sh' "$STUB_CALLS"
grep -q "chezmoi apply $HOME/.config/hypr $HOME/.config/quickshell" "$STUB_CALLS"
grep -q "$HOME/.local/scripts/wallust-refresh" "$STUB_CALLS"
grep -q 'sudo systemctl enable --now NetworkManager.service' "$STUB_CALLS"
grep -q 'sudo systemctl enable --now bluetooth.service' "$STUB_CALLS"
awk '/executable_desktop-settings.sh status/ { migration=NR } /chezmoi apply/ { deploy=NR } END { exit !(migration && migration < deploy) }' "$STUB_CALLS"
grep -q 'desktop-settings.sh status' "$STUB_CALLS"
grep -q 'quickshell-healthcheck.sh' "$STUB_CALLS"

: >"$STUB_CALLS"
rm "$HOME/.config/hypr/config/opacity-toggle.lua"
bash "$root/install_scripts/executable_hyprland_install.sh"
if grep -q 'executable_desktop-settings.sh status' "$STUB_CALLS"; then
  echo 'Fresh installs must initialize preferences after deploying defaults' >&2
  exit 1
fi
grep -q 'desktop-settings.sh status' "$STUB_CALLS"

: >"$STUB_CALLS"
if FAIL_INSTALL=1 bash "$root/install_scripts/executable_hyprland_install.sh"; then
  echo 'Expected package installation failure to abort setup' >&2
  exit 1
fi
[[ $(wc -l <"$STUB_CALLS") == 1 ]]
echo 'Installer checks passed; no real packages, deployment, or services changed'
