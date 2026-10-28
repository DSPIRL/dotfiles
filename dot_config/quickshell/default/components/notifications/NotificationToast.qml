import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import ".."
import "../.." as Style

PanelWindow {
  id: root

  property var bar
  property var wallust
  property var notification
  property var timer

  visible: bar && bar.toastVisible && notification && !bar.notificationPanelOpen && !bar.controlPanelOpen
  implicitWidth: Math.min(440, screen ? screen.width - 24 : 440)
  implicitHeight: toastContent.implicitHeight
  color: "transparent"
  screen: bar ? bar.screen : null
  exclusionMode: ExclusionMode.Ignore

  anchors { top: true; right: true }

  margins {
    top: bar && bar.barVisible ? bar.height + 12 : 12
    right: 12
  }

  WlrLayershell.namespace: "quickshell"

  onVisibleChanged: if (!visible && timer) {
    timer.stop();
  }

  GlassSurface {
    id: toastContent

    implicitHeight: toastColumn.implicitHeight + 32
    anchors.fill: parent
    wallust: root.wallust
    radius: Style.Tokens.panelRadius
    border.color: bar.notificationAccent(notification)

    MouseArea {
      id: toastMouse

      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor

      onClicked: {
        bar.toastVisible = false;
        bar.notificationPanelOpen = true;
      }
    }

    Column {
      id: toastColumn

      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: 16
      spacing: 8

      Row {
        width: parent.width
        spacing: 10

        IconImage {
          width: Style.Tokens.notificationAppIconSize
          height: Style.Tokens.notificationAppIconSize
          implicitSize: 22
          source: bar.notificationIcon(notification)
        }

        Column {
          width: parent.width - Style.Tokens.notificationAppIconSize - toastDismissButton.width - parent.spacing * 2
          spacing: 2

          Text {
            width: parent.width
            text: notification ? (notification.summary && notification.summary.length > 0 ? notification.summary : notification.appName) : ""
            color: wallust.barText
            elide: Text.ElideRight
            font: Style.Typography.notificationTitleFont
          }

          Text {
            visible: Boolean(notification && notification.appName && notification.appName.length > 0)
            width: parent.width
            text: notification ? notification.appName : ""
            color: wallust.barMutedText
            elide: Text.ElideRight
            font: Style.Typography.notificationMetaFont
          }
        }

        ActionButton {
          id: toastDismissButton
          width: Math.max(32, font.pixelSize + 8)
          height: Math.max(Style.Tokens.notificationActionMinHeight, contentItem.implicitHeight + 8)
          leftPadding: 4
          rightPadding: 4
          wallust: root.wallust
          font: Style.Typography.notificationActionFont
          text: "×"
          Accessible.name: "Hide notification popup"
          onClicked: root.bar.toastVisible = false
        }
      }

      Text {
        visible: Boolean(notification && notification.body && notification.body.length > 0)
        width: parent.width
        text: notification ? notification.body : ""
        color: wallust.barText
        textFormat: Text.StyledText
        wrapMode: Text.Wrap
        maximumLineCount: 3
        elide: Text.ElideRight
        font: Style.Typography.notificationBodyFont
      }
    }
  }
}
