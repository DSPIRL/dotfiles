#!/usr/bin/env nu

sudo launchctl enable system/com.example.kanata
sudo launchctl enable system/com.example.karabiner-vhiddaemon
sudo launchctl enable system/com.example.karabiner-vhidmanager
sudo launchctl bootstrap system /Library/LaunchDaemons/com.example.karabiner-vhiddaemon.plist
sudo launchctl bootstrap system /Library/LaunchDaemons/com.example.karabiner-vhidmanager.plist
sudo launchctl bootstrap system /Library/LaunchDaemons/com.example.kanata.plist
