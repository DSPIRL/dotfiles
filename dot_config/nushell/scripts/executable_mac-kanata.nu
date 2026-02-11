#!/usr/bin/env nu

# Consolidated kanata management script for macOS
# Usage: mac-kanata [start|stop|restart]

def main [action?: string] {
    let services = [
        "com.example.kanata"
        "com.example.karabiner-vhiddaemon"
        "com.example.karabiner-vhidmanager"
    ]

    def start-services [] {
        for svc in $services {
            sudo launchctl enable $"system/($svc)"
        }
        for svc in $services {
            sudo launchctl bootstrap system $"/Library/LaunchDaemons/($svc).plist"
        }
        print "Kanata services started"
    }

    def stop-services [] {
        for svc in $services {
            sudo launchctl bootout system $"/Library/LaunchDaemons/($svc).plist"
        }
        for svc in $services {
            sudo launchctl disable $"system/($svc)"
        }
        print "Kanata services stopped"
    }

    match $action {
        "start" => { start-services }
        "stop" => { stop-services }
        "restart" => {
            stop-services
            start-services
        }
        _ => {
            print "Usage: kanata [start|stop|restart]"
            print ""
            print "Commands:"
            print "  start   - Enable and bootstrap kanata services"
            print "  stop    - Bootout and disable kanata services"
            print "  restart - Stop then start services"
        }
    }
}
