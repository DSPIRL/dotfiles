import QtQuick

Rectangle {
  id: root

  property var bar
  property var wallust
  property var ddcDisplay

  readonly property int maximum: ddcDisplay && ddcDisplay.maximum > 0 ? ddcDisplay.maximum : 100
  readonly property int current: ddcDisplay ? ddcDisplay.current : 0
  readonly property real modelPercent: maximum > 0 ? Math.max(0, Math.min(100, (current / maximum) * 100)) : 0
  readonly property real shownPercent: dragging ? pendingPercent : modelPercent
  readonly property string connector: ddcDisplay && ddcDisplay.connector ? ddcDisplay.connector : ""
  readonly property string monitor: ddcDisplay && ddcDisplay.monitor ? ddcDisplay.monitor : "External display"
  readonly property string displayLabel: connectorLabel(connector)

  property bool dragging: false
  property real pendingPercent: modelPercent

  implicitHeight: 58
  height: implicitHeight
  radius: 12
  color: controlMouse.containsMouse || dragging ? wallust.barHover : "transparent"

  onModelPercentChanged: if (!dragging) {
    pendingPercent = modelPercent;
  }

  Behavior on color {
    ColorAnimation {
      duration: 120
    }
  }

  function connectorLabel(connectorName) {
    if (connectorName.length === 0) {
      return ddcDisplay && ddcDisplay.display ? "DDC " + ddcDisplay.display : "DDC";
    }

    const parts = connectorName.split("-");
    if (parts.length > 1 && parts[0].indexOf("card") === 0) {
      return parts.slice(1).join("-");
    }

    return connectorName;
  }

  function clampPercent(percent) {
    return Math.max(0, Math.min(100, percent));
  }

  function updateFromMouse(mouseX) {
    pendingPercent = clampPercent(((mouseX - sliderTrack.x) / sliderTrack.width) * 100);
  }

  function commitPercent(percent) {
    if (!bar || !ddcDisplay) {
      return;
    }

    bar.setDdcBrightness(ddcDisplay.display, clampPercent(percent), maximum);
  }

  MouseArea {
    id: controlMouse

    anchors.fill: parent
    acceptedButtons: Qt.NoButton
    hoverEnabled: true
  }

  Column {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    spacing: 8

    Row {
      width: parent.width
      height: 18
      spacing: 8

      Text {
        width: parent.width - percentLabel.width - parent.spacing
        anchors.verticalCenter: parent.verticalCenter
        text: root.displayLabel + "  " + root.monitor
        color: wallust.barText
        elide: Text.ElideRight
        font.family: "Hack Nerd Font"
        font.pixelSize: 13
      }

      Text {
        id: percentLabel

        width: 42
        anchors.verticalCenter: parent.verticalCenter
        text: Math.round(root.shownPercent) + "%"
        color: wallust.barMutedText
        font.family: "Hack Nerd Font"
        font.pixelSize: 13
        horizontalAlignment: Text.AlignRight
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
