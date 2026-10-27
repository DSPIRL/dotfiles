pragma Singleton
import QtQuick

QtObject {
  // Edit these settings in the chezmoi source, apply, then reload Quickshell.
  // Sizes are logical pixels. Use Font.Normal/Medium/DemiBold/Bold for weights.
  // Wallpaper generation does not touch this file.

  // Shared defaults. Area-specific families/weights inherit these unless changed.
  property string textFamily: "Noto Sans"
  property string iconFamily: "Hack Nerd Font"
  property int normalWeight: Font.Normal
  property int emphasisWeight: Font.DemiBold
  property int iconWeight: Font.Normal
  property int iconEmphasisWeight: Font.DemiBold

  // Bar: all pill text shares one size; emphasis remains explicit.
  property string barFamily: textFamily
  property int barSize: 14
  property int barWeight: normalWeight
  property int barClockWeight: emphasisWeight
  property int barWorkspaceWeight: Font.Medium
  property int barActiveWorkspaceWeight: Font.Bold
  property int barIconSize: 14
  property int barIconWeight: iconWeight

  // Notification content: shared by popup and history cards, not panel chrome.
  property string notificationFamily: textFamily
  property int notificationTitleSize: 15
  property int notificationTitleWeight: emphasisWeight
  property int notificationBodySize: 13
  property int notificationBodyWeight: normalWeight
  property int notificationMetaSize: 12
  property int notificationMetaWeight: normalWeight
  property int notificationActionSize: 13
  property int notificationActionWeight: normalWeight

  // Notification-center chrome: independent of notification content/controls.
  property string centerFamily: textFamily
  property int centerTitleSize: 21
  property int centerTitleWeight: emphasisWeight
  property int centerEmptySize: 14
  property int centerEmptyWeight: normalWeight
  property int centerButtonSize: 13
  property int centerButtonWeight: normalWeight
  property int centerIconSize: 24
  property int centerIconWeight: iconWeight

  // Control center, including its shared buttons, sliders and device controls.
  property string controlFamily: textFamily
  property int controlTitleSize: 21
  property int controlTitleWeight: emphasisWeight
  property int controlHeadingSize: 11
  property int controlHeadingWeight: emphasisWeight
  property int controlLabelSize: 13
  property int controlLabelWeight: normalWeight
  property int controlEmphasisWeight: emphasisWeight
  property int controlHintSize: 11
  property int controlHintWeight: normalWeight
  property int controlMessageSize: 12
  property int controlMessageWeight: normalWeight
  property int controlMetricSize: 20
  property int controlMetricWeight: emphasisWeight
  property int controlIconSize: 13
  property int controlIconWeight: iconWeight
  property int controlEmphasisIconWeight: iconEmphasisWeight

  // Derived font roles. Components bind whole fonts to avoid local overrides.
  readonly property font barTextFont: Qt.font({family: barFamily, pixelSize: barSize, weight: barWeight})
  readonly property font barClockFont: Qt.font({family: barFamily, pixelSize: barSize, weight: barClockWeight})
  readonly property font barWorkspaceFont: Qt.font({family: barFamily, pixelSize: barSize, weight: barWorkspaceWeight})
  readonly property font barActiveWorkspaceFont: Qt.font({family: barFamily, pixelSize: barSize, weight: barActiveWorkspaceWeight})
  readonly property font barIconFont: Qt.font({family: iconFamily, pixelSize: barIconSize, weight: barIconWeight})

  readonly property font notificationTitleFont: Qt.font({family: notificationFamily, pixelSize: notificationTitleSize, weight: notificationTitleWeight})
  readonly property font notificationBodyFont: Qt.font({family: notificationFamily, pixelSize: notificationBodySize, weight: notificationBodyWeight})
  readonly property font notificationMetaFont: Qt.font({family: notificationFamily, pixelSize: notificationMetaSize, weight: notificationMetaWeight})
  readonly property font notificationActionFont: Qt.font({family: notificationFamily, pixelSize: notificationActionSize, weight: notificationActionWeight})

  readonly property font centerTitleFont: Qt.font({family: centerFamily, pixelSize: centerTitleSize, weight: centerTitleWeight})
  readonly property font centerEmptyFont: Qt.font({family: centerFamily, pixelSize: centerEmptySize, weight: centerEmptyWeight})
  readonly property font centerButtonFont: Qt.font({family: centerFamily, pixelSize: centerButtonSize, weight: centerButtonWeight})
  readonly property font centerIconFont: Qt.font({family: iconFamily, pixelSize: centerIconSize, weight: centerIconWeight})

  readonly property font controlTitleFont: Qt.font({family: controlFamily, pixelSize: controlTitleSize, weight: controlTitleWeight})
  readonly property font controlHeadingFont: Qt.font({family: controlFamily, pixelSize: controlHeadingSize, weight: controlHeadingWeight})
  readonly property font controlLabelFont: Qt.font({family: controlFamily, pixelSize: controlLabelSize, weight: controlLabelWeight})
  readonly property font controlEmphasisFont: Qt.font({family: controlFamily, pixelSize: controlLabelSize, weight: controlEmphasisWeight})
  readonly property font controlHintFont: Qt.font({family: controlFamily, pixelSize: controlHintSize, weight: controlHintWeight})
  readonly property font controlMessageFont: Qt.font({family: controlFamily, pixelSize: controlMessageSize, weight: controlMessageWeight})
  readonly property font controlMetricFont: Qt.font({family: controlFamily, pixelSize: controlMetricSize, weight: controlMetricWeight})
  readonly property font controlIconFont: Qt.font({family: iconFamily, pixelSize: controlIconSize, weight: controlIconWeight})
  readonly property font controlEmphasisIconFont: Qt.font({family: iconFamily, pixelSize: controlIconSize, weight: controlEmphasisIconWeight})
}
