import QtQuick
import Quickshell.Io
import QtQuick.Controls
import "../.." as Style

Column {
  id: root
  required property var bar
  required property var wallust
  readonly property var desktop: bar.desktopState
  readonly property bool ready: desktop.loaded && !desktop.busy
  spacing: 12
  property double lastUpdatesCheck: 0
  function refreshUpdates(force) {
    if (updatesProcess.running || (!force && Date.now() - lastUpdatesCheck < 900000)) return;
    lastUpdatesCheck = Date.now();
    updatesProcess.running = true;
  }
  QtObject {
    id: utilityState

    property int cpuUsage: 0
    property int memoryUsage: 0
    property int temperature: 0
    property bool hasTemperature: false
    property int updatesCount: -1
  }

  Process {
    id: utilityStatsProcess

    command: [
      "sh",
      "-c",
      "read -r _ u1 n1 s1 i1 w1 q1 sq1 st1 _ < /proc/stat; t1=$((u1+n1+s1+i1+w1+q1+sq1+st1)); id1=$((i1+w1)); sleep 0.2; read -r _ u2 n2 s2 i2 w2 q2 sq2 st2 _ < /proc/stat; t2=$((u2+n2+s2+i2+w2+q2+sq2+st2)); id2=$((i2+w2)); dt=$((t2-t1)); did=$((id2-id1)); if [ $dt -gt 0 ]; then cpu=$(( (100*(dt-did))/dt )); else cpu=0; fi; memTotal=$(grep -m1 '^MemTotal:' /proc/meminfo | tr -s ' ' | cut -d' ' -f2); memAvail=$(grep -m1 '^MemAvailable:' /proc/meminfo | tr -s ' ' | cut -d' ' -f2); memTotal=${memTotal:-0}; memAvail=${memAvail:-0}; if [ $memTotal -gt 0 ] 2>/dev/null; then mem=$(( (100*(memTotal-memAvail))/memTotal )); else mem=0; fi; temp=-1; for f in /sys/class/thermal/thermal_zone*/temp; do if [ -r $f ]; then raw=$(cat $f); if [ $raw -gt 0 ] 2>/dev/null; then temp=$((raw/1000)); break; fi; fi; done; printf '%s;%s;%s\n' $cpu $mem $temp"
    ]

    stdout: StdioCollector {
      id: utilityStatsStdout
      waitForEnd: true
    }

    onExited: function(exitCode, exitStatus) {
      if (exitCode !== 0) {
        return;
      }

      const line = utilityStatsStdout.text.trim();
      const parts = line.split(";");
      if (parts.length < 3) {
        return;
      }

      utilityState.cpuUsage = parseInt(parts[0], 10) || 0;
      utilityState.memoryUsage = parseInt(parts[1], 10) || 0;

      const parsedTemp = parseInt(parts[2], 10);
      utilityState.hasTemperature = !Number.isNaN(parsedTemp) && parsedTemp >= 0;
      utilityState.temperature = utilityState.hasTemperature ? parsedTemp : 0;
    }
  }

  Timer {
    interval: 8000
    running: root.visible
    repeat: true
    triggeredOnStart: true

    onTriggered: if (!utilityStatsProcess.running) {
      utilityStatsProcess.running = true;
    }
  }

  Process {
    id: updatesProcess

    command: ["sh", "-c", "command -v checkupdates >/dev/null 2>&1 || exit 1; updates=$(checkupdates 2>/dev/null); code=$?; if [ \"$code\" -eq 2 ]; then echo 0; elif [ \"$code\" -eq 0 ]; then printf '%s\\n' \"$updates\" | wc -l; else exit \"$code\"; fi"]

    stdout: StdioCollector {
      id: updatesStdout
      waitForEnd: true
    }

    onExited: function(exitCode, exitStatus) {
      if (exitCode !== 0) {
        utilityState.updatesCount = -1;
        return;
      }

      const parsed = parseInt(updatesStdout.text.trim(), 10);
      utilityState.updatesCount = Number.isNaN(parsed) ? -1 : parsed;
    }
  }

  Timer {
    interval: 900000
    running: root.visible
    repeat: true
    triggeredOnStart: true

    onTriggered: root.refreshUpdates(false)
  }

  Row {
    width: parent.width
    spacing: 8
    Repeater {
      model: ["CPU", "RAM", "TEMP"]
      ControlButton {
        required property var modelData
        width: (root.width - 16) / 3
        wallust: root.wallust
        text: modelData === "CPU" ? utilityState.cpuUsage + "%" : modelData === "RAM" ? utilityState.memoryUsage + "%" : utilityState.hasTemperature ? utilityState.temperature + "°C" : "—"
        font: Style.Typography.controlMetricFont
        subtitle: modelData
        Accessible.name: modelData + " " + text + ". Open system monitor"
        onClicked: root.bar.launchTerminal("btop -p 2")
      }
    }
  }
  Row {
    width: parent.width
    spacing: 8
    ControlButton {
      width: parent.width - refreshUpdates.width - 8
      wallust: root.wallust
      symbol: "󰚰"
      text: "Software updates  ›"
      subtitle: updatesProcess.running ? "Checking…" : utilityState.updatesCount < 0 ? "Check unavailable · try Refresh" : utilityState.updatesCount + " available"
      onClicked: {
        root.bar.launchTerminalShell("if command -v paru >/dev/null 2>&1; then paru -Syu; else sudo pacman -Syu; fi");
        root.bar.controlPanelOpen = false;
      }
    }
    ControlButton {
      id: refreshUpdates
      width: Math.min(parent.width / 2, Math.max(76, implicitWidth))
      height: Math.max(68, implicitHeight)
      wallust: root.wallust
      text: "Refresh"
      enabled: !updatesProcess.running
      onClicked: root.refreshUpdates(true)
    }
  }
  ControlButton {
    width: parent.width; wallust: root.wallust; text: "Reload Hyprland"; symbol: "󰑐"
    enabled: root.ready
    onClicked: root.desktop.run(["hyprctl", "reload"])
  }
  ControlButton {
    width: parent.width; wallust: root.wallust; text: "Reapply monitor configuration"; symbol: "󰍹"
    enabled: root.ready
    onClicked: root.desktop.run(["hyprctl", "repl", "require('config.monitors').apply()"])
  }
  ControlButton {
    width: parent.width; wallust: root.wallust; text: "Refresh display detection"; symbol: "󰑐"
    onClicked: { root.bar.ddcBrightnessState.refresh(); root.bar.laptopBrightnessState.refresh(); }
  }
  ControlButton {
    width: parent.width; wallust: root.wallust; text: "Bar diagnostics"; symbol: "󰒋"
    enabled: root.ready
    onClicked: root.desktop.run([root.desktop.scripts + "quickshell-healthcheck.sh"])
  }
}
