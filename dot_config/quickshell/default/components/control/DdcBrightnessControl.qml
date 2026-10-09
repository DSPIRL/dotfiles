import QtQuick

Rectangle {
  id: root
  required property var bar
  required property var wallust
  required property var ddcDisplay
  readonly property real percent: ddcDisplay.maximum > 0 ? ddcDisplay.current / ddcDisplay.maximum * 100 : 0
  implicitHeight: 76
  height: implicitHeight
  radius: 12
  color: wallust.barCard
  Column {
    x: 12; y: 12
    width: parent.width - 24
    spacing: 5
    Text {
      width: parent.width
      text: root.ddcDisplay.monitor + "  ·  " + Math.round(slider.value) + "%"
      color: root.wallust.barText
      font.family: root.wallust.textFont
      font.pixelSize: 13
      elide: Text.ElideRight
    }
    ControlSlider {
      id: slider
      width: parent.width
      wallust: root.wallust
      value: root.percent
      Accessible.name: "Brightness: " + root.ddcDisplay.monitor
      onPressedChanged: if (!pressed) root.bar.setDdcBrightness(root.ddcDisplay.display, value, root.ddcDisplay.maximum)
      onMoved: if (!pressed) root.bar.setDdcBrightness(root.ddcDisplay.display, value, root.ddcDisplay.maximum)
    }
  }
}
