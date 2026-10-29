import QtQuick
import Quickshell
import Quickshell.Wayland
import ".." as Style

// Native bar geometry only. BarWindow retains services, coordination and pills;
// isolated native fixtures supply plain rectangles instead of service-bound contents.
PanelWindow {
  id: root
  required property var wallust
  required property Rectangle leftIsland
  required property Rectangle rightIsland
  required property Rectangle clockIsland
  readonly property int pillMargin: 4
  property bool barVisible: true
  property real barReveal: barVisible ? 1 : 0
  readonly property bool barInteractive: barVisible && barReveal === 1

  anchors { top: true; left: true; right: true }
  margins { top: 0; left: 0; right: 0 }
  implicitHeight: Style.Tokens.barPillHeight + pillMargin * 2
  // Keep glass mapped with its original height, exclusion and input policy.
  visible: true
  exclusionMode: ExclusionMode.Normal
  exclusiveZone: barVisible || barReveal > 0 ? implicitHeight : 0
  color: "transparent"
  WlrLayershell.namespace: "quickshell"

  Behavior on barReveal {
    enabled: !root.wallust.lowEffects
    NumberAnimation { id: revealAnimation; duration: 200; easing.type: Easing.OutCubic }
  }
  Connections {
    target: root.wallust
    function onLowEffectsChanged() { if (root.wallust.lowEffects) revealAnimation.complete(); }
  }

  mask: Region {
    Region { x: root.pillMargin; y: root.pillMargin; width: root.barInteractive ? root.leftIsland.width : 0; height: root.leftIsland.height; radius: root.leftIsland.radius }
    Region { x: root.width - root.rightIsland.width - root.pillMargin; y: root.pillMargin; width: root.barInteractive ? root.rightIsland.width : 0; height: root.rightIsland.height; radius: root.rightIsland.radius }
    Region { x: root.clockIsland.x; y: root.clockIsland.y; width: root.barInteractive && root.clockIsland.visible ? root.clockIsland.width : 0; height: root.clockIsland.height; radius: root.clockIsland.radius }
  }

  // One source/cutout/effect pipeline for all islands, not one per pill.
  PanelWindow {
    objectName: "barShadowWindow"
    screen: root.screen
    visible: root.visible && shadowPaint.active && root.barReveal > 0
    anchors { top: true; left: true; right: true }
    margins { top: root.margins.top; left: root.margins.left; right: root.margins.right }
    implicitHeight: root.height + 15
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    focusable: false
    mask: Region {}
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell-bar-shadow"
    SurfaceShadow {
      id: shadowPaint
      anchors.fill: parent
      wallust: root.wallust
      opacity: root.barReveal
      transform: Translate { y: -12 * (1 - root.barReveal) }
      radius: root.leftIsland.radius
      panelRects: {
        const rects = [Qt.rect(root.pillMargin, root.pillMargin, root.leftIsland.width, root.leftIsland.height),
          Qt.rect(root.width - root.rightIsland.width - root.pillMargin, root.pillMargin, root.rightIsland.width, root.rightIsland.height)];
        if (root.clockIsland.visible)
          rects.push(Qt.rect(root.clockIsland.x, root.clockIsland.y, root.clockIsland.width, root.clockIsland.height));
        return rects;
      }
    }
  }
}
