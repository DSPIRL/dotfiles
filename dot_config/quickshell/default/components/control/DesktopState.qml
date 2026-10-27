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
  readonly property bool busy: action.running || status.running || nightLightRestore.running
  property bool quiet: false
  property bool keepAwakeRequested: false
  property bool keepAwakeFailed: false
  readonly property bool keepAwake: keepAwakeRequested && !keepAwakeFailed
  property bool nightLightRestored: false
  property int glassOpacity: 40
  property int controlOpacity: 100
  property int windowOpacity: 100
  property int blurSize: 3
  readonly property var numericSettings: ({
    "glass-opacity": { field: "glassOpacity", minimum: 0, maximum: 100 },
    "control-opacity": { field: "controlOpacity", minimum: 0, maximum: 100 },
    "window-opacity": { field: "windowOpacity", minimum: 0, maximum: 100 },
    "blur-size": { field: "blurSize", minimum: 1, maximum: 20 }
  })
  property var pendingSettings: ({})
  property string settingInFlight: ""

  function refresh() { refreshTimer.restart(); }
  function run(command) {
    if (busy) return;
    error = "";
    action.command = ["/usr/bin/env"].concat(command);
    action.running = true;
  }
  function effect(name, enabled) {
    if (["blur", "opacity", "shell-glass", "low-effects", "night-light"].indexOf(name) === -1) return;
    run([scripts + "desktop-settings.sh", name, enabled ? "enable" : "disable"]);
  }
  function setNumericSetting(name, value) {
    const spec = numericSettings[name];
    if (!spec || !spec.field || !Number.isFinite(value)) return;
    root[spec.field] = Math.max(spec.minimum, Math.min(spec.maximum, Math.round(value)));
    queueSetting(name, String(root[spec.field]));
  }
  function setQuiet(enabled) {
    quiet = Boolean(enabled);
    queueSetting("quiet-notifications", quiet ? "enable" : "disable");
  }
  function setKeepAwake(enabled) {
    keepAwakeRequested = Boolean(enabled);
    keepAwakeFailed = false;
    queueSetting("keep-awake", keepAwakeRequested ? "enable" : "disable");
  }
  function queueSetting(name, operation) {
    pendingSettings[name] = operation;
    if (!settingsTimer.running) settingsTimer.start();
  }
  // Throttle rather than debounce: compositor previews continue during long drags.
  // Booleans share the same queue so saving them cannot race another action.
  Timer {
    id: settingsTimer
    interval: 60
    onTriggered: {
      if (root.busy) { restart(); return; }
      const names = Object.keys(root.pendingSettings);
      if (names.length === 0) return;
      const name = names[0];
      const operation = root.pendingSettings[name];
      delete root.pendingSettings[name];
      root.settingInFlight = name;
      root.run([root.scripts + "desktop-settings.sh", name, operation]);
      if (Object.keys(root.pendingSettings).length > 0) restart();
    }
  }

  function theme(mode) {
    if (mode !== "light" && mode !== "dark") return;
    run([scripts + "toggle-breeze-theme.sh", mode]);
  }
  function monitorResolution(wide) {
    run([scripts + "desktop-settings.sh", "monitor-resolution", wide ? "enable" : "disable"]);
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
        for (const name of Object.keys(root.numericSettings)) {
          const field = root.numericSettings[name].field;
          if (root.pendingSettings[name] === undefined && root.settingInFlight !== name && Number.isFinite(root.values[field]))
            root[field] = root.values[field];
        }
        if (root.pendingSettings["quiet-notifications"] === undefined && root.settingInFlight !== "quiet-notifications")
          root.quiet = Boolean(root.values.quietNotifications);
        if (root.pendingSettings["keep-awake"] === undefined && root.settingInFlight !== "keep-awake")
          root.keepAwakeRequested = Boolean(root.values.keepAwake);
        root.loaded = true;
        if (!root.nightLightRestored) {
          root.nightLightRestored = true;
          nightLightRestore.running = true;
        }
      } catch (e) { root.loaded = false; root.error = "Invalid desktop settings response"; }
    }
  }
  Process {
    id: action
    stderr: StdioCollector { id: actionError }
    onExited: function(code) {
      if (code !== 0) root.error = actionError.text.trim() || "Command failed (" + code + ")";
      root.settingInFlight = "";
      root.refresh();
      if (Object.keys(root.pendingSettings).length > 0 && !settingsTimer.running) settingsTimer.start();
    }
  }
  Process {
    id: nightLightRestore
    command: ["/usr/bin/env", root.scripts + "hyprsunset.sh", "apply"]
    stderr: StdioCollector { id: nightLightRestoreError }
    onExited: function(code) {
      if (code !== 0) root.error = nightLightRestoreError.text.trim() || "Could not restore night light";
      root.refresh();
    }
  }
  FileView {
    path: root.stateDir + "effects/night-light"
    printErrors: false
    watchChanges: true
    onFileChanged: { reload(); root.refresh(); }
  }
  FileView {
    path: root.stateDir + "effects/keep-awake"
    printErrors: false
    watchChanges: true
    onFileChanged: { reload(); root.refresh(); }
  }
  FileView {
    path: root.stateDir + "effects/quiet-notifications"
    printErrors: false
    watchChanges: true
    onFileChanged: { reload(); root.refresh(); }
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
    path: root.stateDir + "effects/shell-glass"
    printErrors: false
    watchChanges: true
    onFileChanged: { reload(); root.refresh(); }
  }
  FileView {
    path: root.stateDir + "effects/glass-opacity"
    printErrors: false
    watchChanges: true
    onFileChanged: { reload(); root.refresh(); }
  }
  FileView {
    path: root.stateDir + "effects/control-opacity"
    printErrors: false
    watchChanges: true
    onFileChanged: { reload(); root.refresh(); }
  }
  FileView {
    path: root.stateDir + "effects/window-opacity"
    printErrors: false
    watchChanges: true
    onFileChanged: { reload(); root.refresh(); }
  }
  FileView {
    path: root.stateDir + "effects/blur-size"
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
    path: root.stateDir + "effects/monitor-resolution"
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
