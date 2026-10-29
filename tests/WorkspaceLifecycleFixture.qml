import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "default/components" as Shell
import "default/components/bar" as Bar
import "default/wallust" as Wallust

// Real WorkspacePill/RowLayout/BarSurface/SurfaceShadow, synthetic model only.
// Never grabImage/grabToImage here: forcing a Qt render hides the stale-frame bug.
ShellRoot {
  id: test
  Wallust.Colors { id: palette; lightMode: true }
  QtObject { id: used; property int id: 4; property bool active: true; property bool urgent: false; property var monitor: null }
  QtObject { id: empty; property int id: 5; property bool active: false; property bool urgent: false; property var monitor: null }
  ListModel { id: workspaces; dynamicRoles: true }
  QtObject {
    id: stub
    property var hyprMonitor: null
    property bool spotifyVisible: false
    property string spotifyDisplay: ""
    property int width: bar.width
    function workspaceText(workspace) { return String(workspace.id); }
  }
  // Static stripes make stale shadow paint and glass/blur changes distinguishable.
  PanelWindow {
    screen: bar.screen
    anchors { top: true; left: true; right: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Background
    color: "#dcc591"
    Row {
      Repeater {
        model: Math.ceil(bar.width / 4)
        Rectangle { required property int index; width: 4; height: bar.screen.height; color: index % 2 ? "#dcc591" : "#eeddaa" }
      }
    }
  }
  Shell.BarSurface {
    id: bar
    screen: Quickshell.screens[0]
    wallust: palette
    leftIsland: pill; rightIsland: right; clockIsland: clock
    Item {
      anchors.fill: parent
      opacity: bar.barReveal
      visible: bar.barReveal > 0
      enabled: bar.barInteractive
      transform: Translate { y: -12 * (1 - bar.barReveal) }
      RowLayout {
        anchors.fill: parent; anchors.margins: bar.pillMargin; spacing: 12
        Bar.WorkspacePill { id: pill; bar: stub; wallust: palette; workspaceModel: workspaces }
        Item { Layout.fillWidth: true }
        Rectangle { id: right; implicitWidth: 100; implicitHeight: 36; radius: 18 }
      }
      Rectangle { id: clock; visible: false; width: 100; height: 36; radius: 18 }
    }
  }
  property var shadow: null
  property int shadowFrames: 0
  property int framesAtReturn: 0
  property int framesAtIdle: 0
  property int inFlightReversals: 0
  Connections {
    target: test.shadow ? test.shadow.contentItem.Window.window : null
    function onFrameSwapped() { test.shadowFrames++; }
  }
  Process {
    id: capture
    onExited: function(code) { if (code !== 0) test.fail(new Error("Private screencopy failed: " + code)); }
  }
  function screenshot(name) {
    capture.command = ["grim", "-g", "0,0 160x90", name + ".png"];
    capture.running = true;
  }
  function check(value, message) { if (!value) throw new Error(message); }
  function fail(error) { console.error("SURFACE_GEOMETRY_FAIL workspace", error.toString()); Qt.exit(1); }
  function row() { return pill.children.find(child => child.spacing !== undefined); }
  function delegates() { return row().children.filter(child => child.workspace !== undefined); }
  function settled() {
    const items = delegates(), rect = shadow.contentItem.children[0].panelRects[0];
    check(items.length === 1 && items[0].workspace === used, "Removed workspace delegate retained");
    check(items[0].width === 36 && items[0].implicitWidth === 36 && items[0].height === 26, "Delegate dimensions");
    check(row().width === 36 && row().implicitWidth === 36 && pill.width === 52 && pill.implicitWidth === 52, "Row/pill dimensions");
    const position = pill.mapToItem(bar.contentItem, 0, 0);
    check(bar.mask.regions[0].width === 52 && rect.x === position.x && rect.y === position.y
      && rect.width === 52 && rect.height === 36, "Input/cutout geometry");
    check(shadow.visible && shadow.backingWindowVisible && shadow.width === bar.width && shadow.height === 59, "Native shadow lifecycle");
  }
  Component.onCompleted: workspaces.append({modelData: used})
  property int step: 0
  property int cycle: 0
  Timer {
    interval: 40; repeat: true; running: true
    onTriggered: {
      if (capture.running) return;
      try {
        switch (test.step++) {
        case 8:
          test.shadow = bar.contentItem.data.find(o => o.objectName === "barShadowWindow");
          test.check(test.shadow !== undefined, "Shadow window missing");
          test.settled(); test.screenshot("initial"); break;
        case 9:
          // Vary insertion/activation ordering without resetting the used delegate.
          if (test.cycle % 2) { empty.active = true; workspaces.append({modelData: empty}); used.active = false; }
          else { used.active = false; workspaces.append({modelData: empty}); empty.active = true; }
          break;
        case 10:
          test.check(test.delegates().length === 2 && pill.width > 52, "Insertion did not expand the production pill");
          if (test.delegates()[0].width > 28 && test.delegates()[0].width < 36) test.inFlightReversals++;
          test.framesAtReturn = test.shadowFrames;
          switch (test.cycle % 3) {
          case 0: empty.active = false; used.active = true; workspaces.remove(1); break;
          case 1: workspaces.remove(1); used.active = true; empty.active = false; break;
          case 2: used.active = true; workspaces.remove(1); empty.active = false; break;
          }
          break;
        case 24:
          test.settled();
          test.check(test.shadowFrames > test.framesAtReturn, "Geometry settled but shadow stopped producing frames");
          console.info("WORKSPACE_LIFECYCLE_PROBE cycle=" + test.cycle + " delegate/row=36 pill/mask/cutout=52 shadowFramesAfterReturn=" + (test.shadowFrames - test.framesAtReturn));
          test.screenshot("settled-" + test.cycle);
          break;
        case 30:
          // Allow capture completion and 240ms to drain before sampling frames.
          test.framesAtIdle = test.shadowFrames;
          break;
        case 40:
          // No captures or visual/model mutations during this 400ms idle window.
          test.check(test.shadowFrames === test.framesAtIdle, "Shadow kept producing frames while idle: " + (test.shadowFrames - test.framesAtIdle));
          test.settled();
          console.info("WORKSPACE_LIFECYCLE_PROBE cycle=" + test.cycle + " idleShadowFrames=" + (test.shadowFrames - test.framesAtIdle));
          if (++test.cycle < 12) { test.step = 9; break; }
          test.check(test.inFlightReversals > 0, "No reversal observed during the width animation");
          console.info("SURFACE_GEOMETRY_PASS workspace lifecycle (native pixels checked by runner)"); Qt.quit(); break;
        }
      } catch (error) { test.fail(error); }
    }
  }
}
