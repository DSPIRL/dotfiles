#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export HOME="$tmp" XDG_RUNTIME_DIR="$tmp" HYPRLAND_INSTANCE_SIGNATURE=test PATH="$tmp/bin:$PATH" TEST_DIR="$tmp"
mkdir "$tmp/bin"
script="$root/dot_config/hypr/scripts/executable_dropdown-terminal.sh"
cat >"$tmp/bin/hyprctl" <<'MOCK'
#!/usr/bin/env bash
if [[ $1 == -j ]]; then
  [[ ! -e "$TEST_DIR/ipc-hang" ]] || sleep 3
  [[ ! -e "$TEST_DIR/ipc-fail" ]] || exit 1
  if [[ -e "$TEST_DIR/response" ]]; then
    printf '%s' "$(<"$TEST_DIR/response")"
  elif [[ -e "$TEST_DIR/window" ]]; then printf '[{"initialClass":"dropdown-alacritty","mapped":true,"workspace":{"name":"special:dropdown"}}]'; else printf '[]'; fi
else
  [[ ! -e "$TEST_DIR/dispatch-fail" ]] || exit 1
  printf '%s\n' "$*" >>"$TEST_DIR/dispatches"
fi
MOCK
cat >"$tmp/bin/alacritty" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$TEST_DIR/launches"
[[ ! -e "$TEST_DIR/exit-early" ]] || exit 1
[[ ! -e "$TEST_DIR/no-map" ]] || { sleep 8; exit; }
[[ ! -e "$TEST_DIR/delay" ]] || sleep 0.7
touch "$TEST_DIR/window"
sleep 0.5
MOCK
chmod +x "$tmp/bin/"*
bash "$script"
bash "$script"
[[ $(wc -l <"$tmp/launches") == 1 ]]
grep -Fx -- '--class dropdown-alacritty' "$tmp/launches" >/dev/null
[[ $(wc -l <"$tmp/dispatches") == 2 ]]
grep -Fx 'dispatch hl.dsp.workspace.toggle_special("dropdown")' "$tmp/dispatches" >/dev/null
rm "$tmp/window"
bash "$script"
[[ $(wc -l <"$tmp/launches") == 2 ]]

# Concurrent presses during delayed mapping are discarded, not queued.
rm "$tmp/window"
touch "$tmp/delay"
bash "$script" & first=$!
sleep 0.2
bash "$script"
wait "$first"
[[ $(wc -l <"$tmp/launches") == 3 && $(wc -l <"$tmp/dispatches") == 4 ]]
rm "$tmp/delay" "$tmp/window"

expect_failure() {
  if bash "$script" 2>"$tmp/error"; then echo 'expected failure' >&2; exit 1; fi
  grep -F "$1" "$tmp/error" >/dev/null
}
touch "$tmp/exit-early"
expect_failure 'exited before mapping'
rm "$tmp/exit-early"
touch "$tmp/no-map"
expect_failure 'did not map within 5 seconds'
rm "$tmp/no-map"
touch "$tmp/ipc-fail"
expect_failure 'cannot query Hyprland clients'
rm "$tmp/ipc-fail"
touch "$tmp/ipc-hang"
expect_failure 'cannot query Hyprland clients'
rm "$tmp/ipc-hang"
printf '%s' 'invalid' >"$tmp/response"
expect_failure 'invalid Hyprland clients response'
printf '%s' '[{"initialClass":"dropdown-alacritty","mapped":true,"workspace":{"name":"1"}}]' >"$tmp/response"
expect_failure 'not uniquely on special:dropdown'
printf '%s' '[{"initialClass":"dropdown-alacritty","mapped":false}]' >"$tmp/response"
expect_failure 'exists but is not mapped'
printf '%s' '[{"initialClass":"dropdown-alacritty","mapped":true,"workspace":{"name":"special:dropdown"}}]' >"$tmp/response"
touch "$tmp/dispatch-fail"
expect_failure 'cannot toggle special:dropdown'
rm "$tmp/response" "$tmp/dispatch-fail"
# Run the real switcher against synthetic clients; no Rofi or compositor actions.
cat >"$tmp/bin/pgrep" <<'MOCK'
#!/usr/bin/env bash
exit 1
MOCK
cat >"$tmp/bin/hyprctl" <<'MOCK'
#!/usr/bin/env bash
printf '%s' '[{"mapped":true,"workspace":{"id":1,"name":"1"},"class":"Alacritty","initialClass":"Alacritty","title":"normal","address":"0x1"},{"mapped":true,"workspace":{"id":-99,"name":"special:dropdown"},"class":"dropdown-alacritty","initialClass":"dropdown-alacritty","title":"secret","address":"0x2"}]'
MOCK
cat >"$tmp/bin/rofi" <<'MOCK'
#!/usr/bin/env bash
tee "$TEST_DIR/rows" >/dev/null
exit 1
MOCK
chmod +x "$tmp/bin/"*
bash "$root/dot_config/hypr/scripts/executable_rofi-windows.sh"
grep -F 'normal' "$tmp/rows" >/dev/null
! grep -F 'secret' "$tmp/rows" >/dev/null
lua "$root/tests/dropdown-terminal.lua"
echo 'Dropdown terminal mocked checks passed'
