import QtQuick

Rectangle {
  id: root

  property var bar
  property var wallust
  property var utilityState
  property var utilityStatsProcess
  property var updatesProcess
  property var networkState

  implicitWidth: rightRow.implicitWidth + 22
  implicitHeight: 32
  radius: implicitHeight / 2
  color: wallust.barBackground
  border.width: 1.5
  border.color: wallust.barBorder

  Row {
    id: rightRow

    anchors.centerIn: parent
    spacing: 3

    SystemTraySection {
      wallust: root.wallust
    }

    UtilityDrawer {
      bar: root.bar
      wallust: root.wallust
      utilityState: root.utilityState
      utilityStatsProcess: root.utilityStatsProcess
      updatesProcess: root.updatesProcess
    }

    StatusIndicators {
      bar: root.bar
      wallust: root.wallust
      networkState: root.networkState
    }
  }
}
