import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Wayland
import "default/components" as Shell
import "default/components/notifications" as Notifications
import "default/wallust" as Wallust

// No BarWindow, shell.qml, service singletons, Processes or real actions.
ShellRoot {
  id: test
  Wallust.Colors { id: palette; glassOpacity: 0.4 }
  QtObject {
    id: stub
    property var screen: bar.screen
    property int height: bar.height
    property bool barVisible: bar.barVisible
    property bool notificationPanelOpen: true
    property bool controlPanelOpen: false
    property bool toastVisible: true
    property var notifications: ({trackedNotifications: []})
    property int notificationCount: notifications.trackedNotifications.length
    function notificationAccent(notification) { return palette.barBorder; }
    function notificationIcon(notification) { return ""; }
    function clearNotifications() { throw new Error("No actions allowed"); }
  }
  readonly property var notification: ({summary: "Synthetic", appName: "Fixture", body: "Body", actions: [], image: ""})
  Timer { id: toastTimer; interval: 60000 }
  Shell.BarSurface {
    id: bar
    screen: Quickshell.screens[0]
    wallust: palette
    leftIsland: left
    rightIsland: right
    clockIsland: clock
    // Match BarWindow's pill wrapper, not just the final pill coordinates.
    Item {
      id: pills
      anchors.fill: parent
      opacity: bar.barReveal
      visible: bar.barReveal > 0
      enabled: bar.barInteractive
      transform: Translate { y: -12 * (1 - bar.barReveal) }

      Rectangle { id: left; x: 4; y: 4; width: 160; height: 36; radius: 18 }
      Rectangle { id: right; x: bar.width - width - 4; y: 4; width: 200; height: 36; radius: 18 }
      Rectangle { id: clock; x: (bar.width - width) / 2; y: 4; width: 180; height: 36; radius: 18 }
    }
  }
  Notifications.NotificationPanel { id: panel; bar: stub; wallust: palette }
  Notifications.NotificationToast { id: toast; bar: stub; wallust: palette; notification: test.notification; timer: toastTimer }

  function check(value, message) { if (!value) throw new Error(message); }
  function named(window, name) { return window.contentItem.children.find(o => o.objectName === name); }
  function shadow(window, name) { return window.contentItem.data.find(o => o.objectName === name); }
  function checkShadow(window, name, namespace) {
    const s = shadow(window, name);
    check(s && s.screen === window.screen, name + " screen");
    check(s.visible === (window.visible && !palette.lowEffects && (palette.solidSurfaces || palette.glassOpacity > 0)
      && (window !== bar || bar.barReveal > 0)), name + " lifecycle");
    check(s.backingWindowVisible === s.visible, name + " native mapping");
    check(!s.focusable && s.WlrLayershell.keyboardFocus === WlrKeyboardFocus.None, name + " keyboard");
    check(s.exclusionMode === ExclusionMode.Ignore && s.mask.width === 0 && s.mask.height === 0
      && s.mask.regions.length === 0, name + " input/exclusion");
    check(s.WlrLayershell.layer === WlrLayer.Top && s.WlrLayershell.namespace === namespace, name + " scope");
    check(s.margins.top === window.margins.top && s.margins.right === window.margins.right, name + " margins");
    if (s.visible) check(s.contentItem.children[0].visible, name + " paint unexpectedly hidden");
    if (s.visible) check(s.width === window.width && s.height === window.height + (window === bar ? 15 : 0), name + " native buffer: " + s.width + "x" + s.height + " vs " + window.width + "x" + window.height + " requested " + s.implicitWidth + "x" + s.implicitHeight);
    return s.contentItem.children[0];
  }
  function checkNotification(window, glassName, shadowName, namespace) {
    const glass = named(window, glassName), paint = checkShadow(window, shadowName, namespace);
    if (!window.visible) return glass; // Unmapped content need not be polished yet.
    check(glass.x === 12 && glass.y === 9 && glass.width === window.width - 24 && glass.height === window.height - 24, glassName + " padding");
    check(window.mask.x === glass.x && window.mask.y === glass.y && window.mask.width === glass.width
      && window.mask.height === glass.height && window.mask.radius === glass.radius, glassName + " glass-only input");
    check(paint.panelRects.length === 1 && paint.panelRects[0].x === glass.x && paint.panelRects[0].y === glass.y
      && paint.panelRects[0].width === glass.width && paint.panelRects[0].height === glass.height
      && paint.radius === glass.radius, glassName + " cutout");
    check(window.exclusionMode === ExclusionMode.Ignore && window.anchors.top && window.anchors.right, glassName + " anchors/exclusion");
    return glass;
  }
  function checkBarReveal(paint) {
    check(pills.opacity === bar.barReveal && pills.visible === (bar.barReveal > 0)
      && pills.enabled === bar.barInteractive, "Pill reveal state");
    check(paint.opacity === pills.opacity, "Shadow/pill opacity drift");
    const islands = clock.visible ? [left, right, clock] : [left, right];
    check(paint.panelRects.length === islands.length, "Hidden clock cutout");
    for (let i = 0; i < islands.length; i++) {
      const island = islands[i], rect = paint.panelRects[i];
      const glass = island.mapToItem(bar.contentItem, 0, 0);
      const cutout = paint.mapToItem(paint.parent, rect.x, rect.y);
      check(Math.abs(glass.x - cutout.x) < 0.001 && Math.abs(glass.y - cutout.y) < 0.001
        && rect.width === island.width && rect.height === island.height && paint.radius === island.radius,
        "Shadow/pill geometry drift at reveal " + bar.barReveal + " island " + i);
    }
  }
  property int hidingFrames: 0
  property int showingFrames: 0
  FrameAnimation {
    running: test.step === 5 || test.step === 6
    onTriggered: {
      if (bar.barReveal <= 0 || bar.barReveal >= 1) return;
      try {
        checkBarReveal(shadow(bar, "barShadowWindow").contentItem.children[0]);
        if (bar.barVisible) test.showingFrames++; else test.hidingFrames++;
      } catch (error) {
        console.error("SURFACE_GEOMETRY_FAIL reveal", error.toString()); Qt.exit(1);
      }
    }
  }
  function checkAll() {
    const paint = checkShadow(bar, "barShadowWindow", "quickshell-bar-shadow");
    check(bar.visible && bar.height === 44 && bar.implicitHeight === 44, "Bar glass native height changed");
    check(bar.exclusionMode === ExclusionMode.Normal && bar.exclusiveZone === (bar.barVisible || bar.barReveal > 0 ? 44 : 0), "Bar reservation");
    check(bar.mask.regions.length === 3, "Bar input islands");
    check(bar.mask.regions[0].width === (bar.barInteractive ? left.width : 0)
      && bar.mask.regions[1].width === (bar.barInteractive ? right.width : 0)
      && bar.mask.regions[2].width === (bar.barInteractive && clock.visible ? clock.width : 0), "Bar input state");
    checkBarReveal(paint);
    const pg = checkNotification(panel, "notificationGlass", "notificationShadowWindow", "quickshell-notification-shadow");
    const tg = checkNotification(toast, "toastGlass", "toastShadowWindow", "quickshell-toast-shadow");
    check(panel.maximumHeight === Math.min(520, panel.screen.height - (panel.margins.top + 9) - 16), "Visible history limit");
    if (panel.visible) check(pg.height === Math.min(panel.maximumHeight, pg.implicitHeight), "History content height");
    if (toast.visible) check(tg.height === tg.implicitHeight, "Toast content height");
    check(panel.focusable === panel.visible && !toast.focusable, "Notification focus policy");
    if (panel.visible) {
      const focused = panel.contentItem.Window.window.activeFocusItem;
      check(focused && focused.visible && focused.enabled && focused.text === "×", "Opening history must focus Close");
    }
  }
  property int step: 0
  property int retries: 0
  Timer {
    // Native configure/frame callbacks are asynchronous (up to Qt's 5s
    // occluded-frame timeout on the virtual compositor). Assert settled state.
    interval: 100; running: true; repeat: true
    onTriggered: {
      try {
        switch (test.step) {
        case 0:
          checkAll();
          for (const w of [panel, toast]) {
            const g = named(w, w === panel ? "notificationGlass" : "toastGlass");
            check(g.width === Math.min(440, w.screen.width - 24) && w.margins.right + 12 === 12
              && w.margins.top + 9 === bar.height + 12, "Original visible geometry");
          }
          stub.notificationPanelOpen = false; toastTimer.start(); break;
        case 1:
          checkAll(); check(toast.visible && toastTimer.running, "Visible toast must retain timer");
          stub.controlPanelOpen = true; break;
        case 2:
          checkAll(); check(!toast.visible && !toastTimer.running, "Suppressed toast must stop timer");
          stub.controlPanelOpen = false; stub.notificationPanelOpen = true;
          stub.notifications = {trackedNotifications: Array(12).fill(test.notification)};
          break;
        case 3:
          checkAll(); check(named(panel, "notificationGlass").height === panel.maximumHeight, "History height cap");
          panel.implicitWidth = 264; toast.implicitWidth = 264;
          bar.margins.right = bar.screen.width - 560;
          left.width = 180; right.width = 220; clock.visible = false;
          break;
        case 4:
          checkAll(); check(bar.width === 560 && named(panel, "notificationGlass").width === 240, "Native narrow geometry");
          bar.barVisible = false; break;
        case 5:
          checkAll(); check(bar.barReveal === 0 && bar.exclusiveZone === 0 && !bar.barInteractive, "Hidden bar");
          check(test.hidingFrames > 0, "No intermediate hiding frame checked");
          check(panel.margins.top + 9 === 12 && toast.margins.top + 9 === 12, "Hidden-bar overlay placement");
          bar.barVisible = true; break;
        case 6:
          checkAll(); check(bar.barReveal === 1 && test.showingFrames > 0, "Shown bar/intermediate showing frame");
          bar.barReveal = 0.5; break;
        case 7:
          checkAll(); check(bar.barReveal === 0.5 && !bar.barInteractive, "Partial reveal input");
          bar.barReveal = 1; palette.lowEffects = true; break;
        case 8:
          checkAll(); palette.lowEffects = false; palette.glassOpacity = 0; break;
        case 9:
          checkAll(); palette.solidSurfaces = true; break;
        case 10:
          checkAll(); palette.solidSurfaces = false; palette.glassOpacity = 0.4;
          panel.margins.top = panel.screen.height - 180 - 9; break;
        case 11:
          checkAll(); check(panel.maximumHeight === 164 && named(panel, "notificationGlass").height === 164, "Constrained visible height");
          if (Quickshell.screens.length > 1) bar.screen = Quickshell.screens[1];
          break;
        case 12:
          checkAll(); stub.notificationPanelOpen = false; stub.toastVisible = false; break;
        case 13:
          checkAll(); stub.notificationPanelOpen = true; break;
        default:
          checkAll(); console.info("SURFACE_GEOMETRY_PASS reveal frames hiding=" + test.hidingFrames + " showing=" + test.showingFrames); Qt.quit();
        }
        test.step++; test.retries = 0;
      } catch (error) {
        if (++test.retries < 70) return;
        console.error("SURFACE_GEOMETRY_FAIL step " + test.step, error.toString(), error.stack); Qt.quit();
      }
    }
  }
}
