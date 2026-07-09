import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
  id: root

  property var bar
  property var wallust

  visible: Boolean(bar && bar.controlPanelOpen)
  implicitWidth: 390
  implicitHeight: 480
  color: "transparent"
  screen: bar ? bar.screen : null
  focusable: visible
  exclusionMode: ExclusionMode.Ignore

  anchors {
    top: true
  }

  margins {
    top: bar ? bar.height + 12 : 50
  }

  WlrLayershell.namespace: "quickshell"

  onVisibleChanged: if (visible) {
    controlPanelContent.forceActiveFocus();
    if (bar && bar.ddcBrightnessState) {
      bar.ddcBrightnessState.refresh();
    }
    if (bar && bar.laptopBrightnessState) {
      bar.laptopBrightnessState.refresh();
    }
  }

  Rectangle {
    id: controlPanelContent

    anchors.fill: parent
    focus: true
    implicitHeight: controlPanelColumn.implicitHeight + 24
    radius: 18
    color: wallust.barBackground
    border.width: 1
    border.color: wallust.barBorder
    clip: true

    Keys.onEscapePressed: bar.controlPanelOpen = false

    Flickable {
      id: controlPanelFlickable

      anchors.fill: parent
      anchors.margins: 12
      contentWidth: width
      contentHeight: controlPanelColumn.implicitHeight
      boundsBehavior: Flickable.StopAtBounds
      clip: true
      interactive: contentHeight > height

      Column {
        id: controlPanelColumn

        width: controlPanelFlickable.width
        spacing: 10

      Row {
        width: parent.width
        height: 28
        spacing: 8

        Text {
          width: parent.width - refreshButton.width - parent.spacing
          anchors.verticalCenter: parent.verticalCenter
          text: "Controls"
          color: wallust.barText
          font.family: "Hack Nerd Font"
          font.pixelSize: 15
          font.bold: true
        }

        Rectangle {
          id: refreshButton

          width: refreshLabel.implicitWidth + 16
          height: 26
          radius: 13
          color: refreshMouse.containsMouse ? wallust.barHover : "transparent"
          border.width: 1
          border.color: wallust.barBorder

          Text {
            id: refreshLabel

            anchors.centerIn: parent
            text: bar && ((bar.ddcBrightnessState && bar.ddcBrightnessState.refreshing) || (bar.laptopBrightnessState && bar.laptopBrightnessState.refreshing)) ? "..." : "Refresh"
            color: wallust.barText
            font.family: "Hack Nerd Font"
            font.pixelSize: 13
          }

          MouseArea {
            id: refreshMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: {
              if (bar && bar.ddcBrightnessState) {
                bar.ddcBrightnessState.refresh();
              }
              if (bar && bar.laptopBrightnessState) {
                bar.laptopBrightnessState.refresh();
              }
            }
          }
        }
        }

        AudioDeviceControl {
          width: parent.width
          bar: root.bar
          wallust: root.wallust
          devices: bar ? bar.audioOutputDevices : []
          defaultDevice: bar ? bar.defaultAudioSink : null
        }

        AudioDeviceControl {
          width: parent.width
          bar: root.bar
          wallust: root.wallust
          devices: bar ? bar.audioInputDevices : []
          defaultDevice: bar ? bar.defaultAudioSource : null
          input: true
        }

        LaptopBrightnessControl {
          visible: Boolean(bar && bar.showLaptopBrightnessControl)
          width: parent.width
          bar: root.bar
          wallust: root.wallust
        }

        Rectangle {
        width: parent.width
        implicitHeight: displaySectionColumn.implicitHeight + 20
        height: implicitHeight
        radius: 14
        color: "transparent"
        border.width: 1
        border.color: wallust.barBorder

        Column {
          id: displaySectionColumn

          x: 10
          y: 10
          width: parent.width - 20
          spacing: 10

          Row {
            width: parent.width
            height: 22
            spacing: 8

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: "󰍹"
              color: wallust.color3
              font.family: "Hack Nerd Font"
              font.pixelSize: 16
            }

            Text {
              width: parent.width - 24
              anchors.verticalCenter: parent.verticalCenter
              text: "External display brightness"
              color: wallust.barText
              font.family: "Hack Nerd Font"
              font.pixelSize: 14
              font.bold: true
            }
          }

          Rectangle {
            visible: !bar || !bar.ddcBrightnessState || bar.ddcBrightnessState.displayCount === 0
            width: parent.width
            height: 86
            radius: 12
            color: wallust.barHover
            opacity: 0.7

            Column {
              anchors.centerIn: parent
              spacing: 6

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: bar && bar.ddcBrightnessState && bar.ddcBrightnessState.error.length > 0 ? bar.ddcBrightnessState.error : "No DDC displays found"
                color: wallust.barText
                font.family: "Hack Nerd Font"
                font.pixelSize: 13
              }

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: bar && bar.ddcBrightnessState && bar.ddcBrightnessState.error.length > 0 ? "Check ddcutil and i2c permissions" : "Connect a DDC-capable external monitor"
                color: wallust.barMutedText
                font.family: "Hack Nerd Font"
                font.pixelSize: 12
              }
            }
          }

          Column {
            visible: Boolean(bar && bar.ddcBrightnessState && bar.ddcBrightnessState.displayCount > 0)
            width: parent.width
            height: implicitHeight
            spacing: 8

            Repeater {
              model: bar && bar.ddcBrightnessState ? bar.ddcBrightnessState.displayCount : 0

              DdcBrightnessControl {
                width: parent.width
                bar: root.bar
                wallust: root.wallust
                ddcDisplay: root.bar.ddcBrightnessState.displays[index]
              }
            }
          }
        }
      }
    }
  }
}
}
