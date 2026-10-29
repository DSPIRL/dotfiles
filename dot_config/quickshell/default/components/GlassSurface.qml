import QtQuick
import ".." as Style

// Hyprland supplies backdrop blur. Exterior shadows belong on separate,
// unblurred surfaces, not in the shared glass/blur mask.
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

  Rectangle {
    id: hoverSurface
    anchors.fill: parent
    anchors.margins: 1
    radius: Math.max(0, root.radius - 1)
    Binding on color { value: root.hovered ? root.wallust.barHover : "transparent" }
    border.width: root.wallust.solidSurfaces ? 0 : 1
    border.color: root.wallust.glassInnerEdge
    // Binding survives the target write; disabling Behavior alone leaves its animation running.
    Behavior on color {
      enabled: !root.wallust.lowEffects
      onEnabledChanged: if (!enabled) hoverSurface.color = targetValue
      ColorAnimation { duration: Style.Tokens.surfaceColorDuration }
    }
  }
}
