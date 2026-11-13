import QtQuick
import QtQuick.Controls
import ".."
import "../.." as Style

Column {
  id: root
  required property var bar
  required property var wallust
  readonly property var desktop: bar.desktopState
  readonly property bool ready: desktop.loaded && !desktop.busy
  spacing: Style.Tokens.controlPageSpacing

  ControlToggle {
    width: parent.width
    wallust: root.wallust
    text: "Night light"
    subtitle: root.desktop.values.nightLight ? (root.desktop.values.nightLightActualTemperature > 0 ? "Warm display · " + root.desktop.values.nightLightActualTemperature + " K" : "Unmanaged daemon · temperature unknown") : root.desktop.values.nightLightWanted ? "Saved on · currently inactive" : "Off · temperature saved"
    checked: Boolean(root.desktop.values.nightLightWanted)
    enabled: root.ready && Boolean(root.desktop.values.nightLightAvailable || root.desktop.values.nightLightWanted)
    onToggled: root.desktop.effect("night-light", checked)
  }
  Column {
    width: parent.width
    spacing: 4
    Text {
      x: 12; width: parent.width - 24
      text: "Warmth · " + Math.round(6500 - warmthSlider.value) + " K"
      font: Style.Typography.controlLabelFont
      color: root.wallust.barText
      wrapMode: Text.Wrap
    }
    ControlSlider {
      id: warmthSlider
      objectName: "nightLightWarmthSlider"
      x: 12; width: parent.width - 24
      wallust: root.wallust
      from: 0
      to: 4000
      stepSize: 100
      value: 6500 - root.desktop.nightLightTemperature
      enabled: root.desktop.loaded && Boolean(root.desktop.values.nightLightWanted) && root.desktop.values.nightLightActualTemperature > 0
      opacity: enabled ? 1 : 0.45
      Accessible.name: "Night light warmth, " + Math.round(6500 - value) + " kelvin"
      Accessible.description: "Cooler on the left, warmer on the right."
      // Commit once per drag, rather than restarting the daemon on every move.
      onPressedChanged: if (!pressed) root.desktop.setNumericSetting("night-light-temperature", 6500 - value)
      onMoved: if (!pressed) root.desktop.setNumericSetting("night-light-temperature", 6500 - value)
    }
    Text {
      x: 12; width: parent.width - 24
      text: "Cooler ← → Warmer · saved across logins"
      font: Style.Typography.controlHintFont
      color: root.wallust.barMutedText
      wrapMode: Text.Wrap
    }
  }
  ControlToggle {
    visible: Boolean(root.desktop.values.bigMonitorAvailable)
    width: parent.width
    wallust: root.wallust
    text: "Full ultrawide resolution"
    subtitle: checked ? "5120 × 1440" : "2560 × 1440"
    enabled: root.ready
    checked: Boolean(root.desktop.values.bigMonitorWide)
    onToggled: root.desktop.monitorResolution(checked)
  }
  LaptopBrightnessControl {
    visible: root.bar.showLaptopBrightnessControl
    width: parent.width
    bar: root.bar
    wallust: root.wallust
  }
  Repeater {
    model: root.bar.ddcBrightnessState.displays
    DdcBrightnessControl {
      required property var modelData
      width: root.width
      bar: root.bar
      wallust: root.wallust
      ddcDisplay: modelData
    }
  }
  Text {
    visible: root.bar.ddcBrightnessState.error.length > 0
    width: parent.width
    text: root.bar.ddcBrightnessState.error
    color: root.wallust.barCritical
    font: Style.Typography.controlMessageFont
    wrapMode: Text.Wrap
  }

  ActionButton {
    width: parent.width
    wallust: root.wallust
    symbol: "󰑐"
    text: "Refresh display detection"
    onClicked: { root.bar.ddcBrightnessState.refresh(); root.bar.laptopBrightnessState.refresh(); }
  }
  Text {
    visible: !root.bar.showLaptopBrightnessControl && root.bar.ddcBrightnessState.displayCount === 0
    width: parent.width
    text: "No adjustable brightness displays detected. External monitors need DDC/CI enabled."
    font: Style.Typography.controlMessageFont
    color: root.wallust.barMutedText
    wrapMode: Text.Wrap
  }
}
