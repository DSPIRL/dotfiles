function shorten(text, maxLength) {
  if (!text || text.length <= maxLength) return text || "";
  return text.slice(0, maxLength - 3) + "...";
}

function spotifyTextForPlayer(player, stopped, paused) {
  if (!player || player.playbackState === stopped) return "";
  if (player.playbackState === paused) return "";
  let text = "";
  if (player.trackArtist && player.trackTitle) text = player.trackArtist + " - " + player.trackTitle;
  else if (player.trackTitle) text = player.trackTitle;
  else text = player.identity || "Spotify";
  return shorten(text, 44) + "  ";
}

function workspaceText(workspace, glyphs) {
  const key = workspace.name && workspace.name.length > 0 ? workspace.name : String(workspace.id);
  return glyphs[key] || key;
}

function notificationAccent(notification, critical, palette) {
  return notification && notification.urgency === critical ? palette.barCritical : palette.barBorder;
}

function notificationIcon(notification, resolveIcon) {
  if (notification && notification.appIcon && notification.appIcon.length > 0) {
    const icon = notification.appIcon;
    return icon.startsWith("/") || icon.indexOf(":") !== -1 ? icon : resolveIcon(icon);
  }
  return "";
}

function notificationToastDuration(notification, critical, low) {
  if (notification && notification.urgency === critical) return 9000;
  if (notification && notification.urgency === low) return 3500;
  return 5500;
}

function volumeIcon(volume, muted) {
  if (muted) return "󰝟";
  if (volume <= 0.33) return "󰕿";
  if (volume <= 0.66) return "󰖀";
  return "󰕾";
}

function batteryTextColor(hasBattery, state, percent, discharging, pendingDischarge, palette) {
  if (!hasBattery) return palette.barText;
  if ((state === discharging || state === pendingDischarge) && percent <= 20) return palette.barCritical;
  if (percent <= 30) return palette.color3;
  return palette.barText;
}

function batteryIcon(percent, state, charging, pendingCharge) {
  if (state === charging || state === pendingCharge) return "󰂄";
  if (percent >= 95) return "󰁹";
  if (percent >= 80) return "󰂂";
  if (percent >= 60) return "󰂀";
  if (percent >= 40) return "󰁾";
  if (percent >= 20) return "󰁼";
  return "󰁻";
}

function normalizeBatteryPercent(device) {
  if (!device) return 0;
  const rawPercent = Number(device.percentage);
  if (!Number.isFinite(rawPercent)) return 0;
  if (rawPercent > 1) return Math.max(0, Math.min(100, Math.round(rawPercent)));
  const energy = Number(device.energy);
  const capacity = Number(device.energyCapacity);
  if (Number.isFinite(energy) && Number.isFinite(capacity) && capacity > 0)
    return Math.max(0, Math.min(100, Math.round((energy / capacity) * 100)));
  return Math.max(0, Math.min(100, Math.round(rawPercent * 100)));
}
