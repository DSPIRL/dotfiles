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
  readonly property string displayLabel: connectorLabel(ddcDisplay && ddcDisplay.connector ? ddcDisplay.connector : "")

  property bool dragging: false
  property real pendingPercent: modelPercent

  implicitWidth: 176
  implicitHeight: 24
  width: implicitWidth
  height: implicitHeight
  radius: 10
  color: hoverMouse.containsMouse || sliderMouse.containsMouse || dragging ? wallust.barHover : "transparent"

  onModelPercentChanged: if (!dragging) {
    pendingPercent = modelPercent;
  }

  Behavior on color {
    ColorAnimation {
      duration: 120
    }
  }

  function connectorLabel(connector) {
    if (connector.length === 0) {
      return ddcDisplay && ddcDisplay.display ? "DDC " + ddcDisplay.display : "DDC";
    }

    const parts = connector.split("-");
    if (parts.length > 1 && parts[0].indexOf("card") === 0) {
      return parts.slice(1).join("-");
    }

    return connector;
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
    id: hoverMouse

    anchors.fill: parent
    acceptedButtons: Qt.NoButton
    hoverEnabled: true
  }

  Row {
    anchors.centerIn: parent
    spacing: 6

    Text {
      width: 44
      anchors.verticalCenter: parent.verticalCenter
      text: root.displayLabel
      color: wallust.barText
      elide: Text.ElideRight
      font.family: "Hack Nerd Font"
      font.pixelSize: 12
      horizontalAlignment: Text.AlignRight
    }

    Item {
      id: sliderHitbox

      width: 74
      height: 20
      anchors.verticalCenter: parent.verticalCenter

      Rectangle {
        id: sliderTrack

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        height: 4
        radius: 2
        color: wallust.barSeparator

        Rectangle {
          height: parent.height
          width: Math.max(parent.height, parent.width * root.shownPercent / 100)
          radius: parent.radius
          color: wallust.color3
        }

        Rectangle {
          width: 10
          height: 10
          radius: 5
          anchors.verticalCenter: parent.verticalCenter
          x: Math.max(0, Math.min(sliderTrack.width - width, sliderTrack.width * root.shownPercent / 100 - width / 2))
          color: wallust.barText
        }
      }

      MouseArea {
        id: sliderMouse

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

    Text {
      width: 32
      anchors.verticalCenter: parent.verticalCenter
      text: Math.round(root.shownPercent) + "%"
      color: wallust.barText
      font.family: "Hack Nerd Font"
      font.pixelSize: 12
      horizontalAlignment: Text.AlignRight
    }
  }
}
