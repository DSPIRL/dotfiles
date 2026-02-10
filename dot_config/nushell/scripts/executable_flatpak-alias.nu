#!/usr/bin/env nu

flatpak list

let varAppId = input "What is the Flatpak Application ID?: "
let varAppName = input "What is the app shorthand name (no caps)?: "

sudo ln -fvs $"/var/lib/flatpak/exports/bin/($varAppId)" $"/usr/bin/($varAppName)"
