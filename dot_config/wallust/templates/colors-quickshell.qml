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
  property bool lowEffects: false
  property bool solidSurfaces: false
  property bool controlCenter: false
  property real glassOpacity: 0.4
  property real controlOpacity: 1
  readonly property color panelBackground: lightMode ? "#F0F2F6" : "#181D27"
  // Keep the tint light; backdrop blur and reflective edges supply the material.
  readonly property color glassTop: solidSurfaces ? panelBackground : (lightMode ? "#FFFFFF" : "#303746")
  readonly property color glassBottom: solidSurfaces ? panelBackground : (lightMode ? "#EAF0F8" : "#1A202C")
  readonly property color glassInnerEdge: lightMode ? "#38FFFFFF" : "#18FFFFFF"
  readonly property color controlBase: lightMode ? "#E2E6ED" : "#293140"
  readonly property real controlAlpha: lowEffects ? 1 : Math.max(0, Math.min(1, controlOpacity))
  function controlFill(tint) {
    return Qt.rgba(tint.r, tint.g, tint.b, controlAlpha);
  }
  readonly property color barCard: controlCenter ? controlFill(controlBase) : solidSurfaces ? controlBase : (lightMode ? "#38FFFFFF" : "#24A1B0CB")
  readonly property color barBorder: lightMode ? "#66FFFFFF" : "#38FFFFFF"
  readonly property color barText: lightMode ? "#101827" : "#F4F6FC"
  readonly property color barMutedText: lightMode ? "#29354A" : "#C2CADB"
  readonly property color barAccentText: lightMode ? Qt.darker(color12, 1.8) : Qt.lighter(color12, 1.5)
  readonly property color barHover: lightMode ? "#180F2038" : "#20FFFFFF"
  readonly property color barButtonHover: controlCenter ? controlFill(Qt.tint(controlBase, barHover)) : Qt.tint(barCard, barHover)
  readonly property color barActive: {
    const accent = Qt.rgba(barAccentText.r, barAccentText.g, barAccentText.b, lightMode ? 0.16 : 0.22);
    return controlCenter ? controlFill(Qt.tint(controlBase, accent)) : accent;
  }
  readonly property color barSeparator: lightMode ? "#200F2038" : "#28FFFFFF"
  readonly property color barCritical: lightMode ? "#AD1930" : "#FF9CAA"
}
