import QtQuick
import "../.." as Style

Item {
  id: root

  property var bar
  property var wallust

  visible: bar.spotifyVisible
  implicitWidth: 180
  implicitHeight: 26

  Text {
    id: spotifyLabel

    anchors.centerIn: parent
    width: parent.width - 16
    elide: Text.ElideRight
    horizontalAlignment: Text.AlignHCenter
    text: bar.spotifyDisplay
    color: spotifyMouse.containsMouse ? wallust.barText : wallust.barMutedText
    font: Style.Typography.barTextFont
  }

  MouseArea {
    id: spotifyMouse

    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor

    onClicked: function(mouse) {
      if (!bar.spotifyPlayer) {
        return;
      }

      if (mouse.button === Qt.RightButton) {
        if (bar.spotifyPlayer.canRaise) {
          bar.spotifyPlayer.raise();
        }
        return;
      }

      if (bar.spotifyPlayer.canTogglePlaying) {
        bar.spotifyPlayer.togglePlaying();
      }
    }

    onWheel: function(wheel) {
      if (!bar.spotifyPlayer) {
        return;
      }

      if (wheel.angleDelta.y > 0 && bar.spotifyPlayer.canGoNext) {
        bar.spotifyPlayer.next();
      } else if (wheel.angleDelta.y < 0 && bar.spotifyPlayer.canGoPrevious) {
        bar.spotifyPlayer.previous();
      }
    }
  }
}
