import QtQuick
import QtQuick.Controls

Slider {
  id: root
  required property var wallust
  from: 0
  to: 100
  stepSize: 1
  implicitHeight: 28
  leftPadding: 7
  rightPadding: 7
  wheelEnabled: true

  background: Rectangle {
    x: root.leftPadding
    y: (root.height - height) / 2
    width: root.availableWidth
    height: 5
    radius: 3
    color: root.wallust.barSeparator
    Rectangle {
      width: root.visualPosition * parent.width
      height: parent.height
      radius: 3
      color: root.wallust.barAccentText
    }
  }
  handle: Rectangle {
    x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
    y: (root.height - height) / 2
    width: root.activeFocus ? 16 : 12
    height: width
    radius: width / 2
    color: root.wallust.barAccentText
    border.width: root.activeFocus ? 2 : 0
    border.color: root.wallust.barText
  }
}
