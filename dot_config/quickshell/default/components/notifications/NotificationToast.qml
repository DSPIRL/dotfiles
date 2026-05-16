import QtQuick
import Quickshell
import Quickshell.Widgets

PopupWindow {
  id: root

  property var bar
  property var wallust
  property var notification
  property var timer

  visible: bar && bar.toastVisible && notification && !bar.notificationPanelOpen
  implicitWidth: 390
  implicitHeight: toastContent.implicitHeight
  color: "transparent"

  anchor {
    window: bar
    adjustment: PopupAdjustment.Slide | PopupAdjustment.Resize

    rect {
      x: Math.round((bar.width - root.width) / 2)
      y: Math.round(bar.height + 12)
      width: root.width
      height: root.height
    }
  }

  onVisibleChanged: if (!visible && timer) {
    timer.stop();
  }

  Rectangle {
    id: toastContent

    implicitHeight: toastColumn.implicitHeight + 20
    anchors.fill: parent
    radius: 18
    color: wallust.barBackground
    border.width: 1
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
      anchors.margins: 10
      spacing: 8

      Row {
        width: parent.width
        spacing: 10

        IconImage {
          width: 28
          height: 28
          implicitSize: 22
          source: bar.notificationIcon(notification)
        }

        Column {
          width: parent.width - 28 - toastDismissButton.width - parent.spacing * 2
          spacing: 2

          Text {
            width: parent.width
            text: notification ? (notification.summary && notification.summary.length > 0 ? notification.summary : notification.appName) : ""
            color: wallust.barText
            elide: Text.ElideRight
            font.family: "Hack Nerd Font"
            font.pixelSize: 14
            font.bold: true
          }

          Text {
            visible: Boolean(notification && notification.appName && notification.appName.length > 0)
            width: parent.width
            text: notification ? notification.appName : ""
            color: wallust.barMutedText
            elide: Text.ElideRight
            font.family: "Hack Nerd Font"
            font.pixelSize: 12
          }
        }

        Rectangle {
          id: toastDismissButton

          width: 24
          height: 24
          radius: 12
          color: toastDismissMouse.containsMouse ? wallust.barHover : "transparent"

          Text {
            anchors.centerIn: parent
            text: "󰅖"
            color: wallust.barMutedText
            font.family: "Hack Nerd Font"
            font.pixelSize: 13
          }

          MouseArea {
            id: toastDismissMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: bar.toastVisible = false
          }
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
        font.family: "Hack Nerd Font"
        font.pixelSize: 13
      }
    }
  }
}
