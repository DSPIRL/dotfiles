import QtQuick
import Quickshell
import Quickshell.Io

// One state/action owner across monitors. Commands are fixed argv, not shell input.
Item {
  id: root
  visible: false
  readonly property string home: Quickshell.env("HOME")
  readonly property string scripts: home + "/.config/hypr/scripts/"
  readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || home + "/.local/state") + "/hypr/"
  property var values: ({})
  property bool loaded: false
  property string error: ""
  readonly property bool busy: action.running || status.running
  property bool quiet: false
  property bool keepAwake: false

  function refresh() { refreshTimer.restart(); }
  function run(command) {
    if (busy) return;
    error = "";
    action.command = ["/usr/bin/env"].concat(command);
    action.running = true;
  }
  function effect(name, enabled) {
    if (["blur", "opacity", "low-effects"].indexOf(name) === -1) return;
    run([scripts + "desktop-settings.sh", name, enabled ? "enable" : "disable"]);
  }
  function theme(mode) {
    if (mode !== "light" && mode !== "dark") return;
    run([scripts + "toggle-breeze-theme.sh", mode]);
  }

  Timer {
    id: refreshTimer
    interval: 80
    onTriggered: {
      if (root.busy) { restart(); return; }
      status.running = true;
    }
  }
  Process {
    id: status
    command: ["/usr/bin/env", root.scripts + "desktop-settings.sh", "status"]
    stdout: StdioCollector { id: statusOutput }
    stderr: StdioCollector { id: statusError }
    onExited: function(code) {
      if (code !== 0) { root.loaded = false; root.error = statusError.text.trim() || "Could not read desktop settings"; return; }
      try {
        root.values = JSON.parse(statusOutput.text);
        root.loaded = true;
        if (!root.values.idleRunning) root.keepAwake = false;
      } catch (e) { root.loaded = false; root.error = "Invalid desktop settings response"; }
    }
  }
  Process {
    id: action
    stderr: StdioCollector { id: actionError }
    onExited: function(code) {
      if (code !== 0) root.error = actionError.text.trim() || "Command failed (" + code + ")";
      root.refresh();
    }
  }
  FileView {
    path: root.stateDir + "effects/blur"
    printErrors: false
    watchChanges: true
    onFileChanged: { reload(); root.refresh(); }
  }
  FileView {
    path: root.stateDir + "effects/opacity"
    printErrors: false
    watchChanges: true
    onFileChanged: { reload(); root.refresh(); }
  }
  FileView {
    path: root.stateDir + "effects/low-effects"
    printErrors: false
    watchChanges: true
    onFileChanged: { reload(); root.refresh(); }
  }
  FileView {
    path: root.stateDir + "breeze-theme"
    printErrors: false
    watchChanges: true
    onFileChanged: { reload(); root.refresh(); }
  }
  Component.onCompleted: refresh()
}
