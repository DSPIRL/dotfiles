import QtQuick
import QtQuick.Effects

// Shared material for the bar and controls; Hyprland supplies backdrop blur.
Rectangle {
  id: root
  required property var wallust
  property bool hovered: false
  // One opacity for all shell glass fills; never fade children via Item.opacity.
  function surfaceColor(tint) {
    return root.wallust.solidSurfaces ? tint
      : Qt.rgba(tint.r, tint.g, tint.b, Math.max(0, Math.min(1, root.wallust.glassOpacity)));
  }

  radius: 18
  gradient: Gradient {
    GradientStop { position: 0; color: root.surfaceColor(root.wallust.glassTop) }
    GradientStop { position: 1; color: root.surfaceColor(root.wallust.glassBottom) }
  }
  border.width: 1
  border.color: wallust.barBorder

  // Fading highlights suggest curved edges without brightening the whole fill.
  Rectangle {
    x: root.radius
    y: 1
    width: Math.max(0, root.width - 2 * root.radius)
    height: 1
    visible: !root.wallust.solidSurfaces
    gradient: Gradient {
      orientation: Gradient.Horizontal
      GradientStop { position: 0; color: "transparent" }
      GradientStop { position: 0.25; color: root.wallust.lightMode ? "#D9FFFFFF" : "#99FFFFFF" }
      GradientStop { position: 1; color: "transparent" }
    }
  }

  Rectangle {
    x: root.radius
    y: root.height - 2
    width: Math.max(0, root.width - 2 * root.radius)
    height: 1
    visible: !root.wallust.solidSurfaces
    gradient: Gradient {
      orientation: Gradient.Horizontal
      GradientStop { position: 0; color: "transparent" }
      GradientStop { position: 0.75; color: root.wallust.barBorder }
      GradientStop { position: 1; color: "transparent" }
    }
  }

  RectangularShadow {
    anchors.fill: parent
    z: -1
    visible: !root.wallust.lowEffects
    radius: root.radius
    blur: 12
    offset: Qt.vector2d(0, 3)
    color: root.wallust.lightMode ? "#180B1422" : "#38000000"
  }

  Rectangle {
    anchors.fill: parent
    anchors.margins: 1
    radius: Math.max(0, root.radius - 1)
    color: root.hovered ? root.wallust.barHover : "transparent"
    border.width: root.wallust.solidSurfaces ? 0 : 1
    border.color: root.wallust.glassInnerEdge
    Behavior on color {
      enabled: !root.wallust.lowEffects
      ColorAnimation { duration: 140 }
    }
  }
}
