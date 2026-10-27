import QtQuick
import QtQuick.Controls
import "../.." as Style

Column {
  id: root
  required property var bar
  required property var wallust
  readonly property var desktop: bar.desktopState
  readonly property bool ready: desktop.loaded && !desktop.busy
  spacing: 12
  component Heading: Text {
    width: parent.width
    font: Style.Typography.controlHeadingFont
    color: root.wallust.barMutedText
  }
  component EffectSlider: Column {
    id: settingRoot
    required property string setting
    required property string label
    property string subtitle: ""
    property string suffix: "%"
    property bool available: true
    readonly property var spec: root.desktop.numericSettings[setting]
    width: parent.width
    spacing: 4
    Text {
      x: 12; width: parent.width - 24
      text: settingRoot.label + " · " + root.desktop[settingRoot.spec.field] + settingRoot.suffix
      font: Style.Typography.controlLabelFont
      color: root.wallust.barText
      wrapMode: Text.Wrap
    }
    ControlSlider {
      x: 12; width: parent.width - 24
      wallust: root.wallust
      from: settingRoot.spec.minimum
      to: settingRoot.spec.maximum
      value: root.desktop[settingRoot.spec.field]
      enabled: root.desktop.loaded && settingRoot.available
      opacity: enabled ? 1 : 0.45
      Accessible.name: settingRoot.label
      onMoved: root.desktop.setNumericSetting(settingRoot.setting, value)
    }
    Text {
      x: 12; width: parent.width - 24
      text: settingRoot.subtitle
      font: Style.Typography.controlHintFont
      color: root.wallust.barMutedText
      wrapMode: Text.Wrap
    }
  }
  component Group: Rectangle {
    default property alias contents: groupContents.data
    width: parent.width
    implicitHeight: groupContents.implicitHeight + 16
    radius: 16
    color: root.wallust.barCard
    border.width: 1
    border.color: root.wallust.barSeparator
    Column {
      id: groupContents
      x: 4; y: 8
      width: parent.width - 8
      spacing: 2
    }
  }

  Heading { text: "SHELL SURFACES" }
  Group {
    ControlToggle {
      width: parent.width
      wallust: root.wallust
      text: "Shell glass"
      subtitle: root.desktop.values.lowEffects ? "Off — low-effects mode (preference saved)" : "Bar, control center and notifications; blur is separate"
      enabled: root.ready && !root.desktop.values.lowEffects
      checked: Boolean(root.desktop.values.effectiveShellGlass)
      onToggled: root.desktop.effect("shell-glass", checked)
    }
    EffectSlider {
      setting: "glass-opacity"
      label: "Glass opacity"
      available: Boolean(root.desktop.values.effectiveShellGlass)
      subtitle: available ? "All shell glass backgrounds; control opacity is separate" : "Enable Shell glass; low-effects mode overrides it"
    }
    EffectSlider {
      setting: "control-opacity"
      label: "Control opacity"
      available: !root.desktop.values.lowEffects
      subtitle: available ? "Control-center buttons/cards only; text and icons stay opaque" : "Off — low-effects mode (preference saved)"
    }
  }
  Heading { text: "APPLICATION WINDOWS" }
  Group {
    ControlToggle {
      width: parent.width
      wallust: root.wallust
      text: "Configured transparency"
      subtitle: root.desktop.values.lowEffects ? "Off — low-effects mode (preference saved)" : "Normal application windows; shell glass is separate"
      enabled: root.ready && !root.desktop.values.lowEffects
      checked: Boolean(root.desktop.values.effectiveOpacity)
      onToggled: root.desktop.effect("opacity", checked)
    }
    EffectSlider {
      setting: "window-opacity"
      label: "Hyprland window opacity"
      available: Boolean(root.desktop.values.effectiveOpacity)
      subtitle: available ? "Overrides per-app opacity rules; fullscreen stays opaque" : "Enable Configured transparency; low-effects mode overrides it"
    }
  }
  Heading { text: "BACKDROP BLUR" }
  Group {
    ControlToggle {
      width: parent.width
      wallust: root.wallust
      text: "Backdrop blur"
      subtitle: root.desktop.values.lowEffects ? "Off — low-effects mode (preference saved)" : "Windows and shell surfaces; opacity is separate"
      enabled: root.ready && !root.desktop.values.lowEffects
      checked: Boolean(root.desktop.values.effectiveBlur)
      onToggled: root.desktop.effect("blur", checked)
    }
    EffectSlider {
      setting: "blur-size"
      label: "Hyprland blur size"
      suffix: ""
      available: Boolean(root.desktop.values.effectiveBlur)
      subtitle: available ? "Compositor-wide; passes unchanged; higher values cost more GPU" : "Enable Backdrop blur; low-effects mode overrides it"
    }
  }
  Heading { text: "THEME & WALLPAPER" }
  Flow {
    x: 12; width: parent.width - 24
    spacing: 8
    Text {
      width: Math.max(implicitWidth, parent.width - themeChoices.implicitWidth - 8)
      height: themeChoices.implicitHeight
      verticalAlignment: Text.AlignVCenter
      text: "Theme"
      font: Style.Typography.controlLabelFont
      color: root.wallust.barText
    }
    Row {
      id: themeChoices
      spacing: 6
      Accessible.role: Accessible.Grouping
      Accessible.name: "Theme"
      Repeater {
        model: ["light", "dark"]
        ControlButton {
          required property string modelData
          objectName: modelData + "ThemeChoice"
          width: Math.min(implicitWidth, (root.width - 30) / 2)
          wallust: root.wallust
          flat: true
          symbol: modelData === "light" ? "󰖙" : "󰖔"
          text: (modelData === "light" ? "Light" : "Dark") + (highlightedState ? " ✓" : "")
          highlightedState: (root.desktop.values.theme === "light" ? "light" : "dark") === modelData
          Accessible.role: Accessible.RadioButton
          Accessible.name: modelData === "light" ? "Light theme" : "Dark theme"
          Accessible.checkable: true
          Accessible.checked: highlightedState
          enabled: root.ready
          onClicked: if (root.ready && !highlightedState) root.desktop.theme(modelData)
        }
      }
    }
  }
  ControlButton {
    id: wallpaperButton
    objectName: "wallpaperChoice"
    width: parent.width
    wallust: root.wallust
    flat: true
    text: "Wallpaper"
    Accessible.name: "Choose wallpaper"
    enabled: root.ready
    implicitHeight: Math.max(40, wallpaperContents.implicitHeight + topPadding + bottomPadding)
    onClicked: root.bar.runCommand([root.desktop.scripts + "walli.sh"])
    contentItem: Row {
      id: wallpaperContents
      spacing: 12
      opacity: wallpaperButton.enabled ? 1 : 0.55
      Text {
        id: wallpaperIcon
        anchors.verticalCenter: parent.verticalCenter
        text: "󰸉"
        font: Style.Typography.controlTileIconFont
        color: root.wallust.barText
      }
      Text {
        width: Math.max(0, parent.width - wallpaperIcon.implicitWidth - chooseLabel.implicitWidth - 24)
        anchors.verticalCenter: parent.verticalCenter
        text: wallpaperButton.text
        font: wallpaperButton.font
        color: root.wallust.barText
        elide: Text.ElideRight
      }
      Text {
        id: chooseLabel
        anchors.verticalCenter: parent.verticalCenter
        text: "Choose ›"
        font: Style.Typography.controlHintFont
        color: root.wallust.barMutedText
      }
    }
  }

  ControlToggle {
    width: parent.width
    wallust: root.wallust
    text: "Show bar"
    checked: root.bar.barVisible
    onToggled: root.bar.setBarVisible(checked)
  }
  ControlButton {
    width: parent.width
    wallust: root.wallust
    symbol: "󰏘"
    text: "Pick a screen color"
    onClicked: { root.bar.controlPanelOpen = false; colorPickerTimer.restart(); }
  }
  // Dismiss the panel before sampling the screen.
  Timer { id: colorPickerTimer; interval: 180; onTriggered: root.bar.runHyprScript("colorpicker.sh") }
}
