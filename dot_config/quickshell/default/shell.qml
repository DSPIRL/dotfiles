//@ pragma UseQApplication

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Notifications

import "components"

ShellRoot {
  id: shellRoot

  property int notificationToggleGeneration: 0
  property int controlToggleGeneration: 0

  readonly property string ddcBrightnessCommand: "if ! command -v ddcutil >/dev/null 2>&1; then exit 127; fi; " +
    "ddcutil detect --terse 2>/dev/null | awk '" +
    "/^Display[[:space:]]+[0-9]+/ { if (display != \"\") print display \";\" connector \";\" monitor; display=$2; connector=\"\"; monitor=\"\" } " +
    "/DRM connector:/ { connector=$3 } " +
    "/Monitor:/ { sub(/^[[:space:]]*Monitor:[[:space:]]*/, \"\"); monitor=$0 } " +
    "END { if (display != \"\") print display \";\" connector \";\" monitor }' | " +
    "while IFS=';' read -r display connector monitor; do " +
    "[ -n \"$display\" ] || continue; " +
    "raw=$(ddcutil --display \"$display\" getvcp 10 --brief 2>/dev/null) || continue; " +
    "current=$(printf '%s\\n' \"$raw\" | awk '{print $(NF-1)}'); " +
    "maximum=$(printf '%s\\n' \"$raw\" | awk '{print $NF}'); " +
    "if [ \"$current\" -ge 0 ] 2>/dev/null && [ \"$maximum\" -gt 0 ] 2>/dev/null; then " +
    "printf '%s;%s;%s;%s;%s\\n' \"$display\" \"${connector:-Display $display}\" \"${monitor:-External display}\" \"$current\" \"$maximum\"; " +
    "fi; " +
    "done"

  QtObject {
    id: ddcBrightnessState

    property var displays: []
    property int displayCount: 0
    property bool refreshing: false

    function update(rawText) {
      const text = rawText ? rawText.trim() : "";
      if (text.length === 0) {
        displays = [];
        displayCount = 0;
        return;
      }

      const lines = text.split("\n");
      const nextDisplays = [];

      for (let i = 0; i < lines.length; i += 1) {
        const parts = lines[i].split(";");
        if (parts.length < 5) {
          continue;
        }

        const current = parseInt(parts[3], 10);
        const maximum = parseInt(parts[4], 10);
        if (Number.isNaN(current) || Number.isNaN(maximum) || maximum <= 0) {
          continue;
        }

        nextDisplays.push({
          display: parts[0],
          connector: parts[1],
          monitor: parts[2],
          current: Math.max(0, Math.min(maximum, current)),
          maximum: maximum
        });
      }

      displays = nextDisplays;
      displayCount = nextDisplays.length;
    }

    function updateDisplay(display, current, maximum) {
      const displayId = String(display || "");
      const nextDisplays = [];

      for (let i = 0; i < displays.length; i += 1) {
        const item = displays[i];
        if (String(item.display) === displayId) {
          nextDisplays.push({
            display: item.display,
            connector: item.connector,
            monitor: item.monitor,
            current: current,
            maximum: maximum
          });
          continue;
        }

        nextDisplays.push(item);
      }

      displays = nextDisplays;
      displayCount = nextDisplays.length;
    }

    function refresh() {
      if (!ddcBrightnessProcess.running) {
        ddcBrightnessProcess.running = true;
      }
    }

    function setBrightness(display, percent, maximum) {
      const displayId = String(display || "");
      if (displayId.length === 0) {
        return;
      }

      const maxValue = Math.max(1, parseInt(maximum, 10) || 100);
      const nextPercent = Math.max(0, Math.min(100, Math.round(percent)));
      const nextValue = Math.max(0, Math.min(maxValue, Math.round((nextPercent / 100) * maxValue)));

      Quickshell.execDetached(["ddcutil", "--display", displayId, "setvcp", "10", String(nextValue)]);
      updateDisplay(displayId, nextValue, maxValue);
      ddcBrightnessRefreshAfterSetTimer.restart();
    }
  }

  Process {
    id: ddcBrightnessProcess

    command: ["sh", "-c", shellRoot.ddcBrightnessCommand]

    stdout: StdioCollector {
      id: ddcBrightnessStdout
      waitForEnd: true
    }

    onRunningChanged: ddcBrightnessState.refreshing = running

    onExited: function(exitCode, exitStatus) {
      if (exitCode !== 0) {
        ddcBrightnessState.displays = [];
        return;
      }

      ddcBrightnessState.update(ddcBrightnessStdout.text);
    }
  }

  Timer {
    interval: 60000
    running: true
    repeat: true
    triggeredOnStart: true

    onTriggered: ddcBrightnessState.refresh()
  }

  Timer {
    id: ddcBrightnessRefreshAfterSetTimer

    interval: 1500
    repeat: false

    onTriggered: ddcBrightnessState.refresh()
  }

  NotificationServer {
    id: notificationServer

    keepOnReload: true
    persistenceSupported: true
    bodySupported: true
    bodyMarkupSupported: true
    bodyHyperlinksSupported: false
    bodyImagesSupported: true
    actionsSupported: true
    actionIconsSupported: false
    imageSupported: true
    inlineReplySupported: true

    onNotification: function(notification) {
      notification.tracked = true;
    }
  }

  IpcHandler {
    target: "notifications"

    function toggle(): void {
      notificationToggleGeneration += 1;
    }
  }

  IpcHandler {
    target: "control"

    function toggle(): void {
      controlToggleGeneration += 1;
    }
  }

  Variants {
    model: Quickshell.screens

    BarWindow {
      property var modelData
      screen: modelData
      notifications: notificationServer
      notificationToggleGeneration: shellRoot.notificationToggleGeneration
      controlToggleGeneration: shellRoot.controlToggleGeneration
      focusedHyprMonitor: Hyprland.focusedMonitor
      ddcBrightnessState: ddcBrightnessState
    }
  }
}
