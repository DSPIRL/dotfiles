import QtQuick
import QtQuick.Controls
import ".." as Style

Button {
  id: root
  required property var wallust
  property string subtitle: ""
  property string symbol: ""
  property bool highlightedState: checked
  implicitHeight: Math.max(subtitle.length > 0 ? 68 : 36, root.contentItem.implicitHeight + topPadding + bottomPadding)
  implicitWidth: Math.max(60, labelMetrics.advanceWidth + 28 + (symbol.length > 0 ? glyph.implicitWidth + 12 : 0))
  leftPadding: 12
  rightPadding: 12
  topPadding: 8
  bottomPadding: 8
  hoverEnabled: true
  Accessible.name: text
  Keys.onReturnPressed: if (enabled) clicked()
  Keys.onEnterPressed: if (enabled) clicked()
  font: highlightedState ? Style.Typography.controlEmphasisFont : Style.Typography.controlLabelFont
  TextMetrics { id: labelMetrics; text: root.text; font: root.font }

  background: Rectangle {
    id: buttonBackground
    radius: 14
    Binding on color { value: root.highlightedState ? root.wallust.barActive : root.hovered ? root.wallust.barButtonHover : root.flat ? "transparent" : root.wallust.barCard }
    border.width: root.activeFocus ? 2 : root.flat ? 0 : 1
    border.color: root.activeFocus ? root.wallust.barAccentText : root.wallust.barSeparator
    // Disabled control-center buttons dim labels, not their configured fill opacity.
    opacity: root.enabled || root.wallust.controlCenter ? 1 : 0.55
    Behavior on color {
      enabled: !root.wallust.lowEffects
      onEnabledChanged: if (!enabled) buttonBackground.color = targetValue
      ColorAnimation { duration: Style.Tokens.surfaceColorDuration }
    }
  }
  contentItem: Item {
    implicitHeight: Math.max(labels.implicitHeight, root.symbol.length > 0 ? glyph.implicitHeight : 0)
    Text {
      id: glyph
      visible: root.symbol.length > 0
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      text: root.symbol
      font: Style.Typography.controlTileIconFont
      color: root.highlightedState ? root.wallust.barAccentText : root.wallust.barText
      opacity: root.enabled ? 1 : 0.55
    }
    Column {
      id: labels
      anchors.left: parent.left
      anchors.leftMargin: root.symbol.length > 0 ? glyph.implicitWidth + 12 : 0
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      spacing: 3
      opacity: root.enabled ? 1 : 0.55
      Text {
        width: parent.width
        text: root.text
        textFormat: Text.PlainText
        font: root.font
        color: root.highlightedState ? root.wallust.barAccentText : root.wallust.barText
        elide: Text.ElideRight
        horizontalAlignment: root.subtitle.length > 0 || root.symbol.length > 0 ? Text.AlignLeft : Text.AlignHCenter
      }
      Text {
        width: parent.width
        visible: root.subtitle.length > 0
        text: root.subtitle
        textFormat: Text.PlainText
        font: Style.Typography.controlHintFont
        color: root.wallust.barMutedText
        elide: Text.ElideRight
      }
    }
  }
}
