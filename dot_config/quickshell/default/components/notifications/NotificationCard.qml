import QtQuick
import Quickshell.Widgets

Rectangle {
  id: root

  required property var notification
  property var bar
  property var wallust

  implicitHeight: notificationCardContent.implicitHeight + 20
  radius: 14
  color: notificationMouse.containsMouse ? wallust.barHover : "transparent"
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
    anchors.margins: 10
    spacing: 8

    Row {
      width: parent.width
      spacing: 10

      IconImage {
        width: 14
        height: 14
        implicitSize: 10
        source: bar.notificationIcon(notification)
      }

      Column {
        width: parent.width - 28 - dismissButton.width - parent.spacing * 2
        spacing: 2

        Text {
          width: parent.width
          text: notification.summary && notification.summary.length > 0 ? notification.summary : notification.appName
          color: wallust.barText
          elide: Text.ElideRight
          font.family: "Hack Nerd Font"
          font.pixelSize: 14
          font.bold: true
        }

        Text {
          visible: notification.appName && notification.appName.length > 0
          width: parent.width
          text: notification.appName
          color: wallust.barMutedText
          elide: Text.ElideRight
          font.family: "Hack Nerd Font"
          font.pixelSize: 12
        }
      }

      Rectangle {
        id: dismissButton

        width: 24
        height: 24
        radius: 12
        color: dismissMouse.containsMouse ? wallust.barHover : "transparent"

        Text {
          anchors.centerIn: parent
          text: "󰅖"
          color: wallust.barMutedText
          font.family: "Hack Nerd Font"
          font.pixelSize: 13
        }

        MouseArea {
          id: dismissMouse

          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor

          onClicked: notification.dismiss()
        }
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
      font.family: "Hack Nerd Font"
      font.pixelSize: 13
    }

    Image {
      visible: notification.image && notification.image.length > 0
      width: parent.width
      height: visible ? Math.min(160, implicitHeight) : 0
      source: notification.image
      fillMode: Image.PreserveAspectCrop
      clip: true
    }

    Row {
      visible: notification.actions.length > 0
      width: parent.width
      spacing: 6

      Repeater {
        model: notification.actions

        Rectangle {
          required property var modelData
          readonly property var action: modelData

          width: actionLabel.implicitWidth + 16
          height: 26
          radius: 13
          color: actionMouse.containsMouse ? wallust.barHover : "transparent"
          border.width: 1
          border.color: wallust.barBorder

          Text {
            id: actionLabel

            anchors.centerIn: parent
            text: action.text
            color: wallust.barText
            font.family: "Hack Nerd Font"
            font.pixelSize: 12
          }

          MouseArea {
            id: actionMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: {
              action.invoke();
              notification.dismiss();
            }
          }
        }
      }
    }
  }
}
