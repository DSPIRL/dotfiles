import QtQuick
import ".."
import "../.." as Style

GlassSurface {
  id: root

  property var bar
  property var clock

  implicitWidth: clockLabel.implicitWidth + 32
  implicitHeight: Style.Tokens.barPillHeight
  hovered: clockMouse.containsMouse

  Text {
    id: clockLabel

    anchors.centerIn: parent
    text: Qt.formatDateTime(clock.date, bar.width < 1000 ? "HH:mm" : "ddd, d MMM   ·   HH:mm")
    color: wallust.barText
    font: Style.Typography.barClockFont
  }

  MouseArea {
    id: clockMouse

    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    onClicked: bar.runCommand(["gnome-calendar"])
  }
}
