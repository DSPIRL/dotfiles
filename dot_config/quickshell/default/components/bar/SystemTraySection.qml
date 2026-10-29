import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.DBusMenu
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import Quickshell.Wayland
import ".." as Components
import "../.." as Style

Row {
  id: root

  property var wallust
  property bool useStyledTrayMenu: true
  property bool barInteractive: true
  readonly property var bar: root.QsWindow.window
  spacing: Style.Tokens.barItemSpacing

  Repeater {
    model: SystemTray.items

    Rectangle {
      id: trayButton
      required property var modelData
      readonly property var trayItem: modelData

      visible: trayItem.icon && trayItem.icon.length > 0
      implicitWidth: 24
      implicitHeight: Style.Tokens.barIndicatorHeight
      radius: Style.Tokens.barIndicatorRadius
      Binding on color { value: trayMouse.containsMouse ? wallust.barHover : "transparent" }

      function openMenu() {
        if (!root.barInteractive) return;
        if (root.useStyledTrayMenu) {
          styledWindow.visible = true;
          styledMenu.open();
        } else {
          trayMenu.open();
        }
      }

      Behavior on color {
        enabled: !root.wallust.lowEffects
        // Disabling Behavior alone does not stop an in-flight animation.
        onEnabledChanged: if (!enabled) trayButton.color = targetValue
        ColorAnimation {
          duration: Style.Tokens.barStateColorDuration
        }
      }

      IconImage {
        anchors.centerIn: parent
        implicitSize: 16
        source: trayItem.icon
      }

      QsMenuAnchor {
        id: trayMenu
        objectName: "nativeTrayMenu"

        menu: trayItem.menu
        anchor {
          item: trayButton
          edges: Edges.Bottom | Edges.Left
          gravity: Edges.Bottom | Edges.Right
        }
      }

      PopupWindow {
        id: styledWindow
        objectName: "styledTrayWindow"
        property bool frameReady: false
        // Qt's Wayland popup position is parent-relative, not screen-global.
        // mapFromItem needs explicit transform dependencies to follow configure
        // (including compositor constraint adjustments) on either window.
        readonly property point resolvedPosition: {
          if (!root.bar) return Qt.point(0, 0);
          root.bar.windowTransform;
          styledWindow.windowTransform;
          return root.bar.contentItem.mapFromItem(styledWindow.contentItem, 0, 0);
        }
        visible: false
        // The window, not the embedded Qt Quick Popup, owns outside clicks.
        grabFocus: true
        implicitWidth: styledMenu.width
        implicitHeight: styledMenu.height
        color: "transparent"
        anchor {
          item: trayButton
          // Extend the anchor to the bottom of the bar, not just the icon.
          rect: Qt.rect(0, 0, trayButton.width, trayButton.Window.window
            ? Math.max(trayButton.height, trayButton.Window.window.height - trayButton.mapToItem(null, 0, 0).y)
            : trayButton.height)
          edges: Edges.Bottom | Edges.Left
          gravity: Edges.Bottom | Edges.Right
        }
        onVisibleChanged: if (!visible) {
          frameReady = false;
          styledMenu.close();
        }
        Connections {
          target: styledWindow.contentItem.Window.window
          function onFrameSwapped() {
            if (styledWindow.visible) styledWindow.frameReady = true;
          }
        }
        Connections {
          target: root
          function onBarInteractiveChanged() {
            if (!root.barInteractive) {
              styledWindow.visible = false;
              if (trayMenu.visible) trayMenu.close();
            }
          }
          function onUseStyledTrayMenuChanged() {
            if (!root.useStyledTrayMenu) styledWindow.visible = false;
            else if (trayMenu.visible) trayMenu.close();
          }
        }

        StyledMenu {
          id: styledMenu
          objectName: "styledTrayMenu"
          parent: styledWindow.contentItem
          menu: trayItem.menu
          wallust: root.wallust
          onClosed: styledWindow.visible = false
        }
      }

      // The production bar is full-width at screen-relative (0, 0). Use
      // resolved parent coordinates directly, never guessed global window x/y.
      PanelWindow {
        objectName: "trayShadowWindow"
        screen: root.bar ? root.bar.screen : null
        visible: root.bar !== null && styledWindow.visible && styledWindow.frameReady && shadowPaint.active
        anchors { top: true; left: true }
        margins {
          left: styledWindow.resolvedPosition.x - 12
          top: styledWindow.resolvedPosition.y - 9
        }
        implicitWidth: styledWindow.width + 24
        implicitHeight: styledWindow.height + 24
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        focusable: false
        mask: Region {}
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickshell-tray-shadow"
        Components.SurfaceShadow {
          id: shadowPaint
          anchors.fill: parent
          wallust: root.wallust
          radius: styledMenu.background.radius
          panelRects: [Qt.rect(12, 9, styledWindow.width, styledWindow.height)]
        }
      }

      MouseArea {
        id: trayMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onClicked: function(mouse) {
          if (mouse.button === Qt.LeftButton) {
            if (trayItem.onlyMenu && trayItem.hasMenu) {
              trayButton.openMenu();
            } else {
              trayItem.activate();
            }
            return;
          }

          if (mouse.button === Qt.MiddleButton) {
            trayItem.secondaryActivate();
            return;
          }

          if (trayItem.hasMenu) {
            trayButton.openMenu();
          } else {
            trayItem.secondaryActivate();
          }
        }
      }
    }
  }

  Rectangle {
    visible: SystemTray.items.values.length > 0
    width: 1
    height: 14
    radius: 1
    color: wallust.barSeparator
    anchors.verticalCenter: parent.verticalCenter
  }
}
