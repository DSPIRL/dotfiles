import QtQuick
import QtQuick.Controls

Rectangle {
  id: root

  property var bar
  property var wallust
  property var devices: []
  property var defaultDevice
  property bool input: false

  readonly property int deviceCount: devices ? devices.length : 0
  readonly property bool hasDefaultDevice: Boolean(defaultDevice && defaultDevice.audio)
  readonly property int additionalDeviceCount: Math.max(0, deviceCount - (hasDefaultDevice ? 1 : 0))
  readonly property bool muted: hasDefaultDevice ? defaultDevice.audio.muted : false
  readonly property real modelPercent: hasDefaultDevice ? Math.max(0, Math.min(100, defaultDevice.audio.volume * 100)) : 0
  readonly property real shownPercent: dragging ? pendingPercent : modelPercent
  readonly property string title: input ? "Input" : "Output"
  readonly property string headerIcon: input ? (muted ? "" : "") : (bar ? bar.volumeIcon(modelPercent / 100, muted) : "")

  property bool dragging: false
  property bool deviceListExpanded: false
  property real pendingPercent: modelPercent

  implicitHeight: sectionColumn.implicitHeight + 20
  height: implicitHeight
  radius: 14
  color: "transparent"
  border.width: 1
  border.color: wallust.barBorder

  onModelPercentChanged: if (!dragging) {
    pendingPercent = modelPercent;
  }
  onAdditionalDeviceCountChanged: if (additionalDeviceCount === 0) {
    deviceListExpanded = false;
  }
  onDeviceListExpandedChanged: Qt.callLater(function() {
    sectionColumn.forceLayout();
  })

  function clampPercent(percent) {
    return Math.max(0, Math.min(100, percent));
  }

  function deviceLabel(node) {
    return bar ? bar.audioNodeLabel(node) : "Audio device";
  }

  function isDefaultDevice(node) {
    return Boolean(bar && bar.isDefaultAudioDevice(node, input));
  }

  function updateFromMouse(mouseX) {
    if (sliderTrack.width <= 0) {
      return;
    }

    pendingPercent = clampPercent(((mouseX - sliderTrack.x) / sliderTrack.width) * 100);
  }

  function commitPercent(percent) {
    if (bar && defaultDevice) {
      bar.setAudioDeviceVolume(defaultDevice, clampPercent(percent) / 100);
    }
  }

  Column {
    id: sectionColumn

    x: 10
    y: 10
    width: parent.width - 20
    spacing: 10

    Row {
      width: parent.width
      height: 22
      spacing: 8

      Text {
        width: 20
        anchors.verticalCenter: parent.verticalCenter
        text: root.headerIcon
        color: wallust.color3
        font.family: "Hack Nerd Font"
        font.pixelSize: 16
        horizontalAlignment: Text.AlignHCenter
      }

      Text {
        width: parent.width - 20 - percentLabel.width - parent.spacing * 2
        anchors.verticalCenter: parent.verticalCenter
        text: "Audio " + root.title.toLowerCase()
        color: wallust.barText
        font.family: "Hack Nerd Font"
        font.pixelSize: 14
        font.bold: true
      }

      Text {
        id: percentLabel

        width: 42
        anchors.verticalCenter: parent.verticalCenter
        text: root.hasDefaultDevice ? Math.round(root.shownPercent) + "%" : "--"
        color: wallust.barMutedText
        font.family: "Hack Nerd Font"
        font.pixelSize: 13
        horizontalAlignment: Text.AlignRight
      }
    }

    Rectangle {
      visible: root.deviceCount === 0
      width: parent.width
      height: visible ? 62 : 0
      radius: 12
      color: wallust.barHover
      opacity: 0.7

      Column {
        anchors.centerIn: parent
        spacing: 6

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: "No audio " + root.title.toLowerCase() + " devices found"
          color: wallust.barText
          font.family: "Hack Nerd Font"
          font.pixelSize: 13
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: "Pipewire has no selectable " + root.title.toLowerCase() + " device"
          color: wallust.barMutedText
          font.family: "Hack Nerd Font"
          font.pixelSize: 12
        }
      }
    }

    Rectangle {
      visible: root.deviceCount > 0 && !root.hasDefaultDevice
      width: parent.width
      height: visible ? 42 : 0
      radius: 12
      color: wallust.barHover
      opacity: 0.7

      Text {
        anchors.centerIn: parent
        text: "Select a " + root.title.toLowerCase() + " device"
        color: wallust.barMutedText
        font.family: "Hack Nerd Font"
        font.pixelSize: 13
      }
    }

    Rectangle {
      visible: root.hasDefaultDevice
      width: parent.width
      implicitHeight: activeColumn.implicitHeight + 16
      height: visible ? implicitHeight : 0
      radius: 12
      color: wallust.barHover

      Column {
        id: activeColumn

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 8

        Row {
          width: parent.width
          height: 24
          spacing: 8

          Rectangle {
            width: 26
            height: 22
            radius: 11
            color: muteMouse.containsMouse ? wallust.barSeparator : "transparent"
            border.width: 1
            border.color: wallust.barBorder

            Text {
              anchors.centerIn: parent
              text: root.input ? (root.muted ? "" : "") : root.headerIcon
              color: root.muted ? wallust.barCritical : wallust.barText
              font.family: "Hack Nerd Font"
              font.pixelSize: 13
            }

            MouseArea {
              id: muteMouse

              anchors.fill: parent
              hoverEnabled: true
              acceptedButtons: Qt.LeftButton
              cursorShape: Qt.PointingHandCursor

              onClicked: if (bar) {
                bar.toggleAudioDeviceMute(root.defaultDevice);
              }
            }
          }

          Text {
            id: activeDeviceName

            width: parent.width - 26 - parent.spacing
            anchors.verticalCenter: parent.verticalCenter
            text: root.deviceLabel(root.defaultDevice)
            color: wallust.barText
            elide: Text.ElideRight
            font.family: "Hack Nerd Font"
            font.pixelSize: 13

            MouseArea {
              id: activeDeviceNameMouse

              anchors.fill: parent
              acceptedButtons: Qt.NoButton
              hoverEnabled: true

              ToolTip.visible: containsMouse && activeDeviceName.truncated
              ToolTip.delay: 500
              ToolTip.timeout: 5000
              ToolTip.text: activeDeviceName.text
            }
          }
        }

        Item {
          width: parent.width
          height: 18

          Rectangle {
            id: sliderTrack

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 4
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            height: 5
            radius: 3
            color: wallust.barSeparator

            Rectangle {
              height: parent.height
              width: Math.max(parent.height, parent.width * root.shownPercent / 100)
              radius: parent.radius
              color: root.muted ? wallust.barMutedText : wallust.color3
            }

            Rectangle {
              width: 13
              height: 13
              radius: 7
              anchors.verticalCenter: parent.verticalCenter
              x: Math.max(0, Math.min(sliderTrack.width - width, sliderTrack.width * root.shownPercent / 100 - width / 2))
              color: wallust.barText
            }
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.PointingHandCursor

            onPressed: function(mouse) {
              root.dragging = true;
              root.updateFromMouse(mouse.x);
            }

            onPositionChanged: function(mouse) {
              if (pressed) {
                root.updateFromMouse(mouse.x);
              }
            }

            onReleased: function(mouse) {
              root.updateFromMouse(mouse.x);
              root.dragging = false;
              root.commitPercent(root.pendingPercent);
            }

            onWheel: function(wheel) {
              const step = wheel.angleDelta.y > 0 ? 5 : -5;
              const nextPercent = root.clampPercent(root.shownPercent + step);
              root.pendingPercent = nextPercent;
              root.commitPercent(nextPercent);
            }
          }
        }
      }
    }

    Rectangle {
      id: deviceListToggle

      visible: root.additionalDeviceCount > 0
      width: parent.width
      height: visible ? 34 : 0
      radius: 10
      color: deviceListToggleMouse.containsMouse ? wallust.barHover : "transparent"
      border.width: 1
      border.color: wallust.barBorder

      Row {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 8

        Text {
          width: parent.width - deviceListChevron.width - parent.spacing
          anchors.verticalCenter: parent.verticalCenter
          text: root.hasDefaultDevice ? "Other " + root.title.toLowerCase() + " " + (root.additionalDeviceCount === 1 ? "device" : "devices") + " (" + root.additionalDeviceCount + ")" : "Choose an " + root.title.toLowerCase() + " device"
          color: wallust.barText
          font.family: "Hack Nerd Font"
          font.pixelSize: 13
        }

        Text {
          id: deviceListChevron

          width: 18
          anchors.verticalCenter: parent.verticalCenter
          text: root.deviceListExpanded ? "" : ""
          color: wallust.barMutedText
          font.family: "Hack Nerd Font"
          font.pixelSize: 13
          horizontalAlignment: Text.AlignHCenter
        }
      }

      MouseArea {
        id: deviceListToggleMouse

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor

        onClicked: root.deviceListExpanded = !root.deviceListExpanded
      }
    }

    Column {
      visible: root.deviceListExpanded && root.additionalDeviceCount > 0
      width: parent.width
      height: visible ? implicitHeight : 0
      spacing: 6

      Repeater {
        model: root.devices || []

        Rectangle {
          id: deviceRow

          readonly property bool active: root.isDefaultDevice(modelData)
          readonly property bool selectable: !root.hasDefaultDevice || !active

          visible: selectable
          width: parent.width
          height: visible ? 34 : 0
          radius: 10
          color: deviceMouse.containsMouse ? wallust.barHover : "transparent"

          Text {
            id: deviceName

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            text: root.deviceLabel(modelData)
            color: wallust.barText
            elide: Text.ElideRight
            font.family: "Hack Nerd Font"
            font.pixelSize: 13
          }

          MouseArea {
            id: deviceMouse

            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.PointingHandCursor

            ToolTip.visible: containsMouse && deviceName.truncated
            ToolTip.delay: 500
            ToolTip.timeout: 5000
            ToolTip.text: deviceName.text

            onClicked: {
              if (bar) {
                bar.setDefaultAudioDevice(modelData, root.input);
              }
              root.deviceListExpanded = false;
            }
          }
        }
      }
    }
  }
}
