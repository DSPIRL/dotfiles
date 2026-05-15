//@ pragma UseQApplication

import Quickshell

import "components"

ShellRoot {
  Variants {
    model: Quickshell.screens

    BarWindow {
      property var modelData
      screen: modelData
    }
  }
}
