import QtQuick

Row {
  id: root

  property var bar
  property var wallust
  property var utilityState
  property var utilityStatsProcess
  property var updatesProcess
  spacing: 3

  Rectangle {
    implicitWidth: expandLabel.implicitWidth + 12
    implicitHeight: 24
    radius: 10
    color: expandMouse.containsMouse ? wallust.barHover : "transparent"

    Behavior on color {
      ColorAnimation {
        duration: 120
      }
    }

    Text {
      id: expandLabel
      anchors.centerIn: parent
      text: bar.toolsExpanded ? "" : ""
      color: wallust.barText
      font.family: "Hack Nerd Font"
      font.pixelSize: 16
    }

    MouseArea {
      id: expandMouse
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.LeftButton
      cursorShape: Qt.PointingHandCursor

      onClicked: bar.toolsExpanded = !bar.toolsExpanded
    }
  }

  Item {
    width: bar.toolsExpanded ? utilityRow.implicitWidth : 0
    height: 24
    clip: true

    Behavior on width {
      NumberAnimation {
        duration: 180
        easing.type: Easing.OutCubic
      }
    }

    Row {
      id: utilityRow
      anchors.verticalCenter: parent.verticalCenter
      spacing: 3

      Rectangle {
        implicitWidth: 26
        implicitHeight: 24
        radius: 10
        color: colorpickerMouse.containsMouse ? wallust.barHover : "transparent"

        Behavior on color {
          ColorAnimation {
            duration: 120
          }
        }

        Text {
          anchors.centerIn: parent
          text: ""
          color: wallust.barText
          font.family: "Hack Nerd Font"
          font.pixelSize: 16
        }

        MouseArea {
          id: colorpickerMouse
          anchors.fill: parent
          hoverEnabled: true
          acceptedButtons: Qt.LeftButton
          cursorShape: Qt.PointingHandCursor

          onClicked: bar.runHyprScript("colorpicker.sh")
        }
      }

      Rectangle {
        implicitWidth: updatesLabel.implicitWidth + 12
        implicitHeight: 24
        radius: 10
        color: updatesMouse.containsMouse ? wallust.barHover : "transparent"

        Behavior on color {
          ColorAnimation {
            duration: 120
          }
        }

        Text {
          id: updatesLabel
          anchors.centerIn: parent
          text: "󰅢 " + (utilityState.updatesCount >= 0 ? utilityState.updatesCount : "?")
          color: wallust.barText
          font.family: "Hack Nerd Font"
          font.pixelSize: 16
        }

        MouseArea {
          id: updatesMouse
          anchors.fill: parent
          hoverEnabled: true
          acceptedButtons: Qt.LeftButton | Qt.RightButton
          cursorShape: Qt.PointingHandCursor

          onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
              if (!updatesProcess.running) {
                updatesProcess.running = true;
              }
              return;
            }

            bar.launchTerminalShell("command -v paru >/dev/null 2>&1 && paru -Syu || sudo pacman -Syu");
          }
        }
      }

      Rectangle {
        implicitWidth: 26
        implicitHeight: 24
        radius: 10
        color: hyprsunsetMouse.containsMouse ? wallust.barHover : "transparent"

        Behavior on color {
          ColorAnimation {
            duration: 120
          }
        }

        Text {
          anchors.centerIn: parent
          text: ""
          color: utilityState.hyprsunsetActive ? wallust.color3 : wallust.barText
          font.family: "Hack Nerd Font"
          font.pixelSize: 16
        }

        MouseArea {
          id: hyprsunsetMouse
          anchors.fill: parent
          hoverEnabled: true
          acceptedButtons: Qt.LeftButton | Qt.RightButton
          cursorShape: Qt.PointingHandCursor

          onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
              bar.runCommand(["gddccontrol"]);
              return;
            }

            bar.runHyprScript("hyprsunset.sh");
            if (utilityStatsProcess && !utilityStatsProcess.running) {
              utilityStatsProcess.running = true;
            }
          }
        }
      }

      Rectangle {
        implicitWidth: cpuLabel.implicitWidth + 12
        implicitHeight: 24
        radius: 10
        color: cpuMouse.containsMouse ? wallust.barHover : "transparent"

        Behavior on color {
          ColorAnimation {
            duration: 120
          }
        }

        Text {
          id: cpuLabel
          anchors.centerIn: parent
          text: " " + utilityState.cpuUsage + "%"
          color: wallust.barText
          font.family: "Hack Nerd Font"
          font.pixelSize: 16
        }

        MouseArea {
          id: cpuMouse
          anchors.fill: parent
          hoverEnabled: true
          acceptedButtons: Qt.LeftButton
          cursorShape: Qt.PointingHandCursor

          onClicked: bar.launchTerminal("btop -p 2")
        }
      }

      Rectangle {
        implicitWidth: memoryLabel.implicitWidth + 12
        implicitHeight: 24
        radius: 10
        color: memoryMouse.containsMouse ? wallust.barHover : "transparent"

        Behavior on color {
          ColorAnimation {
            duration: 120
          }
        }

        Text {
          id: memoryLabel
          anchors.centerIn: parent
          text: " " + utilityState.memoryUsage + "%"
          color: wallust.barText
          font.family: "Hack Nerd Font"
          font.pixelSize: 16
        }

        MouseArea {
          id: memoryMouse
          anchors.fill: parent
          hoverEnabled: true
        }
      }

      Rectangle {
        implicitWidth: temperatureLabel.implicitWidth + 12
        implicitHeight: 24
        radius: 10
        color: temperatureMouse.containsMouse ? wallust.barHover : "transparent"

        Behavior on color {
          ColorAnimation {
            duration: 120
          }
        }

        Text {
          id: temperatureLabel
          anchors.centerIn: parent
          text: utilityState.hasTemperature ? " " + utilityState.temperature + "C" : " --"
          color: wallust.barText
          font.family: "Hack Nerd Font"
          font.pixelSize: 16
        }

        MouseArea {
          id: temperatureMouse
          anchors.fill: parent
          hoverEnabled: true
        }
      }

      Rectangle {
        width: 1
        height: 14
        radius: 1
        color: wallust.barSeparator
        anchors.verticalCenter: parent.verticalCenter
      }
    }
  }
}
