import QtQuick
import Quickshell
import Quickshell.DBusMenu
import Quickshell.Services.SystemTray
import Quickshell.Widgets

Row {
  id: root

  property var wallust
  spacing: 3

  Repeater {
    model: SystemTray.items

    Rectangle {
      id: trayButton
      required property var modelData
      readonly property var trayItem: modelData

      visible: trayItem.icon && trayItem.icon.length > 0
      implicitWidth: 24
      implicitHeight: 24
      radius: 10
      color: trayMouse.containsMouse ? wallust.barHover : "transparent"

      function openMenu() {
        trayMenu.open();
      }

      Behavior on color {
        ColorAnimation {
          duration: 120
        }
      }

      IconImage {
        anchors.centerIn: parent
        implicitSize: 16
        source: trayItem.icon
      }

      QsMenuAnchor {
        id: trayMenu

        menu: trayItem.menu
        anchor {
          item: trayButton
          edges: Edges.Bottom | Edges.Left
          gravity: Edges.Bottom | Edges.Right
        }
      }

      MouseArea {
        id: trayMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onClicked: function(mouse) {
          if (mouse.button === Qt.LeftButton) {
            if (trayItem.onlyMenu && trayItem.hasMenu) {
              trayButton.openMenu();
            } else {
              trayItem.activate();
            }
            return;
          }

          if (mouse.button === Qt.MiddleButton) {
            trayItem.secondaryActivate();
            return;
          }

          if (trayItem.hasMenu) {
            trayButton.openMenu();
          } else {
            trayItem.secondaryActivate();
          }
        }
      }
    }
  }

  Rectangle {
    visible: SystemTray.items.values.length > 0
    width: 1
    height: 14
    radius: 1
    color: wallust.barSeparator
    anchors.verticalCenter: parent.verticalCenter
  }
}
