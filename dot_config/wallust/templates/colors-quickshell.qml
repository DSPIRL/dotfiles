import QtQuick

QtObject {
  readonly property color foreground: "{{foreground}}"
  readonly property color background: "{{background}}"
  readonly property color cursor: "{{cursor}}"

  readonly property color color0: "{{color0}}"
  readonly property color color1: "{{color1}}"
  readonly property color color2: "{{color2}}"
  readonly property color color3: "{{color3}}"
  readonly property color color4: "{{color4}}"
  readonly property color color5: "{{color5}}"
  readonly property color color6: "{{color6}}"
  readonly property color color7: "{{color7}}"
  readonly property color color8: "{{color8}}"
  readonly property color color9: "{{color9}}"
  readonly property color color10: "{{color10}}"
  readonly property color color11: "{{color11}}"
  readonly property color color12: "{{color12}}"
  readonly property color color13: "{{color13}}"
  readonly property color color14: "{{color14}}"
  readonly property color color15: "{{color15}}"

  property bool lightMode: false
  readonly property string textFont: "Noto Sans"
  readonly property string iconFont: "Hack Nerd Font"
  readonly property color panelBackground: lightMode ? "#F4F5F7" : "#171B22"
  readonly property color barBackground: lightMode ? "#F0F4F5F7" : "#F0171B22"
  readonly property color barCard: lightMode ? "#E5E8ED" : "#242B35"
  readonly property color barBorder: lightMode ? "#26000000" : "#26FFFFFF"
  readonly property color barText: lightMode ? "#202733" : "#E8EDF5"
  readonly property color barMutedText: lightMode ? "#566171" : "#A7B2C3"
  readonly property color barAccentText: lightMode ? Qt.darker(color12, 1.4) : Qt.lighter(color12, 1.3)
  readonly property color barHover: lightMode ? "#14000000" : "#18FFFFFF"
  readonly property color barActive: Qt.rgba(barAccentText.r, barAccentText.g, barAccentText.b, 0.18)
  readonly property color barSeparator: barBorder
  readonly property color barCritical: lightMode ? "#B42332" : "#FF8993"
}
