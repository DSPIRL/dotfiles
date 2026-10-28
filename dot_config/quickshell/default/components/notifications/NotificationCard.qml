import QtQuick
import Quickshell.Widgets
import ".."
import "../.." as Style

Rectangle {
  id: root

  required property var notification
  property var bar
  property var wallust

  implicitHeight: notificationCardContent.implicitHeight + 28
  radius: 18
  color: notificationMouse.containsMouse ? Qt.tint(wallust.barCard, wallust.barHover) : wallust.barCard
  border.width: 1
  border.color: bar.notificationAccent(notification)

  MouseArea {
    id: notificationMouse

    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.NoButton
  }

  Column {
    id: notificationCardContent
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: 14
    spacing: 8

    Row {
      width: parent.width
      spacing: 10

      IconImage {
        width: Style.Tokens.notificationAppIconSize
        height: Style.Tokens.notificationAppIconSize
        implicitSize: 24
        source: bar.notificationIcon(notification)
      }

      Column {
        width: parent.width - Style.Tokens.notificationAppIconSize - dismissButton.width - parent.spacing * 2
        spacing: 2

        Text {
          width: parent.width
          text: notification.summary && notification.summary.length > 0 ? notification.summary : notification.appName
          color: wallust.barText
          elide: Text.ElideRight
          font: Style.Typography.notificationTitleFont
        }

        Text {
          visible: notification.appName && notification.appName.length > 0
          width: parent.width
          text: notification.appName
          color: wallust.barMutedText
          elide: Text.ElideRight
          font: Style.Typography.notificationMetaFont
        }
      }

      ActionButton {
        id: dismissButton
        width: Math.max(32, font.pixelSize + 8)
        height: Math.max(Style.Tokens.notificationActionMinHeight, contentItem.implicitHeight + 8)
        leftPadding: 4
        rightPadding: 4
        wallust: root.wallust
        font: Style.Typography.notificationActionFont
        text: "×"
        Accessible.name: "Dismiss notification"
        onClicked: root.notification.dismiss()
      }
    }

    Text {
      visible: notification.body && notification.body.length > 0
      width: parent.width
      text: notification.body
      color: wallust.barText
      textFormat: Text.StyledText
      wrapMode: Text.Wrap
      maximumLineCount: 6
      elide: Text.ElideRight
      font: Style.Typography.notificationBodyFont
    }

    Image {
      visible: notification.image && notification.image.length > 0
      width: parent.width
      height: visible ? Math.min(160, implicitHeight) : 0
      source: notification.image
      fillMode: Image.PreserveAspectCrop
      clip: true
    }

    Flow {
      visible: notification.actions.length > 0
      width: parent.width
      spacing: 6

      Repeater {
        model: notification.actions

        ActionButton {
          required property var modelData
          readonly property var notificationAction: modelData
          width: Math.min(implicitWidth, parent.width)
          height: Math.max(Style.Tokens.notificationActionMinHeight, contentItem.implicitHeight + 8)
          wallust: root.wallust
          font: Style.Typography.notificationActionFont
          text: notificationAction.text
          onClicked: {
            notificationAction.invoke();
            root.notification.dismiss();
          }
        }
      }
    }
  }
}
