import QtQuick
import Quickshell
import Quickshell.Hyprland
import ".."
import "../.." as Style

GlassSurface {
  id: root

  property var bar
  property var workspaceModel: Hyprland.workspaces

  implicitWidth: workspaceRow.implicitWidth + 16
  implicitHeight: Style.Tokens.barPillHeight

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
    spacing: Style.Tokens.barItemSpacing

    Repeater {
      model: root.workspaceModel

      Rectangle {
        id: indicator
        required property var modelData
        readonly property var workspace: modelData

        visible: workspace.id > 0
        radius: 13
        Binding on implicitWidth { value: workspace.active ? 36 : 28 }
        implicitHeight: 26
        border.width: workspace.urgent ? 1 : 0
        border.color: wallust.color3
        opacity: bar.hyprMonitor && workspace.monitor && workspace.monitor.id !== bar.hyprMonitor.id ? 0.55 : 1
        Binding on color { value: workspace.active ? wallust.barActive : (workspaceMouse.containsMouse ? wallust.barHover : "transparent") }

        Behavior on implicitWidth {
          enabled: !root.wallust.lowEffects
          onEnabledChanged: if (!enabled) indicator.implicitWidth = targetValue
          NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }
        Behavior on color {
          enabled: !root.wallust.lowEffects
          onEnabledChanged: if (!enabled) indicator.color = targetValue
          ColorAnimation {
            duration: Style.Tokens.barStateColorDuration
          }
        }

        Text {
          id: workspaceLabel

          anchors.centerIn: parent
          text: bar.workspaceText(workspace)
          color: workspace.active ? wallust.barAccentText : wallust.barMutedText
          font: workspace.active ? Style.Typography.barActiveWorkspaceFont : Style.Typography.barWorkspaceFont
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

    SpotifyPill {
      visible: bar.spotifyVisible && bar.width > 1200
      bar: root.bar
      wallust: root.wallust
    }
  }
}
