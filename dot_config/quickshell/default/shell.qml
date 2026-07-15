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

  readonly property string ddcBrightnessCommand: "if ! command -v ddcutil >/dev/null 2>&1; then printf '__QS_DDC_MISSING__\\n'; exit 0; fi; " +
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

  readonly property string laptopBrightnessCommand: "if ! ls /sys/class/backlight/* >/dev/null 2>&1; then exit 0; fi; " +
    "if ! command -v brightnessctl >/dev/null 2>&1; then printf '__QS_BACKLIGHT_MISSING__\\n'; exit 0; fi; " +
    "brightnessctl --class=backlight --machine-readable info 2>/dev/null"

  QtObject {
    id: ddcState

    property var displays: []
    property int displayCount: 0
    property bool refreshing: false
    property string error: ""

    function update(rawText) {
      const text = rawText ? rawText.trim() : "";
      error = "";

      if (text === "__QS_DDC_MISSING__") {
        displays = [];
        displayCount = 0;
        error = "ddcutil is not installed";
        return;
      }

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

  QtObject {
    id: laptopState

    property string device: ""
    property int current: 0
    property int maximum: 100
    property int percent: 0
    property bool available: false
    property bool missingTool: false
    property bool checked: false
    property bool refreshing: false

    function clear() {
      device = "";
      current = 0;
      maximum = 100;
      percent = 0;
      available = false;
    }

    function update(rawText) {
      const text = rawText ? rawText.trim() : "";
      checked = true;
      missingTool = false;

      if (text === "__QS_BACKLIGHT_MISSING__") {
        clear();
        missingTool = true;
        return;
      }

      if (text.length === 0) {
        clear();
        return;
      }

      const line = text.split("\n")[0];
      const parts = line.split(",");
      if (parts.length < 5) {
        clear();
        return;
      }

      const parsedCurrent = parseInt(parts[2], 10);
      const parsedPercent = parseInt(parts[3].replace("%", ""), 10);
      const parsedMaximum = parseInt(parts[4], 10);

      if (Number.isNaN(parsedCurrent) || Number.isNaN(parsedMaximum) || parsedMaximum <= 0) {
        clear();
        return;
      }

      device = parts[0];
      current = Math.max(0, Math.min(parsedMaximum, parsedCurrent));
      maximum = parsedMaximum;
      percent = Number.isNaN(parsedPercent) ? Math.round((current / maximum) * 100) : Math.max(0, Math.min(100, parsedPercent));
      available = true;
    }

    function refresh() {
      if (!laptopBrightnessProcess.running) {
        laptopBrightnessProcess.running = true;
      }
    }

    function setBrightness(percentValue) {
      if (!available) {
        return;
      }

      const nextPercent = Math.max(0, Math.min(100, Math.round(percentValue)));
      const nextMaximum = Math.max(1, maximum || 100);
      const nextCurrent = Math.max(0, Math.min(nextMaximum, Math.round((nextPercent / 100) * nextMaximum)));

      Quickshell.execDetached(["brightnessctl", "--class=backlight", "set", String(nextPercent) + "%"]);
      current = nextCurrent;
      percent = nextPercent;
      maximum = nextMaximum;
      available = true;
      laptopBrightnessRefreshAfterSetTimer.restart();
    }
  }

  Process {
    id: ddcBrightnessProcess

    command: ["sh", "-c", shellRoot.ddcBrightnessCommand]

    stdout: StdioCollector {
      id: ddcBrightnessStdout
      waitForEnd: true
    }

    onRunningChanged: ddcState.refreshing = running

    onExited: function(exitCode, exitStatus) {
      if (exitCode !== 0) {
        ddcState.displays = [];
        ddcState.displayCount = 0;
        ddcState.error = "DDC scan failed";
        return;
      }

      ddcState.update(ddcBrightnessStdout.text);
    }
  }

  Process {
    id: laptopBrightnessProcess

    command: ["sh", "-c", shellRoot.laptopBrightnessCommand]

    stdout: StdioCollector {
      id: laptopBrightnessStdout
      waitForEnd: true
    }

    onRunningChanged: laptopState.refreshing = running

    onExited: function(exitCode, exitStatus) {
      if (exitCode !== 0) {
        laptopState.checked = true;
        laptopState.clear();
        return;
      }

      laptopState.update(laptopBrightnessStdout.text);
    }
  }

  Timer {
    interval: 60000
    running: true
    repeat: true
    triggeredOnStart: true

    onTriggered: ddcState.refresh()
  }

  Timer {
    interval: 60000
    running: true
    repeat: true
    triggeredOnStart: true

    onTriggered: laptopState.refresh()
  }

  Timer {
    id: ddcBrightnessRefreshAfterSetTimer

    interval: 1500
    repeat: false

    onTriggered: ddcState.refresh()
  }

  Timer {
    id: laptopBrightnessRefreshAfterSetTimer

    interval: 1500
    repeat: false

    onTriggered: laptopState.refresh()
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
      ddcBrightnessState: ddcState
      laptopBrightnessState: laptopState
    }
  }
}
