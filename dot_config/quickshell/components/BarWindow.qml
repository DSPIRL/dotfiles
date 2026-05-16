import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.DBusMenu
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Notifications
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import Quickshell.Widgets

import "../wallust" as Wallust

PanelWindow {
  id: barWindow

  anchors {
    top: true
    left: true
    right: true
  }

  margins {
    top: 2
    left: 8
    right: 8
  }

  implicitHeight: 40
  color: "transparent"

  Wallust.Colors {
    id: wallust
  }

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  PwObjectTracker {
    objects: [Pipewire.defaultAudioSink]
  }

  property var hyprMonitor: Hyprland.monitorFor(screen)
  property var notifications
  property int notificationToggleGeneration: 0
  property var focusedHyprMonitor
  property bool notificationPanelOpen: false
  property var toastNotification
  property bool toastVisible: false
  readonly property int notificationCount: notifications ? notifications.trackedNotifications.values.length : 0

  onNotificationToggleGenerationChanged: {
    const focused = isFocusedMonitor();
    notificationPanelOpen = focused ? !notificationPanelOpen : false;
  }

  onNotificationPanelOpenChanged: if (notificationPanelOpen) {
    toastVisible = false;
  }

  readonly property var workspaceGlyphs: ({
    "1": "一",
    "2": "二",
    "3": "三",
    "4": "四",
    "5": "五",
    "6": "六",
    "7": "七",
    "8": "八",
    "9": "九",
    "10": "十"
  })

  readonly property var defaultAudioSink: Pipewire.defaultAudioSink
  readonly property bool sinkMuted: defaultAudioSink && defaultAudioSink.audio ? defaultAudioSink.audio.muted : false
  readonly property real sinkVolume: defaultAudioSink && defaultAudioSink.audio ? defaultAudioSink.audio.volume : 0

  readonly property var bluetoothAdapter: Bluetooth.defaultAdapter
  readonly property int bluetoothConnectedCount: {
    const devices = Bluetooth.devices.values;
    let count = 0;

    for (let i = 0; i < devices.length; i += 1) {
      if (devices[i].connected) {
        count += 1;
      }
    }

    return count;
  }

  readonly property string bluetoothIcon: {
    if (!bluetoothAdapter || !bluetoothAdapter.enabled) {
      return "󰂲";
    }

    return bluetoothConnectedCount > 0 ? "󰂱" : "󰂯";
  }

  readonly property string bluetoothLabel: bluetoothConnectedCount > 0 ? String(bluetoothConnectedCount) : ""

  readonly property string bluetoothTooltip: {
    if (!bluetoothAdapter || !bluetoothAdapter.enabled) {
      return "Bluetooth disabled";
    }

    if (bluetoothConnectedCount === 0) {
      return "Bluetooth enabled";
    }

    const devices = Bluetooth.devices.values;
    let names = "";

    for (let i = 0; i < devices.length; i += 1) {
      if (!devices[i].connected) {
        continue;
      }

      names += names.length === 0 ? devices[i].name : ", " + devices[i].name;
    }

    return names;
  }

  readonly property var displayBattery: UPower.displayDevice
  readonly property bool hasBattery: displayBattery && displayBattery.ready && displayBattery.isLaptopBattery
  readonly property int batteryPercent: hasBattery ? Math.round(displayBattery.percentage) : 0

  readonly property color batteryTextColor: {
    if (!hasBattery) {
      return wallust.barText;
    }

    if ((displayBattery.state === UPowerDeviceState.Discharging || displayBattery.state === UPowerDeviceState.PendingDischarge) && batteryPercent <= 20) {
      return wallust.barCritical;
    }

    if (batteryPercent <= 30) {
      return wallust.color3;
    }

    return wallust.barText;
  }

  property bool toolsExpanded: false

  readonly property var spotifyPlayer: {
    const players = Mpris.players.values;

    for (let i = 0; i < players.length; i += 1) {
      const dbusName = players[i].dbusName ? players[i].dbusName.toLowerCase() : "";
      const identity = players[i].identity ? players[i].identity.toLowerCase() : "";

      if (dbusName.indexOf("spotify") !== -1 || identity === "spotify") {
        return players[i];
      }
    }

    return null;
  }

  readonly property bool spotifyVisible: spotifyPlayer && spotifyPlayer.playbackState !== MprisPlaybackState.Stopped
  readonly property bool spotifyPlaying: spotifyPlayer && spotifyPlayer.playbackState === MprisPlaybackState.Playing
  readonly property string spotifyDisplay: spotifyTextForPlayer(spotifyPlayer)

  function runCommand(command) {
    Quickshell.execDetached(command);
  }

  function runShell(command) {
    runCommand(["sh", "-c", command]);
  }

  function launchTerminal(program) {
    const terminal = Quickshell.env("USER_TERMINAL") || "alacritty";
    runShell(terminal + " -e " + program);
  }

  function launchTerminalShell(command) {
    const terminal = Quickshell.env("USER_TERMINAL") || "alacritty";
    runShell(terminal + " -e sh -lc '" + command + "'");
  }

  function runHyprScript(scriptName) {
    const home = Quickshell.env("HOME") || "";
    if (home.length === 0) {
      return;
    }

    runCommand(["sh", "-c", home + "/.config/hypr/scripts/" + scriptName]);
  }

  function shorten(text, maxLength) {
    if (!text || text.length <= maxLength) {
      return text || "";
    }

    return text.slice(0, maxLength - 3) + "...";
  }

  function spotifyTextForPlayer(player) {
    if (!player || player.playbackState === MprisPlaybackState.Stopped) {
      return "";
    }

    if (player.playbackState === MprisPlaybackState.Paused) {
      return "";
    }

    let text = "";
    if (player.trackArtist && player.trackTitle) {
      text = player.trackArtist + " - " + player.trackTitle;
    } else if (player.trackTitle) {
      text = player.trackTitle;
    } else {
      text = player.identity || "Spotify";
    }

    return shorten(text, 44) + "  ";
  }

  function workspaceText(workspace) {
    const key = workspace.name && workspace.name.length > 0 ? workspace.name : String(workspace.id);
    return workspaceGlyphs[key] || key;
  }

  function isFocusedMonitor() {
    if (!focusedHyprMonitor || !hyprMonitor) {
      return true;
    }

    return focusedHyprMonitor.id === hyprMonitor.id;
  }

  function notificationAccent(notification) {
    if (notification && notification.urgency === NotificationUrgency.Critical) {
      return wallust.barCritical;
    }

    if (notification && notification.urgency === NotificationUrgency.Low) {
      return wallust.barMutedText;
    }

    return wallust.color3;
  }

  function notificationIcon(notification) {
    if (notification && notification.appIcon && notification.appIcon.length > 0) {
      return notification.appIcon;
    }

    return "";
  }

  function notificationToastDuration(notification) {
    if (notification && notification.urgency === NotificationUrgency.Critical) {
      return 9000;
    }

    if (notification && notification.urgency === NotificationUrgency.Low) {
      return 3500;
    }

    return 5500;
  }

  function showNotificationToast(notification) {
    if (!notification || !isFocusedMonitor()) {
      return;
    }

    toastNotification = notification;
    toastVisible = true;
    toastTimer.interval = notificationToastDuration(notification);
    toastTimer.restart();
  }

  function clearNotifications() {
    if (!notifications) {
      return;
    }

    const trackedNotifications = notifications.trackedNotifications.values;
    for (let i = trackedNotifications.length - 1; i >= 0; i -= 1) {
      trackedNotifications[i].dismiss();
    }
  }

  Connections {
    target: barWindow.notifications || null
    ignoreUnknownSignals: true

    function onNotification(notification) {
      barWindow.showNotificationToast(notification);
    }
  }

  Timer {
    id: toastTimer

    repeat: false
    onTriggered: barWindow.toastVisible = false
  }

  function volumeIcon(volume, muted) {
    if (muted) {
      return "󰝟";
    }

    if (volume <= 0.33) {
      return "";
    }

    if (volume <= 0.66) {
      return "";
    }

    return "";
  }

  function batteryIcon(percent, state) {
    if (state === UPowerDeviceState.Charging || state === UPowerDeviceState.PendingCharge) {
      return "󰂄";
    }

    if (percent >= 95) {
      return "󰁹";
    }

    if (percent >= 80) {
      return "󰂂";
    }

    if (percent >= 60) {
      return "󰂀";
    }

    if (percent >= 40) {
      return "󰁾";
    }

    if (percent >= 20) {
      return "󰁼";
    }

    return "󰁻";
  }

  function launchNetworkTui() {
    launchTerminal("nmtui");
  }

  QtObject {
    id: networkState

    property string icon: ""
    property string tooltip: "Disconnected"

    function update(rawText) {
      const text = rawText ? rawText.trim() : "";

      if (text.length === 0) {
        icon = "";
        tooltip = "Disconnected";
        return;
      }

      const lines = text.split("\n");
      let connectedType = "";
      let connectedName = "";

      for (let i = 0; i < lines.length; i += 1) {
        const line = lines[i];
        if (line.length === 0) {
          continue;
        }

        const parts = line.split(":");
        if (parts.length < 3) {
          continue;
        }

        const type = parts[0];
        const state = parts[1];
        const connection = parts.slice(2).join(":");

        if (state !== "connected") {
          continue;
        }

        if (type === "wifi") {
          connectedType = type;
          connectedName = connection;
          break;
        }

        if (type === "ethernet" && connectedType.length === 0) {
          connectedType = type;
          connectedName = connection;
        }
      }

      if (connectedType === "wifi") {
        icon = "";
        tooltip = connectedName.length > 0 ? connectedName : "Wi-Fi connected";
        return;
      }

      if (connectedType === "ethernet") {
        icon = "";
        tooltip = connectedName.length > 0 ? connectedName : "Ethernet connected";
        return;
      }

      icon = "";
      tooltip = "Disconnected";
    }
  }

  Process {
    id: networkProcess

    command: ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION", "device", "status"]

    stdout: StdioCollector {
      id: networkStdout
      waitForEnd: true
    }

    onExited: function(exitCode, exitStatus) {
      if (exitCode === 0) {
        networkState.update(networkStdout.text);
      } else {
        networkState.icon = "";
        networkState.tooltip = "Network unavailable";
      }
    }
  }

  Timer {
    interval: 10000
    running: true
    repeat: true
    triggeredOnStart: true

    onTriggered: if (!networkProcess.running) {
      networkProcess.running = true;
    }
  }

  QtObject {
    id: utilityState

    property int cpuUsage: 0
    property int memoryUsage: 0
    property int temperature: 0
    property bool hasTemperature: false
    property bool hyprsunsetActive: false
    property int updatesCount: -1
  }

  Process {
    id: utilityStatsProcess

    command: [
      "sh",
      "-c",
      "read -r _ u1 n1 s1 i1 w1 q1 sq1 st1 _ < /proc/stat; t1=$((u1+n1+s1+i1+w1+q1+sq1+st1)); id1=$((i1+w1)); sleep 0.2; read -r _ u2 n2 s2 i2 w2 q2 sq2 st2 _ < /proc/stat; t2=$((u2+n2+s2+i2+w2+q2+sq2+st2)); id2=$((i2+w2)); dt=$((t2-t1)); did=$((id2-id1)); if [ $dt -gt 0 ]; then cpu=$(( (100*(dt-did))/dt )); else cpu=0; fi; memTotal=$(grep -m1 '^MemTotal:' /proc/meminfo | tr -s ' ' | cut -d' ' -f2); memAvail=$(grep -m1 '^MemAvailable:' /proc/meminfo | tr -s ' ' | cut -d' ' -f2); memTotal=${memTotal:-0}; memAvail=${memAvail:-0}; if [ $memTotal -gt 0 ] 2>/dev/null; then mem=$(( (100*(memTotal-memAvail))/memTotal )); else mem=0; fi; temp=-1; for f in /sys/class/thermal/thermal_zone*/temp; do if [ -r $f ]; then raw=$(cat $f); if [ $raw -gt 0 ] 2>/dev/null; then temp=$((raw/1000)); break; fi; fi; done; if pgrep -x hyprsunset >/dev/null 2>&1; then sunset=1; else sunset=0; fi; printf '%s;%s;%s;%s\\n' $cpu $mem $temp $sunset"
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
      if (parts.length < 4) {
        return;
      }

      utilityState.cpuUsage = parseInt(parts[0], 10) || 0;
      utilityState.memoryUsage = parseInt(parts[1], 10) || 0;

      const parsedTemp = parseInt(parts[2], 10);
      utilityState.hasTemperature = !Number.isNaN(parsedTemp) && parsedTemp >= 0;
      utilityState.temperature = utilityState.hasTemperature ? parsedTemp : 0;
      utilityState.hyprsunsetActive = (parseInt(parts[3], 10) || 0) === 1;
    }
  }

  Timer {
    interval: 8000
    running: true
    repeat: true
    triggeredOnStart: true

    onTriggered: if (!utilityStatsProcess.running) {
      utilityStatsProcess.running = true;
    }
  }

  Process {
    id: updatesProcess

    command: ["sh", "-c", "if command -v checkupdates >/dev/null 2>&1; then checkupdates 2>/dev/null | wc -l; else echo -1; fi"]

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

  Item {
    anchors.fill: parent

    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: 4
      anchors.rightMargin: 4
      anchors.topMargin: 2
      anchors.bottomMargin: 2
      spacing: 8

      Rectangle {
        id: leftPill

        implicitWidth: workspaceRow.implicitWidth + 16
        implicitHeight: 30
        radius: implicitHeight / 2
        color: wallust.barBackground
        border.width: 1
        border.color: wallust.barBorder

        MouseArea {
          anchors.fill: parent
          acceptedButtons: Qt.NoButton

          onWheel: function(wheel) {
            Hyprland.dispatch(wheel.angleDelta.y > 0 ? "workspace e+1" : "workspace e-1");
          }
        }

        Row {
          id: workspaceRow

          anchors.centerIn: parent
          spacing: 3

          Repeater {
            model: Hyprland.workspaces

            Rectangle {
              required property var modelData
              readonly property var workspace: modelData

              visible: workspace.id > 0
              radius: 10
              implicitWidth: workspaceLabel.implicitWidth + 12
              implicitHeight: 24
              border.width: workspace.urgent ? 1 : 0
              border.color: wallust.color3
              opacity: barWindow.hyprMonitor && workspace.monitor && workspace.monitor.id !== barWindow.hyprMonitor.id ? 0.55 : 1
              color: workspace.active ? wallust.barActive : (workspaceMouse.containsMouse ? wallust.barHover : "transparent")

              Behavior on color {
                ColorAnimation {
                  duration: 120
                }
              }

              Text {
                id: workspaceLabel

                anchors.centerIn: parent
                text: barWindow.workspaceText(workspace)
                color: workspace.active ? wallust.barAccentText : wallust.barMutedText
                font.family: "Hack Nerd Font"
                font.pixelSize: 16
              }

              MouseArea {
                id: workspaceMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onClicked: workspace.activate()
              }
            }
          }
        }
      }

      Item {
        Layout.fillWidth: true
        implicitHeight: spotifyPill.implicitHeight

        Row {
          id: centerRow

          anchors.centerIn: parent
          spacing: 6

          Rectangle {
            id: spotifyPill

            visible: barWindow.spotifyVisible
            implicitWidth: barWindow.spotifyPlaying ? 250 : spotifyLabel.implicitWidth + 20
            implicitHeight: 30
            radius: implicitHeight / 2
            color: spotifyMouse.containsMouse ? wallust.barHover : wallust.barBackground
            border.width: 1
            border.color: wallust.barBorder

            Behavior on color {
              ColorAnimation {
                duration: 120
              }
            }

            Text {
              id: spotifyLabel

              anchors.centerIn: parent
              width: barWindow.spotifyPlaying ? 230 : implicitWidth
              elide: Text.ElideRight
              horizontalAlignment: Text.AlignHCenter
              text: barWindow.spotifyDisplay
              color: wallust.barText
              font.family: "Hack Nerd Font"
              font.pixelSize: 16
            }

            MouseArea {
              id: spotifyMouse

              anchors.fill: parent
              hoverEnabled: true
              acceptedButtons: Qt.LeftButton | Qt.RightButton
              cursorShape: Qt.PointingHandCursor

              onClicked: function(mouse) {
                if (!barWindow.spotifyPlayer) {
                  return;
                }

                if (mouse.button === Qt.RightButton) {
                  if (barWindow.spotifyPlayer.canRaise) {
                    barWindow.spotifyPlayer.raise();
                  }
                  return;
                }

                if (barWindow.spotifyPlayer.canTogglePlaying) {
                  barWindow.spotifyPlayer.togglePlaying();
                }
              }

              onWheel: function(wheel) {
                if (!barWindow.spotifyPlayer) {
                  return;
                }

                if (wheel.angleDelta.y > 0 && barWindow.spotifyPlayer.canGoNext) {
                  barWindow.spotifyPlayer.next();
                } else if (wheel.angleDelta.y < 0 && barWindow.spotifyPlayer.canGoPrevious) {
                  barWindow.spotifyPlayer.previous();
                }
              }
            }
          }
        }
      }

      Rectangle {
        id: rightPill

        implicitWidth: rightRow.implicitWidth + 16
        implicitHeight: 30
        radius: implicitHeight / 2
        color: wallust.barBackground
        border.width: 1
        border.color: wallust.barBorder

        Row {
          id: rightRow

          anchors.centerIn: parent
          spacing: 3

          Repeater {
            model: SystemTray.items

            Rectangle {
              id: trayButton

              required property var modelData
              readonly property var trayItem: modelData

              visible: trayItem.icon && trayItem.icon.length > 0
              implicitWidth: 24
              implicitHeight: 24
              radius: 10
              color: trayMouse.containsMouse ? wallust.barHover : "transparent"

              function openMenu() {
                trayMenu.open();
              }

              Behavior on color {
                ColorAnimation {
                  duration: 120
                }
              }

              IconImage {
                anchors.centerIn: parent
                implicitSize: 16
                source: trayItem.icon
              }

              QsMenuAnchor {
                id: trayMenu

                menu: trayItem.menu

                anchor {
                  item: trayButton
                  edges: Edges.Bottom | Edges.Left
                  gravity: Edges.Bottom | Edges.Right
                }
              }

              MouseArea {
                id: trayMouse

                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor

                onClicked: function(mouse) {
                  if (mouse.button === Qt.LeftButton) {
                    if (trayItem.onlyMenu && trayItem.hasMenu) {
                      trayButton.openMenu();
                    } else {
                      trayItem.activate();
                    }
                    return;
                  }

                  if (mouse.button === Qt.MiddleButton) {
                    trayItem.secondaryActivate();
                    return;
                  }

                  if (trayItem.hasMenu) {
                    trayButton.openMenu();
                  } else {
                    trayItem.secondaryActivate();
                  }
                }
              }
            }
          }

          Rectangle {
            visible: SystemTray.items.values.length > 0
            width: 1
            height: 14
            radius: 1
            color: wallust.barSeparator
            anchors.verticalCenter: parent.verticalCenter
          }

          Rectangle {
            implicitWidth: expandLabel.implicitWidth + 12
            implicitHeight: 24
            radius: 10
            color: expandMouse.containsMouse ? wallust.barHover : "transparent"

            Behavior on color {
              ColorAnimation {
                duration: 120
              }
            }

            Text {
              id: expandLabel

              anchors.centerIn: parent
              text: barWindow.toolsExpanded ? "" : ""
              color: wallust.barText
              font.family: "Hack Nerd Font"
              font.pixelSize: 16
            }

            MouseArea {
              id: expandMouse

              anchors.fill: parent
              hoverEnabled: true
              acceptedButtons: Qt.LeftButton
              cursorShape: Qt.PointingHandCursor

              onClicked: barWindow.toolsExpanded = !barWindow.toolsExpanded
            }
          }

          Item {
            id: utilityDrawer

            width: barWindow.toolsExpanded ? utilityRow.implicitWidth : 0
            height: 24
            clip: true

            Behavior on width {
              NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
              }
            }

            Row {
              id: utilityRow

              anchors.verticalCenter: parent.verticalCenter
              spacing: 3

              Rectangle {
                implicitWidth: 26
                implicitHeight: 24
                radius: 10
                color: colorpickerMouse.containsMouse ? wallust.barHover : "transparent"

                Behavior on color {
                  ColorAnimation {
                    duration: 120
                  }
                }

                Text {
                  anchors.centerIn: parent
                  text: ""
                  color: wallust.barText
                  font.family: "Hack Nerd Font"
                  font.pixelSize: 16
                }

                MouseArea {
                  id: colorpickerMouse

                  anchors.fill: parent
                  hoverEnabled: true
                  acceptedButtons: Qt.LeftButton
                  cursorShape: Qt.PointingHandCursor

                  onClicked: barWindow.runHyprScript("colorpicker.sh")
                }
              }

              Rectangle {
                implicitWidth: updatesLabel.implicitWidth + 12
                implicitHeight: 24
                radius: 10
                color: updatesMouse.containsMouse ? wallust.barHover : "transparent"

                Behavior on color {
                  ColorAnimation {
                    duration: 120
                  }
                }

                Text {
                  id: updatesLabel

                  anchors.centerIn: parent
                  text: "󰅢 " + (utilityState.updatesCount >= 0 ? utilityState.updatesCount : "?")
                  color: wallust.barText
                  font.family: "Hack Nerd Font"
                  font.pixelSize: 16
                }

                MouseArea {
                  id: updatesMouse

                  anchors.fill: parent
                  hoverEnabled: true
                  acceptedButtons: Qt.LeftButton | Qt.RightButton
                  cursorShape: Qt.PointingHandCursor

                  onClicked: function(mouse) {
                    if (mouse.button === Qt.RightButton) {
                      if (!updatesProcess.running) {
                        updatesProcess.running = true;
                      }
                      return;
                    }

                    barWindow.launchTerminalShell("command -v paru >/dev/null 2>&1 && paru -Syu || sudo pacman -Syu")
                  }
                }
              }

              Rectangle {
                implicitWidth: 26
                implicitHeight: 24
                radius: 10
                color: hyprsunsetMouse.containsMouse ? wallust.barHover : "transparent"

                Behavior on color {
                  ColorAnimation {
                    duration: 120
                  }
                }

                Text {
                  anchors.centerIn: parent
                  text: ""
                  color: utilityState.hyprsunsetActive ? wallust.color3 : wallust.barText
                  font.family: "Hack Nerd Font"
                  font.pixelSize: 16
                }

                MouseArea {
                  id: hyprsunsetMouse

                  anchors.fill: parent
                  hoverEnabled: true
                  acceptedButtons: Qt.LeftButton | Qt.RightButton
                  cursorShape: Qt.PointingHandCursor

                  onClicked: function(mouse) {
                    if (mouse.button === Qt.RightButton) {
                      barWindow.runCommand(["gddccontrol"]);
                      return;
                    }

                    barWindow.runHyprScript("hyprsunset.sh")
                    if (!utilityStatsProcess.running) {
                      utilityStatsProcess.running = true;
                    }
                  }
                }
              }

              Rectangle {
                implicitWidth: cpuLabel.implicitWidth + 12
                implicitHeight: 24
                radius: 10
                color: cpuMouse.containsMouse ? wallust.barHover : "transparent"

                Behavior on color {
                  ColorAnimation {
                    duration: 120
                  }
                }

                Text {
                  id: cpuLabel

                  anchors.centerIn: parent
                  text: " " + utilityState.cpuUsage + "%"
                  color: wallust.barText
                  font.family: "Hack Nerd Font"
                  font.pixelSize: 16
                }

                MouseArea {
                  id: cpuMouse

                  anchors.fill: parent
                  hoverEnabled: true
                  acceptedButtons: Qt.LeftButton
                  cursorShape: Qt.PointingHandCursor

                  onClicked: barWindow.launchTerminal("btop -p 2")
                }
              }

              Rectangle {
                implicitWidth: memoryLabel.implicitWidth + 12
                implicitHeight: 24
                radius: 10
                color: memoryMouse.containsMouse ? wallust.barHover : "transparent"

                Behavior on color {
                  ColorAnimation {
                    duration: 120
                  }
                }

                Text {
                  id: memoryLabel

                  anchors.centerIn: parent
                  text: " " + utilityState.memoryUsage + "%"
                  color: wallust.barText
                  font.family: "Hack Nerd Font"
                  font.pixelSize: 16
                }

                MouseArea {
                  id: memoryMouse

                  anchors.fill: parent
                  hoverEnabled: true
                }
              }

              Rectangle {
                implicitWidth: temperatureLabel.implicitWidth + 12
                implicitHeight: 24
                radius: 10
                color: temperatureMouse.containsMouse ? wallust.barHover : "transparent"

                Behavior on color {
                  ColorAnimation {
                    duration: 120
                  }
                }

                Text {
                  id: temperatureLabel

                  anchors.centerIn: parent
                  text: utilityState.hasTemperature ? " " + utilityState.temperature + "C" : " --"
                  color: wallust.barText
                  font.family: "Hack Nerd Font"
                  font.pixelSize: 16
                }

                MouseArea {
                  id: temperatureMouse

                  anchors.fill: parent
                  hoverEnabled: true
                }
              }

              Rectangle {
                width: 1
                height: 14
                radius: 1
                color: wallust.barSeparator
                anchors.verticalCenter: parent.verticalCenter
              }
            }
          }

          Rectangle {
            id: audioButton

            implicitWidth: audioLabel.implicitWidth + 12
            implicitHeight: 24
            radius: 10
            color: audioMouse.containsMouse ? wallust.barHover : "transparent"

            Behavior on color {
              ColorAnimation {
                duration: 120
              }
            }

            Text {
              id: audioLabel

              anchors.centerIn: parent
              text: barWindow.defaultAudioSink ? barWindow.volumeIcon(barWindow.sinkVolume, barWindow.sinkMuted) + " " + Math.round(barWindow.sinkVolume * 100) + "%" : "󰝟 --"
              color: wallust.barText
              font.family: "Hack Nerd Font"
              font.pixelSize: 14
            }

            MouseArea {
              id: audioMouse

              anchors.fill: parent
              hoverEnabled: true
              acceptedButtons: Qt.LeftButton | Qt.RightButton
              cursorShape: Qt.PointingHandCursor

              onClicked: function(mouse) {
                if (mouse.button === Qt.LeftButton) {
                  barWindow.runCommand(["pavucontrol"]);
                  return;
                }

                if (barWindow.defaultAudioSink && barWindow.defaultAudioSink.audio) {
                  barWindow.defaultAudioSink.audio.muted = !barWindow.defaultAudioSink.audio.muted;
                }
              }

              onWheel: function(wheel) {
                if (!barWindow.defaultAudioSink || !barWindow.defaultAudioSink.audio) {
                  return;
                }

                const step = wheel.angleDelta.y > 0 ? 0.03 : -0.03;
                const nextVolume = Math.max(0, Math.min(1, barWindow.defaultAudioSink.audio.volume + step));
                barWindow.defaultAudioSink.audio.volume = nextVolume;
              }
            }
          }

          Rectangle {
            implicitWidth: bluetoothLabelView.implicitWidth + 12
            implicitHeight: 24
            radius: 10
            color: bluetoothMouse.containsMouse ? wallust.barHover : "transparent"

            Behavior on color {
              ColorAnimation {
                duration: 120
              }
            }

            Text {
              id: bluetoothLabelView

              anchors.centerIn: parent
              text: barWindow.bluetoothLabel.length > 0 ? barWindow.bluetoothIcon + " " + barWindow.bluetoothLabel : barWindow.bluetoothIcon
              color: wallust.barText
              font.family: "Hack Nerd Font"
              font.pixelSize: 14
            }

            MouseArea {
              id: bluetoothMouse

              anchors.fill: parent
              hoverEnabled: true
              acceptedButtons: Qt.LeftButton | Qt.RightButton
              cursorShape: Qt.PointingHandCursor

              onClicked: barWindow.runCommand(["blueman-manager"])
            }
          }

          Rectangle {
            implicitWidth: networkLabel.implicitWidth + 12
            implicitHeight: 24
            radius: 10
            color: networkMouse.containsMouse ? wallust.barHover : "transparent"

            Behavior on color {
              ColorAnimation {
                duration: 120
              }
            }

            Text {
              id: networkLabel

              anchors.centerIn: parent
              text: networkState.icon
              color: wallust.barText
              font.family: "Hack Nerd Font"
              font.pixelSize: 14
            }

            MouseArea {
              id: networkMouse

              anchors.fill: parent
              hoverEnabled: true
              acceptedButtons: Qt.LeftButton
              cursorShape: Qt.PointingHandCursor

              onClicked: barWindow.launchNetworkTui()
            }
          }

          Rectangle {
            visible: barWindow.hasBattery
            implicitWidth: batteryLabel.implicitWidth + 12
            implicitHeight: 24
            radius: 10
            color: batteryMouse.containsMouse ? wallust.barHover : "transparent"

            Behavior on color {
              ColorAnimation {
                duration: 120
              }
            }

            Text {
              id: batteryLabel

              anchors.centerIn: parent
              text: barWindow.batteryIcon(barWindow.batteryPercent, barWindow.displayBattery.state) + " " + barWindow.batteryPercent + "%"
              color: barWindow.batteryTextColor
              font.family: "Hack Nerd Font"
              font.pixelSize: 14
            }

            MouseArea {
              id: batteryMouse

              anchors.fill: parent
              hoverEnabled: true
            }
          }

          Rectangle {
            id: notificationButton

            implicitWidth: notificationLabel.implicitWidth + 12
            implicitHeight: 24
            radius: 10
            color: notificationMouse.containsMouse ? wallust.barHover : "transparent"

            Behavior on color {
              ColorAnimation {
                duration: 120
              }
            }

            Text {
              id: notificationLabel

              anchors.centerIn: parent
              text: barWindow.notificationCount > 0 ? " " + barWindow.notificationCount : ""
              color: wallust.barText
              font.family: "Hack Nerd Font"
              font.pixelSize: 14
            }

            MouseArea {
              id: notificationMouse

              anchors.fill: parent
              hoverEnabled: true
              acceptedButtons: Qt.LeftButton
              cursorShape: Qt.PointingHandCursor


              onClicked: barWindow.notificationPanelOpen = !barWindow.notificationPanelOpen
            }
          }

          Rectangle {
            width: 1
            height: 14
            radius: 1
            color: wallust.barSeparator
            anchors.verticalCenter: parent.verticalCenter
          }

          Rectangle {
            implicitWidth: powerLabel.implicitWidth + 12
            implicitHeight: 24
            radius: 10
            color: powerMouse.containsMouse ? wallust.barCritical : "transparent"

            Behavior on color {
              ColorAnimation {
                duration: 120
              }
            }

            Text {
              id: powerLabel

              anchors.centerIn: parent
              text: "󰐥"
              color: wallust.barText
              font.family: "Hack Nerd Font"
              font.pixelSize: 14
            }

            MouseArea {
              id: powerMouse

              anchors.fill: parent
              hoverEnabled: true
              acceptedButtons: Qt.LeftButton
              cursorShape: Qt.PointingHandCursor

              onClicked: barWindow.runCommand(["wlogout"])
            }
          }
        }
      }
    }

    PopupWindow {
      id: notificationToast

      visible: barWindow.toastVisible && barWindow.toastNotification && !barWindow.notificationPanelOpen
      implicitWidth: 390
      implicitHeight: toastContent.implicitHeight
      color: "transparent"

      anchor {
        window: barWindow
        adjustment: PopupAdjustment.Slide | PopupAdjustment.Resize

        rect {
          x: Math.round((barWindow.width - notificationToast.width) / 2)
          y: Math.round(barWindow.height + 12)
          width: notificationToast.width
          height: notificationToast.height
        }
      }

      onVisibleChanged: if (!visible) {
        toastTimer.stop();
      }

      Rectangle {
        id: toastContent

        implicitHeight: toastColumn.implicitHeight + 20
        anchors.fill: parent
        radius: 18
        color: wallust.barBackground
        border.width: 1
        border.color: barWindow.notificationAccent(barWindow.toastNotification)

        MouseArea {
          id: toastMouse

          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor

          onClicked: {
            barWindow.toastVisible = false;
            barWindow.notificationPanelOpen = true;
          }
        }

        Column {
          id: toastColumn

          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.margins: 10
          spacing: 8

          Row {
            width: parent.width
            spacing: 10

            IconImage {
              width: 28
              height: 28
              implicitSize: 22
              source: barWindow.notificationIcon(barWindow.toastNotification)
            }

            Column {
              width: parent.width - 28 - toastDismissButton.width - parent.spacing * 2
              spacing: 2

              Text {
                width: parent.width
                text: barWindow.toastNotification ? (barWindow.toastNotification.summary && barWindow.toastNotification.summary.length > 0 ? barWindow.toastNotification.summary : barWindow.toastNotification.appName) : ""
                color: wallust.barText
                elide: Text.ElideRight
                font.family: "Hack Nerd Font"
                font.pixelSize: 14
                font.bold: true
              }

              Text {
                visible: Boolean(barWindow.toastNotification && barWindow.toastNotification.appName && barWindow.toastNotification.appName.length > 0)
                width: parent.width
                text: barWindow.toastNotification ? barWindow.toastNotification.appName : ""
                color: wallust.barMutedText
                elide: Text.ElideRight
                font.family: "Hack Nerd Font"
                font.pixelSize: 12
              }
            }

            Rectangle {
              id: toastDismissButton

              width: 24
              height: 24
              radius: 12
              color: toastDismissMouse.containsMouse ? wallust.barHover : "transparent"

              Text {
                anchors.centerIn: parent
                text: "󰅖"
                color: wallust.barMutedText
                font.family: "Hack Nerd Font"
                font.pixelSize: 13
              }

              MouseArea {
                id: toastDismissMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onClicked: barWindow.toastVisible = false
              }
            }
          }

          Text {
            visible: Boolean(barWindow.toastNotification && barWindow.toastNotification.body && barWindow.toastNotification.body.length > 0)
            width: parent.width
            text: barWindow.toastNotification ? barWindow.toastNotification.body : ""
            color: wallust.barText
            textFormat: Text.StyledText
            wrapMode: Text.Wrap
            maximumLineCount: 3
            elide: Text.ElideRight
            font.family: "Hack Nerd Font"
            font.pixelSize: 13
          }
        }
      }
    }

    PopupWindow {
      id: notificationPanel

      visible: barWindow.notificationPanelOpen
      implicitWidth: 390
      implicitHeight: Math.min(520, notificationPanelContent.implicitHeight)
      color: "transparent"
      grabFocus: false

      anchor {
        window: barWindow
        adjustment: PopupAdjustment.Slide | PopupAdjustment.Resize

        rect {
          x: Math.round((barWindow.width - notificationPanel.width) / 2)
          y: Math.round(barWindow.height + 12)
          width: notificationPanel.width
          height: notificationPanel.height
        }
      }

      onClosed: barWindow.notificationPanelOpen = false
      onVisibleChanged: if (visible) {
        notificationPanelContent.forceActiveFocus();
      }

      Rectangle {
        id: notificationPanelContent

        anchors.fill: parent
        focus: true
        implicitHeight: notificationPanelColumn.implicitHeight + 24
        radius: 18
        color: wallust.barBackground
        border.width: 1
        border.color: wallust.barBorder

        Keys.onEscapePressed: barWindow.notificationPanelOpen = false

        Column {
          id: notificationPanelColumn

          x: 12
          y: 12
          width: parent.width - 24
          spacing: 10

          Row {
            width: parent.width
            height: 28
            spacing: 8

            Text {
              width: parent.width - clearAllButton.width - parent.spacing
              anchors.verticalCenter: parent.verticalCenter
              text: barWindow.notificationCount === 1 ? "1 notification" : barWindow.notificationCount + " notifications"
              color: wallust.barText
              font.family: "Hack Nerd Font"
              font.pixelSize: 15
              font.bold: true
            }

            Rectangle {
              id: clearAllButton

              visible: barWindow.notificationCount > 0
              width: clearAllLabel.implicitWidth + 16
              height: 26
              radius: 13
              color: clearAllMouse.containsMouse ? wallust.barHover : "transparent"
              border.width: 1
              border.color: wallust.barBorder

              Text {
                id: clearAllLabel

                anchors.centerIn: parent
                text: "Clear"
                color: wallust.barText
                font.family: "Hack Nerd Font"
                font.pixelSize: 13
              }

              MouseArea {
                id: clearAllMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onClicked: barWindow.clearNotifications()
              }
            }
          }

          Rectangle {
            visible: barWindow.notificationCount === 0
            width: parent.width
            height: 104
            radius: 14
            color: "transparent"
            border.width: 1
            border.color: wallust.barBorder

            Column {
              anchors.centerIn: parent
              spacing: 8

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "󰂚"
                color: wallust.barMutedText
                font.family: "Hack Nerd Font"
                font.pixelSize: 24
              }

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "No notifications"
                color: wallust.barMutedText
                font.family: "Hack Nerd Font"
                font.pixelSize: 14
              }
            }
          }

          Flickable {
            visible: barWindow.notificationCount > 0
            width: parent.width
            height: Math.min(430, notificationList.implicitHeight)
            contentWidth: width
            contentHeight: notificationList.implicitHeight
            clip: true

            Column {
              id: notificationList

              width: parent.width
              spacing: 8

              Repeater {
                model: barWindow.notifications ? barWindow.notifications.trackedNotifications : null

                Rectangle {
                  required property var modelData
                  readonly property var notification: modelData

                  width: notificationList.width
                  implicitHeight: notificationCardContent.implicitHeight + 20
                  radius: 14
                  color: notificationMouse.containsMouse ? wallust.barHover : "transparent"
                  border.width: 1
                  border.color: barWindow.notificationAccent(notification)

                  MouseArea {
                    id: notificationMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                  }

                  Column {
                    id: notificationCardContent

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 10
                    spacing: 8

                    Row {
                      width: parent.width
                      spacing: 10

                      IconImage {
                        width: 28
                        height: 28
                        implicitSize: 22
                        source: barWindow.notificationIcon(notification)
                      }

                      Column {
                        width: parent.width - 28 - dismissButton.width - parent.spacing * 2
                        spacing: 2

                        Text {
                          width: parent.width
                          text: notification.summary && notification.summary.length > 0 ? notification.summary : notification.appName
                          color: wallust.barText
                          elide: Text.ElideRight
                          font.family: "Hack Nerd Font"
                          font.pixelSize: 14
                          font.bold: true
                        }

                        Text {
                          visible: notification.appName && notification.appName.length > 0
                          width: parent.width
                          text: notification.appName
                          color: wallust.barMutedText
                          elide: Text.ElideRight
                          font.family: "Hack Nerd Font"
                          font.pixelSize: 12
                        }
                      }

                      Rectangle {
                        id: dismissButton

                        width: 24
                        height: 24
                        radius: 12
                        color: dismissMouse.containsMouse ? wallust.barHover : "transparent"

                        Text {
                          anchors.centerIn: parent
                          text: "󰅖"
                          color: wallust.barMutedText
                          font.family: "Hack Nerd Font"
                          font.pixelSize: 13
                        }

                        MouseArea {
                          id: dismissMouse

                          anchors.fill: parent
                          hoverEnabled: true
                          cursorShape: Qt.PointingHandCursor

                          onClicked: notification.dismiss()
                        }
                      }
                    }

                    Text {
                      visible: notification.body && notification.body.length > 0
                      width: parent.width
                      text: notification.body
                      color: wallust.barText
                      textFormat: Text.StyledText
                      wrapMode: Text.Wrap
                      maximumLineCount: 6
                      elide: Text.ElideRight
                      font.family: "Hack Nerd Font"
                      font.pixelSize: 13
                    }

                    Image {
                      visible: notification.image && notification.image.length > 0
                      width: parent.width
                      height: visible ? Math.min(160, implicitHeight) : 0
                      source: notification.image
                      fillMode: Image.PreserveAspectCrop
                      clip: true
                    }

                    Row {
                      visible: notification.actions.length > 0
                      width: parent.width
                      spacing: 6

                      Repeater {
                        model: notification.actions

                        Rectangle {
                          required property var modelData
                          readonly property var action: modelData

                          width: actionLabel.implicitWidth + 16
                          height: 26
                          radius: 13
                          color: actionMouse.containsMouse ? wallust.barHover : "transparent"
                          border.width: 1
                          border.color: wallust.barBorder

                          Text {
                            id: actionLabel

                            anchors.centerIn: parent
                            text: action.text
                            color: wallust.barText
                            font.family: "Hack Nerd Font"
                            font.pixelSize: 12
                          }

                          MouseArea {
                            id: actionMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                              action.invoke();
                              notification.dismiss();
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

    Rectangle {
      id: centerPill

      anchors.centerIn: parent
      implicitWidth: clockLabel.implicitWidth + 18
      implicitHeight: 30
      radius: implicitHeight / 2
      color: clockMouse.containsMouse ? wallust.barHover : wallust.barBackground
      border.width: 1
      border.color: wallust.barBorder

      Behavior on color {
        ColorAnimation {
          duration: 120
        }
      }

      Text {
        id: clockLabel

        anchors.centerIn: parent
        text: "󰥔 " + Qt.formatDateTime(clock.date, "HH:mm | d MMM")
        color: wallust.barText
        font.family: "Hack Nerd Font"
        font.pixelSize: 15
      }

      MouseArea {
        id: clockMouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: barWindow.runCommand(["gnome-calendar"])
      }
    }
  }
}
