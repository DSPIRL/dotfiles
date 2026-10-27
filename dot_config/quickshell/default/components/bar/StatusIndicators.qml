import QtQuick
import "../.." as Style

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
      enabled: !root.wallust.lowEffects
      ColorAnimation {
        duration: 120
      }
    }

    Row {
      id: audioLabel
      anchors.centerIn: parent
      spacing: 5
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.bar.defaultAudioSink ? root.bar.volumeIcon(root.bar.sinkVolume, root.bar.sinkMuted) : "󰝟"
        color: root.wallust.barText
        font: Style.Typography.barIconFont
      }
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.bar.defaultAudioSink ? Math.round(root.bar.sinkVolume * 100) + "%" : "--"
        color: root.wallust.barText
        font: Style.Typography.barTextFont
      }
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
      enabled: !root.wallust.lowEffects
      ColorAnimation {
        duration: 120
      }
    }

    Row {
      id: bluetoothLabelView
      anchors.centerIn: parent
      spacing: 5
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.bar.bluetoothIcon
        color: root.wallust.barText
        font: Style.Typography.barIconFont
      }
      Text {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.bar.bluetoothLabel.length > 0
        text: root.bar.bluetoothLabel
        color: root.wallust.barText
        font: Style.Typography.barTextFont
      }
    }

    MouseArea {
      id: bluetoothMouse
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      cursorShape: Qt.PointingHandCursor

      onClicked: {
        if (bar.desktopState.values.bluetoothSettings) bar.runCommand(["blueman-manager"]);
        else { bar.desktopState.error = "Bluetooth settings require blueman-manager"; bar.controlPanelOpen = true; }
      }
    }
  }

  Rectangle {
    implicitWidth: networkLabel.implicitWidth + 12
    implicitHeight: 24
    radius: 10
    color: networkMouse.containsMouse ? wallust.barHover : "transparent"

    Behavior on color {
      enabled: !root.wallust.lowEffects
      ColorAnimation {
        duration: 120
      }
    }

    Text {
      id: networkLabel
      anchors.centerIn: parent
      text: networkState.icon
      color: wallust.barText
      font: Style.Typography.barIconFont
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
      enabled: !root.wallust.lowEffects
      ColorAnimation {
        duration: 120
      }
    }

    Row {
      id: batteryLabel
      anchors.centerIn: parent
      spacing: 5
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.bar.batteryIcon(root.bar.batteryPercent, root.bar.displayBattery.state)
        color: root.bar.batteryTextColor
        font: Style.Typography.barIconFont
      }
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.bar.batteryPercent + "%"
        color: root.bar.batteryTextColor
        font: Style.Typography.barTextFont
      }
    }

    MouseArea {
      id: batteryMouse
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

  Rectangle {
    implicitWidth: powerLabel.implicitWidth + 12
    implicitHeight: 24
    radius: 10
    color: powerMouse.containsMouse ? wallust.barCritical : "transparent"

    Behavior on color {
      enabled: !root.wallust.lowEffects
      ColorAnimation {
        duration: 120
      }
    }

    Text {
      id: powerLabel
      anchors.centerIn: parent
      text: "󰐥"
      color: wallust.barText
      font: Style.Typography.barIconFont
    }

    MouseArea {
      id: powerMouse
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.LeftButton
      cursorShape: Qt.PointingHandCursor

      onClicked: { bar.controlPanelOpen = true; bar.sessionRequested(); }
    }
  }
}
