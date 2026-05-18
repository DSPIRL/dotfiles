import QtQuick
import Quickshell
import Quickshell.Hyprland

Rectangle {
  id: root

  property var bar
  property var wallust

  implicitWidth: workspaceRow.implicitWidth + 22
  implicitHeight: 32
  radius: implicitHeight / 2
  color: wallust.barBackground
  border.width: 1.5
  border.color: wallust.barBorder

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.NoButton

    onWheel: function(wheel) {
      Hyprland.dispatch(wheel.angleDelta.y > 0 ? "workspace e+1" : "workspace e-1");
    }
  }

  Row {
    id: workspaceRow

    anchors.centerIn: parent
    spacing: 3

    Repeater {
      model: Hyprland.workspaces

      Rectangle {
        required property var modelData
        readonly property var workspace: modelData

        visible: workspace.id > 0
        radius: 10
        implicitWidth: workspaceLabel.implicitWidth + 12
        implicitHeight: 24
        border.width: workspace.urgent ? 1 : 0
        border.color: wallust.color3
        opacity: bar.hyprMonitor && workspace.monitor && workspace.monitor.id !== bar.hyprMonitor.id ? 0.55 : 1
        color: workspace.active ? wallust.barActive : (workspaceMouse.containsMouse ? wallust.barHover : "transparent")

        Behavior on color {
          ColorAnimation {
            duration: 120
          }
        }

        Text {
          id: workspaceLabel

          anchors.centerIn: parent
          text: bar.workspaceText(workspace)
          color: workspace.active ? wallust.barAccentText : wallust.barMutedText
          font.family: "Hack Nerd Font"
          font.pixelSize: 16
        }

        MouseArea {
          id: workspaceMouse

          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor

          onClicked: workspace.activate()
        }
      }
    }
  }
}
