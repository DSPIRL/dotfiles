import QtQuick
import QtQuick.Controls
import QtQuick.Window
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import ".."
import "../.." as Style

PanelWindow {
  id: root
  required property var bar
  required property var wallust
  readonly property var desktop: bar.desktopState
  property bool desktopTab: false
  property bool toolsExpanded: false
  property bool effectsExpanded: false
  property bool sessionOpen: false
  property string confirmation: ""
  readonly property bool ready: desktop.loaded && !desktop.busy

  visible: Boolean(bar.controlPanelOpen)
  implicitWidth: Math.min(440, screen ? screen.width - 24 : 440)
  implicitHeight: Math.min(screen ? screen.height - margins.top - 16 : 740, Math.max(360, body.implicitHeight + Math.max(182, scroll.y + footer.implicitHeight + 34)))
  color: "transparent"
  screen: bar.screen
  focusable: visible
  exclusionMode: ExclusionMode.Ignore
  anchors { top: true; right: true }
  margins { top: bar.barVisible ? bar.height + 12 : 12; right: 12 }
  WlrLayershell.namespace: "quickshell"

  onVisibleChanged: {
    if (!visible) { effectsExpanded = false; sessionOpen = false; confirmation = ""; return; }
    closeButton.forceActiveFocus();
    desktop.refresh();
    if (bar.ddcBrightnessState) bar.ddcBrightnessState.refresh();
    if (bar.laptopBrightnessState) bar.laptopBrightnessState.refresh();
  }

  Connections {
    target: root.bar
    function onSessionRequested() { root.sessionOpen = true; root.confirmation = ""; }
  }
  Connections {
    target: root.contentItem.Window.window
    function onActiveFocusItemChanged() {
      const item = target.activeFocusItem;
      if (!item) return;
      let parent = item;
      while (parent && parent !== scroll.contentItem) parent = parent.parent;
      if (!parent) return;
      const y = item.mapToItem(scroll.contentItem, 0, 0).y;
      if (y < scroll.contentY) scroll.contentY = y;
      else if (y + item.height > scroll.contentY + scroll.height)
        scroll.contentY = Math.min(scroll.contentHeight - scroll.height, y + item.height - scroll.height);
    }
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
    running: root.visible && root.desktopTab && !root.sessionOpen
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
    running: true
    repeat: true
    triggeredOnStart: true

    onTriggered: if (!updatesProcess.running) {
      updatesProcess.running = true;
    }
  }

  // Let the panel disappear before the picker captures the screen.
  Timer {
    id: colorPickerTimer
    interval: 180
    onTriggered: root.bar.runHyprScript("colorpicker.sh")
  }

  component Heading: Text {
    width: parent.width
    font: Style.Typography.controlHeadingFont
    color: root.wallust.barMutedText
  }
  component EffectSlider: Column {
    id: settingRoot
    required property string setting
    required property string label
    property string subtitle: ""
    property string suffix: "%"
    property bool available: true
    readonly property var spec: root.desktop.numericSettings[setting]
    width: parent.width
    spacing: 4
    Text {
      x: 12; width: parent.width - 24
      text: settingRoot.label + " · " + root.desktop[settingRoot.spec.field] + settingRoot.suffix
      font: Style.Typography.controlLabelFont
      color: root.wallust.barText
      wrapMode: Text.Wrap
    }
    ControlSlider {
      x: 12; width: parent.width - 24
      wallust: root.wallust
      from: settingRoot.spec.minimum
      to: settingRoot.spec.maximum
      value: root.desktop[settingRoot.spec.field]
      enabled: root.desktop.loaded && settingRoot.available
      opacity: enabled ? 1 : 0.45
      Accessible.name: settingRoot.label
      onMoved: root.desktop.setNumericSetting(settingRoot.setting, value)
    }
    Text {
      x: 12; width: parent.width - 24
      text: settingRoot.subtitle
      font: Style.Typography.controlHintFont
      color: root.wallust.barMutedText
      wrapMode: Text.Wrap
    }
  }
  component Group: Rectangle {
    default property alias contents: groupContents.data
    width: parent.width
    implicitHeight: groupContents.implicitHeight + 16
    radius: 16
    color: root.wallust.barCard
    border.width: 1
    border.color: root.wallust.barSeparator
    Column {
      id: groupContents
      x: 4; y: 8
      width: parent.width - 8
      spacing: 2
    }
  }

  GlassSurface {
    anchors.fill: parent
    wallust: root.wallust
    radius: 26
    Keys.onEscapePressed: {
      if (root.sessionOpen) { root.sessionOpen = false; root.confirmation = ""; }
      else root.bar.controlPanelOpen = false;
    }

    Row {
      id: header
      x: 20; y: 16
      width: parent.width - 40
      spacing: 8
      Text {
        width: parent.width - closeButton.width - 8
        anchors.verticalCenter: parent.verticalCenter
        text: root.sessionOpen ? "Session" : "Control Center"
        font: Style.Typography.controlTitleFont
        color: root.wallust.barText
      }
      ControlButton {
        id: closeButton
        width: Math.max(40, font.pixelSize + 24)
        wallust: root.wallust
        text: "×"
        Accessible.name: "Close controls"
        onClicked: root.bar.controlPanelOpen = false
      }
    }
    Row {
      id: tabs
      x: 20; y: header.y + header.implicitHeight + 10
      width: parent.width - 40
      spacing: 6
      visible: !root.sessionOpen
      ControlButton {
        width: (parent.width - 6) / 2
        wallust: root.wallust
        text: "Quick"
        highlightedState: !root.desktopTab
        onClicked: { root.desktopTab = false; scroll.contentY = 0; }
      }
      ControlButton {
        width: (parent.width - 6) / 2
        wallust: root.wallust
        text: "Desktop"
        highlightedState: root.desktopTab
        onClicked: { root.desktopTab = true; scroll.contentY = 0; }
      }
    }

    Flickable {
      id: scroll
      x: 20; y: root.sessionOpen ? header.y + header.implicitHeight + 12 : tabs.y + tabs.implicitHeight + 14
      width: parent.width - 40
      height: Math.max(0, footer.y - y - 14)
      contentWidth: width
      contentHeight: body.implicitHeight
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
      Column {
        id: body
        width: scroll.width
        spacing: 12
        Text {
          visible: root.desktop.error.length > 0
          width: parent.width
          text: root.desktop.error
          wrapMode: Text.Wrap
          color: root.wallust.barCritical
          font: Style.Typography.controlMessageFont
        }
        Column {
          visible: !root.desktopTab && !root.sessionOpen
          width: parent.width
          spacing: 12
          Grid {
            width: parent.width
            columns: 2
            spacing: 8
            ControlButton {
              width: (parent.width - 8) / 2
              wallust: root.wallust
              text: "Network  ›"
              subtitle: root.bar.networkStatus
              enabled: root.ready && Boolean(root.desktop.values.networkSettings)
              onClicked: root.bar.launchNetworkTui()
            }
            ControlButton {
              width: (parent.width - 8) / 2
              wallust: root.wallust
              text: "Bluetooth  ›"
              subtitle: root.desktop.values.bluetoothSettings ? root.bar.bluetoothTooltip : "Install blueman for settings"
              highlightedState: Boolean(root.bar.bluetoothAdapter && root.bar.bluetoothAdapter.enabled)
              enabled: root.ready && Boolean(root.desktop.values.bluetoothSettings)
              onClicked: root.bar.runCommand(["blueman-manager"])
            }
            ControlButton {
              width: (parent.width - 8) / 2
              wallust: root.wallust
              text: "Night light"
              subtitle: root.desktop.values.nightLight ? "Warm display · 4000 K · saved" : root.desktop.values.nightLightWanted ? "Saved on · currently inactive" : "Off"
              highlightedState: Boolean(root.desktop.values.nightLightWanted)
              enabled: root.ready && Boolean(root.desktop.values.nightLightAvailable || root.desktop.values.nightLightWanted)
              onClicked: root.desktop.effect("night-light", !root.desktop.values.nightLightWanted)
            }
            ControlButton {
              width: (parent.width - 8) / 2
              wallust: root.wallust
              text: "Keep awake"
              subtitle: root.desktop.keepAwakeRequested && root.desktop.keepAwakeFailed ? "Saved on · inhibitor unavailable" : root.desktop.keepAwake ? "Saved on · manual locking still works" : "Off"
              highlightedState: root.desktop.keepAwakeRequested
              enabled: root.desktop.loaded
              onClicked: root.desktop.setKeepAwake(!root.desktop.keepAwakeRequested)
            }
          }
          Heading { text: "SOUND" }
          AudioDeviceControl {
            width: parent.width
            bar: root.bar
            wallust: root.wallust
            devices: root.bar.audioOutputDevices
            defaultDevice: root.bar.defaultAudioSink
          }
          AudioDeviceControl {
            width: parent.width
            bar: root.bar
            wallust: root.wallust
            devices: root.bar.audioInputDevices
            defaultDevice: root.bar.defaultAudioSource
            input: true
          }
          Heading { text: "DISPLAYS"; visible: root.desktop.values.bigMonitorAvailable || root.bar.showLaptopBrightnessControl || root.bar.ddcBrightnessState.displayCount > 0 || root.bar.ddcBrightnessState.error.length > 0 }
          ControlToggle {
            visible: Boolean(root.desktop.values.bigMonitorAvailable)
            width: parent.width
            wallust: root.wallust
            text: "Full ultrawide resolution"
            subtitle: checked ? "5120 × 1440" : "2560 × 1440"
            enabled: root.ready
            checked: Boolean(root.desktop.values.bigMonitorWide)
            onToggled: root.desktop.monitorResolution(checked)
          }
          LaptopBrightnessControl {
            visible: root.bar.showLaptopBrightnessControl
            width: parent.width
            bar: root.bar
            wallust: root.wallust
          }
          Repeater {
            model: root.bar.ddcBrightnessState.displays
            DdcBrightnessControl {
              required property var modelData
              width: body.width
              bar: root.bar
              wallust: root.wallust
              ddcDisplay: modelData
            }
          }
          Text {
            visible: root.bar.ddcBrightnessState.error.length > 0
            width: parent.width
            text: root.bar.ddcBrightnessState.error
            color: root.wallust.barCritical
            font: Style.Typography.controlMessageFont
            wrapMode: Text.Wrap
          }
          ControlToggle {
            width: parent.width
            wallust: root.wallust
            text: "Quiet notifications"
            subtitle: "Saved; keeps history and critical alerts"
            enabled: root.desktop.loaded
            checked: root.desktop.quiet
            onToggled: root.desktop.setQuiet(checked)
          }
        }
        Column {
          visible: root.desktopTab && !root.sessionOpen
          width: parent.width
          spacing: 12
          Heading { text: "SYSTEM" }
          Row {
            width: parent.width
            spacing: 8
            Repeater {
              model: ["CPU", "RAM", "TEMP"]
              ControlButton {
                required property var modelData
                width: (body.width - 16) / 3
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
              text: "Software updates  ›"
              subtitle: updatesProcess.running ? "Checking…" : utilityState.updatesCount < 0 ? "Check unavailable · try Refresh" : utilityState.updatesCount + " available"
              onClicked: {
                root.bar.launchTerminalShell("if command -v paru >/dev/null 2>&1; then paru -Syu; else sudo pacman -Syu; fi");
                root.bar.controlPanelOpen = false;
              }
            }
            ControlButton {
              id: refreshUpdates
              width: 76
              height: 68
              wallust: root.wallust
              text: "Refresh"
              enabled: !updatesProcess.running
              onClicked: updatesProcess.running = true
            }
          }
          ControlButton {
            width: parent.width
            wallust: root.wallust
            text: "Pick a screen color  ›"
            onClicked: {
              root.bar.controlPanelOpen = false;
              colorPickerTimer.restart();
            }
          }
          Heading { text: "DESKTOP EFFECTS" }
          Group {
            ControlToggle {
              width: parent.width
              wallust: root.wallust
              text: "Low-effects mode"
              subtitle: "Disables blur, transparency, animations & shadows"
              enabled: root.ready
              checked: Boolean(root.desktop.values.lowEffects)
              onToggled: root.desktop.effect("low-effects", checked)
            }
          }
          ControlButton {
            width: parent.width
            wallust: root.wallust
            text: root.effectsExpanded ? "Appearance & effects  ▴" : "Appearance & effects  ▾"
            Accessible.name: root.effectsExpanded ? "Collapse appearance and effects" : "Expand appearance and effects"
            onClicked: root.effectsExpanded = !root.effectsExpanded
          }
          Column {
            visible: root.effectsExpanded
            width: parent.width
            spacing: 12
            Heading { text: "SHELL SURFACES" }
            Group {
              ControlToggle {
                width: parent.width
                wallust: root.wallust
                text: "Shell glass"
                subtitle: root.desktop.values.lowEffects ? "Off — low-effects mode (preference saved)" : "Bar, control center and notifications; blur is separate"
                enabled: root.ready && !root.desktop.values.lowEffects
                checked: Boolean(root.desktop.values.effectiveShellGlass)
                onToggled: root.desktop.effect("shell-glass", checked)
              }
              EffectSlider {
                setting: "glass-opacity"
                label: "Glass opacity"
                available: Boolean(root.desktop.values.effectiveShellGlass)
                subtitle: available ? "All shell glass backgrounds; control opacity is separate" : "Enable Shell glass; low-effects mode overrides it"
              }
              EffectSlider {
                setting: "control-opacity"
                label: "Control opacity"
                available: !root.desktop.values.lowEffects
                subtitle: available ? "Control-center buttons/cards only; text and icons stay opaque" : "Off — low-effects mode (preference saved)"
              }
            }
            Heading { text: "APPLICATION WINDOWS" }
            Group {
              ControlToggle {
                width: parent.width
                wallust: root.wallust
                text: "Configured transparency"
                subtitle: root.desktop.values.lowEffects ? "Off — low-effects mode (preference saved)" : "Normal application windows; shell glass is separate"
                enabled: root.ready && !root.desktop.values.lowEffects
                checked: Boolean(root.desktop.values.effectiveOpacity)
                onToggled: root.desktop.effect("opacity", checked)
              }
              EffectSlider {
                setting: "window-opacity"
                label: "Hyprland window opacity"
                available: Boolean(root.desktop.values.effectiveOpacity)
                subtitle: available ? "Overrides per-app opacity rules; fullscreen stays opaque" : "Enable Configured transparency; low-effects mode overrides it"
              }
            }
            Heading { text: "BACKDROP BLUR" }
            Group {
              ControlToggle {
                width: parent.width
                wallust: root.wallust
                text: "Backdrop blur"
                subtitle: root.desktop.values.lowEffects ? "Off — low-effects mode (preference saved)" : "Windows and shell surfaces; opacity is separate"
                enabled: root.ready && !root.desktop.values.lowEffects
                checked: Boolean(root.desktop.values.effectiveBlur)
                onToggled: root.desktop.effect("blur", checked)
              }
              EffectSlider {
                setting: "blur-size"
                label: "Hyprland blur size"
                suffix: ""
                available: Boolean(root.desktop.values.effectiveBlur)
                subtitle: available ? "Compositor-wide; passes unchanged; higher values cost more GPU" : "Enable Backdrop blur; low-effects mode overrides it"
              }
            }
            Heading { text: "THEME & WALLPAPER" }
            Group {
              Row {
                width: parent.width
                spacing: 8
                ControlButton {
                  width: (parent.width - 8) / 2
                  wallust: root.wallust
                  text: "Light theme"
                  highlightedState: root.desktop.values.theme === "light"
                  enabled: root.ready
                  onClicked: root.desktop.theme("light")
                }
                ControlButton {
                  width: (parent.width - 8) / 2
                  wallust: root.wallust
                  text: "Dark theme"
                  highlightedState: root.desktop.values.theme !== "light"
                  enabled: root.ready
                  onClicked: root.desktop.theme("dark")
                }
              }
              ControlButton {
                width: parent.width
                wallust: root.wallust
                text: "Change wallpaper  ›"
                enabled: root.ready
                onClicked: root.bar.runCommand([root.desktop.scripts + "walli.sh"])
              }
            }
          }
          ControlToggle {
            width: parent.width
            wallust: root.wallust
            text: "Show bar"
            checked: root.bar.barVisible
            onToggled: root.bar.setBarVisible(checked)
          }
          ControlButton {
            width: parent.width
            wallust: root.wallust
            text: root.toolsExpanded ? "Tools  ▴" : "Tools  ▾"
            onClicked: root.toolsExpanded = !root.toolsExpanded
          }
          Column {
            visible: root.toolsExpanded
            width: parent.width
            spacing: 6
            ControlButton {
              width: parent.width; wallust: root.wallust; text: "Reload Hyprland"
              enabled: root.ready
              onClicked: root.desktop.run(["hyprctl", "reload"])
            }
            ControlButton {
              width: parent.width; wallust: root.wallust; text: "Reapply monitor configuration"
              enabled: root.ready
              onClicked: root.desktop.run(["hyprctl", "repl", "require('config.monitors').apply()"])
            }
            ControlButton {
              width: parent.width; wallust: root.wallust; text: "Refresh display detection"
              onClicked: { root.bar.ddcBrightnessState.refresh(); root.bar.laptopBrightnessState.refresh(); }
            }
            ControlButton {
              width: parent.width; wallust: root.wallust; text: "Bar diagnostics"
              enabled: root.ready
              onClicked: root.desktop.run([root.desktop.scripts + "quickshell-healthcheck.sh"])
            }
          }
        }
        Column {
          visible: root.sessionOpen
          width: parent.width
          spacing: 12
          Text {
            width: parent.width
            text: root.confirmation.length > 0 ? "Confirm " + root.confirmation + "? Unsaved work may be lost." : "Choose a session action."
            font: Style.Typography.controlLabelFont
            color: root.wallust.barText
            wrapMode: Text.Wrap
          }
          Repeater {
            model: root.confirmation.length > 0 ? [] : ["Suspend", "Log out", "Reboot", "Shutdown"]
            ControlButton {
              required property string modelData
              width: parent.width
              wallust: root.wallust
              text: modelData
              onClicked: root.confirmation = modelData
            }
          }
          ControlButton {
            visible: root.confirmation.length > 0
            width: parent.width
            wallust: root.wallust
            text: "Confirm " + root.confirmation
            enabled: root.ready
            onClicked: {
              const actions = {
                "Suspend": [root.desktop.scripts + "session-action.sh", "suspend"],
                "Log out": ["hyprctl", "dispatch", "hl.dsp.exit()"],
                "Reboot": ["systemctl", "reboot"],
                "Shutdown": ["systemctl", "poweroff"]
              };
              root.desktop.run(actions[root.confirmation]);
              root.confirmation = "";
            }
          }
          ControlButton {
            width: parent.width
            wallust: root.wallust
            text: "Cancel"
            onClicked: { root.sessionOpen = false; root.confirmation = ""; }
          }
        }
      }
    }
    Row {
      id: footer
      x: 20; y: parent.height - height - 16
      width: parent.width - 40
      spacing: 8
      ControlButton {
        wallust: root.wallust
        text: "Lock"
        enabled: root.ready && Boolean(root.desktop.values.lockAvailable)
        onClicked: { root.bar.runCommand(["hyprlock"]); root.bar.controlPanelOpen = false; }
      }
      ControlButton {
        wallust: root.wallust
        text: "Session…"
        onClicked: { root.sessionOpen = !root.sessionOpen; root.confirmation = ""; scroll.contentY = 0; }
      }
      Item { width: Math.max(0, footer.width - 180); height: 36
        Text {
          anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
          text: root.desktop.busy ? "Working…" : "Super+A"
          color: root.wallust.barMutedText
          font: Style.Typography.controlHintFont
        }
      }
    }
  }
}
