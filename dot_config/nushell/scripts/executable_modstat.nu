#!/usr/bin/env nu

def main [...files] {
    let stat_string_list = (stat -c "%n;%F;%A;%a:" ...$files)
    print ($stat_string_list | split row `:` | split column `;` | str trim | drop 1 | rename "Filename" "Filetype" "Exec Modes" "Hex Values")
}

