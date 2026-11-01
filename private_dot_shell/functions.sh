if [[ "$(uname -s)" == Darwin ]]; then
    mac-kanata() {
        local action="${1:-}" svc result=0
        local services=(
            com.example.kanata
            com.example.karabiner-vhiddaemon
            com.example.karabiner-vhidmanager
        )

        if (( $# > 1 )); then
            echo "Usage: mac-kanata [start|stop|restart]" >&2
            return 1
        fi

        case "$action" in
            start)
                for svc in "${services[@]}"; do
                    sudo launchctl enable "system/$svc" || result=$?
                done
                for svc in "${services[@]}"; do
                    sudo launchctl bootstrap system "/Library/LaunchDaemons/$svc.plist" || result=$?
                done
                (( result == 0 )) && echo "Kanata services started"
                ;;
            stop)
                for svc in "${services[@]}"; do
                    sudo launchctl bootout system "/Library/LaunchDaemons/$svc.plist" || result=$?
                done
                for svc in "${services[@]}"; do
                    sudo launchctl disable "system/$svc" || result=$?
                done
                (( result == 0 )) && echo "Kanata services stopped"
                ;;
            restart)
                mac-kanata stop || result=$?
                mac-kanata start || result=$?
                ;;
            *)
                echo "Usage: mac-kanata [start|stop|restart]" >&2
                return 1
                ;;
        esac
        return "$result"
    }
fi

ref_dirinfo() {
    dir="${1:-.}"
    echo "File count:"
    find "$dir" -type f | wc -l
    echo "Total size (GiB):"
    find "$dir" -type f -printf '%s\n' | awk '{total += $1} END {printf "%.2f GB\n", total/1024/1024/1024}'
}

ref_dirinfo2() {
    dir="${1:-.}"
    echo "File count:  $(find "$dir" -type f | wc -l)"
    echo "Total size: $(find "$dir" -type f -print0 | du --files0-from=- -ch | tail -n1)"
}

mp4togif() {
    local input="$1"
    local fps="${2:-15}"
    local width="${3:-720}"
    local dither="${4:-bayer}"
    local output="${input%.mp4}.gif"

    ffmpeg -i "$input" \
        -vf "fps=${fps},scale=${width}:-1:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors=256[p];[s1][p]paletteuse=dither=${dither}" \
        "$output"
}

y() {
    local tmp cwd
    tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
    command yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd <"$tmp"
    [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd" || builtin true
    command rm -f -- "$tmp"
}
