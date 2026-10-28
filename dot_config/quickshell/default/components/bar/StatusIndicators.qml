import QtQuick
import "../.." as Style

Row {
  id: root

  property var bar
  property var wallust
  property var networkState
  spacing: Style.Tokens.barItemSpacing

  Rectangle {
    id: audioIndicator
    implicitWidth: audioLabel.implicitWidth + 12
    implicitHeight: Style.Tokens.barIndicatorHeight
    radius: Style.Tokens.barIndicatorRadius
    Binding on color { value: audioMouse.containsMouse ? wallust.barHover : "transparent" }

    // Disabling Behavior alone leaves its animation running. Write only after it
    // is disabled; the Binding element survives the write and tracks later hovers.
    Behavior on color {
      enabled: !root.wallust.lowEffects
      onEnabledChanged: if (!enabled) audioIndicator.color = targetValue
      ColorAnimation {
        duration: Style.Tokens.barStateColorDuration
      }
    }

    Row {
      id: audioLabel
      anchors.centerIn: parent
      spacing: 5
      Text {
        anchors.verticalCenter: parent.verticalCenter
        // A stable em-wide slot contains Nerd Font overhangs in every state.
        width: Style.Typography.barAudioIconSize
        horizontalAlignment: Text.AlignHCenter
        text: root.bar.defaultAudioSink ? root.bar.volumeIcon(root.bar.sinkVolume, root.bar.sinkMuted) : "󰝟"
        color: root.wallust.barText
        font: Style.Typography.barAudioIconFont
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
          bar.controlPanelOpen = true;
          bar.categoryRequested("audio");
          return;
        }

        bar.toggleAudioDeviceMute(bar.defaultAudioSink);
      }

      onWheel: function(wheel) {
        if (!bar.defaultAudioSink || !bar.defaultAudioSink.audio) {
          return;
        }

        const step = wheel.angleDelta.y > 0 ? 0.03 : -0.03;
        bar.setAudioDeviceVolume(bar.defaultAudioSink, bar.defaultAudioSink.audio.volume + step);
      }
    }
  }

  Rectangle {
    id: bluetoothIndicator
    implicitWidth: bluetoothLabelView.implicitWidth + 12
    implicitHeight: Style.Tokens.barIndicatorHeight
    radius: Style.Tokens.barIndicatorRadius
    Binding on color { value: bluetoothMouse.containsMouse ? wallust.barHover : "transparent" }

    Behavior on color {
      enabled: !root.wallust.lowEffects
      onEnabledChanged: if (!enabled) bluetoothIndicator.color = targetValue
      ColorAnimation {
        duration: Style.Tokens.barStateColorDuration
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

      onClicked: function(mouse) {
        if (mouse.button === Qt.LeftButton) {
          bar.controlPanelOpen = true;
          bar.categoryRequested("quick");
          return;
        }
        if (bar.desktopState.values.bluetoothSettings) bar.runCommand(["blueman-manager"]);
        else { bar.desktopState.error = "Bluetooth settings require blueman-manager"; bar.controlPanelOpen = true; }
      }
    }
  }

  Rectangle {
    id: networkIndicator
    implicitWidth: networkLabel.implicitWidth + 12
    implicitHeight: Style.Tokens.barIndicatorHeight
    radius: Style.Tokens.barIndicatorRadius
    Binding on color { value: networkMouse.containsMouse ? wallust.barHover : "transparent" }

    Behavior on color {
      enabled: !root.wallust.lowEffects
      onEnabledChanged: if (!enabled) networkIndicator.color = targetValue
      ColorAnimation {
        duration: Style.Tokens.barStateColorDuration
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

      onClicked: { bar.controlPanelOpen = true; bar.categoryRequested("quick"); }
    }
  }

  Rectangle {
    id: batteryIndicator
    visible: bar.hasBattery
    implicitWidth: batteryLabel.implicitWidth + 12
    implicitHeight: Style.Tokens.barIndicatorHeight
    radius: Style.Tokens.barIndicatorRadius
    Binding on color { value: batteryMouse.containsMouse ? wallust.barHover : "transparent" }

    Behavior on color {
      enabled: !root.wallust.lowEffects
      onEnabledChanged: if (!enabled) batteryIndicator.color = targetValue
      ColorAnimation {
        duration: Style.Tokens.barStateColorDuration
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
    id: powerIndicator
    implicitWidth: powerLabel.implicitWidth + 12
    implicitHeight: Style.Tokens.barIndicatorHeight
    radius: Style.Tokens.barIndicatorRadius
    Binding on color { value: powerMouse.containsMouse ? wallust.barCritical : "transparent" }

    Behavior on color {
      enabled: !root.wallust.lowEffects
      onEnabledChanged: if (!enabled) powerIndicator.color = targetValue
      ColorAnimation {
        duration: Style.Tokens.barStateColorDuration
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
