import QtQuick

QtObject {
  property string status: "disconnected"
  property string icon: ""
  property string tooltip: "Disconnected"
  property string wifiTooltip: "Disconnected"

  function unavailable() {
    status = "unavailable";
    icon = "";
    tooltip = "Network unavailable";
    wifiTooltip = "Network unavailable";
  }

  function update(rawText) {
    const text = rawText ? rawText.trim() : "";
    const lines = text.length ? text.split("\n") : [];
    let connectedType = "";
    let connectedName = "";
    let malformed = false;
    let valid = false;

    for (let i = 0; i < lines.length; i += 1) {
      const line = lines[i];
      if (line.length === 0) continue;
      const parts = line.split(":");
      // Structural check only: fewer than the three expected fields, not semantic validation.
      if (parts.length < 3) {
        malformed = true;
        continue;
      }
      valid = true;
      const type = parts[0];
      const state = parts[1];
      const connection = parts.slice(2).join(":");
      if (state !== "connected") continue;
      if (type === "wifi") {
        connectedType = type;
        connectedName = connection;
        break;
      }
      if (type === "ethernet" && connectedType.length === 0) {
        connectedType = type;
        connectedName = connection;
      }
    }

    wifiTooltip = connectedType === "wifi" ? (connectedName.length > 0 ? connectedName : "Wi-Fi connected") : "Disconnected";
    if (connectedType === "wifi") {
      status = "connected";
      icon = "";
      tooltip = connectedName.length > 0 ? connectedName : "Wi-Fi connected";
    } else if (connectedType === "ethernet") {
      status = "connected";
      icon = "";
      tooltip = connectedName.length > 0 ? connectedName : "Ethernet connected";
    } else {
      status = malformed && !valid ? "malformed" : "disconnected";
      icon = "";
      tooltip = "Disconnected";
    }
  }
}
