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
    subtitle: root.desktop.values.nightLight ? "Warm display · 4000 K · saved" : root.desktop.values.nightLightWanted ? "Saved on · currently inactive" : "Warm display · 4000 K"
    checked: Boolean(root.desktop.values.nightLightWanted)
    enabled: root.ready && Boolean(root.desktop.values.nightLightAvailable || root.desktop.values.nightLightWanted)
    onToggled: root.desktop.effect("night-light", checked)
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
