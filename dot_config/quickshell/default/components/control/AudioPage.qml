import QtQuick
import "../.." as Style

Column {
  id: root
  required property var bar
  required property var wallust
  spacing: Style.Tokens.controlPageSpacing
  function dismissDetails() { return output.dismissDetails() || microphone.dismissDetails(); }
  AudioDeviceControl {
    id: output
    width: parent.width
    bar: root.bar
    wallust: root.wallust
    devices: root.bar.audioOutputDevices
    defaultDevice: root.bar.defaultAudioSink
    onChooseDeviceChanged: if (chooseDevice) microphone.chooseDevice = false
  }
  AudioDeviceControl {
    id: microphone
    width: parent.width
    bar: root.bar
    wallust: root.wallust
    devices: root.bar.audioInputDevices
    defaultDevice: root.bar.defaultAudioSource
    input: true
    expanded: true
    onChooseDeviceChanged: if (chooseDevice) output.chooseDevice = false
  }
}
