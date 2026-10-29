import QtQuick
import QtQuick.Controls
import Quickshell
import ".." as Components

// Embedded popup: the caller supplies a parent item and a QsMenuHandle.
Popup {
  id: root
  required property var wallust
  property var menu
  padding: 6
  width: 240
  height: Math.min(400, Math.max(48, page.implicitHeight + padding * 2))
  // A modal Popup dims its entire window, including the transparent corners.
  modal: false
  focus: true
  closePolicy: Popup.CloseOnPressOutside
  onOpened: page.forceActiveFocus()
  onAboutToHide: page.reset()
  background: Components.GlassSurface {
    wallust: root.wallust
    radius: 12
  }
  contentItem: MenuPage {
    id: page
    menu: root.visible ? root.menu : null
    wallust: root.wallust
    onDismiss: { page.reset(); root.close(); }
    onBackRequested: root.close()
  }
}
