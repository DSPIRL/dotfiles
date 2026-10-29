import QtQuick
import ".."
import "../.." as Style

GlassSurface {
  id: root

  property var bar
  property var networkState

  implicitWidth: rightRow.implicitWidth + 24
  implicitHeight: Style.Tokens.barPillHeight

  Row {
    id: rightRow

    anchors.centerIn: parent
    spacing: Style.Tokens.barItemSpacing

    SystemTraySection {
      wallust: root.wallust
      barInteractive: root.bar.barInteractive
    }

    StatusIndicators {
      bar: root.bar
      wallust: root.wallust
      networkState: root.networkState
    }
  }
}
