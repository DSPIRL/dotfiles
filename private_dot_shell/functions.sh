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
