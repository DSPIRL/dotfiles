#!/usr/bin/env nu

sudo launchctl bootout system /Library/LaunchDaemons/com.example.kanata.plist
sudo launchctl bootout system /Library/LaunchDaemons/com.example.karabiner-vhiddaemon.plist
sudo launchctl bootout system /Library/LaunchDaemons/com.example.karabiner-vhidmanager.plist
sudo launchctl disable system/com.example.kanata
sudo launchctl disable system/com.example.karabiner-vhiddaemon
sudo launchctl disable system/com.example.karabiner-vhidmanager
