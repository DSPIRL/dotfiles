//@ pragma UseQApplication

import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import "default/components" as Shell
import "default/components/bar" as Bar
import "default/wallust" as Wallust

// Production tray delegate/PopupWindow, synthetic SNI/DBusMenu, private KWin.
ShellRoot {
  id: test
  Wallust.Colors { id: palette; glassOpacity: 0.4 }
  Shell.BarSurface {
    id: bar
    screen: Quickshell.screens[0]
    wallust: palette
    leftIsland: left
    rightIsland: right
    clockIsland: clock
    Rectangle { id: left; x: 4; y: 4; width: 80; height: 36; radius: 18 }
    Rectangle {
      id: right
      x: bar.width - width - 4; y: 4; width: 40; height: 36; radius: 18
      Bar.SystemTraySection {
        id: tray
        x: 8; y: 6
        wallust: palette
        barInteractive: bar.barInteractive
      }
    }
    Rectangle { id: clock; visible: false; width: 1; height: 36; radius: 18 }
    TestCase { id: objects; name: "TrayShadowObjects"; when: false }
  }
  property var popup
  property var menu
  property var shadow
  property var nativeMenu
  property int frames: 0
  property int step: 0
  property int retries: 0
  property real previousX
  property real originalHeight
  function check(value, message) { if (!value) throw new Error(message); }
  function fail(error) { console.error("SURFACE_GEOMETRY_FAIL step " + step, error.toString(), error.stack); Qt.exit(1); }
  Process {
    id: input
    onExited: function(code) { if (code !== 0) test.fail(new Error("Input client exit " + code)); }
  }
  function send(args) {
    check(!input.running, "Input still running");
    input.command = [Quickshell.env("SURFACE_TEST_INPUT")].concat(args.map(String));
    input.running = true;
  }
  function clickTray() { send(["click", bar.screen.x + bar.width - 24, bar.screen.y + 22]); }
  Connections {
    target: test.popup || null
    function onVisibleChanged() {
      if (!test.popup.visible) { test.frames = 0; return; }
      try {
        test.check(!test.popup.frameReady && !test.shadow.visible, "Shadow appeared before first popup frame");
      } catch (error) { test.fail(error); }
    }
  }
  Connections {
    target: test.popup ? test.popup.contentItem.Window.window : null
    function onFrameSwapped() { if (test.popup.visible) test.frames++; }
  }
  function hidden() {
    check(!popup.visible && !popup.frameReady && !shadow.visible && !shadow.backingWindowVisible && !menu.visible,
      "Popup/shadow must reset on hide");
  }
  function geometry(label) {
    check(popup.visible && menu.visible && popup.frameReady && frames > 0, "Popup first frame missing");
    check(popup.grabFocus && popup.contentItem.Window.window.active, "Popup grab/focus lost");
    const active = !palette.lowEffects && (palette.solidSurfaces || palette.glassOpacity > 0);
    check(shadow.visible === active && shadow.backingWindowVisible === active, "Shadow suppression/mapping");
    check(shadow.screen === bar.screen && popup.screen === bar.screen, "Popup/shadow screen mismatch");
    check(shadow.WlrLayershell.namespace === "quickshell-tray-shadow" && shadow.WlrLayershell.layer === WlrLayer.Top,
      "Shadow namespace/layer");
    check(!shadow.focusable && shadow.WlrLayershell.keyboardFocus === WlrKeyboardFocus.None
      && shadow.exclusionMode === ExclusionMode.Ignore, "Shadow focus/exclusion");
    check(shadow.mask.width === 0 && shadow.mask.height === 0 && shadow.mask.regions.length === 0, "Shadow input region");
    const resolved = bar.contentItem.mapFromItem(popup.contentItem, 0, 0);
    check(popup.resolvedPosition.x === resolved.x && popup.resolvedPosition.y === resolved.y, "Stale window transforms");
    check(shadow.margins.left + 12 === resolved.x && shadow.margins.top + 9 === resolved.y, "Screen-relative shadow placement");
    check(resolved.x >= 0 && resolved.x + popup.width <= bar.screen.width && resolved.y >= bar.height, "Popup constraints");
    let alpha;
    if (active) {
      check(shadow.width === popup.width + 24 && shadow.height === popup.height + 24, "Shadow native buffer size");
      const paint = shadow.contentItem.children[0], rect = paint.panelRects[0];
      check(paint.visible && rect.x === 12 && rect.y === 9 && rect.width === popup.width && rect.height === popup.height
        && paint.radius === menu.background.radius, "Shadow cutout geometry");
      if (label) {
        const image = objects.grabImage(shadow.contentItem);
        const cx = Math.floor(12 + popup.width / 2), cy = Math.floor(9 + popup.height / 2);
        alpha = [image.alpha(cx, 8), image.alpha(11, cy), image.alpha(cx, 9 + popup.height), image.alpha(cx, cy)];
        check(alpha.slice(0, 3).every(a => a >= 20) && alpha[3] === 0, "Native shadow edge/interior alpha: " + alpha);
      }
    }
    if (label) console.info("TRAY_SHADOW_PROBE", label, JSON.stringify({screen: bar.screen.name,
      screenOrigin: [bar.screen.x, bar.screen.y], resolved: [resolved.x, resolved.y],
      popup: [popup.width, popup.height], shadow: [shadow.width, shadow.height],
      margins: [shadow.margins.left, shadow.margins.top], frames: frames, alphaTopSideBottomInterior: alpha}));
  }
  Timer {
    interval: 100; running: true; repeat: true
    onTriggered: {
      if (input.running) return;
      try {
        switch (test.step) {
        case 0:
          check(SystemTray.items.values.length === 1 && bar.width === 1280, "Waiting for synthetic tray/output");
          const button = tray.children.find(o => o.trayItem !== undefined);
          check(button, "Production tray delegate missing");
          test.popup = button.data.find(o => o.objectName === "styledTrayWindow");
          test.menu = popup ? objects.findChild(popup.contentItem, "styledTrayMenu") : null;
          test.shadow = button.data.find(o => o.objectName === "trayShadowWindow");
          test.nativeMenu = button.data.find(o => o.objectName === "nativeTrayMenu");
          check(popup && menu && shadow && nativeMenu, "Production tray objects missing: " + [!!popup, !!menu, !!shadow, !!nativeMenu]);
          hidden(); clickTray(); break;
        case 1:
          geometry(); check(popup.width === 240 && popup.resolvedPosition.x === bar.width - 240, "Right constraint not exercised");
          geometry("constrained-right"); test.previousX = popup.resolvedPosition.x; test.originalHeight = popup.height;
          menu.width = 350; break;
        case 2:
          geometry(); check(popup.width === 350 && popup.resolvedPosition.x === bar.width - 350
            && popup.resolvedPosition.x !== previousX, "Width resize did not reposition");
          geometry("width-resize"); menu.height = originalHeight + 100; break;
        case 3:
          geometry(); check(popup.height === originalHeight + 100, "Height resize");
          geometry("height-resize"); popup.anchor.rect = Qt.rect(-400, 0, 24, 34); break;
        case 4:
          geometry(); check(popup.resolvedPosition.x === right.x + tray.x - 400, "Anchor move did not react");
          geometry("anchor-move"); popup.anchor.rect = Qt.rect(-1300, 0, 24, 34); break;
        case 5:
          geometry(); check(popup.resolvedPosition.x === 0, "Left constraint not exercised");
          geometry("constrained-left"); popup.anchor.rect = Qt.rect(0, 0, 24, 34); palette.lowEffects = true; break;
        case 6:
          geometry(); palette.lowEffects = false; palette.glassOpacity = 0; break;
        case 7:
          geometry(); palette.solidSurfaces = true; break;
        case 8:
          geometry(); palette.solidSurfaces = false; palette.glassOpacity = 0.4; break;
        case 9:
          geometry(); send(["key", 1]); break; // Real compositor Escape delivery.
        case 10:
          hidden(); clickTray(); break;
        case 11:
          geometry("reopened"); bar.barVisible = false; break;
        case 12:
          hidden(); check(!bar.barInteractive, "Hidden bar still interactive");
          bar.screen = Quickshell.screens[1]; bar.barVisible = true; break;
        case 13:
          check(bar.barInteractive && bar.screen.x > 0 && bar.width === 1280, "Second output not ready");
          hidden(); clickTray(); break;
        case 14:
          geometry(); check(popup.resolvedPosition.x === bar.width - 350, "Second-output global offset leaked");
          geometry("second-output"); send(["click", bar.screen.x + 20, bar.screen.y + 700]); break;
        case 15:
          hidden(); tray.useStyledTrayMenu = false; clickTray(); break;
        case 16:
          hidden(); check(nativeMenu.visible, "Native fallback did not open");
          tray.useStyledTrayMenu = true; break;
        case 17:
          hidden(); check(!nativeMenu.visible, "Mode switch did not close native menu");
          clickTray(); break;
        case 18:
          geometry(); tray.useStyledTrayMenu = false; break;
        default:
          hidden(); console.info("SURFACE_GEOMETRY_PASS tray shadow, native fallback, Escape and outside dismissal"); Qt.quit();
        }
        test.step++; test.retries = 0;
      } catch (error) {
        // Configure/frame/native geometry are asynchronous; never repeat actions
        // before their settled-state assertions pass. Overall runner is bounded.
        if (++test.retries >= 70) test.fail(error);
      }
    }
  }
}
