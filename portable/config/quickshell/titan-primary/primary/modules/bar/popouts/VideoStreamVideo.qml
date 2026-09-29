pragma ComponentBehavior: Bound

import QtQuick
import QtMultimedia

import Quickshell
import "../../../services"

Item {
  id: root
  anchors.fill: parent

  property string streamUrl: ""
  property bool hasVideo: false
  property bool hasAudio: false
  property int duration: 0
  property real bufferProgress: 0.0
  property int playbackState: 0
  property bool isPlaying: false

  property bool moduleLoaded: true
  property bool createFailed: false
  property var metaData: null

  signal errorOccurred(int error, string errorString)
  signal resolutionChanged(int width, int height)

  function togglePlay() { if (isPlaying) pause(); else play() }
  function play() { mediaPlayer.play() }
  function pause() { mediaPlayer.pause() }
  function stop() { mediaPlayer.stop() }

  onStreamUrlChanged: {
    if (VideoStream.isPlaying || VideoStream.isPreviewing) {
      mediaPlayer.stop()
      Qt.callLater(mediaPlayer.play)
    }
  }

  function _onPlaybackStateChanged(state) {
    var numericState = Number(state) || 0
    playbackState = numericState
    isPlaying = (numericState === MediaPlayer.PlayingState)
    if (isPlaying) VideoStream.onStreamConnected(); else VideoStream.onStreamDisconnected()
  }

  function _onMetaDataChanged(md) {
    metaData = md
    try {
      var res = md && md.value ? md.value(MediaMetaData.Resolution) : null
      if (res && res.width && res.height) root.resolutionChanged(res.width, res.height)
    } catch(e) {
      console.log('VideoStreamVideo: metaData parse fail', e)
    }
  }

  MediaPlayer {
    id: mediaPlayer
    source: root.streamUrl
    videoOutput: videoOutput

    onPlaybackStateChanged: root._onPlaybackStateChanged(playbackState)
    onErrorOccurred: function(error, errorString) {
      root.errorOccurred(error, errorString)
      VideoStream.onStreamErrorOccurred(error, errorString)
    }
    onHasVideoChanged: {
      root.hasVideo = mediaPlayer.hasVideo
      VideoStream.hasVideo = mediaPlayer.hasVideo
    }
    onHasAudioChanged: {
      root.hasAudio = mediaPlayer.hasAudio
      VideoStream.hasAudio = mediaPlayer.hasAudio
    }
    onDurationChanged: {
      root.duration = mediaPlayer.duration
      VideoStream.duration = mediaPlayer.duration
    }
    onBufferProgressChanged: {
      root.bufferProgress = mediaPlayer.bufferProgress
      VideoStream.bufferProgress = mediaPlayer.bufferProgress
    }
    onMetaDataChanged: root._onMetaDataChanged(mediaPlayer.metaData)
  }

  VideoOutput {
    id: videoOutput
    anchors.fill: parent
    fillMode: VideoOutput.PreserveAspectFit
  }

  Component.onCompleted: {
    // Ensure we don't auto-start; the parent must invoke play() on streamStarted events.
  }

  Component.onDestruction: stop()
}
