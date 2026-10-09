import QtQuick
import QtQuick.Controls

Switch {
  id: root
  required property var wallust
  property string subtitle: ""
  implicitHeight: subtitle.length > 0 ? 58 : 42
  leftPadding: 12
  rightPadding: 12
  hoverEnabled: true

  background: Rectangle {
    radius: 10
    color: root.hovered ? root.wallust.barHover : "transparent"
    border.width: root.activeFocus ? 2 : 0
    border.color: root.wallust.barAccentText
  }
  indicator: Rectangle {
    x: root.width - width - root.rightPadding
    y: (root.height - height) / 2
    width: 36
    height: 20
    radius: 10
    color: root.checked ? root.wallust.barAccentText : root.wallust.barMutedText
    opacity: root.enabled ? 1 : 0.5
    Rectangle {
      x: root.checked ? 19 : 3
      y: 3
      width: 14
      height: 14
      radius: 7
      color: root.wallust.lightMode ? "#FFFFFF" : "#171B22"
      Behavior on x { NumberAnimation { duration: 100 } }
    }
  }
  contentItem: Item {
    implicitHeight: root.subtitle.length > 0 ? 34 : 18
    Column {
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width - 50
      spacing: 3
      opacity: root.enabled ? 1 : 0.6
      Text {
        width: parent.width
        text: root.text
        color: root.wallust.barText
        font.family: root.wallust.textFont
        font.pixelSize: 13
        elide: Text.ElideRight
      }
      Text {
        width: parent.width
        visible: root.subtitle.length > 0
        text: root.subtitle
        color: root.wallust.barMutedText
        font.family: root.wallust.textFont
        font.pixelSize: 11
        elide: Text.ElideRight
      }
    }
  }
}
