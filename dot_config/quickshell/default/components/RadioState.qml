import QtQuick

Item {
  id: root
  required property var wifi
  required property var adapter
  required property int networkManager
  required property int blocked
  required property int enabling
  required property int disabling
  property int timeout: 5000
  readonly property bool wifiAvailable: wifi.backend === root.networkManager
  readonly property bool bluetoothBlocked: Boolean(adapter && adapter.state === root.blocked)
  readonly property bool bluetoothChanging: Boolean(adapter && (adapter.state === root.enabling || adapter.state === root.disabling))
  property bool wifiPending: false
  property bool bluetoothPending: false
  property bool wifiTarget: false
  property bool bluetoothTarget: false
  property string wifiError: ""
  property string bluetoothError: ""
  property var requestedAdapter: null

  function toggleWifi() {
    if (wifiPending || !wifiAvailable || !wifi.wifiHardwareEnabled) return;
    wifiError = ""; wifiTarget = !wifi.wifiEnabled; wifiPending = true;
    wifiTimer.restart(); wifi.wifiEnabled = wifiTarget;
  }
  function toggleBluetooth() {
    if (!adapter || bluetoothPending || bluetoothBlocked || bluetoothChanging) return;
    bluetoothError = ""; bluetoothTarget = !adapter.enabled; bluetoothPending = true; requestedAdapter = adapter;
    bluetoothTimer.restart(); adapter.enabled = bluetoothTarget;
  }
  onWifiAvailableChanged: {
    if (!wifiAvailable) { wifiPending = false; wifiError = ""; wifiTimer.stop(); }
  }
  onAdapterChanged: {
    if (requestedAdapter !== adapter) {
      bluetoothPending = false; bluetoothError = ""; requestedAdapter = null; bluetoothTimer.stop();
    }
  }
  Connections {
    target: root.wifi
    function onWifiEnabledChanged() {
      if (root.wifi.wifiEnabled === root.wifiTarget && (root.wifiPending || root.wifiError)) {
        root.wifiPending = false; root.wifiError = ""; wifiTimer.stop();
      }
    }
  }
  Connections {
    target: root.requestedAdapter
    function onEnabledChanged() {
      if (root.requestedAdapter && root.requestedAdapter === root.adapter && root.requestedAdapter.enabled === root.bluetoothTarget && (root.bluetoothPending || root.bluetoothError)) {
        root.bluetoothPending = false; root.bluetoothError = ""; bluetoothTimer.stop();
      }
    }
  }
  Timer { id: wifiTimer; interval: root.timeout; onTriggered: root.wifiError = "Wi-Fi change not confirmed" }
  Timer { id: bluetoothTimer; interval: root.timeout; onTriggered: root.bluetoothError = "Bluetooth change not confirmed" }
}
