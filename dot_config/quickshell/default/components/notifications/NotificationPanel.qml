import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import ".."
import "../.." as Style

PanelWindow {
  id: root

  property var bar
  property var wallust

  visible: bar && bar.notificationPanelOpen
  readonly property real maximumHeight: Math.min(520, screen ? screen.height - margins.top - 16 : 520)
  implicitWidth: Math.min(440, screen ? screen.width - 24 : 440)
  implicitHeight: Math.min(maximumHeight, notificationPanelContent.implicitHeight)
  color: "transparent"
  screen: bar ? bar.screen : null
  focusable: visible
  exclusionMode: ExclusionMode.Ignore

  anchors { top: true; right: true }

  margins {
    top: bar && bar.barVisible ? bar.height + 12 : 12
    right: 12
  }

  WlrLayershell.namespace: "quickshell"

  onVisibleChanged: if (visible) {
    closeButton.forceActiveFocus();
  }

  GlassSurface {
    id: notificationPanelContent

    anchors.fill: parent
    focus: true
    implicitHeight: notificationPanelColumn.implicitHeight + 40
    wallust: root.wallust
    radius: Style.Tokens.panelRadius

    Keys.onEscapePressed: bar.notificationPanelOpen = false

    Column {
      id: notificationPanelColumn

      x: 20
      y: 20
      width: parent.width - 40
      spacing: 12

      Row {
        id: panelHeader
        width: parent.width
        height: Math.max(36, title.implicitHeight, clearAllButton.height, closeButton.height)
        spacing: 8

        Text {
          id: title
          width: parent.width - closeButton.width - parent.spacing - (clearAllButton.visible ? clearAllButton.width + parent.spacing : 0)
          anchors.verticalCenter: parent.verticalCenter
          text: bar.notificationCount === 1 ? "1 notification" : bar.notificationCount + " notifications"
          color: wallust.barText
          font: Style.Typography.centerTitleFont
          elide: Text.ElideRight
        }

        ActionButton {
          id: clearAllButton
          visible: bar.notificationCount > 0
          width: Math.max(64, implicitWidth)
          wallust: root.wallust
          font: Style.Typography.centerButtonFont
          text: "Clear"
          Accessible.name: "Clear all notifications"
          onClicked: root.bar.clearNotifications()
        }
        ActionButton {
          id: closeButton
          width: Math.max(40, font.pixelSize + 24)
          wallust: root.wallust
          font: Style.Typography.centerButtonFont
          text: "×"
          Accessible.name: "Close notifications"
          onClicked: root.bar.notificationPanelOpen = false
        }
      }

      Rectangle {
        visible: bar.notificationCount === 0
        width: parent.width
        height: Math.max(104, emptyState.implicitHeight + 32)
        radius: 18
        color: wallust.barCard
        border.width: 1
        border.color: wallust.barSeparator

        Column {
          id: emptyState
          anchors.centerIn: parent
          spacing: 8

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "󰂚"
            color: wallust.barMutedText
            font: Style.Typography.centerIconFont
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "No notifications"
            color: wallust.barMutedText
            font: Style.Typography.centerEmptyFont
          }
        }
      }

      Flickable {
        visible: bar.notificationCount > 0
        width: parent.width
        height: Math.min(Math.max(0, root.maximumHeight - panelHeader.height - 52), notificationList.implicitHeight)
        contentWidth: width
        contentHeight: notificationList.implicitHeight
        clip: true
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

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
