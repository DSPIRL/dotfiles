import QtQuick
import "../.." as Style

Rectangle {
  id: root
  required property var bar
  required property var wallust
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
      text: root.bar.laptopBrightnessState.available ? "Laptop brightness  ·  " + Math.round(slider.value) + "%" : "brightnessctl is not installed"
      color: root.wallust.barText
      font: Style.Typography.controlLabelFont
    }
    ControlSlider {
      id: slider
      width: parent.width
      wallust: root.wallust
      enabled: root.bar.laptopBrightnessState.available
      value: root.bar.laptopBrightnessState.percent
      Accessible.name: "Laptop brightness"
      onPressedChanged: if (!pressed) root.bar.setLaptopBrightness(value)
      onMoved: if (!pressed) root.bar.setLaptopBrightness(value)
    }
  }
}
