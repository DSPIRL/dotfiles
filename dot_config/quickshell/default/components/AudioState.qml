import QtQuick

QtObject {
  required property var pipewire
  readonly property var defaultAudioSink: pipewire.defaultAudioSink
  readonly property var defaultAudioSource: pipewire.defaultAudioSource
  readonly property bool sinkMuted: defaultAudioSink && defaultAudioSink.audio ? defaultAudioSink.audio.muted : false
  readonly property real sinkVolume: defaultAudioSink && defaultAudioSink.audio ? defaultAudioSink.audio.volume : 0
  readonly property var audioOutputDevices: audioDevices(false)
  readonly property var audioInputDevices: audioDevices(true)
  readonly property var audioTrackedNodes: {
    const nodes = audioOutputDevices.concat(audioInputDevices);
    if (defaultAudioSink) nodes.push(defaultAudioSink);
    if (defaultAudioSource) nodes.push(defaultAudioSource);
    return nodes;
  }

  function audioDevices(input) {
    const nodes = pipewire.nodes.values || [];
    const devices = [];
    for (let i = 0; i < nodes.length; i += 1) {
      const node = nodes[i];
      if (!node || !node.audio || node.isStream) continue;
      if (input && node.isSink) continue;
      if (!input && !node.isSink) continue;
      devices.push(node);
    }
    return devices;
  }

  function audioNodeLabel(node) {
    if (!node) return "Audio device";
    if (node.nickname && node.nickname.length > 0) return node.nickname;
    if (node.description && node.description.length > 0) return node.description;
    if (node.name && node.name.length > 0) return node.name;
    return "Audio device";
  }

  function isDefaultAudioDevice(node, input) {
    const current = input ? defaultAudioSource : defaultAudioSink;
    return Boolean(node && current && (node === current || node.id === current.id));
  }

  function setDefaultAudioDevice(node, input) {
    if (!node) return;
    if (input) pipewire.preferredDefaultAudioSource = node;
    else pipewire.preferredDefaultAudioSink = node;
  }

  function setAudioDeviceVolume(node, volume) {
    if (node && node.audio) node.audio.volume = Math.max(0, Math.min(1, volume));
  }

  function toggleAudioDeviceMute(node) {
    if (node && node.audio) node.audio.muted = !node.audio.muted;
  }
}
