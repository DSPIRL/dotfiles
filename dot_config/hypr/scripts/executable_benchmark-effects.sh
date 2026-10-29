#!/usr/bin/env bash
# Compare the live Hyprland desktop with low-effects disabled and enabled.
set -euo pipefail
umask 077

usage() {
  cat <<EOF
Usage: ${0##*/} [--quick] [--rounds N] [--battery-seconds N] [--no-battery]

Runs interleaved saved-effects and low-effects measurements, prints comparison
tables, and saves raw results under
${XDG_STATE_HOME:-~/.local/state}/hypr/benchmarks/. On normal completion it
verifies restoration of the original workspace and effects mode.

Options:
  --quick                Short defaults suitable for checking the script;
                         explicit options still override them
  --rounds N             Paired rounds per mode (default: 4)
  --battery-seconds N    Stationary battery sample seconds per mode/round
                         (default: 30; use 0 or at least 10)
  --no-battery           Skip battery measurements
  -h, --help             Show this help

For comparable battery results, unplug AC power, keep brightness fixed, close
unrelated busy applications, and do not use the desktop during the test. The
script holds an idle inhibitor so automatic locking and blanking do not
interrupt the benchmark. Forced termination can prevent state restoration.
EOF
}

original_args=("$@")
quick=false
rounds_override=
battery_seconds_override=
while (($#)); do
  case "$1" in
    --quick) quick=true ;;
    --rounds)
      [[ $# -ge 2 ]] || { printf 'Missing value for --rounds\n' >&2; exit 2; }
      rounds_override=$2; shift
      ;;
    --battery-seconds)
      [[ $# -ge 2 ]] || { printf 'Missing value for --battery-seconds\n' >&2; exit 2; }
      battery_seconds_override=$2; shift
      ;;
    --no-battery) battery_seconds_override=0 ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

if $quick; then
  rounds=1
  battery_seconds=10
  transition_count=30
  app_runs=3
  idle_seconds=3
else
  rounds=4
  battery_seconds=30
  transition_count=80
  app_runs=5
  idle_seconds=6
fi
[[ -z "$rounds_override" ]] || rounds=$rounds_override
[[ -z "$battery_seconds_override" ]] || battery_seconds=$battery_seconds_override
[[ "$rounds" =~ ^[1-9][0-9]*$ ]] || { printf 'Rounds must be a positive integer\n' >&2; exit 2; }
[[ "$battery_seconds" =~ ^[0-9]+$ ]] || { printf 'Battery seconds must be a non-negative integer\n' >&2; exit 2; }
((battery_seconds == 0 || battery_seconds >= 10)) || { printf 'Battery samples must be at least 10 seconds\n' >&2; exit 2; }

if command -v systemd-inhibit >/dev/null 2>&1 && [[ ${HYPR_EFFECTS_BENCHMARK_INHIBITED:-0} != 1 ]]; then
  exec env HYPR_EFFECTS_BENCHMARK_INHIBITED=1 systemd-inhibit \
    --what=idle --mode=block --who=hypr-effects-benchmark \
    --why='Prevent idle locking during the compositor benchmark' \
    bash "$0" "${original_args[@]}"
fi

for command in awk column dd flock hyperfine hyprctl jq sha256sum; do
  command -v "$command" >/dev/null 2>&1 || { printf 'Required command not found: %s\n' "$command" >&2; exit 1; }
done
[[ ${XDG_CURRENT_DESKTOP:-} == *Hyprland* ]] || { printf 'Run this inside the Hyprland session\n' >&2; exit 1; }

settings="$HOME/.config/hypr/scripts/desktop-settings.sh"
[[ -x "$settings" ]] || { printf 'Missing executable: %s\n' "$settings" >&2; exit 1; }

state_home=${XDG_STATE_HOME:-$HOME/.local/state}
benchmark_root="$state_home/hypr/benchmarks"
mkdir -p "$benchmark_root"
exec 9>"$benchmark_root/.lock"
flock -n 9 || { printf 'Another effects benchmark is already running\n' >&2; exit 1; }

stamp=$(date +%Y%m%d-%H%M%S)
result_dir="$benchmark_root/$stamp"
mkdir -p "$result_dir"
raw_file="$result_dir/compositor.tsv"
app_file="$result_dir/application.tsv"
report_file="$result_dir/report.txt"
metadata_file="$result_dir/metadata.txt"

hypr_pid=$(hyprctl -j instances | jq -r --arg signature "${HYPRLAND_INSTANCE_SIGNATURE:-}" \
  '.[] | select(.instance == $signature) | .pid' | head -1)
[[ "$hypr_pid" =~ ^[0-9]+$ && -r "/proc/$hypr_pid/stat" ]] || {
  printf 'Cannot identify the current Hyprland process\n' >&2
  exit 1
}
clock_ticks=$(getconf CLK_TCK)
original_low=$($settings low-effects status)
original_workspace=$(hyprctl -j activeworkspace | jq -r '.id')
original_status=$($settings status)

benchmark_workspace=99
while hyprctl -j workspaces | jq -e --argjson id "$benchmark_workspace" '.[] | select(.id == $id)' >/dev/null; do
  benchmark_workspace=$((benchmark_workspace - 1))
  ((benchmark_workspace > 20)) || { printf 'Could not find a spare benchmark workspace\n' >&2; exit 1; }
done

focus_workspace() {
  local workspace=$1
  hyprctl repl "hl.dispatch(hl.dsp.focus({ workspace = $workspace })); return true" >/dev/null
}

restore_state() {
  local failed=0
  focus_workspace "$original_workspace" >/dev/null 2>&1 || failed=1
  if [[ "$original_low" == enabled ]]; then
    "$settings" low-effects enable >/dev/null 2>&1 || failed=1
  else
    "$settings" low-effects disable >/dev/null 2>&1 || failed=1
  fi
  [[ $(hyprctl -j activeworkspace 2>/dev/null | jq -r '.id') == "$original_workspace" ]] || failed=1
  [[ $($settings low-effects status 2>/dev/null) == "$original_low" ]] || failed=1
  return "$failed"
}

cleanup() { restore_state >/dev/null 2>&1 || true; }
trap cleanup EXIT
trap 'exit 130' INT TERM

set_mode() {
  if [[ $1 == low ]]; then
    "$settings" low-effects enable
  else
    "$settings" low-effects disable
  fi
  sleep 2
}

cpu_ticks() {
  awk '{print $14 + $15}' "/proc/$hypr_pid/stat"
}

gpu_ns() {
  local file
  for file in /proc/"$hypr_pid"/fdinfo/*; do
    awk '
      /^drm-client-id:/ { id=$2 }
      /^drm-engine-render:/ { render=$2 + 0 }
      END { if (id != "") printf "%s %.0f\n", id, render }
    ' "$file" 2>/dev/null || true
  done | awk '{ found=1; if ($2 > max[$1]) max[$1]=$2 } END {
    if (!found) exit 1
    for (id in max) sum += max[id]
    printf "%.0f\n", sum
  }'
}

system_ticks() {
  awk '/^cpu / { total=0; for (i=2; i<=NF; i++) total += $i; print total, $5 + $6 }' /proc/stat
}

battery_dir=
for candidate in /sys/class/power_supply/*; do
  [[ -r "$candidate/type" ]] || continue
  [[ $(<"$candidate/type") == Battery ]] || continue
  battery_dir=$candidate
  break
done

ac_online() {
  local supply value
  for supply in /sys/class/power_supply/*; do
    [[ -r "$supply/type" && -r "$supply/online" ]] || continue
    case $(<"$supply/type") in Mains|USB|USB_C) ;; *) continue ;; esac
    read -r value <"$supply/online"
    [[ "$value" == 1 ]] && return 0
  done
  return 1
}

battery_power_uw() {
  [[ -n "$battery_dir" && -r "$battery_dir/status" ]] || return 1
  [[ $(<"$battery_dir/status") == Discharging ]] || return 1
  ! ac_online || return 1
  if [[ -r "$battery_dir/power_now" ]]; then
    local power
    read -r power <"$battery_dir/power_now"
    [[ "$power" =~ ^[0-9]+$ && "$power" -gt 0 ]] || return 1
    printf '%s\n' "$power"
    return
  fi
  [[ -r "$battery_dir/current_now" && -r "$battery_dir/voltage_now" ]] || return 1
  local current voltage
  read -r current <"$battery_dir/current_now"
  read -r voltage <"$battery_dir/voltage_now"
  [[ "$current" =~ ^[0-9]+$ && "$voltage" =~ ^[0-9]+$ ]] || return 1
  awk -v current="$current" -v voltage="$voltage" 'BEGIN { printf "%.0f\n", current*voltage/1e6 }'
}

battery_energy_uwh() {
  [[ -n "$battery_dir" && -r "$battery_dir/energy_now" ]] || return 1
  local energy
  read -r energy <"$battery_dir/energy_now"
  [[ "$energy" =~ ^[0-9]+$ ]] || return 1
  printf '%s\n' "$energy"
}

battery_enabled=false
battery_note='disabled by option'
if ((battery_seconds > 0)); then
  if [[ -z "$battery_dir" ]]; then
    battery_note='no battery power supply found'
  elif ac_online || [[ $(<"$battery_dir/status") != Discharging ]]; then
    battery_note='battery is not discharging; unplug external power and rerun'
  elif ! battery_power_uw >/dev/null; then
    battery_note='no readable battery power counter found'
  else
    battery_enabled=true
    battery_note='measured during stationary desktop segments'
  fi
fi
if $battery_enabled; then stationary_seconds=$battery_seconds; else stationary_seconds=$idle_seconds; fi

initial_energy_uwh=
initial_energy_full_uwh=
initial_capacity=
if [[ -n "$battery_dir" ]]; then
  initial_energy_uwh=$(battery_energy_uwh 2>/dev/null || true)
  [[ -r "$battery_dir/energy_full" ]] && read -r initial_energy_full_uwh <"$battery_dir/energy_full" || true
  [[ -r "$battery_dir/capacity" ]] && read -r initial_capacity <"$battery_dir/capacity" || true
fi

printf 'round\tmode\tkind\tseconds\thypr_cpu_pct\tgpu_render_pct\tsystem_cpu_pct\thypr_rss_kib\tbattery_power_w\tbattery_energy_w\n' >"$raw_file"
printf 'round\tmode\tmean_seconds\tstddev_seconds\n' >"$app_file"

measure_compositor() {
  local round=$1 mode=$2 kind=$3
  local cpu0 cpu1 gpu0 gpu1 total0 idle0 total1 idle1 time0 time1 elapsed_ns
  local gpu_render_pct= power power_sum=0 power_count=0 expected_power_count=0
  local energy0= energy1= battery_power_w= battery_energy_w=
  local iterations index target

  focus_workspace "$original_workspace"
  sleep 0.6
  cpu0=$(cpu_ticks)
  gpu0=$(gpu_ns 2>/dev/null || true)
  read -r total0 idle0 < <(system_ticks)
  time0=$(date +%s%N)

  if [[ "$kind" == stationary ]]; then
    iterations=$((stationary_seconds * 10))
    $battery_enabled && energy0=$(battery_energy_uwh 2>/dev/null || true)
    for ((index=0; index<iterations; index++)); do
      if $battery_enabled && ((index % 10 == 0)); then
        expected_power_count=$((expected_power_count + 1))
        if power=$(battery_power_uw 2>/dev/null); then
          power_sum=$((power_sum + power))
          power_count=$((power_count + 1))
        fi
      fi
      sleep 0.1
    done
    $battery_enabled && energy1=$(battery_energy_uwh 2>/dev/null || true)
  else
    for ((index=0; index<transition_count; index++)); do
      if ((index % 2 == 0)); then target=$benchmark_workspace; else target=$original_workspace; fi
      focus_workspace "$target"
      sleep 0.1
    done
    focus_workspace "$original_workspace"
    for ((index=0; index<5; index++)); do sleep 0.1; done
  fi

  time1=$(date +%s%N)
  read -r total1 idle1 < <(system_ticks)
  gpu1=$(gpu_ns 2>/dev/null || true)
  cpu1=$(cpu_ticks)
  elapsed_ns=$((time1 - time0))

  if [[ "$gpu0" =~ ^[0-9]+$ && "$gpu1" =~ ^[0-9]+$ ]]; then
    gpu_render_pct=$(awk -v delta=$((gpu1-gpu0)) -v ns="$elapsed_ns" 'BEGIN { print delta/ns*100 }')
  fi
  if ((expected_power_count > 0 && power_count == expected_power_count)); then
    battery_power_w=$(awk -v sum="$power_sum" -v count="$power_count" 'BEGIN { printf "%.3f", sum/count/1e6 }')
  fi
  if [[ "$energy0" =~ ^[0-9]+$ && "$energy1" =~ ^[0-9]+$ ]] && ((energy0 > energy1)); then
    battery_energy_w=$(awk -v delta=$((energy0-energy1)) -v ns="$elapsed_ns" 'BEGIN { printf "%.3f", delta*3600/(ns/1e9)/1e6 }')
  fi

  printf '%s\t%s\t%s\t%.3f\t%.3f\t%s\t%.3f\t%s\t%s\t%s\n' \
    "$round" "$mode" "$kind" \
    "$(awk -v ns="$elapsed_ns" 'BEGIN { print ns/1e9 }')" \
    "$(awk -v delta=$((cpu1-cpu0)) -v hz="$clock_ticks" -v ns="$elapsed_ns" 'BEGIN { print delta/hz/(ns/1e9)*100 }')" \
    "$gpu_render_pct" \
    "$(awk -v total=$((total1-total0)) -v idle=$((idle1-idle0)) 'BEGIN { print (total-idle)/total*100 }')" \
    "$(awk '/VmRSS:/ {print $2}' "/proc/$hypr_pid/status")" \
    "$battery_power_w" "$battery_energy_w" >>"$raw_file"
}

measure_application() {
  local round=$1 mode=$2 json="$result_dir/hyperfine-$round-$mode.json"
  hyperfine --shell=default --warmup 1 --runs "$app_runs" --export-json "$json" \
    'dd if=/dev/zero bs=8M count=64 status=none | sha256sum >/dev/null' \
    >"$result_dir/hyperfine-$round-$mode.log" 2>&1
  jq -r --arg round "$round" --arg mode "$mode" \
    '[$round, $mode, (.results[0].summary.time_wall_clock.mean|tostring), (.results[0].summary.time_wall_clock.stddev|tostring)] | @tsv' \
    "$json" >>"$app_file"
}

printf 'Hyprland effects benchmark\n'
printf 'Results: %s\n' "$result_dir"
printf 'Do not interact with the desktop until the tables appear.\n\n'

for ((round=1; round<=rounds; round++)); do
  if ((round % 2 == 1)); then modes=(full low); else modes=(low full); fi
  for mode in "${modes[@]}"; do
    printf 'Round %d/%d, %s effects: stationary for %ds...\n' "$round" "$rounds" "$mode" "$stationary_seconds"
    set_mode "$mode"
    measure_compositor "$round" "$mode" stationary
    printf 'Round %d/%d, %s effects: %d workspace transitions...\n' "$round" "$rounds" "$mode" "$transition_count"
    measure_compositor "$round" "$mode" transitions
    printf 'Round %d/%d, %s effects: foreground SHA-256 benchmark...\n' "$round" "$rounds" "$mode"
    measure_application "$round" "$mode"
  done
done

if ! restore_state; then
  printf 'Benchmark finished, but the original workspace or effects mode could not be restored.\n' >&2
  exit 1
fi
trap - EXIT INT TERM

final_capacity=
if [[ -n "$battery_dir" && -r "$battery_dir/capacity" ]]; then
  read -r final_capacity <"$battery_dir/capacity"
fi

mean_metric() {
  local file=$1 mode=$2 kind=$3 column=$4
  awk -F '\t' -v mode="$mode" -v kind="$kind" -v column="$column" '
    NR > 1 && $2 == mode && $3 == kind && $column != "" { sum += $column; count++ }
    END { if (count) printf "%.6f", sum/count }
  ' "$file"
}

mean_application() {
  local mode=$1
  awk -F '\t' -v mode="$mode" 'NR > 1 && $2 == mode { sum += $3; count++ } END { if (count) printf "%.6f", sum/count }' "$app_file"
}

percent_change() {
  awk -v full="$1" -v low="$2" 'BEGIN { if (full != 0) printf "%+.1f%%", (low/full-1)*100; else print "n/a" }'
}

format_number() {
  awk -v value="$1" -v digits="$2" 'BEGIN { printf "%.*f", digits, value }'
}

cpu_model=$(lscpu | awk -F: '/Model name/ { sub(/^[[:space:]]+/, "", $2); print $2; exit }')
gpu_model=$(command -v lspci >/dev/null 2>&1 && lspci | awk '/VGA compatible controller|3D controller|Display controller/ { sub(/^.*: /, ""); print; exit }' || true)
monitor_summary=$(hyprctl -j monitors | jq -r '[.[] | "\(.name) \(.width)x\(.height)@\(.refreshRate|floor) scale \(.scale)"] | join(", ")')
hypr_version=$(hyprctl version | head -1)
brightness_summary=unavailable
for backlight in /sys/class/backlight/*; do
  if [[ -r "$backlight/brightness" && -r "$backlight/max_brightness" ]]; then
    read -r brightness <"$backlight/brightness"
    read -r brightness_max <"$backlight/max_brightness"
    brightness_summary=$(awk -v value="$brightness" -v maximum="$brightness_max" 'BEGIN { printf "%.0f%%", value/maximum*100 }')
    break
  fi
done

{
  printf 'timestamp=%s\n' "$stamp"
  printf 'hyprland=%s\n' "$hypr_version"
  printf 'cpu=%s\n' "$cpu_model"
  printf 'gpu=%s\n' "${gpu_model:-unknown}"
  printf 'monitors=%s\n' "$monitor_summary"
  printf 'brightness=%s\n' "$brightness_summary"
  printf 'rounds=%s\n' "$rounds"
  printf 'stationary_seconds=%s\n' "$stationary_seconds"
  printf 'transition_count=%s\n' "$transition_count"
  printf 'application_runs=%s\n' "$app_runs"
  printf 'original_desktop_status=%s\n' "$original_status"
} >"$metadata_file"

compositor_table="$result_dir/compositor-table.tsv"
printf 'Workload\tMetric\tFull effects\tLow effects\tChange\n' >"$compositor_table"
for kind in stationary transitions; do
  if [[ "$kind" == stationary ]]; then workload=Stationary; else workload=Transitions; fi
  for specification in '5|Hyprland CPU (% of one core)|2' '6|GPU render busy (%)|2' '7|Total system CPU (%)|2'; do
    IFS='|' read -r column label digits <<<"$specification"
    full=$(mean_metric "$raw_file" full "$kind" "$column")
    low=$(mean_metric "$raw_file" low "$kind" "$column")
    if [[ -n "$full" && -n "$low" ]]; then
      printf '%s\t%s\t%s\t%s\t%s\n' "$workload" "$label" \
        "$(format_number "$full" "$digits")" "$(format_number "$low" "$digits")" "$(percent_change "$full" "$low")" >>"$compositor_table"
    else
      printf '%s\t%s\tn/a\tn/a\tn/a\n' "$workload" "$label" >>"$compositor_table"
    fi
  done
done

app_full=$(mean_application full)
app_low=$(mean_application low)
app_result=$(awk -v full="$app_full" -v low="$app_low" 'BEGIN {
  change=(low/full-1)*100
  if (change <= 0) printf "%.2f%% faster", -change
  else printf "%.2f%% slower", change
}')

{
  printf 'Hyprland effects benchmark — %s\n\n' "$stamp"
  printf 'System: %s; %s; %s\n' "$cpu_model" "${gpu_model:-unknown GPU}" "$monitor_summary"
  printf 'Brightness: %s. Paired rounds per mode: %d.\n\n' "$brightness_summary" "$rounds"
  printf 'Compositor\n'
  column -t -s $'\t' "$compositor_table"
  printf '\nForeground CPU task\n'
  printf 'Task\tFull effects\tLow effects\tResult\n' >"$result_dir/application-table.tsv"
  printf '512 MiB SHA-256\t%.4f s\t%.4f s\t%s\n' "$app_full" "$app_low" "$app_result" >>"$result_dir/application-table.tsv"
  column -t -s $'\t' "$result_dir/application-table.tsv"
  printf '\nBattery\n'
  if $battery_enabled; then
    power_full=$(mean_metric "$raw_file" full stationary 9)
    power_low=$(mean_metric "$raw_file" low stationary 9)
    energy_full=$(mean_metric "$raw_file" full stationary 10)
    energy_low=$(mean_metric "$raw_file" low stationary 10)
    printf 'Metric\tFull effects\tLow effects\tChange\n' >"$result_dir/battery-table.tsv"
    if [[ -z "$power_full" || -z "$power_low" ]]; then
      printf 'Sampled battery draw\tn/a\tn/a\tincomplete samples\n' >>"$result_dir/battery-table.tsv"
      column -t -s $'\t' "$result_dir/battery-table.tsv"
      printf 'Battery samples became unavailable during the run; runtime estimates were omitted.\n'
    else
      printf 'Sampled battery draw\t%.2f W\t%.2f W\t%s\n' "$power_full" "$power_low" "$(percent_change "$power_full" "$power_low")" >>"$result_dir/battery-table.tsv"
      if ((battery_seconds >= 30)) && [[ -n "$energy_full" && -n "$energy_low" ]]; then
        printf 'Energy-counter draw\t%.2f W\t%.2f W\t%s\n' "$energy_full" "$energy_low" "$(percent_change "$energy_full" "$energy_low")" >>"$result_dir/battery-table.tsv"
      fi
      if [[ "$initial_energy_full_uwh" =~ ^[0-9]+$ && "$initial_energy_full_uwh" -gt 0 ]]; then
        drain_full=$(awk -v power="$power_full" -v energy="$initial_energy_full_uwh" 'BEGIN { printf "%.2f", power/(energy/1e6)*100 }')
        drain_low=$(awk -v power="$power_low" -v energy="$initial_energy_full_uwh" 'BEGIN { printf "%.2f", power/(energy/1e6)*100 }')
        printf 'Drain of full capacity\t%s%%/h\t%s%%/h\t%s\n' "$drain_full" "$drain_low" "$(percent_change "$drain_full" "$drain_low")" >>"$result_dir/battery-table.tsv"
      fi
      if [[ "$initial_energy_uwh" =~ ^[0-9]+$ && "$initial_energy_uwh" -gt 0 ]]; then
        runtime_full=$(awk -v power="$power_full" -v energy="$initial_energy_uwh" 'BEGIN { printf "%.2f", (energy/1e6)/power }')
        runtime_low=$(awk -v power="$power_low" -v energy="$initial_energy_uwh" 'BEGIN { printf "%.2f", (energy/1e6)/power }')
        printf 'Estimated remaining runtime\t%s h\t%s h\t%+.1f%%\n' "$runtime_full" "$runtime_low" \
          "$(awk -v full="$runtime_full" -v low="$runtime_low" 'BEGIN { print (low/full-1)*100 }')" >>"$result_dir/battery-table.tsv"
      fi
      column -t -s $'\t' "$result_dir/battery-table.tsv"
    fi
    printf 'Battery capacity: %s%% → %s%% during the complete benchmark.\n' "${initial_capacity:-unknown}" "${final_capacity:-unknown}"
  else
    printf 'Not measured: %s.\n' "$battery_note"
  fi
  printf '\nNotes\n'
  printf -- '- Full effects means low-effects disabled with your saved blur, opacity, shell, animation, and shadow preferences.\n'
  printf -- '- Battery draw is sampled only during stationary segments; transitions and SHA-256 runs are excluded.\n'
  printf -- '- Short battery tests are noisy. Use --battery-seconds 60 or longer for decisions about small differences.\n'
  printf -- '- Original low-effects mode (%s) and workspace (%s) were restored.\n' "$original_low" "$original_workspace"
  printf '\nRaw results: %s\n' "$result_dir"
} | tee "$report_file"
