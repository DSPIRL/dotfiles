import QtQuick

Rectangle {
  id: root

  property var bar
  property var wallust

  readonly property var brightnessState: bar ? bar.laptopBrightnessState : null
  readonly property bool available: Boolean(brightnessState && brightnessState.available)
  readonly property bool missingTool: Boolean(brightnessState && brightnessState.missingTool)
  readonly property string deviceLabel: brightnessState && brightnessState.device ? brightnessState.device : "Laptop display"
  readonly property real modelPercent: available ? Math.max(0, Math.min(100, brightnessState.percent)) : 0
  readonly property real shownPercent: dragging ? pendingPercent : modelPercent

  property bool dragging: false
  property real pendingPercent: modelPercent

  onAvailableChanged: Qt.callLater(function() {
    sectionColumn.forceLayout();
  })
  onMissingToolChanged: Qt.callLater(function() {
    sectionColumn.forceLayout();
  })

  implicitHeight: sectionColumn.implicitHeight + 20
  height: implicitHeight
  radius: 14
  color: "transparent"
  border.width: 1
  border.color: wallust.barBorder

  onModelPercentChanged: if (!dragging) {
    pendingPercent = modelPercent;
  }

  function clampPercent(percent) {
    return Math.max(0, Math.min(100, percent));
  }

  function updateFromMouse(mouseX) {
    if (sliderTrack.width <= 0) {
      return;
    }

    pendingPercent = clampPercent(((mouseX - sliderTrack.x) / sliderTrack.width) * 100);
  }

  function commitPercent(percent) {
    if (bar) {
      bar.setLaptopBrightness(clampPercent(percent));
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
        text: "󰃠"
        color: wallust.color3
        font.family: "Hack Nerd Font"
        font.pixelSize: 16
        horizontalAlignment: Text.AlignHCenter
      }

      Text {
        width: parent.width - 20 - percentLabel.width - parent.spacing * 2
        anchors.verticalCenter: parent.verticalCenter
        text: "Internal display brightness"
        color: wallust.barText
        font.family: "Hack Nerd Font"
        font.pixelSize: 14
        font.bold: true
      }

      Text {
        id: percentLabel

        width: 42
        anchors.verticalCenter: parent.verticalCenter
        text: root.available ? Math.round(root.shownPercent) + "%" : "--"
        color: wallust.barMutedText
        font.family: "Hack Nerd Font"
        font.pixelSize: 13
        horizontalAlignment: Text.AlignRight
      }
    }

    Rectangle {
      visible: !root.available
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
          text: root.missingTool ? "brightnessctl is not installed" : "No internal backlight found"
          color: wallust.barText
          font.family: "Hack Nerd Font"
          font.pixelSize: 13
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: root.missingTool ? "Install brightnessctl to control laptop brightness" : "No /sys/class/backlight device is available"
          color: wallust.barMutedText
          font.family: "Hack Nerd Font"
          font.pixelSize: 12
        }
      }
    }

    Text {
      visible: root.available
      width: parent.width
      text: root.deviceLabel
      color: wallust.barMutedText
      elide: Text.ElideRight
      font.family: "Hack Nerd Font"
      font.pixelSize: 12
    }

    Item {
      visible: root.available
      width: parent.width
      height: visible ? 18 : 0

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
          color: wallust.color3
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
