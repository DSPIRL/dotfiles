import QtQuick
import QtQuick.Controls

Rectangle {
  id: root
  required property var bar
  required property var wallust
  property var devices: []
  property var defaultDevice
  property bool input: false
  property bool expanded: !input
  property bool chooseDevice: false
  readonly property bool available: Boolean(defaultDevice && defaultDevice.audio)
  readonly property bool muted: available && defaultDevice.audio.muted
  implicitHeight: contents.implicitHeight + 24
  height: implicitHeight
  radius: 12
  color: wallust.barCard

  Column {
    id: contents
    x: 12; y: 12
    width: parent.width - 24
    spacing: 6
    Row {
      width: parent.width
      spacing: 8
      ControlButton {
        wallust: root.wallust
        width: 42
        text: root.input ? (root.muted ? "" : "") : root.bar.volumeIcon(root.available ? root.defaultDevice.audio.volume : 0, root.muted)
        font.family: root.wallust.iconFont
        highlightedState: root.muted
        enabled: root.available
        Accessible.name: root.input ? "Mute microphone" : "Mute output"
        onClicked: root.bar.toggleAudioDeviceMute(root.defaultDevice)
      }
      ControlButton {
        wallust: root.wallust
        width: parent.width - 50
        text: (root.input ? "Microphone" : "Output") + "  ·  " + (root.available ? (root.muted ? "Muted" : Math.round(root.defaultDevice.audio.volume * 100) + "%") : "Unavailable") + (root.input ? (root.expanded ? "  ▴" : "  ▾") : "")
        onClicked: root.expanded = !root.expanded
      }
    }
    ControlSlider {
      visible: root.expanded && root.available
      width: parent.width
      wallust: root.wallust
      value: root.available ? root.defaultDevice.audio.volume * 100 : 0
      Accessible.name: root.input ? "Microphone volume" : "Output volume"
      onMoved: root.bar.setAudioDeviceVolume(root.defaultDevice, value / 100)
    }
    ControlButton {
      visible: root.expanded
      width: parent.width
      wallust: root.wallust
      text: root.available ? root.bar.audioNodeLabel(root.defaultDevice) + "  ▾" : "Choose an audio device  ▾"
      enabled: root.devices.length > 0
      onClicked: root.chooseDevice = !root.chooseDevice
      ToolTip.visible: hovered
      ToolTip.text: root.available ? root.defaultDevice.description : "No devices found"
    }
    Column {
      visible: root.expanded && root.chooseDevice
      width: parent.width
      spacing: 4
      Repeater {
        model: root.devices
        ControlButton {
          required property var modelData
          width: parent.width
          wallust: root.wallust
          text: root.bar.audioNodeLabel(modelData)
          highlightedState: root.bar.isDefaultAudioDevice(modelData, root.input)
          onClicked: {
            root.bar.setDefaultAudioDevice(modelData, root.input);
            root.chooseDevice = false;
          }
        }
      }
    }
  }
}
