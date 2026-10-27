import QtQuick
import QtQuick.Controls
import "../.." as Style

Column {
  id: root
  required property var bar
  required property var wallust
  readonly property var desktop: bar.desktopState
  readonly property bool ready: desktop.loaded && !desktop.busy
  spacing: 12

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
        ControlButton {
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
        ControlButton {
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
    ControlButton {
      width: (parent.width - 8) / 2
      wallust: root.wallust
      symbol: ""
      text: "Network"
      subtitle: root.bar.networkStatus
      enabled: root.ready && Boolean(root.desktop.values.networkSettings)
      Accessible.name: "Open network settings"
      ToolTip.visible: hovered
      ToolTip.text: "Open network settings in nmtui"
      onClicked: root.bar.launchNetworkTui()
    }
    ControlButton {
      width: (parent.width - 8) / 2
      wallust: root.wallust
      symbol: ""
      text: "Bluetooth"
      subtitle: root.desktop.values.bluetoothSettings ? root.bar.bluetoothTooltip : "Install blueman for settings"
      highlightedState: Boolean(root.bar.bluetoothAdapter && root.bar.bluetoothAdapter.enabled)
      enabled: root.ready && Boolean(root.desktop.values.bluetoothSettings)
      Accessible.name: "Open Bluetooth settings"
      ToolTip.visible: hovered
      ToolTip.text: "Open Bluetooth settings in Blueman"
      onClicked: root.bar.runCommand(["blueman-manager"])
    }
    ControlButton {
      width: (parent.width - 8) / 2
      wallust: root.wallust
      symbol: "󰖔"
      text: "Night light"
      subtitle: root.desktop.values.nightLight ? "Warm display · 4000 K" : root.desktop.values.nightLightWanted ? "Saved on · currently inactive" : "Off"
      highlightedState: Boolean(root.desktop.values.nightLightWanted)
      enabled: root.ready && Boolean(root.desktop.values.nightLightAvailable || root.desktop.values.nightLightWanted)
      onClicked: root.desktop.effect("night-light", !root.desktop.values.nightLightWanted)
    }
    ControlButton {
      width: (parent.width - 8) / 2
      wallust: root.wallust
      symbol: "󰅶"
      text: "Keep awake"
      subtitle: root.desktop.keepAwakeRequested && root.desktop.keepAwakeFailed ? "Saved on · inhibitor unavailable" : root.desktop.keepAwake ? "On · manual locking still works" : "Off"
      highlightedState: root.desktop.keepAwakeRequested
      enabled: root.desktop.loaded
      onClicked: root.desktop.setKeepAwake(!root.desktop.keepAwakeRequested)
    }
    ControlButton {
      width: (parent.width - 8) / 2
      wallust: root.wallust
      symbol: "󰂛"
      text: "Quiet notifications"
      subtitle: root.desktop.quiet ? "On · critical alerts still shown" : "Off · show notification popups"
      highlightedState: root.desktop.quiet
      enabled: root.desktop.loaded
      onClicked: root.desktop.setQuiet(!root.desktop.quiet)
    }
    ControlButton {
      width: (parent.width - 8) / 2
      wallust: root.wallust
      symbol: "󰍹"
      text: "Display settings"
      subtitle: "Brightness · resolution · Night light"
      onClicked: root.categoryRequested("display")
    }
  }
}
