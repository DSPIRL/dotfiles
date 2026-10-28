import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Notifications
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Wayland

import ".." as Style
import "../wallust" as Wallust
import "bar"
import "control"
import "notifications"
import "Presentation.js" as Presentation

PanelWindow {
  id: barWindow

  readonly property int pillMargin: 4

  anchors {
    top: true
    left: true
    right: true
  }

  margins {
    top: 0
    left: 0
    right: 0
  }

  implicitHeight: Style.Tokens.barPillHeight + pillMargin * 2
  // Keep the surface mapped so Hyprland cannot add a second show/hide animation.
  // Once hidden it reserves no space and accepts no input.
  visible: true
  exclusionMode: ExclusionMode.Normal
  exclusiveZone: barVisible || barReveal > 0 ? implicitHeight : 0
  color: "transparent"

  property real barReveal: barVisible ? 1 : 0
  readonly property bool barInteractive: barVisible && barReveal === 1

  Behavior on barReveal {
    enabled: !wallust.lowEffects
    NumberAnimation {
      id: revealAnimation
      duration: 200
      easing.type: Easing.OutCubic
    }
  }

  WlrLayershell.namespace: "quickshell"

  // Only the glass islands receive input; gaps remain part of the desktop.
  mask: Region {
    Region { x: barWindow.pillMargin; y: barWindow.pillMargin; width: barWindow.barInteractive ? workspacePill.width : 0; height: workspacePill.height; radius: workspacePill.radius }
    Region { x: barWindow.width - rightPill.width - barWindow.pillMargin; y: barWindow.pillMargin; width: barWindow.barInteractive ? rightPill.width : 0; height: rightPill.height; radius: rightPill.radius }
    Region {
      x: clockPill.x
      y: clockPill.y
      width: barWindow.barInteractive && clockPill.visible ? clockPill.width : 0
      height: clockPill.height
      radius: clockPill.radius
    }
  }

  Wallust.Colors {
    id: wallust
    lightMode: barWindow.desktopState && barWindow.desktopState.values.theme === "light"
    lowEffects: Boolean(barWindow.desktopState && barWindow.desktopState.values.lowEffects)
    onLowEffectsChanged: if (lowEffects) revealAnimation.complete()
    glassOpacity: barWindow.desktopState ? barWindow.desktopState.glassOpacity / 100 : 0.4
    solidSurfaces: lowEffects || !Boolean(barWindow.desktopState && barWindow.desktopState.values.effectiveShellGlass)
  }

  // Control fills have their own opacity, independent of shell glass.
  Wallust.Colors {
    id: controlColors
    lightMode: wallust.lightMode
    lowEffects: wallust.lowEffects
    solidSurfaces: wallust.solidSurfaces
    glassOpacity: wallust.glassOpacity
    controlCenter: true
    controlOpacity: barWindow.desktopState ? barWindow.desktopState.controlOpacity / 100 : 1
  }

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  AudioState { id: audioState; pipewire: Pipewire }

  PwObjectTracker {
    objects: audioState.audioTrackedNodes
  }

  property var hyprMonitor: Hyprland.monitorFor(screen)
  property var notifications
  property int notificationToggleGeneration: 0
  property int controlToggleGeneration: 0
  property int sessionToggleGeneration: 0
  property var desktopState
  property var radioState
  signal setBarVisible(bool value)
  signal sessionRequested()
  signal categoryRequested(string category)
  property bool barVisible: true
  readonly property string networkStatus: networkState.tooltip
  readonly property string wifiStatus: networkState.wifiTooltip
  property var focusedHyprMonitor
  property var ddcBrightnessState
  property var laptopBrightnessState
  property bool controlPanelOpen: false
  property bool notificationPanelOpen: false
  property var toastNotification
  property bool toastVisible: false
  readonly property int notificationCount: notifications ? notifications.trackedNotifications.values.length : 0

  onNotificationToggleGenerationChanged: {
    const focused = isFocusedMonitor();
    notificationPanelOpen = focused ? !notificationPanelOpen : false;
  }

  onControlToggleGenerationChanged: {
    const focused = isFocusedMonitor();
    controlPanelOpen = focused ? !controlPanelOpen : false;
  }

  onSessionToggleGenerationChanged: {
    controlPanelOpen = isFocusedMonitor();
    if (controlPanelOpen) sessionRequested();
  }

  onBarVisibleChanged: if (!barVisible) {
    notificationPanelOpen = false;
    toastVisible = false;
  }

  onNotificationPanelOpenChanged: if (notificationPanelOpen) {
    toastVisible = false;
    controlPanelOpen = false;
  }

  onControlPanelOpenChanged: if (controlPanelOpen) {
    toastVisible = false;
    notificationPanelOpen = false;
  }

  readonly property var workspaceGlyphs: ({
    "1": "1",
    "2": "2",
    "3": "3",
    "4": "4",
    "5": "5",
    "6": "6",
    "7": "7",
    "8": "8",
    "9": "9",
    "10": "0"
    // "1": "一",
    // "2": "二",
    // "3": "三",
    // "4": "四",
    // "5": "五",
    // "6": "六",
    // "7": "七",
    // "8": "八",
    // "9": "九",
    // "10": "十"
  })

  readonly property var defaultAudioSink: audioState.defaultAudioSink
  readonly property var defaultAudioSource: audioState.defaultAudioSource
  readonly property bool sinkMuted: audioState.sinkMuted
  readonly property real sinkVolume: audioState.sinkVolume
  readonly property var audioOutputDevices: audioState.audioOutputDevices
  readonly property var audioInputDevices: audioState.audioInputDevices

  readonly property var bluetoothAdapter: radioState.adapter
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
  readonly property int batteryPercent: hasBattery ? Presentation.normalizeBatteryPercent(displayBattery) : 0
  readonly property bool showLaptopBrightnessControl: Boolean(laptopBrightnessState && (laptopBrightnessState.available || laptopBrightnessState.missingTool))

  readonly property color batteryTextColor: Presentation.batteryTextColor(
    hasBattery, hasBattery ? displayBattery.state : null, batteryPercent,
    UPowerDeviceState.Discharging, UPowerDeviceState.PendingDischarge, wallust)

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
  readonly property string spotifyDisplay: Presentation.spotifyTextForPlayer(spotifyPlayer, MprisPlaybackState.Stopped, MprisPlaybackState.Paused)

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

  function setDdcBrightness(display, percent, maximum) {
    if (ddcBrightnessState) {
      ddcBrightnessState.setBrightness(display, percent, maximum);
    }
  }

  function setLaptopBrightness(percent) {
    if (laptopBrightnessState) {
      laptopBrightnessState.setBrightness(percent);
    }
  }

  function audioNodeLabel(node) { return audioState.audioNodeLabel(node); }
  function isDefaultAudioDevice(node, input) { return audioState.isDefaultAudioDevice(node, input); }
  function setDefaultAudioDevice(node, input) { audioState.setDefaultAudioDevice(node, input); }
  function setAudioDeviceVolume(node, volume) { audioState.setAudioDeviceVolume(node, volume); }
  function toggleAudioDeviceMute(node) { audioState.toggleAudioDeviceMute(node); }

  function workspaceText(workspace) {
    return Presentation.workspaceText(workspace, workspaceGlyphs);
  }

  function isFocusedMonitor() {
    if (!focusedHyprMonitor || !hyprMonitor) {
      return true;
    }

    return focusedHyprMonitor.id === hyprMonitor.id;
  }

  function notificationAccent(notification) {
    return Presentation.notificationAccent(notification, NotificationUrgency.Critical, wallust);
  }

  function notificationIcon(notification) {
    return Presentation.notificationIcon(notification, function(icon) { return Quickshell.iconPath(icon); });
  }

  function notificationToastDuration(notification) {
    return Presentation.notificationToastDuration(notification, NotificationUrgency.Critical, NotificationUrgency.Low);
  }

  function showNotificationToast(notification) {
    if (!notification || !isFocusedMonitor() || ((!desktopState.loaded || desktopState.quiet) && notification.urgency !== NotificationUrgency.Critical)) {
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
    target: barWindow.desktopState
    function onQuietChanged() {
      if (barWindow.desktopState.quiet && barWindow.toastNotification && barWindow.toastNotification.urgency !== NotificationUrgency.Critical)
        barWindow.toastVisible = false;
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
    return Presentation.volumeIcon(volume, muted);
  }

  function batteryIcon(percent, state) {
    return Presentation.batteryIcon(percent, state, UPowerDeviceState.Charging, UPowerDeviceState.PendingCharge);
  }

  function launchNetworkTui() {
    launchTerminal("nmtui");
  }

  NetworkState {
    id: networkState
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
        networkState.unavailable();
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

  NotificationToast {
    bar: barWindow
    wallust: wallust
    notification: barWindow.toastNotification
    timer: toastTimer
  }

  NotificationPanel {
    bar: barWindow
    wallust: wallust
  }

  ControlPanel {
    bar: barWindow
    wallust: controlColors
  }

  Item {
    anchors.fill: parent
    opacity: barWindow.barReveal
    visible: barWindow.barReveal > 0
    enabled: barWindow.barInteractive
    transform: Translate { y: -12 * (1 - barWindow.barReveal) }

    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: barWindow.pillMargin
      anchors.rightMargin: barWindow.pillMargin
      anchors.topMargin: barWindow.pillMargin
      anchors.bottomMargin: barWindow.pillMargin
      spacing: 12

      WorkspacePill {
        id: workspacePill
        bar: barWindow
        wallust: wallust
      }

      Item { Layout.fillWidth: true }

      RightPill {
        id: rightPill
        bar: barWindow
        wallust: wallust
        networkState: networkState
      }
    }

    ClockPill {
      id: clockPill
      x: (parent.width - width) / 2
      y: barWindow.pillMargin
      visible: x > workspacePill.width + barWindow.pillMargin + 12 && x + width < parent.width - rightPill.width - barWindow.pillMargin - 12
      bar: barWindow
      wallust: wallust
      clock: clock
    }
  }
}
