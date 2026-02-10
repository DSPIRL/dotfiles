#!/usr/bin/env nu

sudo launchctl bootout system /Library/LaunchDaemons/com.example.kanata.plist
sudo launchctl disable system/com.example.kanata

sudo launchctl enable system/com.example.kanata
sudo launchctl bootstrap system /Library/LaunchDaemons/com.example.kanata.plist
