import QtQuick
import QtQuick.Window
import QtQuick.Effects

// Paint only: each local PanelWindow owner supplies placement and lifecycle.
// Combine all shadows, then subtract the union so neighbors cannot wash interiors.
// The full canvas includes the blur-12/offset-(0,3) envelope (12/12/9/15).
Item {
  id: root
  required property var wallust
  required property var panelRects
  required property real radius
  readonly property bool active: !wallust.lowEffects && (wallust.solidSurfaces || wallust.glassOpacity > 0)
  visible: active

  // Geometry can change while another window's layout is being polished.
  // Hidden texture sources alone can leave this window's last frame on screen;
  // defer its repaint to the event loop, coalescing calls to the same function.
  // Qt.callLater is not a guaranteed after-polish barrier.
  function repaint() { if (root.Window.window) root.Window.window.update(); }
  onPanelRectsChanged: Qt.callLater(repaint)
  onRadiusChanged: Qt.callLater(repaint)

  Item {
    id: shadowSource
    anchors.fill: parent
    layer.enabled: true
    visible: false
    Repeater {
      model: root.panelRects
      RectangularShadow {
        required property var modelData
        x: modelData.x; y: modelData.y
        width: modelData.width; height: modelData.height
        radius: root.radius
        blur: 12
        offset: Qt.vector2d(0, 3)
        color: root.wallust.lightMode ? "#800B1422" : "#99000000"
      }
    }
  }
  Item {
    id: cutout
    anchors.fill: parent
    layer.enabled: true
    visible: false
    Repeater {
      model: root.panelRects
      Rectangle {
        required property var modelData
        x: modelData.x; y: modelData.y
        width: modelData.width; height: modelData.height
        radius: root.radius
        color: "white"
      }
    }
  }
  MultiEffect {
    anchors.fill: parent
    source: shadowSource
    autoPaddingEnabled: false
    maskEnabled: true
    maskSource: cutout
    maskInverted: true
    // Preserve the rounded mask's antialiasing, with no soft interior wash.
    maskThresholdMin: 0
    maskSpreadAtMin: 0
    maskThresholdMax: 1
    maskSpreadAtMax: 0
  }
}
