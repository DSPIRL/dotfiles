import QtQuick

Row {
  id: root

  property var bar
  property var wallust
  property var networkState
  spacing: 3

  Rectangle {
    implicitWidth: audioLabel.implicitWidth + 12
    implicitHeight: 24
    radius: 10
    color: audioMouse.containsMouse ? wallust.barHover : "transparent"

    Behavior on color {
      ColorAnimation {
        duration: 120
      }
    }

    Text {
      id: audioLabel
      anchors.centerIn: parent
      text: bar.defaultAudioSink ? bar.volumeIcon(bar.sinkVolume, bar.sinkMuted) + " " + Math.round(bar.sinkVolume * 100) + "%" : "󰝟 --"
      color: wallust.barText
      font.family: "Hack Nerd Font"
      font.pixelSize: 14
    }

    MouseArea {
      id: audioMouse
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      cursorShape: Qt.PointingHandCursor

      onClicked: function(mouse) {
        if (mouse.button === Qt.LeftButton) {
          bar.runCommand(["pavucontrol"]);
          return;
        }

        if (bar.defaultAudioSink && bar.defaultAudioSink.audio) {
          bar.defaultAudioSink.audio.muted = !bar.defaultAudioSink.audio.muted;
        }
      }

      onWheel: function(wheel) {
        if (!bar.defaultAudioSink || !bar.defaultAudioSink.audio) {
          return;
        }

        const step = wheel.angleDelta.y > 0 ? 0.03 : -0.03;
        const nextVolume = Math.max(0, Math.min(1, bar.defaultAudioSink.audio.volume + step));
        bar.defaultAudioSink.audio.volume = nextVolume;
      }
    }
  }

  Rectangle {
    implicitWidth: bluetoothLabelView.implicitWidth + 12
    implicitHeight: 24
    radius: 10
    color: bluetoothMouse.containsMouse ? wallust.barHover : "transparent"

    Behavior on color {
      ColorAnimation {
        duration: 120
      }
    }

    Text {
      id: bluetoothLabelView
      anchors.centerIn: parent
      text: bar.bluetoothLabel.length > 0 ? bar.bluetoothIcon + " " + bar.bluetoothLabel : bar.bluetoothIcon
      color: wallust.barText
      font.family: "Hack Nerd Font"
      font.pixelSize: 14
    }

    MouseArea {
      id: bluetoothMouse
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      cursorShape: Qt.PointingHandCursor

      onClicked: bar.runCommand(["blueman-manager"])
    }
  }

  Rectangle {
    implicitWidth: networkLabel.implicitWidth + 12
    implicitHeight: 24
    radius: 10
    color: networkMouse.containsMouse ? wallust.barHover : "transparent"

    Behavior on color {
      ColorAnimation {
        duration: 120
      }
    }

    Text {
      id: networkLabel
      anchors.centerIn: parent
      text: networkState.icon
      color: wallust.barText
      font.family: "Hack Nerd Font"
      font.pixelSize: 14
    }

    MouseArea {
      id: networkMouse
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.LeftButton
      cursorShape: Qt.PointingHandCursor

      onClicked: bar.launchNetworkTui()
    }
  }

  Rectangle {
    visible: bar.hasBattery
    implicitWidth: batteryLabel.implicitWidth + 12
    implicitHeight: 24
    radius: 10
    color: batteryMouse.containsMouse ? wallust.barHover : "transparent"

    Behavior on color {
      ColorAnimation {
        duration: 120
      }
    }

    Text {
      id: batteryLabel
      anchors.centerIn: parent
      text: bar.batteryIcon(bar.batteryPercent, bar.displayBattery.state) + " " + bar.batteryPercent + "%"
      color: bar.batteryTextColor
      font.family: "Hack Nerd Font"
      font.pixelSize: 14
    }

    MouseArea {
      id: batteryMouse
      anchors.fill: parent
      hoverEnabled: true
    }
  }

  Rectangle {
    implicitWidth: notificationLabel.implicitWidth + 12
    implicitHeight: 24
    radius: 10
    color: notificationMouse.containsMouse ? wallust.barHover : "transparent"

    Behavior on color {
      ColorAnimation {
        duration: 120
      }
    }

    Text {
      id: notificationLabel
      anchors.centerIn: parent
      text: bar.notificationCount > 0 ? " " + bar.notificationCount : ""
      color: wallust.barText
      font.family: "Hack Nerd Font"
      font.pixelSize: 14
    }

    MouseArea {
      id: notificationMouse
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.LeftButton
      cursorShape: Qt.PointingHandCursor

      onClicked: bar.notificationPanelOpen = !bar.notificationPanelOpen
    }
  }

  Rectangle {
    width: 1
    height: 14
    radius: 1
    color: wallust.barSeparator
    anchors.verticalCenter: parent.verticalCenter
  }

  Rectangle {
    implicitWidth: powerLabel.implicitWidth + 12
    implicitHeight: 24
    radius: 10
    color: powerMouse.containsMouse ? wallust.barCritical : "transparent"

    Behavior on color {
      ColorAnimation {
        duration: 120
      }
    }

    Text {
      id: powerLabel
      anchors.centerIn: parent
      text: "󰐥"
      color: wallust.barText
      font.family: "Hack Nerd Font"
      font.pixelSize: 14
    }

    MouseArea {
      id: powerMouse
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.LeftButton
      cursorShape: Qt.PointingHandCursor

      onClicked: bar.runCommand(["wlogout"])
    }
  }
}
