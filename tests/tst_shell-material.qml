import QtQuick
import QtQuick.Window
import QtTest
import "../dot_config/quickshell/default/components" as Shell
import "../dot_config/quickshell/default/components/control" as Control
import "../dot_config/quickshell/default/components/bar" as Bar
import "../dot_config/quickshell/default" as Style
import "../dot_config/quickshell/default/components/Presentation.js" as Presentation

Item {
  id: testRoot
  width: 800
  height: 600

  Component {
    id: scrollFactory
    Flickable {
      id: scrollFixture
      required property var wallust
      width: 320; height: 140
      contentWidth: width
      contentHeight: 700
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      Control.ControlSlider {
        objectName: "scrollTestSlider"
        x: 20; y: 40; width: 280
        wallust: scrollFixture.wallust
        value: 50
      }
    }
  }
  Component {
    id: focusScrollFactory
    Flickable {
      id: focusView
      required property var wallust
      width: 320; height: 140; contentHeight: 400; clip: true
      Control.ControlToggle { objectName: "firstToggle"; y: 80; width: 280; text: "First"; wallust: focusView.wallust }
      Control.ControlToggle { objectName: "nextToggle"; y: 160; width: 280; text: "Next"; wallust: focusView.wallust }
    }
  }
  Component { id: networkFactory; Shell.NetworkState {} }
  Component { id: audioFactory; Shell.AudioState {} }
  Component { id: audioBackendFactory; QtObject {
    property var nodes: ({values: []})
    property var defaultAudioSink
    property var defaultAudioSource
    property var preferredDefaultAudioSink
    property var preferredDefaultAudioSource
  } }
  Component { id: audioNodesFactory; QtObject { property var values: [] } }
  Component { id: audioNodeFactory; QtObject {
    property bool isSink: true
    property bool isStream: false
    property var audio: QtObject { property real volume: 0.5; property bool muted: false }
  } }
  Component { id: radioFactory; Shell.RadioState { networkManager: 1; blocked: 2; enabling: 3; disabling: 4; timeout: 40 } }
  Component { id: delayedWifiFactory; QtObject {
    property int backend: 1
    property bool wifiEnabled: false
    property bool wifiHardwareEnabled: true
    property bool reject: true
    onWifiEnabledChanged: if (reject && wifiEnabled) wifiEnabled = false
  } }
  Component { id: delayedBluetoothFactory; QtObject {
    property int state: 0
    property bool enabled: false
    property bool reject: true
    onEnabledChanged: if (reject && enabled) enabled = false
  } }
  Component { id: quickFactory; Control.QuickPage { width: 400 } }
  Component {
    id: radiosFactory
    QtObject {
      property var wifi: QtObject { property int backend: 0; property bool wifiEnabled: false; property bool wifiHardwareEnabled: false }
      property bool wifiAvailable: false
      property bool bluetoothBlocked: false
      property bool bluetoothChanging: false
      property bool wifiPending: false
      property bool bluetoothPending: false
      property string wifiError: ""
      property string bluetoothError: ""
      function toggleWifi() {}
      function toggleBluetooth() {}
    }
  }
  Component {
    id: quickBarFactory
    QtObject {
      property var desktopState: QtObject {
        property bool loaded: true
        property bool busy: false
        property bool keepAwake: false
        property bool keepAwakeRequested: false
        property bool keepAwakeFailed: false
        property bool quiet: false
        property var values: ({networkSettings: true})
      }
      property bool hasBattery: false
      property var defaultAudioSink: null
      property bool showLaptopBrightnessControl: false
      property var ddcBrightnessState: ({displays: []})
      property var laptopBrightnessState: ({available: false, percent: 0})
      property string networkStatus: "Disconnected"
      property string wifiStatus: "Disconnected"
      property string bluetoothTooltip: "Disabled"
      property var bluetoothAdapter: null
      property int launches: 0
      function volumeIcon(volume, muted) { return ""; }
      function launchNetworkTui() { launches += 1; }
    }
  }
  Component { id: surfaceFactory; Shell.GlassSurface { width: 400; height: 180 } }
  Component { id: shadowFactory; Shell.SurfaceShadow { width: 168; height: 128; panelRects: [Qt.rect(24, 24, 120, 80)]; radius: 26 } }
  Component { id: surfaceCanvasFactory; Window { width: 168; height: 128; color: "transparent"; visible: true } }
  Component { id: toggleFactory; Control.ControlToggle { width: 200; text: "Toggle" } }
  Component { id: buttonFactory; Shell.ActionButton { x: 20; y: 30; width: 160; text: "Control" } }
  Component { id: actionButtonFactory; Shell.ActionButton { x: 20; y: 30; width: 160; text: "Action" } }
  Component { id: customContentFactory; Item { implicitWidth: 30; implicitHeight: 25 } }
  SignalSpy { id: actionClicks; signalName: "clicked" }
  Component { id: indicatorsFactory; Bar.StatusIndicators {} }
  Component { id: clockFactory; Bar.ClockPill {} }
  Component { id: mediaFactory; Bar.SpotifyPill {} }
  Component { id: notificationBodyFactory; Text { text: "Body"; font: Style.Typography.notificationBodyFont } }
  Component { id: notificationActionFactory; Shell.ActionButton { text: "Act"; font: Style.Typography.notificationActionFont } }
  Component {
    id: statusBarFactory
    QtObject {
      property var defaultAudioSink: ({audio: {volume: 0.38, muted: false}})
      property bool controlPanelOpen: false
      property string requestedCategory: ""
      property var desktopState: QtObject { property var values: ({bluetoothSettings: true}); property string error: "" }
      property string command: ""
      function categoryRequested(category) { requestedCategory = category; }
      function runCommand(args) { command = args[0]; }
      function launchNetworkTui() { command = "network"; }
      property int width: 1920
      property bool spotifyVisible: true
      property string spotifyDisplay: "Test track"
      property string audioGlyph: "󰕾"
      property real sinkVolume: 0.38
      property bool sinkMuted: false
      property string bluetoothIcon: ""
      property string bluetoothLabel: "2"
      property bool hasBattery: true
      property int batteryPercent: 67
      property var displayBattery: ({state: 0})
      property color batteryTextColor: "#ff0000"
      function toggleAudioDeviceMute(node) { if (node && node.audio) node.audio.muted = !node.audio.muted; }
      function setAudioDeviceVolume(node, volume) { if (node && node.audio) node.audio.volume = Math.max(0, Math.min(1, volume)); }
      function volumeIcon(volume, muted) { return audioGlyph; }
      function batteryIcon(percent, state) { return "󰁹"; }
    }
  }

  TestCase {
    function test_audioState() {
      const sink = {id: 1, isSink: true, audio: {volume: 0.5, muted: false}, nickname: "Speaker"};
      const source = {id: 2, isSink: false, audio: {volume: 0.3, muted: false}, description: "Mic"};
      const backend = createTemporaryObject(audioBackendFactory, testRoot, {nodes: {values: [sink, source, {isStream: true, audio: {}}, {isSink: true}]}, defaultAudioSink: sink, defaultAudioSource: source});
      const state = createTemporaryObject(audioFactory, testRoot, {pipewire: backend});
      compare(state.audioOutputDevices.length, 1); compare(state.audioInputDevices.length, 1);
      compare(state.audioTrackedNodes.length, 4);
      compare(state.audioNodeLabel(sink), "Speaker"); compare(state.audioNodeLabel(source), "Mic");
      compare(state.audioNodeLabel(null), "Audio device");
      verify(state.isDefaultAudioDevice({id: 1}, false)); verify(!state.isDefaultAudioDevice(sink, true));
      state.setDefaultAudioDevice(source, true); compare(backend.preferredDefaultAudioSource.id, source.id);
      state.setDefaultAudioDevice(sink, false); compare(backend.preferredDefaultAudioSink.id, sink.id);
      state.setAudioDeviceVolume(sink, 2); compare(sink.audio.volume, 1);
      state.setAudioDeviceVolume(sink, -1); compare(sink.audio.volume, 0);
      state.toggleAudioDeviceMute(sink); verify(sink.audio.muted);
      state.toggleAudioDeviceMute(null); state.setAudioDeviceVolume(null, 1); state.setDefaultAudioDevice(null, false);
      const empty = createTemporaryObject(audioFactory, testRoot, {pipewire: {nodes: {values: []}, defaultAudioSink: null, defaultAudioSource: null}});
      compare(empty.sinkVolume, 0); verify(!empty.sinkMuted); compare(empty.audioTrackedNodes.length, 0);
    }
    function test_audioStateReactive() {
      const nodes = createTemporaryObject(audioNodesFactory, testRoot);
      const backend = createTemporaryObject(audioBackendFactory, testRoot, {nodes: nodes});
      const state = createTemporaryObject(audioFactory, testRoot, {pipewire: backend});
      const sink = createTemporaryObject(audioNodeFactory, testRoot);
      const source = createTemporaryObject(audioNodeFactory, testRoot, {isSink: false});
      compare(state.sinkVolume, 0); verify(!state.sinkMuted);
      compare(state.audioTrackedNodes.length, 0);

      nodes.values = [sink, source];
      compare(state.audioOutputDevices.length, 1); compare(state.audioOutputDevices[0], sink);
      compare(state.audioInputDevices.length, 1); compare(state.audioInputDevices[0], source);
      backend.defaultAudioSink = sink; backend.defaultAudioSource = source;
      compare(state.sinkVolume, 0.5); verify(!state.sinkMuted);
      compare(state.audioTrackedNodes.length, 4);
      compare(state.audioTrackedNodes[0], sink); compare(state.audioTrackedNodes[1], source);
      compare(state.audioTrackedNodes[2], sink); compare(state.audioTrackedNodes[3], source);

      sink.audio.volume = 0.8; sink.audio.muted = true;
      compare(state.sinkVolume, 0.8); verify(state.sinkMuted);
      sink.isStream = true;
      compare(state.audioOutputDevices.length, 0); compare(state.audioTrackedNodes.length, 3);
      source.isSink = true;
      compare(state.audioInputDevices.length, 0); compare(state.audioOutputDevices[0], source);
      nodes.values = [];
      compare(state.audioOutputDevices.length, 0); compare(state.audioInputDevices.length, 0);
      compare(state.audioTrackedNodes.length, 2);
      compare(state.audioTrackedNodes[0], sink); compare(state.audioTrackedNodes[1], source);
      backend.defaultAudioSink = source; backend.defaultAudioSource = null;
      compare(state.sinkVolume, 0.5); verify(!state.sinkMuted);
      compare(state.audioTrackedNodes.length, 1); compare(state.audioTrackedNodes[0], source);
      nodes.values = [source];
      compare(state.audioOutputDevices.length, 1);
      source.audio = null;
      compare(state.audioOutputDevices.length, 0);
      compare(state.audioTrackedNodes.length, 1); compare(state.audioTrackedNodes[0], source);
      compare(state.sinkVolume, 0); verify(!state.sinkMuted);
      backend.defaultAudioSink = null;
      compare(state.audioTrackedNodes.length, 0);
    }
    function test_pointerThenKeyboardOnSameFocus() {
      const palette = createTemporaryObject(paletteFactory, testRoot);
      const view = createTemporaryObject(focusScrollFactory, testRoot, {wallust: palette});
      const first = findChild(view, "firstToggle"), next = findChild(view, "nextToggle");
      view.contentY = first.y + first.height / 2;
      const before = view.contentY;
      mouseClick(first, 20, first.height - 5);
      verify(first.activeFocus);
      compare(first.focusReason, Qt.MouseFocusReason);
      compare(view.contentY, before);
      verify(first.checked);
      keyClick(Qt.Key_Space);
      verify(first.activeFocus);
      verify(!first.checked, "Space must activate the pointer-focused switch");
      compare(view.contentY, before);
      keyClick(Qt.Key_Tab);
      verify(next.activeFocus, "Tab must move to the next control");
      compare(next.focusReason, Qt.TabFocusReason);
      first.forceActiveFocus(Qt.OtherFocusReason);
      verify(first.activeFocus);
      compare(first.focusReason, Qt.OtherFocusReason);
      view.destroy();
      wait(0);
    }
    function test_quickNetworkAction() {
      const palette = createTemporaryObject(paletteFactory, testRoot);
      const bar = createTemporaryObject(quickBarFactory, testRoot);
      const radios = createTemporaryObject(radiosFactory, testRoot);
      const page = createTemporaryObject(quickFactory, testRoot, {bar: bar, wallust: palette, radios: radios});
      const button = findChild(page, "quickNetwork");
      verify(button && !button.enabled);
      verify(!findChild(page, "quickNetworkSettings"));
      const settings = findChild(page, "wifiSettings");
      verify(settings && settings.enabled);
      settings.triggered();
      compare(bar.launches, 1);
      bar.desktopState.busy = true;
      verify(!settings.enabled);
      page.destroy();
      wait(0);
    }
    function test_sharedRadioRequests() {
      const wifi = createTemporaryObject(delayedWifiFactory, testRoot);
      const adapter = createTemporaryObject(delayedBluetoothFactory, testRoot);
      const radios = createTemporaryObject(radioFactory, testRoot, {wifi: wifi, adapter: adapter});
      const palette = createTemporaryObject(paletteFactory, testRoot);
      const bar = createTemporaryObject(quickBarFactory, testRoot);
      bar.bluetoothAdapter = adapter;
      const first = createTemporaryObject(quickFactory, testRoot, {bar: bar, wallust: palette, radios: radios});
      const second = createTemporaryObject(quickFactory, testRoot, {bar: bar, wallust: palette, radios: radios});
      const firstWifi = findChild(first, "quickNetwork"), secondWifi = findChild(second, "quickNetwork");
      const firstBt = findChild(first, "quickBluetooth"), secondBt = findChild(second, "quickBluetooth");
      firstWifi.clicked(); firstBt.clicked();
      verify(radios.wifiPending && radios.bluetoothPending);
      verify(!firstWifi.enabled && !secondWifi.enabled && !firstBt.enabled && !secondBt.enabled);
      radios.toggleWifi(); radios.toggleBluetooth();
      verify(radios.wifiTarget && radios.bluetoothTarget);
      first.destroy();
      tryCompare(radios, "wifiError", "Wi-Fi change not confirmed", 1000);
      tryCompare(radios, "bluetoothError", "Bluetooth change not confirmed", 1000);
      verify(radios.wifiPending && radios.bluetoothPending);
      verify(!secondWifi.enabled && !secondBt.enabled);
      radios.toggleWifi(); radios.toggleBluetooth();
      verify(radios.wifiTarget && radios.bluetoothTarget);
      compare(secondWifi.subtitle, "Wi-Fi change not confirmed");
      compare(secondBt.subtitle, "Bluetooth change not confirmed");
      wifi.wifiHardwareEnabled = false; adapter.state = 2;
      compare(secondWifi.subtitle, "Hardware blocked"); compare(secondBt.subtitle, "Hardware blocked");
      wifi.wifiHardwareEnabled = true; adapter.state = 0;
      compare(secondWifi.subtitle, "Wi-Fi change not confirmed");
      compare(secondBt.subtitle, "Bluetooth change not confirmed");
      wifi.reject = false; adapter.reject = false;
      wifi.wifiEnabled = true; adapter.enabled = true;
      compare(radios.wifiError, ""); compare(radios.bluetoothError, "");
      verify(!radios.wifiPending && !radios.bluetoothPending);
      verify(secondWifi.enabled && secondBt.enabled);
      compare(secondWifi.subtitle, "On");
      bar.wifiStatus = "Stale network";
      compare(secondWifi.subtitle, "On");
      radios.adapter = null;
      compare(radios.bluetoothError, "");
      second.destroy();
      wait(0);
    }
    function test_radioBackendReplacement() {
      const wifi = createTemporaryObject(delayedWifiFactory, testRoot);
      const oldAdapter = createTemporaryObject(delayedBluetoothFactory, testRoot);
      const newAdapter = createTemporaryObject(delayedBluetoothFactory, testRoot);
      const radios = createTemporaryObject(radioFactory, testRoot, {wifi: wifi, adapter: oldAdapter});
      const palette = createTemporaryObject(paletteFactory, testRoot);
      const bar = createTemporaryObject(quickBarFactory, testRoot, {bluetoothAdapter: oldAdapter});
      const page = createTemporaryObject(quickFactory, testRoot, {bar: bar, wallust: palette, radios: radios});
      const wifiButton = findChild(page, "quickNetwork"), btButton = findChild(page, "quickBluetooth");
      radios.toggleWifi(); radios.toggleBluetooth();
      verify(radios.wifiPending && radios.bluetoothPending);
      radios.adapter = newAdapter; bar.bluetoothAdapter = newAdapter;
      verify(!radios.bluetoothPending && btButton.enabled);
      radios.toggleBluetooth();
      verify(radios.bluetoothPending);
      oldAdapter.reject = false; oldAdapter.enabled = true;
      verify(radios.bluetoothPending, "old adapter must not confirm the new request");
      wifi.backend = 0;
      verify(!radios.wifiPending);
      compare(wifiButton.subtitle, "NetworkManager unavailable");
      tryCompare(radios, "bluetoothError", "Bluetooth change not confirmed", 1000);
      radios.adapter = null; bar.bluetoothAdapter = null;
      compare(btButton.subtitle, "Adapter unavailable");
      verify(!radios.bluetoothPending && !radios.bluetoothError);
      wifi.backend = 1;
      verify(wifiButton.enabled);
      page.destroy();
      wait(0);
    }
    function test_networkState() {
      const network = createTemporaryObject(networkFactory, testRoot);
      verify(network !== null);
      compare(network.status, "disconnected");
      network.update(null);
      compare(network.tooltip, "Disconnected");
      network.update("wifi:connected");
      compare(network.status, "malformed");
      compare(network.tooltip, "Disconnected");
      network.update("broken\nwifi:disconnected:--");
      compare(network.status, "disconnected");
      network.update("vpn:connected:name");
      compare(network.status, "disconnected");
      network.update("wifi: connected:name");
      compare(network.status, "disconnected");
      network.update("ethernet:connected:wired\nwifi:connected:my:network");
      compare(network.status, "connected");
      compare(network.icon, "");
      compare(network.tooltip, "my:network");
      network.update("ethernet:connected:");
      compare(network.icon, "");
      compare(network.tooltip, "Ethernet connected");
      compare(network.wifiTooltip, "Disconnected");
      network.update("wifi:connected:");
      compare(network.tooltip, "Wi-Fi connected");
      network.unavailable();
      compare(network.status, "unavailable");
      compare(network.tooltip, "Network unavailable");
      network.update("");
      compare(network.status, "disconnected");
    }
    name: "ShellMaterial"
    when: windowShown
    property var paletteFactory

    function initTestCase() {
      // The checked-in fallback is valid QML; no wallpaper generation is needed.
      paletteFactory = Qt.createComponent(Qt.resolvedUrl("../dot_config/quickshell/default/wallust/Colors.qml.tmpl"));
      compare(paletteFactory.status, Component.Ready, paletteFactory.errorString());
    }
    function fixture(light, alpha) {
      const palette = createTemporaryObject(paletteFactory, testRoot, {
        lightMode: light, controlCenter: true, controlOpacity: alpha, glassOpacity: 0.25
      });
      verify(palette !== null);
      const surface = createTemporaryObject(surfaceFactory, testRoot, { wallust: palette });
      verify(surface !== null);
      const button = createTemporaryObject(buttonFactory, surface, { wallust: palette });
      verify(button !== null);
      mouseMove(testRoot, 750, 550);
      return { palette: palette, surface: surface, button: button };
    }
    function findText(item, text) {
      if (item.text === text && item.font !== undefined) return item;
      for (const child of item.children) {
        const found = findText(child, text);
        if (found) return found;
      }
      return null;
    }
    function test_presentationBoundaries() {
      compare(Presentation.volumeIcon(0, true), "󰝟");
      for (const row of [[0.33, "󰕿"], [0.3301, "󰖀"], [0.66, "󰖀"], [0.6601, "󰕾"]])
        compare(Presentation.volumeIcon(row[0], false), row[1]);
      for (const row of [[19, "󰁻"], [20, "󰁼"], [39, "󰁼"], [40, "󰁾"], [59, "󰁾"], [60, "󰂀"], [79, "󰂀"], [80, "󰂂"], [94, "󰂂"], [95, "󰁹"]])
        compare(Presentation.batteryIcon(row[0], 0, 1, 2), row[1]);
      compare(Presentation.batteryIcon(0, 1, 1, 2), "󰂄");
      compare(Presentation.batteryIcon(100, 2, 1, 2), "󰂄");
      const palette = {barText: "text", barCritical: "critical", color3: "warning", barBorder: "border"};
      compare(Presentation.batteryTextColor(false, null, 0, 3, 4, palette), "text");
      compare(Presentation.batteryTextColor(true, 3, 20, 3, 4, palette), "critical");
      compare(Presentation.batteryTextColor(true, 4, 21, 3, 4, palette), "warning");
      compare(Presentation.batteryTextColor(true, 0, 20, 3, 4, palette), "warning");
      compare(Presentation.batteryTextColor(true, 0, 30, 3, 4, palette), "warning");
      compare(Presentation.batteryTextColor(true, 0, 31, 3, 4, palette), "text");
      compare(Presentation.normalizeBatteryPercent(null), 0);
      compare(Presentation.normalizeBatteryPercent({}), 0);
      compare(Presentation.normalizeBatteryPercent({percentage: 0.5}), 50);
      compare(Presentation.normalizeBatteryPercent({percentage: 1}), 100);
      compare(Presentation.normalizeBatteryPercent({percentage: 1.1}), 1);
      compare(Presentation.normalizeBatteryPercent({percentage: 200}), 100);
      compare(Presentation.normalizeBatteryPercent({percentage: -0.5}), 0);
      compare(Presentation.normalizeBatteryPercent({percentage: 0.5, energy: 2, energyCapacity: 4}), 50);
      compare(Presentation.normalizeBatteryPercent({percentage: 0.5, energy: 3, energyCapacity: 4}), 75);
      compare(Presentation.normalizeBatteryPercent({percentage: 0.5, energy: 3, energyCapacity: 0}), 50);
      compare(Presentation.shorten(null, 4), "");
      compare(Presentation.shorten("abcd", 4), "abcd");
      compare(Presentation.shorten("abcde", 4), "a...");
      compare(Presentation.workspaceText({id: 10}, {"10": "0"}), "0");
      compare(Presentation.workspaceText({id: 2, name: "special"}, {}), "special");
      compare(Presentation.spotifyTextForPlayer(null, 0, 1), "");
      compare(Presentation.spotifyTextForPlayer({playbackState: 0}, 0, 1), "");
      compare(Presentation.spotifyTextForPlayer({playbackState: 1}, 0, 1), "");
      compare(Presentation.spotifyTextForPlayer({playbackState: 2}, 0, 1), "Spotify  ");
      compare(Presentation.spotifyTextForPlayer({playbackState: 2, trackArtist: "A", trackTitle: "T"}, 0, 1), "A - T  ");
      compare(Presentation.notificationAccent(null, 2, palette), "border");
      compare(Presentation.notificationAccent({urgency: 2}, 2, palette), "critical");
      compare(Presentation.notificationToastDuration(null, 2, 0), 5500);
      compare(Presentation.notificationToastDuration({urgency: 0}, 2, 0), 3500);
      compare(Presentation.notificationToastDuration({urgency: 2}, 2, 0), 9000);
      const resolve = function(icon) { return "resolved:" + icon; };
      compare(Presentation.notificationIcon(null, resolve), "");
      compare(Presentation.notificationIcon({appIcon: ""}, resolve), "");
      compare(Presentation.notificationIcon({appIcon: "/tmp/icon"}, resolve), "/tmp/icon");
      compare(Presentation.notificationIcon({appIcon: "file:icon"}, resolve), "file:icon");
      compare(Presentation.notificationIcon({appIcon: "app"}, resolve), "resolved:app");
    }
    function test_actionButton_data() {
      return [{tag: "dark", light: false}, {tag: "light", light: true}];
    }
    function test_actionButton(data) {
      const palette = createTemporaryObject(paletteFactory, testRoot, {
        lightMode: data.light, controlCenter: true, controlOpacity: 0.37, lowEffects: true
      });
      const button = createTemporaryObject(actionButtonFactory, testRoot, {wallust: palette});
      verify(button !== null);
      mouseMove(testRoot, 750, 550);
      compare(button.background.color, palette.barCard);
      compare(button.background.border.width, 1);
      mouseMove(button, button.width / 2, button.height / 2);
      tryCompare(button, "hovered", true);
      compare(button.background.color, palette.barButtonHover);
      button.forceActiveFocus();
      compare(button.background.border.width, 2);
      compare(button.background.border.color, palette.barAccentText);
      actionClicks.target = button;
      actionClicks.clear();
      keyClick(Qt.Key_Space);
      keyClick(Qt.Key_Return);
      keyClick(Qt.Key_Enter);
      compare(actionClicks.count, 3);
      mouseClick(button, button.width / 2, button.height / 2);
      compare(actionClicks.count, 4);
      button.checkable = true;
      mouseClick(button, button.width / 2, button.height / 2);
      compare(button.checked, true);
      compare(button.highlightedState, true);
      compare(button.background.color, palette.barActive);
      mouseClick(button, button.width / 2, button.height / 2);
      compare(button.checked, false);
      compare(button.highlightedState, false);
      compare(actionClicks.count, 6);
      compare(button.Accessible.name, "Action");
      button.Accessible.name = "Custom action";
      compare(button.Accessible.name, "Custom action");
      button.highlightedState = true;
      compare(button.background.color, palette.barActive);
      compare(findText(button.contentItem, "Action").color.toString(), palette.barAccentText.toString());
      button.highlightedState = false;
      button.flat = true;
      button.focus = false;
      mouseMove(testRoot, 750, 550);
      tryCompare(button, "hovered", false);
      compare(button.background.color.a, 0);
      compare(button.background.border.width, 0);
      button.symbol = "★";
      button.subtitle = "Details";
      const glyph = findText(button, "★");
      const subtitle = findText(button, "Details");
      verify(glyph.visible && subtitle.visible);
      compare(glyph.font.pixelSize, Style.Typography.controlTileIconSize);
      compare(subtitle.font.pixelSize, Style.Typography.controlHintSize);
      verify(button.implicitHeight >= 68);
      button.font = Style.Typography.notificationActionFont;
      compare(findText(button.contentItem, "Action").font.pixelSize, Style.Typography.notificationActionSize);
      button.enabled = false;
      compare(glyph.opacity, 0.55);
      compare(findText(button.contentItem, "Action").parent.opacity, 0.55);
      compare(button.background.opacity, 1);
      palette.controlCenter = false;
      compare(button.background.opacity, 0.55);
      // Retain a separate enabled focus target so disabled-key checks cannot pass
      // merely because no item had focus.
      const focusTarget = createTemporaryObject(actionButtonFactory, testRoot, {wallust: palette, y: 100});
      focusTarget.forceActiveFocus();
      verify(focusTarget.activeFocus);
      button.enabled = true;
      button.forceActiveFocus();
      verify(button.activeFocus);
      button.enabled = false;
      focusTarget.forceActiveFocus();
      verify(focusTarget.activeFocus);
      keyClick(Qt.Key_Return);
      keyClick(Qt.Key_Space);
      mouseClick(button, button.width / 2, button.height / 2);
      compare(actionClicks.count, 6);
      const custom = createTemporaryObject(customContentFactory, button);
      button.contentItem = custom;
      compare(button.contentItem, custom);
      verify(button.implicitHeight >= custom.implicitHeight + button.topPadding + button.bottomPadding);
      actionClicks.target = null;
    }
    function test_tokens() {
      const tokens = Style.Tokens;
      const names = [
        "panelRadius", "barIndicatorRadius", "deviceCardRadius", "deviceCardInset",
        "controlPageSpacing", "barItemSpacing", "barPillHeight", "barIndicatorHeight",
        "notificationAppIconSize", "notificationActionMinHeight", "surfaceColorDuration",
        "barStateColorDuration"
      ];
      for (const name of names)
        verify(typeof tokens[name] === "number" && Number.isFinite(tokens[name]) && tokens[name] > 0, name);
      const palette = createTemporaryObject(paletteFactory, testRoot);
      const clock = createTemporaryObject(clockFactory, testRoot, {
        bar: createTemporaryObject(statusBarFactory, testRoot), wallust: palette,
        clock: {date: new Date(2026, 0, 1, 12, 0)}
      });
      verify(clock !== null);
      compare(clock.implicitHeight, tokens.barPillHeight);
    }
    function test_wheelScrollsInsteadOfChangingSlider() {
      const palette = createTemporaryObject(paletteFactory, testRoot);
      const view = createTemporaryObject(scrollFactory, testRoot, {wallust: palette});
      const slider = findChild(view, "scrollTestSlider");
      verify(slider !== null);
      compare(slider.wheelEnabled, false);
      try {
        for (const focused of [false, true]) {
          view.cancelFlick();
          view.contentY = 0;
          if (focused) { slider.forceActiveFocus(); verify(slider.activeFocus); }
          mouseWheel(slider, slider.width / 2, slider.height / 2, 0, -120, Qt.NoButton);
          tryVerify(() => view.contentY > 0, 1000, "Wheel must scroll the parent over the slider");
          compare(slider.value, 50, "Wheel must not change the value, focused or not");
        }
        view.cancelFlick();
        view.contentY = 0;
        slider.forceActiveFocus();
        keyClick(Qt.Key_Right);
        compare(slider.value, 51, "Arrow-key adjustment must still work");
        mouseDrag(slider, slider.width * 0.51, slider.height / 2, slider.width * 0.2, 0);
        verify(slider.value > 60, "Dragging must still adjust the slider");
      } finally {
        // Destroy the consumer before QtTest deletes its temporary palette.
        view.destroy();
        wait(0);
      }
    }
    function test_flatButtonsKeepSelectionAndFocus() {
      for (const light of [false, true]) {
        const f = fixture(light, 0.37);
        f.button.flat = true;
        tryVerify(() => f.button.background.color.a < 0.002);
        compare(f.button.background.border.width, 0);
        mouseMove(f.button, f.button.width / 2, f.button.height / 2);
        tryCompare(f.button, "hovered", true);
        tryVerify(() => Math.abs(f.button.background.color.a - f.palette.barButtonHover.a) < 0.002);
        f.button.highlightedState = true;
        mouseMove(testRoot, 750, 550);
        tryCompare(f.button, "hovered", false);
        tryVerify(() => Math.abs(f.button.background.color.a - f.palette.barActive.a) < 0.002);
        f.button.forceActiveFocus();
        compare(f.button.background.border.width, 2, "Flat controls retain keyboard-focus outlines");
        f.button.focus = false;
        f.button.flat = false;
        compare(f.button.background.border.width, 1, "Ordinary buttons retain their borders");
      }
    }
    function test_controlIconsUseTheirOwnRole() {
      const f = fixture(false, 0.5);
      const t = Style.Typography;
      const saved = t.controlTileIconSize;
      const defaultHeight = f.button.contentItem.implicitHeight;
      try {
        f.button.symbol = "󰒓";
        compare(findText(f.button, "󰒓").font.family, t.iconFamily);
        t.controlTileIconSize = 32;
        compare(findText(f.button, "󰒓").font.pixelSize, 32);
        compare(f.button.font.pixelSize, t.controlLabelSize);
        compare(t.barIconFont.pixelSize, t.barIconSize);
        tryVerify(() => f.button.height >= findText(f.button, "󰒓").implicitHeight + 16);
        f.button.symbol = "";
        compare(f.button.contentItem.implicitHeight, defaultHeight);
      } finally {
        t.controlTileIconSize = saved;
      }
    }
    function test_typographyChangesAreScoped() {
      const t = Style.Typography;
      const saved = {
        textFamily: t.textFamily, barSize: t.barSize, normalWeight: t.normalWeight,
        iconWeight: t.iconWeight, controlLabelSize: t.controlLabelSize,
        notificationBodySize: t.notificationBodySize, notificationActionSize: t.notificationActionSize
      };
      const palette = createTemporaryObject(paletteFactory, testRoot);
      const bar = createTemporaryObject(statusBarFactory, testRoot);
      const button = createTemporaryObject(buttonFactory, testRoot, {wallust: palette});
      const indicators = createTemporaryObject(indicatorsFactory, testRoot, {
        bar: bar, wallust: palette, networkState: {icon: "󰤨"}
      });
      const body = createTemporaryObject(notificationBodyFactory, testRoot);
      const action = createTemporaryObject(notificationActionFactory, testRoot, {wallust: palette});
      verify(body !== null);
      verify(action !== null);
      try {
        t.barSize = 16;
        compare(findText(indicators, "38%").font.pixelSize, 16);
        compare(t.barClockFont.pixelSize, 16);
        compare(t.barWorkspaceFont.pixelSize, 16);
        compare(t.barActiveWorkspaceFont.pixelSize, 16);
        compare(body.font.pixelSize, saved.notificationBodySize);

        t.controlLabelSize = 24;
        compare(button.font.pixelSize, 24);
        compare(action.font.pixelSize, saved.notificationActionSize);
        tryVerify(() => button.height >= button.contentItem.implicitHeight + button.topPadding + button.bottomPadding);

        t.notificationBodySize = 19;
        compare(body.font.pixelSize, 19);
        compare(button.font.pixelSize, 24);
        t.notificationActionSize = 22;
        compare(action.font.pixelSize, 22);
        compare(t.centerButtonFont.pixelSize, t.centerButtonSize);
        tryVerify(() => action.height >= action.contentItem.implicitHeight + 8);

        t.normalWeight = Font.Medium;
        compare(findText(indicators, "38%").font.weight, t.barWeight);
        compare(body.font.weight, t.notificationBodyWeight);
        compare(t.barClockFont.weight, t.barClockWeight);
        compare(t.barActiveWorkspaceFont.weight, t.barActiveWorkspaceWeight);
        t.iconWeight = Font.Bold;
        compare(findText(indicators, "󰕾").font.weight, t.barIconWeight);

        t.textFamily = "Noto Serif";
        compare(body.font.family, t.notificationFamily);
        compare(button.font.family, t.controlFamily);
        compare(findText(indicators, "38%").font.family, t.barFamily);
        compare(findText(indicators, "󰕾").font.family, t.iconFamily);
      } finally {
        for (const name of Object.keys(saved)) t[name] = saved[name];
      }
    }
    function test_clockAndMediaTypography() {
      const palette = createTemporaryObject(paletteFactory, testRoot);
      const bar = createTemporaryObject(statusBarFactory, testRoot);
      const clock = createTemporaryObject(clockFactory, testRoot, {
        bar: bar, wallust: palette, clock: {date: new Date(2026, 0, 1, 12, 0)}
      });
      const media = createTemporaryObject(mediaFactory, testRoot, {bar: bar, wallust: palette});
      for (const pill of [clock, media]) {
        verify(pill !== null);
        const label = pill.children.find(item => item.font !== undefined);
        verify(label !== undefined);
        compare(label.font.family, Style.Typography.barFamily);
        compare(label.font.pixelSize, Style.Typography.barSize);
      }
    }
    function test_statusLowEffects() {
      const palette = createTemporaryObject(paletteFactory, testRoot, {lowEffects: false});
      const bar = createTemporaryObject(statusBarFactory, testRoot);
      const indicators = createTemporaryObject(indicatorsFactory, testRoot, {bar: bar, wallust: palette, networkState: {icon: "N"}});
      const targets = [indicators.children[0], indicators.children[1], indicators.children[2], indicators.children[3], indicators.children[5]];
      for (const item of targets) {
        mouseMove(testRoot, 750, 550);
        tryCompare(item, "color", Qt.color("transparent"));
        mouseMove(item, item.width / 2, item.height / 2);
        const target = item === targets[4] ? palette.barCritical : palette.barHover;
        tryVerify(() => item.color.toString() !== Qt.color("transparent").toString() && item.color.toString() !== target.toString(), 1000, "hover must be in flight");
        palette.lowEffects = true;
        compare(item.color, target, "disabling effects must finish hover immediately");
        wait(160);
        compare(item.color, target, "no stale hover update");
        mouseMove(testRoot, 750, 550);
        compare(item.color, Qt.color("transparent"));
        palette.lowEffects = false;
        mouseMove(item, item.width / 2, item.height / 2);
        tryCompare(item, "color", target);
        mouseMove(testRoot, 750, 550);
        tryCompare(item, "color", Qt.color("transparent"));
      }
    }
    function test_statusActions() {
      const palette = createTemporaryObject(paletteFactory, testRoot);
      const bar = createTemporaryObject(statusBarFactory, testRoot);
      const indicators = createTemporaryObject(indicatorsFactory, testRoot, {bar: bar, wallust: palette, networkState: {icon: "N"}});
      wait(0);
      const audio = indicators.children[0], bluetooth = indicators.children[1], network = indicators.children[2];
      mouseClick(audio, audio.width / 2, audio.height / 2, Qt.LeftButton);
      compare(bar.requestedCategory, "audio"); verify(bar.controlPanelOpen);
      mouseClick(bluetooth, bluetooth.width / 2, bluetooth.height / 2, Qt.LeftButton);
      compare(bar.requestedCategory, "quick");
      bar.requestedCategory = "audio";
      mouseClick(network, network.width / 2, network.height / 2, Qt.LeftButton);
      compare(bar.requestedCategory, "quick"); compare(bar.command, "");
      mouseClick(audio, audio.width / 2, audio.height / 2, Qt.RightButton);
      verify(bar.defaultAudioSink.audio.muted);
      mouseWheel(audio, audio.width / 2, audio.height / 2, 0, 120, Qt.NoButton);
      fuzzyCompare(bar.defaultAudioSink.audio.volume, 0.41, 0.001);
      mouseClick(bluetooth, bluetooth.width / 2, bluetooth.height / 2, Qt.RightButton);
      compare(bar.command, "blueman-manager");
      bar.desktopState.values = ({bluetoothSettings: false}); bar.controlPanelOpen = false;
      mouseClick(bluetooth, bluetooth.width / 2, bluetooth.height / 2, Qt.RightButton);
      verify(bar.controlPanelOpen); compare(bar.desktopState.error, "Bluetooth settings require blueman-manager");
      bar.defaultAudioSink = null; bar.controlPanelOpen = false;
      mouseClick(audio, audio.width / 2, audio.height / 2, Qt.LeftButton);
      verify(bar.controlPanelOpen); compare(bar.requestedCategory, "audio");
      mouseClick(audio, audio.width / 2, audio.height / 2, Qt.RightButton);
      mouseWheel(audio, audio.width / 2, audio.height / 2, 0, 120, Qt.NoButton);
    }
    function test_statusTypography() {
      const palette = createTemporaryObject(paletteFactory, testRoot);
      const bar = createTemporaryObject(statusBarFactory, testRoot);
      const indicators = createTemporaryObject(indicatorsFactory, testRoot, {
        bar: bar, wallust: palette, networkState: {icon: "󰤨"}
      });
      verify(indicators !== null);
      wait(0);
      for (const value of ["38%", "2", "67%"]) {
        const label = findText(indicators, value);
        verify(label !== null, value);
        compare(label.font.family, Style.Typography.barFamily);
        compare(label.font.pixelSize, Style.Typography.barSize);
        const position = label.mapToItem(label.parent.parent, 0, 0);
        // The row and its text can each snap half a pixel when centered.
        fuzzyCompare(position.y + label.height / 2, 12, 1);
      }
      for (const value of ["", "󰤨", "󰁹", "󰐥"]) {
        const icon = findText(indicators, value);
        compare(icon.font.family, Style.Typography.iconFamily);
        compare(icon.font.pixelSize, Style.Typography.barIconSize);
      }
      const audioIcon = findText(indicators, "󰕾");
      compare(audioIcon.font.pixelSize, Style.Typography.barAudioIconSize);
      compare(audioIcon.font.family, Style.Typography.iconFamily);
      const originalAudioWidth = audioIcon.parent.implicitWidth;
      for (const glyph of ["󰝟", "󰕿", "󰖀", "󰕾"]) {
        bar.audioGlyph = glyph;
        compare(audioIcon.width, Style.Typography.barAudioIconSize);
        compare(audioIcon.parent.implicitWidth, originalAudioWidth, "Volume state must not change icon spacing");
        compare(findText(indicators, "38%").font.pixelSize, Style.Typography.barSize);
      }
      const savedAudioSize = Style.Typography.barAudioIconSize;
      try {
        Style.Typography.barAudioIconSize = 22;
        compare(audioIcon.font.pixelSize, 22);
        compare(audioIcon.width, 22);
        compare(findText(indicators, "").font.pixelSize, Style.Typography.barIconSize);
        compare(findText(indicators, "38%").font.pixelSize, Style.Typography.barSize);
      } finally {
        Style.Typography.barAudioIconSize = savedAudioSize;
      }
      compare(findText(indicators, "67%").color, bar.batteryTextColor);
      compare(findText(indicators, "󰁹").color, bar.batteryTextColor);

      bar.defaultAudioSink = null;
      tryVerify(() => findText(indicators, "--") !== null);
      compare(findText(indicators, "--").font.family, Style.Typography.barFamily);
      compare(findText(indicators, "󰝟").font.family, Style.Typography.iconFamily);
      bar.bluetoothLabel = "";
      const bluetooth = findText(indicators, "");
      tryVerify(() => Math.abs(bluetooth.parent.implicitWidth - bluetooth.width) < 0.01,
                1000, "An empty Bluetooth label must not leave a gap");
      bar.hasBattery = false;
      tryCompare(findText(indicators, "67%"), "visible", false);
    }

    function test_stateVisibility_data() {
      const cases = [];
      for (const light of [false, true])
        for (const alpha of [0, 0.37, 1])
          cases.push({tag: (light ? "light-" : "dark-") + alpha, light: light, alpha: alpha});
      return cases;
    }
    function test_stateVisibility(data) {
      const f = fixture(data.light, data.alpha);
      const label = findText(f.button.contentItem, "Control");
      const normalLabel = label.color.toString();
      const normalFill = f.button.background.color.toString();
      f.button.forceActiveFocus();
      verify(f.button.activeFocus);
      compare(f.button.background.border.width, 2);
      compare(f.button.background.border.color, f.palette.barAccentText);
      mouseMove(f.button, f.button.width / 2, f.button.height / 2);
      tryCompare(f.button, "hovered", true);
      tryCompare(f.button.background, "color", f.palette.barButtonHover);
      if (data.alpha === 0)
        fuzzyCompare(f.button.background.color.a, 0, 0.002);
      else
        verify(f.button.background.color.toString() !== normalFill, "Hover fill must differ from normal");
      f.button.highlightedState = true;
      compare(label.color.toString(), f.palette.barAccentText.toString());
      verify(label.color.toString() !== normalLabel, "Selected label must differ from normal");
      compare(f.button.background.border.width, 2);
      compare(f.button.background.border.color, f.palette.barAccentText);
    }
    function test_controlOpacity_data() {
      const cases = [];
      for (const light of [false, true]) {
        for (const alpha of [0, 0.37, 1])
          cases.push({ tag: (light ? "light" : "dark") + "-" + alpha, light: light, alpha: alpha });
      }
      return cases;
    }
    function test_controlOpacity(data) {
      const f = fixture(data.light, data.alpha);
      fuzzyCompare(f.palette.barCard.a, data.alpha, 0.002);
      fuzzyCompare(f.button.background.color.a, data.alpha, 0.002);
      fuzzyCompare(f.palette.barButtonHover.a, data.alpha, 0.002);
      mouseMove(f.button, f.button.width / 2, f.button.height / 2);
      tryCompare(f.button, "hovered", true);
      fuzzyCompare(f.button.background.color.a, data.alpha, 0.002);
      f.button.highlightedState = true;
      fuzzyCompare(f.palette.barActive.a, data.alpha, 0.002);
      fuzzyCompare(f.button.background.color.a, data.alpha, 0.002);
      f.button.enabled = false;
      compare(f.button.background.opacity, 1, "Disabled controls must not double-dim their fill");
      fuzzyCompare(f.button.background.color.a, data.alpha, 0.002);
      compare(f.button.opacity, 1, "Text/icons must not inherit the fill opacity");
      compare(f.button.contentItem.children[0].opacity, 0.55, "Disabled state dims labels only");

      // The glass channel is independent, including when its background is solid.
      f.palette.glassOpacity = 0.75;
      fuzzyCompare(f.surface.gradient.stops[0].color.a, 0.75, 0.002);
      fuzzyCompare(f.button.background.color.a, data.alpha, 0.002);
      f.palette.solidSurfaces = true;
      compare(f.surface.gradient.stops[0].color.a, 1);
      fuzzyCompare(f.palette.barCard.a, data.alpha, 0.002);
    }
    function test_surfaceHasNoExteriorAlpha_data() {
      const cases = [];
      for (const light of [false, true])
        for (const radius of [12, 18, 26])
          cases.push({tag: (light ? "light-" : "dark-") + radius, light: light, radius: radius});
      return cases;
    }
    function test_surfaceHasNoExteriorAlpha(data) {
      const palette = createTemporaryObject(paletteFactory, testRoot, {lightMode: data.light});
      // Capture an unclipped, transparent margin so effects cannot hide outside the grab.
      const canvas = createTemporaryObject(surfaceCanvasFactory, testRoot);
      const surface = createTemporaryObject(surfaceFactory, canvas.contentItem, {
        wallust: palette, x: 24, y: 24, width: 120, height: 80, radius: data.radius
      });
      // Software omits shader effects; also protect removal of the shared path.
      verify(surface.shadowEnabled === undefined);
      verify(!surface.children.some(child => child.blur !== undefined), "Shared glass must stay shadowless");
      for (const hovered of [false, true]) {
        surface.hovered = hovered;
        wait(Style.Tokens.surfaceColorDuration + 50);
        const image = grabImage(canvas.contentItem);
        verify(image.alpha(84, 64) > 0, "The glass fill must render");
        compare(image.alpha(24, 24), 0, "Rounded corner must stay transparent");
        for (let y = 0; y < image.height; y++)
          for (let x = 0; x < image.width; x++)
            if (x < surface.x || x >= surface.x + surface.width
                || y < surface.y || y >= surface.y + surface.height)
              compare(image.alpha(x, y), 0, "Exterior alpha at " + x + "," + y);
      }
    }
    function test_surfaceShadow_data() {
      return [{tag: "dark", light: false}, {tag: "light", light: true}];
    }
    function test_surfaceShadow(data) {
      const palette = createTemporaryObject(paletteFactory, testRoot, {lightMode: data.light});
      const shadow = createTemporaryObject(shadowFactory, testRoot, {wallust: palette});
      verify(shadow.visible);
      compare(shadow.children.filter(child => child.maskEnabled !== undefined).length, 1,
        "All rectangles must share one effect pipeline");
      palette.lowEffects = true;
      compare(shadow.visible, false);
      palette.lowEffects = false;
      palette.glassOpacity = 0;
      compare(shadow.visible, false);
      palette.solidSurfaces = true;
      compare(shadow.visible, true, "Opaque shell glass still casts a shadow");
      palette.solidSurfaces = false;
      palette.glassOpacity = 0.4;
      compare(shadow.visible, true);
    }
    function test_surfaceShadowAlpha_data() { return test_surfaceShadow_data(); }
    function test_surfaceShadowAlpha(data) {
      if (testRoot.GraphicsInfo.api === GraphicsInfo.Software)
        skip("Shader alpha requires a graphics backend; use an isolated Xvfb/OpenGL run");
      const palette = createTemporaryObject(paletteFactory, testRoot, {lightMode: data.light});
      const canvas = createTemporaryObject(surfaceCanvasFactory, testRoot);
      const shadow = createTemporaryObject(shadowFactory, canvas.contentItem, {wallust: palette});
      wait(100);
      let image = grabImage(canvas.contentItem);
      const edges = [[84, 23], [23, 64], [144, 64], [84, 104]];
      console.info("Hollow shadow " + data.tag + " top/left/right/bottom alpha: "
        + edges.map(p => image.alpha(p[0], p[1])));
      for (const edge of edges)
        verify(image.alpha(edge[0], edge[1]) >= 20, "Rendered edge must exceed the faint pilot: " + edge);
      verify(image.alpha(84, 104) > image.alpha(84, 23), "Offset must strengthen the bottom edge");
      verify(image.alpha(84, 110) < image.alpha(84, 104), "Shadow must fall off outwards");
      let peak = 0;
      for (let y = 0; y < image.height; y++)
        for (let x = 0; x < image.width; x++) {
          const alpha = image.alpha(x, y);
          peak = Math.max(peak, alpha);
          if (x < 12 || x >= 156 || y < 15 || y >= 119)
            compare(alpha, 0, "Paint exceeds padded envelope at " + x + "," + y);
          // Every pixel safely inside the rounded contour must be punched out,
          // not just the center. Exclude the 1px antialiased boundary.
          const dx = Math.max(50 - (x + 0.5), 0, (x + 0.5) - 118);
          const dy = Math.max(50 - (y + 0.5), 0, (y + 0.5) - 78);
          if (x >= 25 && x < 143 && y >= 25 && y < 103 && dx * dx + dy * dy < 25 * 25)
            compare(alpha, 0, "Shadow darkens glass interior at " + x + "," + y);
        }
      verify(peak > 26, "Separate surface must not retain the old blur-alpha cap");
      for (const p of [[12,15], [155,15], [12,118], [155,118]])
        compare(image.alpha(p[0], p[1]), 0, "Envelope corners must be clear");
      // Moving/resizing the glass updates the cutout and shader together.
      shadow.panelRects = [Qt.rect(36, 30, 96, 64)];
      shadow.radius = 18;
      wait(100);
      image = grabImage(canvas.contentItem);
      compare(image.alpha(84, 64), 0);
      verify(image.alpha(84, 94) > 26);
      compare(image.alpha(23, 64), 0, "Old geometry must not leave paint behind");
      palette.lowEffects = true;
      wait(100);
      image = grabImage(canvas.contentItem);
      for (let y = 0; y < image.height; y++)
        for (let x = 0; x < image.width; x++) compare(image.alpha(x, y), 0);
    }
    function test_shadowUnion_data() { return test_surfaceShadow_data(); }
    function test_shadowUnion(data) {
      if (testRoot.GraphicsInfo.api === GraphicsInfo.Software)
        skip("Union mask requires an isolated OpenGL run");
      const palette = createTemporaryObject(paletteFactory, testRoot, {lightMode: data.light});
      const canvas = createTemporaryObject(surfaceCanvasFactory, testRoot);
      // A narrow gap makes each shadow reach well inside its neighbor.
      const rects = [Qt.rect(24, 24, 56, 72), Qt.rect(84, 24, 60, 72)];
      const shadow = createTemporaryObject(shadowFactory, canvas.contentItem, {
        wallust: palette, panelRects: rects, radius: 18
      });
      wait(100);
      let image = grabImage(canvas.contentItem);
      verify(image.alpha(82, 60) > 26, "Gap must contain combined shadow paint");
      for (const rect of rects)
        for (let y = rect.y + 1; y < rect.y + rect.height - 1; y++)
          for (let x = rect.x + 1; x < rect.x + rect.width - 1; x++) {
            const dx = Math.max(rect.x + 18 - (x + 0.5), 0, x + 0.5 - (rect.x + rect.width - 18));
            const dy = Math.max(rect.y + 18 - (y + 0.5), 0, y + 0.5 - (rect.y + rect.height - 18));
            if (dx * dx + dy * dy < 17 * 17)
              compare(image.alpha(x, y), 0, "Neighbor shadow entered union interior at " + x + "," + y);
          }
      shadow.panelRects = [rects[0]];
      wait(100);
      image = grabImage(canvas.contentItem);
      verify(image.alpha(85, 60) > 0, "Removing a pill must remove its cutout too");
      compare(image.alpha(144, 60), 0, "Removed pill must not leave stale shadow");
      shadow.panelRects = [];
      wait(100);
      image = grabImage(canvas.contentItem);
      for (let y = 0; y < image.height; y++)
        for (let x = 0; x < image.width; x++) compare(image.alpha(x, y), 0);
    }
    function test_lowEffectsOverridesBothChannels_data() {
      return [{ tag: "dark", light: false }, { tag: "light", light: true }];
    }
    function test_lowEffectsOverridesBothChannels(data) {
      const f = fixture(data.light, 0.37);
      f.palette.lowEffects = true;
      f.palette.solidSurfaces = true;
      wait(180);
      compare(f.palette.controlAlpha, 1);
      compare(f.button.background.color.a, 1);
      compare(f.surface.gradient.stops[0].color.a, 1);
      compare(f.palette.controlOpacity, 0.37, "The saved percentage must survive the override");
    }
    function test_lowEffectsAndReversal_data() {
      return [{tag: "dark", light: false}, {tag: "light", light: true}];
    }
    function test_lowEffectsAndReversal(data) {
      const f = fixture(data.light, 0.37);
      const toggle = createTemporaryObject(toggleFactory, testRoot, {wallust: f.palette});
      verify(toggle !== null);
      const knob = toggle.indicator.children[0];
      const overlay = f.surface.children.find(child => child.anchors && child.anchors.margins === 1);
      verify(overlay !== undefined);
      mouseMove(testRoot, 750, 550);

      // Start transitions, reverse them before completion, then assert their final state.
      f.surface.hovered = true;
      f.button.highlightedState = true;
      toggle.checked = true;
      tryVerify(() => overlay.color.toString() !== Qt.color("transparent").toString()
                && overlay.color.toString() !== f.palette.barHover.toString()
                && f.button.background.color.toString() !== f.palette.barCard.toString()
                && f.button.background.color.toString() !== f.palette.barActive.toString()
                && knob.x > 3 && knob.x < 19, 90, "All transitions must be in progress before reversal");
      f.surface.hovered = false;
      f.button.highlightedState = false;
      toggle.checked = false;
      tryCompare(overlay, "color", Qt.color("transparent"));
      tryCompare(f.button.background, "color", f.palette.barCard);
      tryCompare(knob, "x", 3);

      // Enabling low-effects during a transition must also reach its target.
      f.surface.hovered = true;
      f.button.highlightedState = true;
      toggle.checked = true;
      tryVerify(() => overlay.color.toString() !== Qt.color("transparent").toString()
                && overlay.color.toString() !== f.palette.barHover.toString()
                && f.button.background.color.toString() !== f.palette.barCard.toString()
                && f.button.background.color.toString() !== f.palette.barActive.toString()
                && knob.x > 3 && knob.x < 19, 90, "All transitions must be in progress before low-effects");
      f.palette.lowEffects = true;
      tryCompare(overlay, "color", f.palette.barHover, 50);
      tryCompare(f.button.background, "color", f.palette.barActive, 50);
      tryCompare(knob, "x", 19, 50);
      wait(200);
      compare(overlay.color, f.palette.barHover, "No stale glass update");
      compare(f.button.background.color, f.palette.barActive, "No stale button update");
      compare(knob.x, 19, "No stale toggle update");
      f.surface.hovered = false;
      f.button.highlightedState = false;
      toggle.checked = false;
      f.surface.hovered = true;
      f.button.highlightedState = true;
      toggle.checked = true;
      compare(overlay.color, f.palette.barHover);
      compare(f.button.background.color, f.palette.barActive);
      compare(knob.x, 19);
      f.surface.hovered = false;
      f.button.highlightedState = false;
      toggle.checked = false;
      compare(overlay.color, Qt.color("transparent"));
      compare(f.button.background.color, f.palette.barCard);
      compare(knob.x, 3);

      // Re-enable animation, reverse again, and disable it mid-reversal.
      f.palette.lowEffects = false;
      f.surface.hovered = true;
      f.button.highlightedState = true;
      toggle.checked = true;
      tryVerify(() => overlay.color.toString() !== Qt.color("transparent").toString()
                && overlay.color.toString() !== f.palette.barHover.toString()
                && f.button.background.color.toString() !== f.palette.barCard.toString()
                && f.button.background.color.toString() !== f.palette.barActive.toString()
                && knob.x > 3 && knob.x < 19, 90);
      f.surface.hovered = false;
      f.button.highlightedState = false;
      toggle.checked = false;
      wait(16);
      f.palette.lowEffects = true;
      tryCompare(overlay, "color", Qt.color("transparent"), 50);
      tryCompare(f.button.background, "color", f.palette.barCard, 50);
      tryCompare(knob, "x", 3, 50);
      wait(200);
      compare(overlay.color, Qt.color("transparent"));
      compare(f.button.background.color, f.palette.barCard);
      compare(knob.x, 3);
      f.palette.lowEffects = false;
      toggle.checked = true;
      tryCompare(knob, "x", 19);
    }
    function test_nonControlPalettesStayIndependent() {
      const palette = createTemporaryObject(paletteFactory, testRoot, { controlCenter: false });
      verify(palette !== null);
      for (const light of [false, true]) {
        palette.lightMode = light;
        const card = palette.barCard.toString();
        const active = palette.barActive.toString();
        palette.controlOpacity = 0.13;
        compare(palette.barCard.toString(), card);
        compare(palette.barActive.toString(), active);
      }
    }
  }
}
