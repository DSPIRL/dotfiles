import QtQuick
import QtQuick.Controls
import ".."
import "../.." as Style

Column {
  id: root
  required property var bar
  required property var wallust
  readonly property var desktop: bar.desktopState
  readonly property bool ready: desktop.loaded && !desktop.busy
  required property var radios
  readonly property var wifi: radios.wifi

  function dismissDetails() {
    if (wifiMenu.visible) { wifiMenu.close(); return true; }
    if (bluetoothMenu.visible) { bluetoothMenu.close(); return true; }
    return false;
  }
  spacing: Style.Tokens.controlPageSpacing

  signal categoryRequested(string category)

  Text {
    width: parent.width
    text: root.bar.hasBattery ? root.bar.batteryPercent + "% battery · " + (root.desktop.keepAwake ? "Keeping awake" : "Automatic idle locking enabled") : "Your desktop at a glance"
    textFormat: Text.PlainText
    font: Style.Typography.controlHintFont
    color: root.wallust.barMutedText
    wrapMode: Text.Wrap
  }
  Rectangle {
    width: parent.width
    implicitHeight: sound.implicitHeight + 24
    color: root.wallust.barCard
    radius: 16
    Column {
      id: sound
      x: 12; y: 12; width: parent.width - 24
      spacing: 8
      Row {
        width: parent.width
        height: Math.max(muteButton.implicitHeight, audioDetails.implicitHeight)
        spacing: 8
        ActionButton {
          id: muteButton
          objectName: "quickOutputMute"
          width: height
          height: parent.height
          leftPadding: 8
          rightPadding: 8
          wallust: root.wallust
          text: root.bar.volumeIcon(root.bar.defaultAudioSink && root.bar.defaultAudioSink.audio ? root.bar.defaultAudioSink.audio.volume : 0, Boolean(root.bar.defaultAudioSink && root.bar.defaultAudioSink.audio && root.bar.defaultAudioSink.audio.muted))
          font: Style.Typography.controlTileIconFont
          enabled: Boolean(root.bar.defaultAudioSink && root.bar.defaultAudioSink.audio)
          Accessible.name: root.bar.defaultAudioSink && root.bar.defaultAudioSink.audio && root.bar.defaultAudioSink.audio.muted ? "Unmute output" : "Mute output"
          onClicked: root.bar.toggleAudioDeviceMute(root.bar.defaultAudioSink)
        }
        ActionButton {
          id: audioDetails
          width: parent.width - muteButton.width - parent.spacing
          height: parent.height
          wallust: root.wallust
          text: root.bar.defaultAudioSink && root.bar.defaultAudioSink.audio ? "Output · " + (root.bar.defaultAudioSink.audio.muted ? "Muted" : Math.round(root.bar.defaultAudioSink.audio.volume * 100) + "%") + "  ›" : "Audio settings  ›"
          Accessible.name: "Open audio settings"
          onClicked: root.categoryRequested("audio")
        }
      }
      ControlSlider {
        width: parent.width
        wallust: root.wallust
        enabled: Boolean(root.bar.defaultAudioSink && root.bar.defaultAudioSink.audio)
        value: enabled ? root.bar.defaultAudioSink.audio.volume * 100 : 0
        Accessible.name: "Output volume"
        onMoved: root.bar.setAudioDeviceVolume(root.bar.defaultAudioSink, value / 100)
      }
    }
  }
  Repeater {
    model: !root.bar.showLaptopBrightnessControl && root.bar.ddcBrightnessState.displays.length > 0 ? [root.bar.ddcBrightnessState.displays[0]] : []
    DdcBrightnessControl {
      required property var modelData
      width: root.width
      bar: root.bar
      wallust: root.wallust
      ddcDisplay: modelData
    }
  }
  LaptopBrightnessControl {
    visible: root.bar.showLaptopBrightnessControl
    width: parent.width
    bar: root.bar
    wallust: root.wallust
  }
  Grid {
    width: parent.width
    columns: 2
    spacing: 8
    ActionButton {
      width: (parent.width - 8) / 2
      wallust: root.wallust
      objectName: "quickNetwork"
      symbol: ""
      text: "Wi-Fi"
      subtitle: !root.radios.wifiAvailable ? "NetworkManager unavailable" : !root.wifi.wifiHardwareEnabled ? "Hardware blocked" : root.radios.wifiError || (root.radios.wifiPending ? "Changing…" : root.wifi.wifiEnabled ? "On" : "Off")
      enabled: !root.radios.wifiPending && root.radios.wifiAvailable && root.wifi.wifiHardwareEnabled
      highlightedState: root.wifi.wifiEnabled
      Accessible.name: root.wifi.wifiEnabled ? "Turn Wi-Fi off" : "Turn Wi-Fi on"
      Accessible.role: Accessible.CheckBox
      Accessible.checked: root.wifi.wifiEnabled
      Accessible.description: subtitle + ". When this tile is enabled, right-click, press the Menu key, or press Shift+F10 for network settings."
      ToolTip.visible: hovered
      ToolTip.text: "Right-click for network settings"
      onClicked: root.radios.toggleWifi()
      Keys.onPressed: event => { if (event.key === Qt.Key_Menu || (event.key === Qt.Key_F10 && (event.modifiers & Qt.ShiftModifier))) { wifiMenu.open(); event.accepted = true; } }
      TapHandler { acceptedButtons: Qt.RightButton; onTapped: wifiMenu.open() }
      Menu {
        id: wifiMenu
        objectName: "wifiMenu"
        x: 0; y: parent.height
        MenuItem { objectName: "wifiSettings"; text: "Open network settings"; enabled: root.ready && Boolean(root.desktop.values.networkSettings); onTriggered: root.bar.launchNetworkTui() }
      }
    }
    ActionButton {
      width: (parent.width - 8) / 2
      wallust: root.wallust
      symbol: ""
      text: "Bluetooth"
      objectName: "quickBluetooth"
      subtitle: !root.bar.bluetoothAdapter ? "Adapter unavailable" : root.radios.bluetoothBlocked ? "Hardware blocked" : root.radios.bluetoothError || (root.radios.bluetoothPending || root.radios.bluetoothChanging ? "Changing…" : root.bar.bluetoothTooltip)
      enabled: !root.radios.bluetoothPending && Boolean(root.bar.bluetoothAdapter) && !root.radios.bluetoothBlocked && !root.radios.bluetoothChanging
      highlightedState: Boolean(root.bar.bluetoothAdapter && root.bar.bluetoothAdapter.enabled)
      Accessible.name: highlightedState ? "Turn Bluetooth off" : "Turn Bluetooth on"
      Accessible.role: Accessible.CheckBox
      Accessible.checked: highlightedState
      Accessible.description: subtitle + ". When this tile is enabled, right-click, press the Menu key, or press Shift+F10 for Bluetooth settings."
      ToolTip.visible: hovered
      ToolTip.text: "Right-click for Bluetooth settings"
      onClicked: root.radios.toggleBluetooth()
      Keys.onPressed: event => { if (event.key === Qt.Key_Menu || (event.key === Qt.Key_F10 && (event.modifiers & Qt.ShiftModifier))) { bluetoothMenu.open(); event.accepted = true; } }
      TapHandler { acceptedButtons: Qt.RightButton; onTapped: bluetoothMenu.open() }
      Menu {
        id: bluetoothMenu
        objectName: "bluetoothMenu"
        x: 0; y: parent.height
        MenuItem { objectName: "bluetoothSettings"; text: "Open Bluetooth settings"; enabled: root.ready && Boolean(root.desktop.values.bluetoothSettings); onTriggered: root.bar.runCommand(["blueman-manager"]) }
      }
    }
    ActionButton {
      width: (parent.width - 8) / 2
      wallust: root.wallust
      symbol: "󰖔"
      text: "Night light"
      subtitle: root.desktop.values.nightLight ? "Warm display · 4000 K" : root.desktop.values.nightLightWanted ? "Saved on · currently inactive" : "Off"
      highlightedState: Boolean(root.desktop.values.nightLightWanted)
      enabled: root.ready && Boolean(root.desktop.values.nightLightAvailable || root.desktop.values.nightLightWanted)
      onClicked: root.desktop.effect("night-light", !root.desktop.values.nightLightWanted)
    }
    ActionButton {
      width: (parent.width - 8) / 2
      wallust: root.wallust
      symbol: "󰅶"
      text: "Keep awake"
      subtitle: root.desktop.keepAwakeRequested && root.desktop.keepAwakeFailed ? "Saved on · inhibitor unavailable" : root.desktop.keepAwake ? "On · manual locking still works" : "Off"
      highlightedState: root.desktop.keepAwakeRequested
      enabled: root.desktop.loaded
      onClicked: root.desktop.setKeepAwake(!root.desktop.keepAwakeRequested)
    }
    ActionButton {
      width: (parent.width - 8) / 2
      wallust: root.wallust
      symbol: "󰂛"
      text: "Quiet notifications"
      subtitle: root.desktop.quiet ? "On · critical alerts still shown" : "Off · show notification popups"
      highlightedState: root.desktop.quiet
      enabled: root.desktop.loaded
      onClicked: root.desktop.setQuiet(!root.desktop.quiet)
    }
    ActionButton {
      width: (parent.width - 8) / 2
      wallust: root.wallust
      symbol: "󰍹"
      text: "Display settings"
      subtitle: "Brightness · resolution · Night light"
      onClicked: root.categoryRequested("display")
    }
  }
}
