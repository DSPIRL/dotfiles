import QtQuick
import ".."

GlassSurface {
  id: root

  property var bar
  property var networkState

  implicitWidth: rightRow.implicitWidth + 24
  implicitHeight: 36

  Row {
    id: rightRow

    anchors.centerIn: parent
    spacing: 3

    SystemTraySection {
      wallust: root.wallust
    }

    StatusIndicators {
      bar: root.bar
      wallust: root.wallust
      networkState: root.networkState
    }
  }
}
