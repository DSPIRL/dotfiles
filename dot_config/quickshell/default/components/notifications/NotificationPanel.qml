import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
  id: root

  property var bar
  property var wallust

  visible: bar && bar.notificationPanelOpen
  implicitWidth: 390
  implicitHeight: Math.min(520, notificationPanelContent.implicitHeight)
  color: "transparent"
  screen: bar ? bar.screen : null
  focusable: visible
  exclusionMode: ExclusionMode.Ignore

  anchors {
    top: true
  }

  margins {
    top: bar ? bar.height + 12 : 50
  }

  WlrLayershell.namespace: "quickshell"

  onVisibleChanged: if (visible) {
    notificationPanelContent.forceActiveFocus();
  }

  Rectangle {
    id: notificationPanelContent

    anchors.fill: parent
    focus: true
    implicitHeight: notificationPanelColumn.implicitHeight + 24
    radius: 18
    color: wallust.barBackground
    border.width: 1
    border.color: wallust.barBorder

    Keys.onEscapePressed: bar.notificationPanelOpen = false

    Column {
      id: notificationPanelColumn

      x: 12
      y: 12
      width: parent.width - 24
      spacing: 10

      Row {
        width: parent.width
        height: 28
        spacing: 8

        Text {
          width: parent.width - clearAllButton.width - parent.spacing
          anchors.verticalCenter: parent.verticalCenter
          text: bar.notificationCount === 1 ? "1 notification" : bar.notificationCount + " notifications"
          color: wallust.barText
          font.family: "Hack Nerd Font"
          font.pixelSize: 15
          font.bold: true
        }

        Rectangle {
          id: clearAllButton

          visible: bar.notificationCount > 0
          width: clearAllLabel.implicitWidth + 16
          height: 26
          radius: 13
          color: clearAllMouse.containsMouse ? wallust.barHover : "transparent"
          border.width: 1
          border.color: wallust.barBorder

          Text {
            id: clearAllLabel

            anchors.centerIn: parent
            text: "Clear"
            color: wallust.barText
            font.family: "Hack Nerd Font"
            font.pixelSize: 13
          }

          MouseArea {
            id: clearAllMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: bar.clearNotifications()
          }
        }
      }

      Rectangle {
        visible: bar.notificationCount === 0
        width: parent.width
        height: 104
        radius: 14
        color: "transparent"
        border.width: 1
        border.color: wallust.barBorder

        Column {
          anchors.centerIn: parent
          spacing: 8

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "󰂚"
            color: wallust.barMutedText
            font.family: "Hack Nerd Font"
            font.pixelSize: 24
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "No notifications"
            color: wallust.barMutedText
            font.family: "Hack Nerd Font"
            font.pixelSize: 14
          }
        }
      }

      Flickable {
        visible: bar.notificationCount > 0
        width: parent.width
        height: Math.min(430, notificationList.implicitHeight)
        contentWidth: width
        contentHeight: notificationList.implicitHeight
        clip: true

        Column {
          id: notificationList
          width: parent.width
          spacing: 8

          Repeater {
            model: bar.notifications ? bar.notifications.trackedNotifications : null

            NotificationCard {
              required property var modelData
              width: notificationList.width
              notification: modelData
              bar: root.bar
              wallust: root.wallust
            }
          }
        }
      }
    }
  }
}
