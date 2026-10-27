import QtQuick
import "../.." as Style

Rectangle {
  id: root
  required property var bar
  required property var wallust
  implicitHeight: contents.implicitHeight + 24
  height: implicitHeight
  radius: 12
  color: wallust.barCard
  Column {
    id: contents
    x: 12; y: 12
    width: parent.width - 24
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
