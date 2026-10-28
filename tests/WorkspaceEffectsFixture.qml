import QtQuick
import Quickshell
import "default/components/bar" as Bar

ShellRoot {
  id: root
  property int stage: 0
  property int attempts: 0
  property var palette: null
  function check(ok, message) { if (!ok) throw new Error(message); }
  function findText(item) {
    if (item.text === "1") return item;
    for (const child of item.children) {
      const found = findText(child);
      if (found) return found;
    }
    return null;
  }
  QtObject { id: state; property int id: 1; property bool active: false; property bool urgent: false; property var monitor: null }
  QtObject {
    id: bar
    property var hyprMonitor: null
    property string spotifyDisplay: ""
    property bool spotifyVisible: false
    property int width: 800
    function workspaceText(workspace) { return String(workspace.id); }
  }
  Window {
    visible: true; width: 300; height: 100
    Bar.WorkspacePill { id: pill; bar: bar; wallust: root.palette; workspaceModel: [state]; visible: root.palette !== null }
  }
  Component.onCompleted: {
    const factory = Qt.createComponent(Qt.resolvedUrl("default/wallust/Colors.qml.tmpl"));
    if (factory.status !== Component.Ready) { console.error("WORKSPACE_FAIL " + factory.errorString()); return; }
    root.palette = factory.createObject(root, {lowEffects: false});
  }
  Timer {
    interval: 40; repeat: true; running: true
    onTriggered: {
      try {
        const label = root.findText(pill);
        root.check(label !== null, "workspace delegate missing");
        const indicator = label.parent;
        const mouse = indicator.children.find(child => child.containsMouse !== undefined);
        const inactiveColor = () => mouse.containsMouse ? root.palette.barHover : Qt.color("transparent");
        switch (root.stage++) {
        case 0:
          root.check(indicator.implicitWidth === 28, "initial width");
          state.active = true;
          break;
        case 1:
          // A busy runner can miss the entire animation; retry rather than treating
          // a late timer callback as a product failure. Still require a real frame.
          if (!(indicator.implicitWidth > 28 && indicator.implicitWidth < 36)) {
            root.check(++root.attempts < 5, "could not observe reversal in flight");
            state.active = false; root.palette.lowEffects = true; root.palette.lowEffects = false;
            root.stage = 0; break;
          }
          root.attempts = 0;
          root.check(indicator.implicitWidth > 28 && indicator.implicitWidth < 36, "width must be in progress before reversal");
          root.check(indicator.color.toString() !== inactiveColor().toString() && indicator.color.toString() !== root.palette.barActive.toString(), "color must be in progress before reversal");
          state.active = false;
          break;
        case 7:
          root.check(indicator.implicitWidth === 28, "reversed width");
          root.check(indicator.color.toString() === inactiveColor().toString(), "reversed color: " + indicator.color);
          state.active = true;
          break;
        case 8:
          if (!(indicator.implicitWidth > 28 && indicator.implicitWidth < 36)) {
            root.check(++root.attempts < 5, "could not observe low-effects transition in flight");
            root.palette.lowEffects = true; state.active = false; root.palette.lowEffects = false;
            root.stage = 7; break;
          }
          root.attempts = 0;
          root.check(indicator.implicitWidth > 28 && indicator.implicitWidth < 36, "width must be in progress before low-effects");
          root.check(indicator.color.toString() !== inactiveColor().toString() && indicator.color.toString() !== root.palette.barActive.toString(), "color must be in progress before low-effects");
          root.palette.lowEffects = true;
          break;
        case 9:
          root.check(indicator.implicitWidth === 36, "low-effects active width within 40ms");
          root.check(indicator.color.toString() === root.palette.barActive.toString(), "low-effects active color within 40ms");
          break;
        case 15:
          root.check(indicator.implicitWidth === 36, "no stale width update");
          root.check(indicator.color.toString() === root.palette.barActive.toString(), "no stale color update");
          state.active = false;
          root.check(indicator.implicitWidth === 28, "low-effects inactive width");
          root.check(indicator.color.toString() === inactiveColor().toString(), "low-effects inactive color");
          root.palette.lowEffects = false;
          state.active = true;
          break;
        case 16:
          if (!(indicator.implicitWidth > 28 && indicator.implicitWidth < 36)) {
            root.check(++root.attempts < 5, "could not observe re-enabled animation");
            root.palette.lowEffects = true; state.active = false; root.palette.lowEffects = false; state.active = true;
            root.stage = 16; break;
          }
          root.attempts = 0;
          root.check(indicator.implicitWidth > 28 && indicator.implicitWidth < 36, "width animates after re-enable");
          state.active = false;
          break;
        case 17:
          root.palette.lowEffects = true;
          break;
        case 18:
          root.check(indicator.implicitWidth === 28, "reversed width after re-enable");
          root.check(indicator.color.toString() === inactiveColor().toString(), "reversed color after re-enable");
          break;
        case 24:
          root.check(indicator.implicitWidth === 28, "no stale reversed width");
          root.check(indicator.color.toString() === inactiveColor().toString(), "no stale reversed color");
          root.palette.lowEffects = false;
          state.active = true;
          break;
        case 30:
          root.check(indicator.implicitWidth === 36, "binding survives repeated re-enable");
          root.check(indicator.color.toString() === root.palette.barActive.toString(), "color binding survives repeated re-enable");
          console.log("WORKSPACE_PASS");
          Qt.quit();
          break;
        }
      } catch (error) {
        console.error("WORKSPACE_FAIL " + error);
        Qt.quit();
      }
    }
  }
}
