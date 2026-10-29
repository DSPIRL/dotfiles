import QtQuick
import QtQuick.Controls
import QtQuick.Window
import Quickshell
import Quickshell.Wayland
import ".."
import "../.." as Style

PanelWindow {
  id: root
  required property var bar
  required property var wallust
  readonly property var desktop: bar.desktopState
  readonly property bool ready: desktop.loaded && !desktop.busy
  property string category: "quick"
  property bool systemLoaded: false
  property bool sessionOpen: false
  property string confirmation: ""
  onSessionOpenChanged: {
    scroll.contentY = 0;
    if (sessionOpen) Qt.callLater(() => { if (root.visible && root.sessionOpen) sessionButton.forceActiveFocus(); });
  }
  onConfirmationChanged: if (sessionOpen) Qt.callLater(() => {
    if (root.visible && root.sessionOpen) {
      if (root.confirmation.length > 0) confirmAction.forceActiveFocus();
      else sessionButton.forceActiveFocus();
    }
  })
  readonly property var categories: [
    {key: "quick", label: "Quick", symbol: "󰒓"},
    {key: "music", label: "Music", symbol: "󰝚"},
    {key: "appearance", label: "Look & Feel", symbol: "󰏘"},
    {key: "audio", label: "Audio", symbol: "󰕾"},
    {key: "display", label: "Display", symbol: "󰍹"},
    {key: "system", label: "System", symbol: "󰻠"}
  ]

  visible: Boolean(bar.controlPanelOpen)
  // Both native surfaces share padded bounds. Glass retains its visible size,
  // compositor transitions and local coordinates; the shadow maps instantly.
  implicitWidth: Math.max(0, Math.min(640, screen ? screen.width - 24 : 640)) + 24
  implicitHeight: Math.max(0, Math.min(740, screen ? screen.height - (margins.top + 9) - 16 : 740)) + 24
  color: "transparent"
  screen: bar.screen
  focusable: visible
  exclusionMode: ExclusionMode.Ignore
  anchors { top: true; right: true }
  margins { top: (bar.barVisible ? bar.height + 12 : 12) - 9; right: 0 }
  WlrLayershell.namespace: "quickshell"
  // Shadow padding and rounded corners must not intercept desktop input.
  mask: Region { x: glass.x; y: glass.y; width: glass.width; height: glass.height; radius: glass.radius }

  function selectCategory(key) {
    const index = categories.findIndex(page => page.key === key);
    if (index < 0) return;
    category = key;
    const button = categoryButtons.itemAt(index);
    if (button) revealCategory(button);
    if (key === "system") systemLoaded = true;
    sessionOpen = false;
    confirmation = "";
    scroll.contentY = 0;
    if (visible && key === "display") refreshDisplays();
  }
  function focusCategory(index) {
    const button = categoryButtons.itemAt(index);
    selectCategory(categories[index].key);
    button.forceActiveFocus();
  }
  function revealCategory(button) {
    if (button.x < navigation.contentX) navigation.contentX = button.x;
    else if (button.x + button.width > navigation.contentX + navigation.width)
      navigation.contentX = button.x + button.width - navigation.width;
  }
  function refreshDisplays() {
    if (bar.ddcBrightnessState) bar.ddcBrightnessState.refresh();
    if (bar.laptopBrightnessState) bar.laptopBrightnessState.refresh();
  }
  onVisibleChanged: {
    if (!visible) { sessionOpen = false; confirmation = ""; return; }
    closeButton.forceActiveFocus();
    desktop.refresh();
    refreshDisplays();
  }
  Connections {
    target: root.bar
    function onSessionRequested() { root.sessionOpen = true; root.confirmation = ""; scroll.contentY = 0; }
    function onCategoryRequested(category) {
      root.selectCategory(category);
      if (root.visible) closeButton.forceActiveFocus();
    }
  }
  Connections {
    target: root.contentItem.Window.window
    function onActiveFocusItemChanged() {
      const item = target.activeFocusItem;
      // Pointer users can already see what they clicked; revealing the entire
      // control here makes partially visible toggles jump under the pointer.
      // Disabled controls can transfer focus to their Loader, which is not a
      // navigation target and would otherwise scroll the entire page into view.
      if (!item || item === pageLoader || item === systemLoader || item.focusReason === Qt.MouseFocusReason) return;
      let ancestor = item;
      while (ancestor && ancestor !== scroll.contentItem) ancestor = ancestor.parent;
      if (!ancestor) return;
      const y = item.mapToItem(scroll.contentItem, 0, 0).y;
      if (y < scroll.contentY) scroll.contentY = y;
      else if (y + item.height > scroll.contentY + scroll.height)
        scroll.contentY = Math.max(0, Math.min(scroll.contentHeight - scroll.height, y + item.height - scroll.height));
    }
  }

  TextMetrics { id: categoryMetrics; font: Style.Typography.controlHintFont; text: "Look & Feel" }

  GlassSurface {
    id: glass
    objectName: "controlGlass"
    anchors.fill: parent
    anchors { leftMargin: 12; rightMargin: 12; topMargin: 9; bottomMargin: 15 }
    wallust: root.wallust
    radius: Style.Tokens.panelRadius
    Keys.onEscapePressed: {
      if (root.confirmation.length > 0) root.confirmation = "";
      else if (root.sessionOpen) { root.sessionOpen = false; sessionButton.forceActiveFocus(); }
      else if (!(pageLoader.item && typeof pageLoader.item.dismissDetails === "function" && pageLoader.item.dismissDetails())) root.bar.controlPanelOpen = false;
    }

    Row {
      id: header
      x: 20; y: 16
      width: parent.width - 40
      spacing: 8
      Text {
        width: parent.width - closeButton.width - shortcut.implicitWidth - 16
        anchors.verticalCenter: parent.verticalCenter
        text: root.sessionOpen ? "Session" : "Control Center"
        font: Style.Typography.controlTitleFont
        color: root.wallust.barText
        elide: Text.ElideRight
      }
      Text {
        id: shortcut
        anchors.verticalCenter: parent.verticalCenter
        text: root.desktop.busy ? "Working…" : "Super+A"
        color: root.wallust.barMutedText
        font: Style.Typography.controlHintFont
      }
      ActionButton {
        id: closeButton
        width: Math.max(40, font.pixelSize + 24)
        wallust: root.wallust
        text: "×"
        Accessible.name: "Close controls"
        onClicked: root.bar.controlPanelOpen = false
      }
    }
    Flickable {
      id: navigation
      objectName: "categoryNavigation"
      x: 20; y: header.y + header.implicitHeight + 12
      width: parent.width - 40
      height: categoryRow.implicitHeight
      contentWidth: categoryRow.width
      contentHeight: height
      visible: !root.sessionOpen
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      Row {
        id: categoryRow
        width: Math.max(navigation.width, (categoryMetrics.advanceWidth + 24) * 6 + 30)
        spacing: 6
        Repeater {
          id: categoryButtons
          model: root.categories
          ActionButton {
            id: categoryButton
            required property var modelData
            required property int index
            width: (categoryRow.width - 30) / 6
            implicitHeight: tabContents.implicitHeight + topPadding + bottomPadding
            wallust: root.wallust
            text: modelData.label
            highlightedState: root.category === modelData.key
            Accessible.role: Accessible.PageTab
            Accessible.name: modelData.label
            Accessible.selected: highlightedState
            onClicked: root.selectCategory(modelData.key)
            onActiveFocusChanged: if (activeFocus) root.revealCategory(categoryButton)
            Keys.onLeftPressed: root.focusCategory((index + 5) % 6)
            Keys.onRightPressed: root.focusCategory((index + 1) % 6)
            Keys.onPressed: event => {
              if (event.key === Qt.Key_Home || event.key === Qt.Key_End) {
                root.focusCategory(event.key === Qt.Key_Home ? 0 : 5);
                event.accepted = true;
              }
            }
            contentItem: Column {
              id: tabContents
              spacing: 5
              Text {
                width: parent.width
                text: categoryButton.modelData.symbol
                font: Style.Typography.controlTileIconFont
                color: categoryButton.highlightedState ? root.wallust.barAccentText : root.wallust.barText
                horizontalAlignment: Text.AlignHCenter
              }
              Text {
                width: parent.width
                text: categoryButton.text
                font: Style.Typography.controlHintFont
                color: categoryButton.highlightedState ? root.wallust.barAccentText : root.wallust.barMutedText
                horizontalAlignment: Text.AlignHCenter
              }
            }
          }
        }
      }
    }
    Flickable {
      id: scroll
      x: 20
      y: root.sessionOpen ? header.y + header.implicitHeight + 14 : navigation.y + navigation.height + 14
      width: parent.width - 40
      height: Math.max(0, footer.y - y - 14)
      contentWidth: width
      contentHeight: body.implicitHeight
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
      Column {
        id: body
        width: scroll.width
        spacing: 12
        Text {
          visible: root.desktop.error.length > 0
          width: parent.width
          text: root.desktop.error
          textFormat: Text.PlainText
          wrapMode: Text.Wrap
          color: root.wallust.barCritical
          font: Style.Typography.controlMessageFont
        }
        // Unload ordinary pages so their details reset and media timers stop.
        Loader {
          id: pageLoader
          objectName: "controlPage"
          width: parent.width
          active: root.visible && !root.sessionOpen && root.category !== "system"
          // Loader retains its previous size after unloading; exclude it from
          // the Column so it cannot push System/session content below the fold.
          visible: active
          sourceComponent: ({
            quick: quickPage, music: musicPage, appearance: appearancePage,
            audio: audioPage, display: displayPage
          })[root.category]
        }
        // Retain System after its first visit: an in-flight package check can
        // finish and its result is cached. Its timers pause while hidden.
        Loader {
          id: systemLoader
          objectName: "systemPage"
          width: parent.width
          active: root.systemLoaded
          visible: root.visible && !root.sessionOpen && root.category === "system"
          sourceComponent: systemPage
        }
        Column {
          visible: root.sessionOpen
          width: parent.width
          spacing: 12
          Text {
            width: parent.width
            text: root.confirmation.length > 0 ? "Confirm " + root.confirmation + "? Unsaved work may be lost." : "Choose a session action."
            font: Style.Typography.controlLabelFont
            color: root.wallust.barText
            wrapMode: Text.Wrap
          }
          Repeater {
            model: root.confirmation.length > 0 ? [] : ["Suspend", "Log out", "Reboot", "Shutdown"]
            ActionButton {
              required property string modelData
              width: parent.width
              wallust: root.wallust
              text: modelData
              onClicked: root.confirmation = modelData
            }
          }
          ActionButton {
            id: confirmAction
            visible: root.confirmation.length > 0
            width: parent.width
            wallust: root.wallust
            text: "Confirm " + root.confirmation
            enabled: root.ready
            onClicked: {
              const actions = {
                "Suspend": [root.desktop.scripts + "session-action.sh", "suspend"],
                "Log out": ["hyprctl", "repl", "hl.dispatch(hl.dsp.exit())"],
                "Reboot": ["systemctl", "reboot"],
                "Shutdown": ["systemctl", "poweroff"]
              };
              root.desktop.run(actions[root.confirmation]);
              root.confirmation = "";
            }
          }
          ActionButton {
            width: parent.width
            wallust: root.wallust
            text: "Cancel"
            onClicked: { root.sessionOpen = false; root.confirmation = ""; }
          }
        }
      }
    }
    Flow {
      id: footer
      x: 20; y: parent.height - height - 16
      width: parent.width - 40
      spacing: 8
      ControlToggle {
        width: Math.min(parent.width, Math.max(180, Style.Typography.controlLabelSize * 8 + 76))
        wallust: root.wallust
        text: "Low effects"
        checked: Boolean(root.desktop.values.lowEffects)
        enabled: root.ready
        onToggled: root.desktop.effect("low-effects", checked)
        ToolTip.visible: hovered
        ToolTip.text: "Disable blur, transparency, animations and shadows; retain preferences"
      }
      ActionButton {
        wallust: root.wallust
        symbol: "󰌾"
        text: "Lock"
        enabled: root.ready && Boolean(root.desktop.values.lockAvailable)
        onClicked: { root.bar.runCommand(["hyprlock"]); root.bar.controlPanelOpen = false; }
      }
      ActionButton {
        id: sessionButton
        wallust: root.wallust
        symbol: "󰐥"
        text: "Session…"
        onClicked: { root.sessionOpen = !root.sessionOpen; root.confirmation = ""; scroll.contentY = 0; }
      }
    }
  }

  // Hyprland's scoped order=1 rule paints this Top surface before order-0
  // glass. Do not rely on QML z, declaration order or map timing across windows.
  PanelWindow {
    id: shadowWindow
    objectName: "controlShadowWindow"
    screen: root.screen
    visible: root.visible && shadowPaint.active
    implicitWidth: root.implicitWidth
    implicitHeight: root.implicitHeight
    anchors { top: true; right: true }
    margins { top: root.margins.top; right: root.margins.right }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    focusable: false
    mask: Region {}
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell-control-shadow"
    SurfaceShadow {
      id: shadowPaint
      anchors.fill: parent
      wallust: root.wallust
      panelRects: [Qt.rect(glass.x, glass.y, glass.width, glass.height)]
      radius: glass.radius
    }
  }

  Component { id: quickPage; QuickPage { bar: root.bar; wallust: root.wallust; radios: root.bar.radioState; onCategoryRequested: category => root.selectCategory(category) } }
  Component { id: musicPage; MusicPage { wallust: root.wallust } }
  Component { id: appearancePage; AppearancePage { bar: root.bar; wallust: root.wallust } }
  Component { id: audioPage; AudioPage { bar: root.bar; wallust: root.wallust } }
  Component { id: displayPage; DisplayPage { bar: root.bar; wallust: root.wallust } }
  Component { id: systemPage; SystemPage { bar: root.bar; wallust: root.wallust } }
}
