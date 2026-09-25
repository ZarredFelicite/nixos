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
  property int mediaStatus: MediaPlayer.NoMedia
  property int playbackGeneration: 0
  property bool hasRenderedFrame: false
  property bool videoReadyReported: false

  signal errorOccurred(int error, string errorString)
  signal resolutionChanged(int width, int height)
  signal videoReady()

  readonly property bool playbackRequested: root.streamUrl.length > 0
      && (VideoStream.isPlaying || VideoStream.isPreviewing)

  function togglePlay() { if (isPlaying) pause(); else play() }
  function play() {
    if (!root.streamUrl || !playbackRequested) return
    mediaPlayer.play()
  }
  function pause() { mediaPlayer.pause() }
  function stop() {
    playbackGeneration++
    loadTimeout.stop()
    stallTimeout.stop()
    hasRenderedFrame = false
    videoReadyReported = false
    mediaPlayer.stop()
  }

  function updateVideoReadiness() {
    if (!playbackRequested || !isPlaying || !hasVideo || !hasRenderedFrame || videoReadyReported) return
    videoReadyReported = true
    videoReady()
  }

  function restartPlayback() {
    if (!playbackRequested) return
    playbackGeneration++
    var generation = playbackGeneration
    hasRenderedFrame = false
    videoReadyReported = false
    mediaPlayer.stop()
    Qt.callLater(function() {
      // URL changes and popup teardown can race this deferred restart.
      if (generation !== playbackGeneration || !playbackRequested || !root.streamUrl) return
      mediaPlayer.play()
    })
  }

  function reportPlaybackFailure(message) {
    if (!playbackRequested) return
    playbackGeneration++
    loadTimeout.stop()
    stallTimeout.stop()
    mediaPlayer.stop()
    root.errorOccurred(MediaPlayer.NetworkError, message)
    VideoStream.onStreamErrorOccurred(MediaPlayer.NetworkError, message)
  }

  function _onMediaStatusChanged(status) {
    mediaStatus = Number(status)
    if (!playbackRequested) {
      loadTimeout.stop()
      stallTimeout.stop()
      return
    }
    if (status === MediaPlayer.LoadingMedia) {
      stallTimeout.stop()
      if (!loadTimeout.running) loadTimeout.start()
    } else if (status === MediaPlayer.StalledMedia || status === MediaPlayer.BufferingMedia) {
      if (isPlaying) loadTimeout.stop()
      if (!stallTimeout.running) stallTimeout.start()
    } else if (status === MediaPlayer.LoadedMedia || status === MediaPlayer.BufferedMedia) {
      loadTimeout.stop()
      stallTimeout.stop()
    } else if (status === MediaPlayer.InvalidMedia) {
      reportPlaybackFailure("CCTV stream is invalid")
    }
  }

  // A new source is started by the matching service handshake. Source changes
  // while already active (for example, crop changes) still restart immediately.
  property bool sourceWasActive: false
  onStreamUrlChanged: {
    if (!root.streamUrl) {
      sourceWasActive = false
      stop()
    } else if (playbackRequested) {
      if (sourceWasActive) restartPlayback()
      sourceWasActive = true
    }
  }

  Connections {
    target: VideoStream
    // A reconnect can restart the backend while isPlaying remains true. The
    // source binding does not change in that case, so consume the explicit
    // start event to resume the stopped MediaPlayer.
    function onStreamStarted() {
      if (root.playbackRequested && VideoStream.isPlaying) root.restartPlayback()
    }
    // Preview startup has no media-player state transition of its own. Start
    // the retained player from the service handshake once its URL is installed.
    function onPreviewStarted() {
      if (root.playbackRequested && VideoStream.isPreviewing) root.restartPlayback()
    }
  }

  Timer {
    id: loadTimeout
    interval: 10000
    repeat: false
    onTriggered: {
      if (root.playbackRequested && !root.isPlaying)
        root.reportPlaybackFailure("CCTV stream did not load within 10 seconds")
    }
  }

  Timer {
    id: stallTimeout
    interval: 5000
    repeat: false
    onTriggered: {
      if (root.playbackRequested)
        root.reportPlaybackFailure("CCTV stream stalled for 5 seconds")
    }
  }

  function _onPlaybackStateChanged(state) {
    var numericState = Number(state) || 0
    playbackState = numericState
    isPlaying = (numericState === MediaPlayer.PlayingState)
    if (!isPlaying) {
      hasRenderedFrame = false
      videoReadyReported = false
    }
    updateVideoReadiness()
    // A stop during a guarded URL/profile switch is internal, not a disconnect.
    if (isPlaying) VideoStream.onStreamConnected()
    else if (!playbackRequested) VideoStream.onStreamDisconnected()
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
    onMediaStatusChanged: root._onMediaStatusChanged(mediaStatus)
    onErrorOccurred: function(error, errorString) {
      if (!root.playbackRequested) return
      root.playbackGeneration++
      loadTimeout.stop()
      stallTimeout.stop()
      root.errorOccurred(error, errorString || "CCTV playback error")
      VideoStream.onStreamErrorOccurred(error, errorString || "CCTV playback error")
    }
    onHasVideoChanged: {
      root.hasVideo = mediaPlayer.hasVideo
      root.updateVideoReadiness()
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

  // PlayingState alone is not enough for the MJPEG backend: it can parse the
  // stream without delivering a frame to the output. Treat the first delivered
  // frame plus PlayingState/hasVideo as the usable-video handshake.
  Connections {
    target: videoOutput.videoSink
    function onVideoFrameChanged() {
      if (!root.playbackRequested || !root.isPlaying) return
      root.hasRenderedFrame = true
      root.updateVideoReadiness()
    }
  }

  Component.onCompleted: {
    // The player is intentionally kept alive while the popout container exists.
    // Playback is started only after the service has selected a valid profile.
  }

  Component.onDestruction: stop()
}
