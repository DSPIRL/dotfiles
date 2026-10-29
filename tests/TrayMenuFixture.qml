import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import Quickshell.Services.SystemTray
import "default/components/bar" as Bar

ShellRoot {
  id: root
  property int step: 0
  property int outsideAlpha
  property int outsideClicks: 0
  property var colors: ({barCard: "#303030", barSeparator: "#606060", barButtonHover: "#505050", barHover: "#505050", barText: "white", lowEffects: true, solidSurfaces: false, lightMode: false, glassOpacity: 0.4, glassTop: Qt.rgba(0.2, 0.2, 0.2, 1), glassBottom: Qt.rgba(0.1, 0.1, 0.1, 1), barBorder: "#88ffffff", glassInnerEdge: "#18ffffff"})
  Window {
    id: window
    visible: true
    color: "transparent"
    width: 400; height: 400
    Bar.StyledMenu {
      id: popup
      parent: window.contentItem
      x: 10; y: 10
      wallust: root.colors
    }
    Rectangle {
      id: outsideTarget
      x: 350; y: 350; width: 40; height: 40
      color: "transparent"
      MouseArea { anchors.fill: parent; onClicked: root.outsideClicks++ }
    }
    TestCase { id: keys; name: "MenuKeys"; when: false }
  }
  Timer {
    interval: 200; running: true; repeat: true
    onTriggered: {
      if (root.step === 0 && SystemTray.items.values.length === 1) {
        root.outsideAlpha = keys.grabImage(window.contentItem).alpha(390, 390);
        popup.menu = SystemTray.items.values[0].menu;
        popup.open();
        root.step = 1;
      } else if (root.step === 1) {
        if (keys.grabImage(window.contentItem).alpha(390, 390) !== root.outsideAlpha) { console.log("TRAY_FAIL popup dims transparent window"); Qt.exit(1); return; }
        const list = keys.findChild(popup.contentItem, "menuList");
        if (!list) { console.log("TRAY_FAIL missing list"); Qt.exit(1); return; }
        keys.mouseClick(list, 100, 18); // Disabled item must not fire.
        if (!popup.visible) { console.log("TRAY_FAIL disabled click"); Qt.exit(1); return; }
        keys.keyClick(Qt.Key_Down);
        keys.keyClick(Qt.Key_Right);
        root.step = 2;
      } else if (root.step === 2) {
        keys.keyClick(Qt.Key_Escape);
        root.step = 7;
      } else if (root.step === 7) {
        if (!popup.visible) { console.log("TRAY_FAIL nested escape closed popup"); Qt.exit(1); return; }
        keys.keyClick(Qt.Key_Right);
        root.step = 6;
      } else if (root.step === 6) {
        keys.keyClick(Qt.Key_Down);
        keys.keyClick(Qt.Key_Return);
        root.step = 3;
      } else if (root.step === 3) {
        if (popup.visible) { console.log("TRAY_FAIL popup did not close"); Qt.exit(1); return; }
        popup.open();
        root.step = 9;
      } else if (root.step === 9) {
        root.step = 4;
      } else if (root.step === 4) {
        const list = keys.findChild(popup.contentItem, "menuList");
        if (!list) { console.log("TRAY_FAIL missing list"); Qt.exit(1); return; }
        keys.mouseClick(list, 100, 63);
        root.step = 8;
      } else if (root.step === 8) {
        keys.keyClick(Qt.Key_Escape);
        root.step = 5;
      } else if (root.step === 5) {
        if (popup.visible) { console.log("TRAY_FAIL removed submenu still open"); Qt.exit(1); return; }
        if (popup.background.border.width !== 1 || popup.background.border.color !== Qt.color(root.colors.barBorder)) { console.log("TRAY_FAIL glass border"); Qt.exit(1); return; }
        popup.open();
        root.step = 10;
      } else if (root.step === 10) {
        keys.mouseClick(outsideTarget, 20, 20);
        if (popup.visible || root.outsideClicks !== 1) { console.log("TRAY_FAIL outside click"); Qt.exit(1); return; }
        console.log("TRAY_PASS");
        Qt.quit();
      }
    }
  }
}
