import QtQuick
import QtQuick.Controls
import QtQuick.Window
import Quickshell
import Quickshell.Wayland

PanelWindow {
  id: root
  required property var bar
  required property var wallust
  readonly property var desktop: bar.desktopState
  property bool desktopTab: false
  property bool toolsExpanded: false
  property bool sessionOpen: false
  property string confirmation: ""
  readonly property bool ready: desktop.loaded && !desktop.busy

  visible: Boolean(bar.controlPanelOpen)
  implicitWidth: Math.min(440, screen ? screen.width - 24 : 440)
  implicitHeight: Math.min(screen ? screen.height - margins.top - 16 : 740, Math.max(360, body.implicitHeight + 182))
  color: "transparent"
  screen: bar.screen
  focusable: visible
  exclusionMode: ExclusionMode.Ignore
  anchors { top: true; right: true }
  margins { top: bar.barVisible ? bar.height + 12 : 12; right: 12 }
  WlrLayershell.namespace: "quickshell"

  onVisibleChanged: {
    if (!visible) { sessionOpen = false; confirmation = ""; return; }
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

  component Heading: Text {
    width: parent.width
    font.family: root.wallust.textFont
    font.pixelSize: 11
    font.weight: Font.DemiBold
    color: root.wallust.barMutedText
  }
  component Group: Rectangle {
    default property alias contents: groupContents.data
    width: parent.width
    implicitHeight: groupContents.implicitHeight + 16
    radius: 12
    color: root.wallust.barCard
    Column {
      id: groupContents
      x: 4; y: 8
      width: parent.width - 8
      spacing: 2
    }
  }

  Rectangle {
    anchors.fill: parent
    radius: 18
    color: root.wallust.panelBackground
    border.width: 1
    border.color: root.wallust.barBorder
    clip: true
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
        text: root.sessionOpen ? "Session" : "Controls"
        font.family: root.wallust.textFont
        font.pixelSize: 21
        font.weight: Font.DemiBold
        color: root.wallust.barText
      }
      ControlButton {
        id: closeButton
        width: 40
        wallust: root.wallust
        text: "×"
        Accessible.name: "Close controls"
        onClicked: root.bar.controlPanelOpen = false
      }
    }
    Row {
      id: tabs
      x: 20; y: 62
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
      x: 20; y: root.sessionOpen ? 64 : 112
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
          font.family: root.wallust.textFont
          font.pixelSize: 12
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
              subtitle: root.desktop.values.nightLight ? "Warm display · 4000 K" : "Off"
              highlightedState: Boolean(root.desktop.values.nightLight)
              enabled: root.ready && Boolean(root.desktop.values.nightLightAvailable)
              onClicked: root.desktop.run([root.desktop.scripts + "hyprsunset.sh", root.desktop.values.nightLight ? "disable" : "enable"])
            }
            ControlButton {
              width: (parent.width - 8) / 2
              wallust: root.wallust
              text: "Keep awake"
              subtitle: root.desktop.values.idleRunning ? (root.desktop.keepAwake ? "Until shell exits · locking still works" : "Off") : "Idle service not running"
              highlightedState: root.desktop.keepAwake
              enabled: Boolean(root.desktop.values.idleRunning)
              onClicked: root.desktop.keepAwake = !root.desktop.keepAwake
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
          Heading { text: "DISPLAYS"; visible: root.bar.showLaptopBrightnessControl || root.bar.ddcBrightnessState.displayCount > 0 || root.bar.ddcBrightnessState.error.length > 0 }
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
            font.family: root.wallust.textFont
            font.pixelSize: 12
            wrapMode: Text.Wrap
          }
          ControlToggle {
            width: parent.width
            wallust: root.wallust
            text: "Quiet notifications"
            subtitle: "Keep history; allow critical alerts"
            checked: root.desktop.quiet
            onToggled: root.desktop.quiet = checked
          }
        }
        Column {
          visible: root.desktopTab && !root.sessionOpen
          width: parent.width
          spacing: 12
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
            ControlToggle {
              width: parent.width
              wallust: root.wallust
              text: "Backdrop blur"
              subtitle: root.desktop.values.lowEffects ? "Off — low-effects mode (preference saved)" : "Windows and shell surfaces"
              enabled: root.ready && !root.desktop.values.lowEffects
              checked: Boolean(root.desktop.values.effectiveBlur)
              onToggled: root.desktop.effect("blur", checked)
            }
            ControlToggle {
              width: parent.width
              wallust: root.wallust
              text: "Configured transparency"
              subtitle: root.desktop.values.lowEffects ? "Off — low-effects mode (preference saved)" : "Hyprland rules; app opacity is separate"
              enabled: root.ready && !root.desktop.values.lowEffects
              checked: Boolean(root.desktop.values.effectiveOpacity)
              onToggled: root.desktop.effect("opacity", checked)
            }
          }
          Heading { text: "APPEARANCE" }
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
            onClicked: root.bar.runCommand([root.desktop.scripts + "waypaper.sh"])
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
            font.family: root.wallust.textFont
            font.pixelSize: 13
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
          font.family: root.wallust.textFont
          font.pixelSize: 11
        }
      }
    }
  }
}
