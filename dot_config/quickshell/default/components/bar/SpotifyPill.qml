import QtQuick

Rectangle {
  id: root

  property var bar
  property var wallust

  visible: bar.spotifyVisible
  implicitWidth: bar.spotifyPlaying ? 250 : spotifyLabel.implicitWidth + 20
  implicitHeight: 30
  radius: implicitHeight / 2
  color: spotifyMouse.containsMouse ? wallust.barHover : wallust.barBackground
  border.width: 1
  border.color: wallust.barBorder

  Behavior on color {
    ColorAnimation {
      duration: 120
    }
  }

  Text {
    id: spotifyLabel

    anchors.centerIn: parent
    width: bar.spotifyPlaying ? 230 : implicitWidth
    elide: Text.ElideRight
    horizontalAlignment: Text.AlignHCenter
    text: bar.spotifyDisplay
    color: wallust.barText
    font.family: "Hack Nerd Font"
    font.pixelSize: 15
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
