import QtQuick

Rectangle {
  id: root

  property var bar
  property var wallust
  property var clock

  implicitWidth: clockLabel.implicitWidth + 22
  implicitHeight: 32
  radius: implicitHeight / 2
  color: clockMouse.containsMouse ? wallust.barHover : wallust.barBackground
  border.width: 1
  border.color: wallust.barBorder

  Behavior on color {
    ColorAnimation {
      duration: 120
    }
  }

  Text {
    id: clockLabel

    anchors.centerIn: parent
    text: Qt.formatDateTime(clock.date, bar.width < 1000 ? "HH:mm" : "HH:mm  ·  d MMM")
    color: wallust.barText
    font.family: wallust.textFont
    font.pixelSize: 15
  }

  MouseArea {
    id: clockMouse

    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    onClicked: bar.runCommand(["gnome-calendar"])
  }
}
