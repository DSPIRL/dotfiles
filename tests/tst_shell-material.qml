import QtQuick
import QtTest
import "../dot_config/quickshell/default/components" as Shell
import "../dot_config/quickshell/default/components/control" as Control
import "../dot_config/quickshell/default/components/bar" as Bar
import "../dot_config/quickshell/default" as Style

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
  Component { id: surfaceFactory; Shell.GlassSurface { width: 400; height: 180 } }
  Component { id: buttonFactory; Control.ControlButton { x: 20; y: 30; width: 160; text: "Control" } }
  Component { id: indicatorsFactory; Bar.StatusIndicators {} }
  Component { id: clockFactory; Bar.ClockPill {} }
  Component { id: mediaFactory; Bar.SpotifyPill {} }
  Component { id: notificationBodyFactory; Text { text: "Body"; font: Style.Typography.notificationBodyFont } }
  Component { id: notificationActionFactory; Control.ControlButton { text: "Act"; font: Style.Typography.notificationActionFont } }
  Component {
    id: statusBarFactory
    QtObject {
      property var defaultAudioSink: ({audio: {volume: 0.38, muted: false}})
      property int width: 1920
      property bool spotifyVisible: true
      property string spotifyDisplay: "Test track"
      property real sinkVolume: 0.38
      property bool sinkMuted: false
      property string bluetoothIcon: ""
      property string bluetoothLabel: "2"
      property bool hasBattery: true
      property int batteryPercent: 67
      property var displayBattery: ({state: 0})
      property color batteryTextColor: "#ff0000"
      function volumeIcon(volume, muted) { return "󰕾"; }
      function batteryIcon(percent, state) { return "󰁹"; }
    }
  }

  TestCase {
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
      for (const value of ["󰕾", "", "󰤨", "󰁹", "󰐥"]) {
        const icon = findText(indicators, value);
        compare(icon.font.family, Style.Typography.iconFamily);
        compare(icon.font.pixelSize, Style.Typography.barIconSize);
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
