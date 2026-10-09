import QtQuick
import QtQuick.Controls

Button {
  id: root
  required property var wallust
  property string subtitle: ""
  property bool highlightedState: checked
  implicitHeight: subtitle.length > 0 ? 68 : 36
  implicitWidth: Math.max(60, labelMetrics.advanceWidth + 28)
  leftPadding: 12
  rightPadding: 12
  topPadding: 8
  bottomPadding: 8
  hoverEnabled: true
  Keys.onReturnPressed: if (enabled) clicked()
  Keys.onEnterPressed: if (enabled) clicked()
  font.family: wallust.textFont
  font.pixelSize: 13
  font.weight: highlightedState ? Font.DemiBold : Font.Normal
  TextMetrics { id: labelMetrics; text: root.text; font: root.font }

  background: Rectangle {
    radius: 10
    color: root.highlightedState ? root.wallust.barActive : root.hovered ? Qt.tint(root.wallust.barCard, root.wallust.barHover) : root.wallust.barCard
    border.width: root.activeFocus ? 2 : 0
    border.color: root.wallust.barAccentText
    opacity: root.enabled ? 1 : 0.55
    Behavior on color { ColorAnimation { duration: 100 } }
  }
  contentItem: Item {
    implicitHeight: root.subtitle.length > 0 ? 36 : 18
    Column {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      spacing: 3
      opacity: root.enabled ? 1 : 0.55
      Text {
        width: parent.width
        text: root.text
        font: root.font
        color: root.highlightedState ? root.wallust.barAccentText : root.wallust.barText
        elide: Text.ElideRight
        horizontalAlignment: root.subtitle.length > 0 ? Text.AlignLeft : Text.AlignHCenter
      }
      Text {
        width: parent.width
        visible: root.subtitle.length > 0
        text: root.subtitle
        font.family: root.wallust.textFont
        font.pixelSize: 11
        color: root.wallust.barMutedText
        elide: Text.ElideRight
      }
    }
  }
}
