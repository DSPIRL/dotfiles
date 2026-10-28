import QtQuick
import "../.." as Style

Rectangle {
  id: root
  required property var bar
  required property var wallust
  required property var ddcDisplay
  readonly property real percent: ddcDisplay.maximum > 0 ? ddcDisplay.current / ddcDisplay.maximum * 100 : 0
  implicitHeight: contents.implicitHeight + 2 * Style.Tokens.deviceCardInset
  height: implicitHeight
  radius: Style.Tokens.deviceCardRadius
  color: wallust.barCard
  Column {
    id: contents
    x: Style.Tokens.deviceCardInset; y: Style.Tokens.deviceCardInset
    width: parent.width - 2 * Style.Tokens.deviceCardInset
    spacing: 5
    Text {
      width: parent.width
      text: root.ddcDisplay.monitor + "  ·  " + Math.round(slider.value) + "%"
      color: root.wallust.barText
      font: Style.Typography.controlLabelFont
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
