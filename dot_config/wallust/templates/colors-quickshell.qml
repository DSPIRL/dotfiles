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

  readonly property color barBackground: "#99{{background | strip}}"
  readonly property color barBorder: "{{color2}}"
  readonly property color barText: "{{foreground}}"
  readonly property color barMutedText: "{{color8}}"
  readonly property color barAccentText: "{{cursor}}"
  readonly property color barHover: "#4D{{color7 | strip}}"
  readonly property color barActive: "#66{{cursor | strip}}"
  readonly property color barSeparator: "#66{{foreground | strip}}"
  readonly property color barCritical: "{{color1}}"
}
