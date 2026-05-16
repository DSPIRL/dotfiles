//@ pragma UseQApplication

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Notifications

import "components"

ShellRoot {
  id: shellRoot

  property int notificationToggleGeneration: 0

  NotificationServer {
    id: notificationServer

    keepOnReload: true
    persistenceSupported: true
    bodySupported: true
    bodyMarkupSupported: true
    bodyHyperlinksSupported: false
    bodyImagesSupported: true
    actionsSupported: true
    actionIconsSupported: false
    imageSupported: true
    inlineReplySupported: true

    onNotification: function(notification) {
      notification.tracked = true;
    }
  }

  IpcHandler {
    target: "notifications"

    function toggle(): void {
      notificationToggleGeneration += 1;
    }
  }

  Variants {
    model: Quickshell.screens

    BarWindow {
      property var modelData
      screen: modelData
      notifications: notificationServer
      notificationToggleGeneration: shellRoot.notificationToggleGeneration
      focusedHyprMonitor: Hyprland.focusedMonitor
    }
  }
}
