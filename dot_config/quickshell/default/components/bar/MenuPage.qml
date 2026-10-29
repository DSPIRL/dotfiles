import QtQuick
import Quickshell
import Quickshell.Widgets
import "../.." as Style

FocusScope {
  id: root
  required property var wallust
  property var menu
  signal dismiss()
  signal backRequested()
  property var selectedEntry: null
  property var openEntry: null
  implicitHeight: child.active ? child.item.implicitHeight : Math.max(36, list.contentHeight)
  QsMenuOpener { id: opener; menu: root.menu }
  function reset() {
    if (child.item) { child.item.reset(); child.item.menu = null; }
    child.active = false;
    openEntry = null;
    select(-1);
  }
  function select(index) {
    const entries = opener.children ? opener.children.values : [];
    list.currentIndex = index;
    selectedEntry = index >= 0 && index < entries.length ? entries[index] : null;
  }
  function reconcile() {
    const entries = opener.children ? opener.children.values : [];
    const index = entries.indexOf(selectedEntry);
    if (index < 0 || !selectedEntry.enabled || selectedEntry.isSeparator) select(-1);
    else list.currentIndex = index;
    if (child.active && (!openEntry || entries.indexOf(openEntry) < 0 || !openEntry.hasChildren || !openEntry.enabled)) back();
  }
  Connections {
    target: opener.children
    function onValuesChanged() { root.reconcile(); }
  }
  Connections {
    target: root.openEntry
    function onHasChildrenChanged() { root.reconcile(); }
    function onEnabledChanged() { root.reconcile(); }
  }
  Connections {
    target: root.selectedEntry
    function onEnabledChanged() { root.reconcile(); }
    function onIsSeparatorChanged() { root.reconcile(); }
  }
  function move(delta) {
    const entries = opener.children ? opener.children.values : [];
    if (!entries.length) return;
    let index = list.currentIndex;
    for (let i = 0; i < entries.length; ++i) {
      index = (index + delta + entries.length) % entries.length;
      if (entries[index].enabled && !entries[index].isSeparator) { select(index); return; }
    }
  }
  function back() {
    if (child.active) { child.item.reset(); child.item.menu = null; child.active = false; openEntry = null; list.forceActiveFocus(); }
    else backRequested();
  }
  Keys.onEscapePressed: event => { event.accepted = true; Qt.callLater(back); }
  Keys.onLeftPressed: event => { event.accepted = true; Qt.callLater(back); }
  ListView {
    id: list
    objectName: "menuList"
    anchors.fill: parent
    visible: !child.active
    focus: true
    clip: true
    model: opener.children
    currentIndex: -1
    keyNavigationWraps: true
    Keys.onDownPressed: event => { root.move(1); event.accepted = true; }
    Keys.onUpPressed: event => { if (currentIndex < 0) root.select(0); root.move(-1); event.accepted = true; }
    Keys.onRightPressed: event => { if (currentItem && currentItem.modelData.hasChildren) currentItem.activate(); event.accepted = true; }
    Keys.onReturnPressed: { if (currentItem) currentItem.activate(); }
    Keys.onEnterPressed: { if (currentItem) currentItem.activate(); }
    Keys.onSpacePressed: { if (currentItem) currentItem.activate(); }
    delegate: Rectangle {
      id: row
      required property var modelData
      required property int index
      width: list.width
      height: modelData.isSeparator ? 9 : 36
      radius: 8
      Accessible.role: modelData.isSeparator ? Accessible.Separator : modelData.buttonType === QsMenuButtonType.CheckBox ? Accessible.CheckBox : modelData.buttonType === QsMenuButtonType.RadioButton ? Accessible.RadioButton : Accessible.MenuItem
      Accessible.name: modelData.text
      enabled: modelData.enabled && !modelData.isSeparator
      Accessible.checkable: modelData.buttonType !== QsMenuButtonType.None
      Accessible.checked: modelData.checkState === Qt.Checked
      Accessible.checkStateMixed: modelData.checkState === Qt.PartiallyChecked
      color: list.currentIndex === index && !modelData.isSeparator ? root.wallust.barButtonHover : "transparent"
      function activate() {
        if (!modelData.enabled || modelData.isSeparator) return;
        if (modelData.hasChildren) {
          root.openEntry = modelData;
          child.setSource("MenuPage.qml", { menu: modelData, wallust: root.wallust });
          child.active = true;
          child.item.forceActiveFocus();
        } else {
          modelData.triggered();
          root.dismiss();
        }
      }
      Rectangle {
        visible: row.modelData.isSeparator
        anchors.verticalCenter: parent.verticalCenter
        x: 8; width: parent.width - 16; height: 1
        color: root.wallust.barSeparator
      }
      Text {
        id: checkmark
        anchors.left: parent.left; anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        width: 20
        text: row.modelData.buttonType === QsMenuButtonType.None ? "" : row.modelData.checkState === Qt.PartiallyChecked ? "−" : row.modelData.buttonType === QsMenuButtonType.RadioButton ? (row.modelData.checkState === Qt.Checked ? "●" : "○") : (row.modelData.checkState === Qt.Checked ? "☑" : "☐")
        color: root.wallust.barText
        opacity: row.modelData.enabled ? 1 : 0.55
      }
      IconImage {
        id: icon
        anchors.left: checkmark.right
        anchors.verticalCenter: parent.verticalCenter
        implicitSize: 18
        visible: row.modelData.icon.length > 0
        source: row.modelData.icon
      }
      Text {
        anchors.left: icon.right
        anchors.leftMargin: icon.visible ? 6 : -icon.width
        anchors.right: arrow.left; anchors.verticalCenter: parent.verticalCenter
        text: row.modelData.text
        textFormat: Text.PlainText
        font: Style.Typography.controlLabelFont
        color: root.wallust.barText
        opacity: row.modelData.enabled ? 1 : 0.55
        elide: Text.ElideRight
        visible: !row.modelData.isSeparator
      }
      Text {
        id: arrow
        anchors.right: parent.right; anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        text: row.modelData.hasChildren ? "›" : ""
        color: root.wallust.barText
      }
      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: if (row.modelData.enabled && !row.modelData.isSeparator) root.select(row.index)
        onClicked: row.activate()
      }
    }
  }
  Loader {
    id: child
    anchors.fill: parent
    active: false
    onLoaded: item.forceActiveFocus()
    Connections {
      target: child.item
      function onDismiss() { root.dismiss(); }
      function onBackRequested() { root.back(); }
    }
  }
}
