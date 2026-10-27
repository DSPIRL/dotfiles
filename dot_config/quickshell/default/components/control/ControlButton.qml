import QtQuick
import QtQuick.Controls
import "../.." as Style

Button {
  id: root
  required property var wallust
  property string subtitle: ""
  property bool highlightedState: checked
  implicitHeight: Math.max(subtitle.length > 0 ? 68 : 36, contentItem.implicitHeight + topPadding + bottomPadding)
  implicitWidth: Math.max(60, labelMetrics.advanceWidth + 28)
  leftPadding: 12
  rightPadding: 12
  topPadding: 8
  bottomPadding: 8
  hoverEnabled: true
  Keys.onReturnPressed: if (enabled) clicked()
  Keys.onEnterPressed: if (enabled) clicked()
  font: highlightedState ? Style.Typography.controlEmphasisFont : Style.Typography.controlLabelFont
  TextMetrics { id: labelMetrics; text: root.text; font: root.font }

  background: Rectangle {
    radius: 14
    color: root.highlightedState ? root.wallust.barActive : root.hovered ? root.wallust.barButtonHover : root.wallust.barCard
    border.width: root.activeFocus ? 2 : 1
    border.color: root.activeFocus ? root.wallust.barAccentText : root.wallust.barSeparator
    // Disabled control-center buttons dim labels, not their configured fill opacity.
    opacity: root.enabled || root.wallust.controlCenter ? 1 : 0.55
    Behavior on color { enabled: !root.wallust.lowEffects; ColorAnimation { duration: 140 } }
  }
  contentItem: Item {
    implicitHeight: labels.implicitHeight
    Column {
      id: labels
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
        font: Style.Typography.controlHintFont
        color: root.wallust.barMutedText
        elide: Text.ElideRight
      }
    }
  }
}
