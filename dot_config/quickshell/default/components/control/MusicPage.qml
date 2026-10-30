import QtQuick
import QtQuick.Effects
import QtQuick.Controls
import Quickshell.Services.Mpris
import ".."
import "../.." as Style

Column {
  id: root
  required property var wallust
  // Injectable for native fixtures; production uses the existing MPRIS service.
  property var players: Mpris.players.values
  property string selectedPlayer: ""
  readonly property var player: {
    const available = players || [];
    return available.find(p => p.dbusName === selectedPlayer)
      || available.find(p => p.isPlaying) || available[0] || null;
  }
  property real position: 0
  readonly property real duration: player && player.lengthSupported && Number.isFinite(player.length) ? Math.max(0, player.length) : 0
  readonly property bool seekable: Boolean(player && player.canSeek && player.positionSupported && duration > 0)
  spacing: 18

  function clock(seconds) {
    const value = Math.max(0, Math.floor(Number(seconds) || 0));
    const minutes = Math.floor(value / 60);
    return minutes + ":" + String(value % 60).padStart(2, "0");
  }
  function syncPosition() {
    position = player && player.positionSupported && Number.isFinite(player.position) ? Math.max(0, player.position) : 0;
  }
  function artwork(url) {
    // Treat player metadata as data, not markup, commands or QML resources.
    const value = String(url || "");
    return /^(file:\/\/|https:\/\/)/i.test(value) ? value : "";
  }
  onPlayerChanged: syncPosition()
  Component.onCompleted: syncPosition()
  Connections {
    target: root.player
    ignoreUnknownSignals: true
    function onPositionChanged() { root.syncPosition(); }
    function onPlaybackStateChanged() { root.syncPosition(); }
    function onPostTrackChanged() { root.syncPosition(); }
  }
  Timer {
    interval: 1000
    repeat: true
    running: root.visible && !seek.pressed && Boolean(root.player && root.player.isPlaying && root.player.positionSupported)
    onTriggered: root.syncPosition()
  }

  Flow {
    width: parent.width
    spacing: 6
    visible: root.players.length > 1
    Repeater {
      model: root.players
      ActionButton {
        required property var modelData
        wallust: root.wallust
        text: modelData.identity || "Media player"
        width: Math.min(implicitWidth, root.width)
        highlightedState: root.player === modelData
        onClicked: root.selectedPlayer = modelData.dbusName
      }
    }
  }
  Text {
    visible: !root.player
    width: parent.width
    text: "Nothing playing\nOpen a media player to see its playback controls here."
    font: Style.Typography.controlLabelFont
    color: root.wallust.barMutedText
    wrapMode: Text.Wrap
  }
  Column {
    visible: Boolean(root.player)
    width: parent.width
    spacing: 20
    Row {
      width: parent.width
      spacing: 16
      Rectangle {
        id: cover
        width: Math.min(160, parent.width * 0.32)
        height: width
        radius: 18
        color: root.wallust.barCard
        Text {
          anchors.centerIn: parent
          text: "󰝚"
          font: Style.Typography.controlTileIconFont
          color: root.wallust.barMutedText
          visible: art.status !== Image.Ready
        }
        Rectangle {
            id: artworkMask
            anchors.fill: parent
            radius: cover.radius
            color: "white"
            antialiasing: true
            visible: false
            layer.enabled: true
        }
        Image {
          id: art
          anchors.fill: parent
          anchors.margins: 0
          source: root.player ? root.artwork(root.player.trackArtUrl) : ""
          sourceSize.width: 320
          sourceSize.height: 320
          fillMode: Image.PreserveAspectCrop
          asynchronous: true
          visible: status === Image.Ready
          layer.enabled: true
          layer.effect: MultiEffect {
              maskEnabled: true
              maskSource: artworkMask
              maskThresholdMin: 0
              maskSpreadAtMin: 0
              maskThresholdMax: 1
              maskSpreadAtMax: 0
          }
        }
      }
      Column {
        width: parent.width - cover.width - 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8
        Text {
          width: parent.width
          text: root.player ? root.player.trackTitle || "Unknown track" : ""
          textFormat: Text.PlainText
          font: Style.Typography.controlTitleFont
          color: root.wallust.barText
          wrapMode: Text.Wrap
          maximumLineCount: 3
          elide: Text.ElideRight
        }
        Text {
          width: parent.width
          text: root.player ? root.player.trackArtist || root.player.identity : ""
          textFormat: Text.PlainText
          font: Style.Typography.controlLabelFont
          color: root.wallust.barMutedText
          wrapMode: Text.Wrap
          maximumLineCount: 2
          elide: Text.ElideRight
        }
        Text {
          width: parent.width
          text: root.player ? root.player.trackAlbum || "" : ""
          textFormat: Text.PlainText
          font: Style.Typography.controlHintFont
          color: root.wallust.barMutedText
          elide: Text.ElideRight
        }
      }
    }
    Column {
      width: parent.width
      spacing: 6
      ControlSlider {
        id: seek
        objectName: "mediaSeek"
        property var seekingPlayer: null
        property string seekingTrack: ""
        width: parent.width
        wallust: root.wallust
        from: 0
        to: Math.max(1, root.duration)
        stepSize: 1
        enabled: root.seekable
        opacity: enabled ? 1 : 0.45
        value: Math.min(root.position, root.duration)
        Accessible.name: "Playback position"
        onMoved: if (!pressed && root.seekable) root.player.position = value
        onPressedChanged: {
          if (pressed) { seekingPlayer = root.player; seekingTrack = root.player ? root.player.uniqueId : ""; }
          else if (root.seekable && root.player === seekingPlayer && root.player.uniqueId === seekingTrack) root.player.position = value;
        }
      }
      Row {
        width: parent.width
        Text {
          width: parent.width / 2
          text: root.player && root.player.positionSupported ? root.clock(seek.pressed ? seek.value : root.position) : "—"
          font: Style.Typography.controlHintFont
          color: root.wallust.barMutedText
        }
        Text {
          width: parent.width / 2
          text: root.duration > 0 ? root.clock(root.duration) : "Live / unknown duration"
          horizontalAlignment: Text.AlignRight
          font: Style.Typography.controlHintFont
          color: root.wallust.barMutedText
        }
      }
    }
    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 12
      ActionButton {
        objectName: "mediaPrevious"
        width: 64; implicitHeight: 52
        wallust: root.wallust
        text: "󰒮"
        font: Style.Typography.controlTileIconFont
        enabled: Boolean(root.player && root.player.canGoPrevious)
        Accessible.name: "Previous track"
        ToolTip.visible: hovered
        ToolTip.text: Accessible.name
        onClicked: if (root.player && root.player.canGoPrevious) root.player.previous()
      }
      ActionButton {
        objectName: "mediaPlayPause"
        width: 80; implicitHeight: 52
        wallust: root.wallust
        text: root.player && root.player.isPlaying ? "󰏤" : "󰐊"
        font: Style.Typography.controlTileIconFont
        highlightedState: true
        enabled: Boolean(root.player && root.player.canTogglePlaying)
        Accessible.name: root.player && root.player.isPlaying ? "Pause" : "Play"
        ToolTip.visible: hovered
        ToolTip.text: Accessible.name
        onClicked: if (root.player && root.player.canTogglePlaying) root.player.togglePlaying()
      }
      ActionButton {
        objectName: "mediaNext"
        width: 64; implicitHeight: 52
        wallust: root.wallust
        text: "󰒭"
        font: Style.Typography.controlTileIconFont
        enabled: Boolean(root.player && root.player.canGoNext)
        Accessible.name: "Next track"
        ToolTip.visible: hovered
        ToolTip.text: Accessible.name
        onClicked: if (root.player && root.player.canGoNext) root.player.next()
      }
    }
  }
}
