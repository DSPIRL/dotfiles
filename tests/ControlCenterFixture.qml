import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Networking
import Quickshell.Bluetooth
// tests/control-center.sh copies this fixture beside the source config.
import "default/components" as Shell
import "default/components/control" as Control
import "default/wallust" as Wallust
import "default" as Style


ShellRoot {
  id: testRoot
  QtObject {
    id: desktop
    property bool loaded: true
    property bool busy: false
    property string error: ""
    property bool quiet: false
    property bool keepAwake: false
    property bool keepAwakeRequested: false
    property bool keepAwakeFailed: false
    property string scripts: "/not-executed/"
    property var actions: []
    property var values: ({theme:"dark", lowEffects:false, effectiveBlur:true, effectiveOpacity:false, effectiveShellGlass:true, nightLight:false, nightLightWanted:false, nightLightAvailable:false, lockAvailable:false, bigMonitorAvailable:false})
    property int glassOpacity: 18
    property int controlOpacity: 50
    property int windowOpacity: 100
    property int blurSize: 5
    property var numericSettings: ({
      "glass-opacity": {field:"glassOpacity", minimum:0, maximum:100},
      "control-opacity": {field:"controlOpacity", minimum:0, maximum:100},
      "window-opacity": {field:"windowOpacity", minimum:0, maximum:100},
      "blur-size": {field:"blurSize", minimum:1, maximum:20}
    })
    function refresh() {}
    function run(command) { actions.push(command); }
    property bool busyOnEffect: false
    function effect(name, value) { actions.push([name,value]); if (busyOnEffect) busy = true; }
    function theme(value) { actions.push(["theme",value]); }
    function setQuiet(value) { actions.push(["quiet",value]); }
    function setKeepAwake(value) { actions.push(["awake",value]); }
    function setNumericSetting(name, value) { actions.push([name,value]); }
    function monitorResolution(value) { actions.push(["monitor",value]); }
  }
  QtObject {
    id: brightness
    property bool available: false
    property real percent: 100
    property int displayCount: 0
    property var displays: []
    property string error: ""
    function refresh() {}
  }
  QtObject {
    id: wifiMock
    property int backend: NetworkBackendType.NetworkManager
    property bool wifiEnabled: true
    property bool wifiHardwareEnabled: true
  }
  QtObject {
    id: bluetoothMock
    property bool enabled: true
    property int state: BluetoothAdapterState.Enabled
  }
  Shell.RadioState {
    id: sharedRadios
    wifi: wifiMock
    adapter: barStub.bluetoothAdapter
    networkManager: NetworkBackendType.NetworkManager
    blocked: BluetoothAdapterState.Blocked
    enabling: BluetoothAdapterState.Enabling
    disabling: BluetoothAdapterState.Disabling
  }
  QtObject {
    id: barStub
    property var radioState: sharedRadios
    property var desktopState: desktop
    property var screen: Quickshell.screens[0]
    property bool controlPanelOpen: true
    property bool hasBattery: true
    property int batteryPercent: 82
    property bool barVisible: true
    property int height: 44
    property string networkStatus: "Unavailable in isolated test"
    property string wifiStatus: "Disconnected"
    property string bluetoothTooltip: "Unavailable in isolated test"
    property var bluetoothAdapter: null
    property var audioOutputDevices: [audioNode]
    property var audioInputDevices: [audioNode]
    property var defaultAudioSink: audioNode
    property var defaultAudioSource: audioNode
    property bool showLaptopBrightnessControl: false
    property var laptopBrightnessState: brightness
    property var ddcBrightnessState: brightness
    signal sessionRequested()
    signal categoryRequested(string category)
    function audioNodeLabel(node) { return node.description; }
    function isDefaultAudioDevice(node, input) { return node === audioNode; }
    function setDefaultAudioDevice(node, input) { desktop.actions.push("default-device"); }
    function setAudioDeviceVolume(node, volume) { desktop.actions.push("volume"); }
    function toggleAudioDeviceMute(node) { desktop.actions.push("mute"); }
    function setDdcBrightness(display, value, maximum) { desktop.actions.push("ddc-brightness"); }
    function launchNetworkTui() { desktop.actions.push("network"); }
    function volumeIcon(volume, muted) { return muted ? "󰝟" : "󰕾"; }
    function runCommand(command) { desktop.actions.push(command); }
    function runHyprScript(command) { desktop.actions.push(command); }
    function launchTerminal(command) { desktop.actions.push(command); }
    function launchTerminalShell(command) { desktop.actions.push(command); }
    function setBarVisible(value) { barVisible = value; }
  }
  Wallust.Colors { id: palette; controlCenter: true; controlOpacity: 0.5; glassOpacity: 0.18 }

  QtObject {
    id: audioNode
    property string description: "Synthetic audio"
    property var audio: QtObject { property real volume: 0.42; property bool muted: false }
  }
  QtObject {
    id: media
    property string dbusName: "org.mpris.MediaPlayer2.synthetic"
    property string identity: "Synthetic player"
    property string uniqueId: "track-1"
    property string trackTitle: "<b>Metadata is plain text</b>"
    property string trackArtist: "Test artist"
    property string trackAlbum: "Test album"
    property string trackArtUrl: ""
    property bool isPlaying: true
    property int playbackState: 1
    property bool canTogglePlaying: true
    property bool canGoNext: false
    property bool canGoPrevious: true
    property bool canSeek: true
    property bool positionSupported: true
    property bool lengthSupported: true
    property real position: 42
    property real length: 180
    property var actions: []
    function togglePlaying() { actions.push("play-pause"); }
    function next() { actions.push("next"); }
    function previous() { actions.push("previous"); }
  }
  QtObject {
    id: otherMedia
    property string dbusName: "org.mpris.MediaPlayer2.other"
    property string identity: "Other player"
    property string uniqueId: "track-2"
    property string trackTitle: "Unknown duration"
    property string trackArtist: ""
    property string trackAlbum: ""
    property string trackArtUrl: ""
    property bool isPlaying: false
    property int playbackState: 0
    property bool canTogglePlaying: false
    property bool canGoNext: false
    property bool canGoPrevious: false
    property bool canSeek: false
    property bool positionSupported: false
    property bool lengthSupported: false
    property real position: 0
    property real length: 0
  }
  Control.ControlPanel { id: panel; bar: barStub; wallust: palette }
  function walk(item, predicate) {
    if (predicate(item)) return item;
    for (const child of item.children || []) {
      const found = walk(child, predicate);
      if (found) return found;
    }
    return null;
  }
  function label(text) { return walk(panel.contentItem, o => o.text === text); }
  function named(name) { return walk(panel.contentItem, o => o.objectName === name); }
  function check(value, message) { if (!value) throw new Error(message); }
  function page() { return panel.category === "system" ? named("systemPage").item : named("controlPage").item; }
  function checkCategoryVisible(name) {
    const navigation = named("categoryNavigation"), button = label(name);
    const x = button.mapToItem(navigation, 0, 0).x;
    check(x >= -0.01 && x + button.width <= navigation.width + 0.01, name + " tab outside navigation viewport");
  }
  function checkSystemFits(previousPage) {
    const loader = named("systemPage");
    const viewport = loader.parent.parent.parent;
    check(loader.y === 0, "Unloaded " + previousPage + " left blank space above System");
    check(viewport.contentHeight <= viewport.height, "System unnecessarily requires scrolling after " + previousPage);
    const last = label("Bar diagnostics");
    const y = last.mapToItem(viewport, 0, 0).y;
    check(y >= 0 && y + last.height <= viewport.height, "System diagnostics below viewport after " + previousPage);
  }
  function checkThemeGeometry() {
    const wallpaper=named("wallpaperChoice");
    let bottom=0;
    for (const name of ["lightThemeChoice","darkThemeChoice"]) {
      const button=named(name), position=button.mapToItem(page(),0,0);
      check(position.x >= 0 && position.x + button.width <= page().width, "Theme choice exceeds narrow page");
      const text=walk(button.contentItem,o => o.text === button.text);
      check(text.width + 1 >= text.implicitWidth, "Theme choice label clipped at larger font size");
      bottom=Math.max(bottom,position.y + button.height);
    }
    check(wallpaper.y >= bottom, "Wallpaper overlaps the theme selector");
  }
  function low(value) {
    desktop.values = Object.assign({},desktop.values,{lowEffects:value,effectiveShellGlass:!value,effectiveBlur:!value});
    palette.lowEffects=value; palette.solidSurfaces=value;
  }
  property int stage: 0
  property int busyCheck: -1
  property real busyScroll: 0
  property real busyHeight: 0
  property var savedLayout: ({})
  Timer {
    interval: 120
    repeat: true
    running: Quickshell.env("CONTROL_CENTER_PREVIEW") !== "1"
    onTriggered: {
      try {
        switch (testRoot.stage++) {
          case 0:
            check(panel.category === "quick" && page(), "Quick must be the initial page");
            check(label("Quick").height >= label("Quick").contentItem.implicitHeight + 16, "Category labels clipped");
            check(label("Low effects").visible, "Low effects not available");
            barStub.bluetoothAdapter=bluetoothMock;
            const wifi=named("quickNetwork"), bluetooth=named("quickBluetooth");
            check(wifi.highlightedState && bluetooth.highlightedState, "Radio state missing");
            wifi.clicked(); bluetooth.clicked();
            check(!wifiMock.wifiEnabled && !bluetoothMock.enabled && !sharedRadios.wifiPending && !sharedRadios.bluetoothPending, "Radio toggles did not follow mocked state");
            wifiMock.wifiHardwareEnabled=false;
            wifi.clicked();
            check(!wifiMock.wifiEnabled, "Blocked Wi-Fi toggled");
            wifiMock.wifiHardwareEnabled=true;
            bluetoothMock.state=BluetoothAdapterState.Blocked;
            bluetooth.clicked();
            check(!bluetoothMock.enabled, "Blocked Bluetooth toggled");
            bluetoothMock.state=BluetoothAdapterState.Disabled;
            barStub.bluetoothAdapter=null;
            bluetooth.clicked();
            check(!bluetoothMock.enabled, "Missing adapter toggled");
            const quickMute=named("quickOutputMute");
            check(quickMute.width === quickMute.height && quickMute.font.pixelSize === Style.Typography.controlTileIconSize, "Quick mute icon geometry inconsistent");
            brightness.displays=[{monitor:"Synthetic monitor",current:50,maximum:100,display:7}];
            check(label("Synthetic monitor  ·  50%"), "Quick external brightness missing");
            brightness.displays=[];
            // Simulate an outstanding backend confirmation while Quick unloads.
            sharedRadios.wifiTarget=true; sharedRadios.wifiPending=true;
            panel.selectCategory("audio");
            check(sharedRadios.wifiPending, "Pending request lost on page change");
            barStub.controlPanelOpen=false;
            check(sharedRadios.wifiPending, "Pending request lost on close");
            wifiMock.wifiEnabled=true;
            check(!sharedRadios.wifiPending, "Late confirmation not observed while closed");
            sharedRadios.wifiError="Wi-Fi change not confirmed";
            wifiMock.wifiEnabled=false; wifiMock.wifiEnabled=true;
            check(sharedRadios.wifiError === "", "Late confirmation did not clear timeout");
            barStub.controlPanelOpen=true;
            panel.selectCategory("system");
            break;
          case 1:
            checkSystemFits("Quick");
            panel.selectCategory("appearance");
            break;
          case 2: {
            check(walk(panel.contentItem,o => o.setting === "glass-opacity"), "Appearance controls missing");
            const toggle=label("Shell glass"), viewport=named("controlPage").parent.parent.parent;
            if (busyCheck === -1) {
            const toggleY=toggle.mapToItem(viewport.contentItem, 0, 0).y;
            viewport.contentY=toggleY + toggle.height / 2;
            const before=viewport.contentY;
            toggle.forceActiveFocus(Qt.MouseFocusReason);
            check(toggle.activeFocus, "Appearance toggle did not receive focus");
            check(viewport.contentY === before, "Pointer focus unexpectedly scrolled a partially visible toggle");
            label("×").forceActiveFocus();
            toggle.forceActiveFocus(Qt.TabFocusReason);
            check(viewport.contentY === toggleY, "Keyboard focus did not reveal a partially visible toggle");
            label("×").forceActiveFocus();
            viewport.contentY=toggleY + toggle.height / 2;
            toggle.forceActiveFocus(Qt.OtherFocusReason);
            check(viewport.contentY === toggleY, "Programmatic focus did not reveal a partially visible toggle");
            desktop.busyOnEffect=true;
            busyCheck=0;
            }
            const names=["Shell glass", "Configured transparency", "Backdrop blur"];
            if (busyCheck < names.length * 3) {
              const name=names[Math.floor(busyCheck / 3)], control=label(name);
              if (busyCheck % 3 === 0) {
                label("×").forceActiveFocus();
                const y=control.mapToItem(viewport.contentItem, 0, 0).y;
                viewport.contentY=Math.min(y, viewport.contentHeight - viewport.height);
                control.forceActiveFocus(Qt.MouseFocusReason);
                busyScroll=viewport.contentY; busyHeight=viewport.contentHeight;
                control.toggle();
                control.toggled(); // toggle() does not emit the user-only signal.
                check(desktop.busy, name + " did not dispatch a mocked effect");
                check(panel.contentItem.Window.window.activeFocusItem === named("controlPage"), name + " did not transfer focus to loader");
              } else if (busyCheck % 3 === 1) {
                check(viewport.contentY === busyScroll && viewport.contentHeight === busyHeight, name + " jumped while busy");
                if (busyCheck === 4) label("×").forceActiveFocus();
                desktop.busy=false;
              } else {
                check(viewport.contentY === busyScroll && viewport.contentHeight === busyHeight, name + " jumped after completion");
                check(busyCheck === 5 ? label("×").activeFocus : control.activeFocus, name + " stole or lost focus after completion");
              }
              busyCheck++;
              testRoot.stage--;
              break;
            }
            desktop.busyOnEffect=false;
            desktop.actions=[];
            viewport.contentY=0;
            const light=named("lightThemeChoice"), dark=named("darkThemeChoice"), wallpaper=named("wallpaperChoice");
            check(light.flat && dark.flat && wallpaper.flat && wallpaper.parent === page(), "Theme section still nested in a card");
            check(!light.highlightedState && dark.highlightedState, "Saved theme selection missing");
            check(light.background.border.width === 0 && wallpaper.background.border.width === 0, "Flat rows have decorative outlines");
            light.clicked();
            check(JSON.stringify(desktop.actions) === JSON.stringify([["theme","light"]]), "Theme choice dispatched incorrect action");
            desktop.values=Object.assign({},desktop.values,{theme:"light"});
            check(light.highlightedState && !dark.highlightedState && light.Accessible.checked && !dark.Accessible.checked, "Theme selection did not follow shared state");
            light.clicked();
            check(desktop.actions.length === 1, "Selected theme unnecessarily reapplied");
            wallpaper.clicked();
            check(JSON.stringify(desktop.actions[1]) === JSON.stringify(["/not-executed/walli.sh"]), "Wallpaper action changed");
            desktop.busy=true;
            check(!light.enabled && !dark.enabled && !wallpaper.enabled, "Busy-state guards lost");
            desktop.busy=false;
            desktop.values=Object.assign({},desktop.values,{theme:"dark"});
            desktop.actions=[];
            panel.selectCategory("system");
            break;
          }
          case 3:
            checkSystemFits("Look & Feel");
            panel.selectCategory("appearance");
            break;
          case 4:
            savedLayout={width:panel.implicitWidth,labelSize:Style.Typography.controlLabelSize};
            panel.implicitWidth=360;
            Style.Typography.controlLabelSize=24;
            break;
          case 5:
            checkThemeGeometry();
            panel.implicitWidth=savedLayout.width;
            Style.Typography.controlLabelSize=savedLayout.labelSize;
            break;
          case 6:
            check(walk(panel.contentItem,o => o.setting === "glass-opacity"), "Appearance controls missing");
            check(desktop.actions.length === 0, "Navigation changed settings");
            low(true);
            break;
          case 7:
            check(!walk(panel.contentItem,o => o.setting === "blur-size").children[1].enabled, "Low effects must disable blur slider");
            check(desktop.glassOpacity === 18 && desktop.controlOpacity === 50, "Low effects erased preferences");
            low(false);
            panel.selectCategory("audio");
            break;
          case 8: {
            const controls=page().children.filter(o => o.chooseDevice !== undefined);
            check(controls.length === 2, "Audio controls missing");
            for (const control of controls) {
              const prefix=control.input ? "Microphone" : "Output";
              const header=walk(control,o => typeof o.text === "string" && o.text.startsWith(prefix));
              check(header && header.text.endsWith("▴"), prefix + " expanded indicator missing");
              const mute=named(control.input ? "microphoneMute" : "outputMute");
              check(mute.width === mute.height && mute.height === header.height && mute.height >= 40, prefix + " mute target/header misaligned");
              check(Math.abs(header.x - mute.x - mute.width - 8) < 0.01, prefix + " icon spacing inconsistent");
              check(mute.font.pixelSize === Style.Typography.controlTileIconSize, prefix + " icon too small");
              header.clicked();
              check(!control.expanded && header.text.endsWith("▾"), prefix + " collapsed indicator missing");
              header.clicked();
              check(control.expanded && header.text.endsWith("▴"), prefix + " expanded indicator stale");
            }
            audioNode.audio.muted=true;
            check(named("microphoneMute").text === "󰍭" && named("outputMute").text === "󰝟", "Muted glyphs not from the same icon set");
            check(named("outputMute").font.pixelSize === Style.Typography.controlTileIconSize && named("outputMute").Accessible.name === "Unmute output", "Muted sizing/action label changed");
            audioNode.audio.muted=false;
            check(named("microphoneMute").text === "󰍬", "Unmuted microphone glyph inconsistent");
            controls[0].chooseDevice=true;
            controls[1].chooseDevice=true;
            check(!controls[0].chooseDevice, "Multiple device menus expanded");
            check(page().dismissDetails() && !controls[1].chooseDevice, "Escape detail dismissal failed");
            check(!page().dismissDetails(), "No detail should remain open");
            panel.selectCategory("music");
            break;
          }
          case 9:
            page().players=[media, otherMedia];
            check(page().player === media, "Playing player not selected");
            check(named("mediaSeek").enabled && named("mediaSeek").value === 42, "Seek not bound to player");
            check(label(media.trackTitle).textFormat === Text.PlainText, "Player metadata interpreted as markup");
            check(page().clock(367) === "6:07", "Playback time formatting");
            check(page().artwork("qrc:/unexpected") === "", "Unexpected artwork scheme allowed");
            named("mediaNext").clicked();
            check(media.actions.length === 0, "Unsupported next action dispatched");
            named("mediaPlayPause").clicked();
            check(media.actions[0] === "play-pause", "Playback action not dispatched");
            page().selectedPlayer=otherMedia.dbusName;
            break;
          case 10:
            check(page().player === otherMedia && !named("mediaSeek").enabled && !named("mediaPlayPause").enabled, "Unsupported player capabilities enabled");
            page().selectedPlayer=media.dbusName;
            page().players=[otherMedia];
            check(page().player === otherMedia, "Disappearing player not replaced");
            page().players=[];
            check(page().player === null, "Empty player state broken");
            barStub.controlPanelOpen=false;
            break;
          case 11:
            check(!named("controlPage").item && panel.category === "music", "Closing did not unload page/preserve category");
            // Reverse visibility repeatedly before the event loop can settle.
            barStub.controlPanelOpen=true;
            barStub.controlPanelOpen=false;
            barStub.controlPanelOpen=true;
            panel.selectCategory("not-a-category");
            check(panel.category === "music", "Invalid category accepted");
            panel.implicitWidth=360; panel.implicitHeight=500;
            panel.selectCategory("system");
            break;
          case 12:
            const focusAfterReversal = panel.contentItem.Window.window.activeFocusItem;
            check(panel.visible && focusAfterReversal && focusAfterReversal.visible && focusAfterReversal.enabled && focusAfterReversal.activeFocus, "Panel reversal left no valid focused control (focus=" + focusAfterReversal + ", window active=" + panel.contentItem.Window.window.active + ")");
            check(panel.category === "system" && page(), "Narrow navigation failed");
            check(label("Low effects").visible && label("Session…").y + label("Session…").height < panel.height, "Footer unavailable on narrow panel");
            check(desktop.actions.length === 0, "Navigation/closing changed desktop state");
            Style.Typography.controlHintSize=24;
            panel.focusCategory(4);
            check(label("Display").height >= label("Display").contentItem.implicitHeight + 16, "Larger category fonts clipped");
            barStub.sessionRequested();
            break;
          case 13:
            check(panel.sessionOpen && !named("controlPage").item && !named("systemPage").visible, "Session overlay did not hide content");
            label("Log out").clicked();
            check(panel.confirmation === "Log out", "Session confirmation missing");
            barStub.categoryRequested("quick");
            check(!panel.sessionOpen && panel.confirmation === "" && panel.category === "quick" && panel.visible, "Category request did not clear session confirmation");
            checkCategoryVisible("Quick");
            const leftX = named("categoryNavigation").contentX;
            barStub.categoryRequested("audio");
            check(panel.category === "audio" && panel.visible, "Category request did not select Audio while open");
            checkCategoryVisible("Audio");
            check(named("categoryNavigation").contentX > leftX, "Audio request did not scroll right");
            check(panel.contentItem.Window.window.activeFocusItem, "Category request lost focus");
            barStub.categoryRequested("quick");
            check(panel.category === "quick" && panel.visible, "Category request did not select Quick while open");
            checkCategoryVisible("Quick");
            check(named("categoryNavigation").contentX < leftX + 0.01, "Quick request did not scroll left");
            barStub.sessionRequested();
            check(label("Suspend") && label("Shutdown"), "Session actions missing");
            check(desktop.actions.length === 0, "Session actions ran without confirmation");
            label("Log out").clicked();
            check(desktop.actions.length === 0 && panel.confirmation === "Log out", "Choosing logout bypassed confirmation");
            label("Confirm Log out").clicked();
            check(JSON.stringify(desktop.actions[0]) === JSON.stringify(["hyprctl","repl","hl.dispatch(hl.dsp.exit())"]), "Confirmed logout command incorrect");
            console.log("CONTROL_CENTER_PASS");
            Qt.quit();
        }
      } catch (error) {
        console.error("CONTROL_CENTER_FAIL stage " + testRoot.stage + ": " + error);
        Qt.quit();
      }
    }
  }
  // Preview mode uses the same mocks and never executes desktop/session actions.
  IpcHandler {
    target: "test"
    function select(name: string): void { panel.selectCategory(name); }
    function takeFocus(): void { panel.WlrLayershell.keyboardFocus = WlrKeyboardFocus.Exclusive; }
    function focusCategory(index: int): void { panel.focusCategory(index); }
    function size(width: int, height: int): void { panel.implicitWidth=width; panel.implicitHeight=height; }
    function demoMedia(): void { panel.selectCategory("music"); page().players=[media,otherMedia]; }
    function light(value: bool): void { palette.lightMode=value; }
    function lowEffects(value: bool): void { low(value); }
    function state(): string {
      const window=panel.contentItem.Window.window;
      const focus=window.activeFocusItem;
      return JSON.stringify({category:panel.category,active:window.active,focus:focus ? focus.Accessible.name || focus.text || focus.toString() : "",actions:desktop.actions});
    }
    function quit(): void { Qt.quit(); }
  }
}
