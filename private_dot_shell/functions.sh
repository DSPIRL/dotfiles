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
