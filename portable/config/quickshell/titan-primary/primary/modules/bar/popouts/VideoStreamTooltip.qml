pragma ComponentBehavior: Bound

import QtQuick

import Quickshell
import "../../../services"

Item {
    id: root
    
    required property Item wrapper
    
    // Custom background for video content
    readonly property bool hasOwnBackground: true
    
    // Root MouseArea for hover behavior - keeps tooltip open while mouse is over it
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true
        onExited: if (root.wrapper) root.wrapper.scheduleClose()
        onClicked: function(mouse) {
            mouse.accepted = false
        }
        onPressed: function(mouse) {
            mouse.accepted = false
        }
        onReleased: function(mouse) {
            mouse.accepted = false
        }
        z: -1  // Place behind other interactive elements
    }
    
    // Dynamic sizing: default fallback 640x360 until metaData available
    property bool liveUnavailable: false

    property int fallbackWidth: 640
    property int fallbackHeight: 360
    // Track natural resolution from stream (metaData.resolution is QSize)
    // Natural resolution; try modern metaData.value(MediaMetaData.Resolution) first, fallback to legacy metaData.resolution
    property int naturalWidth: 0
    property int naturalHeight: 0
    readonly property bool previewActive: !!(root.wrapper && root.wrapper.hasCurrent
        && root.wrapper.currentName === 'tooltip-video-stream' && !VideoStream.isPlaying)
    // Scale: hover preview is 1/3 screen height; clicked/expanded view is double that.
    property int maxHeight: Math.round(wrapper && wrapper.screen ? wrapper.screen.height / 3 : 360)
    property int expandedMaxHeight: Math.round(wrapper && wrapper.screen ? Math.min(wrapper.screen.height * 0.82, maxHeight * 2) : maxHeight * 2)
    function computeDimensions() {
        var w = naturalWidth > 0 ? naturalWidth : fallbackWidth;
        var h = naturalHeight > 0 ? naturalHeight : fallbackHeight;
        if (h <= 0) h = fallbackHeight;
        if (w <= 0) w = fallbackWidth;
        var scale = 1;
        var targetHeight = VideoStream.popupExpanded ? expandedMaxHeight : maxHeight;
        if (h > targetHeight) {
            scale = targetHeight / h;
        }
        return { w: Math.round(w * scale), h: Math.round(h * scale) };
    }
    function computeWidth() { return computeDimensions().w }
    function computeHeight() { return computeDimensions().h }
    implicitWidth: computeWidth()
    implicitHeight: computeHeight()

    Connections {
        target: VideoStream
        function onPopupExpandedChanged() {
            if (root.wrapper) Qt.callLater(function(){ root.wrapper.currentName = root.wrapper.currentName; })
        }
    }

    onPreviewActiveChanged: {
        if (previewActive) {
            VideoStream.startPreviewStream()
        } else {
            VideoStream.stopPreviewStream()
            VideoStream.clearPreviewArtifacts()
        }
    }

    // Helper to update natural size from available metadata
    function updateNaturalSize(reason) {
        // Cropping changes the MJPEG frame dimensions. Keep the popout sized to
        // the original/full stream and only zoom the video content.
        if (VideoStream.cropActive) {
            console.log('[VideoStreamTooltip] ignoring cropped stream size for window sizing; reason=' + reason)
            return
        }
        var w = 0; var h = 0;
        try {
            if (videoLoader && videoLoader.item && videoLoader.item.metaData) {
                // Qt 6+ preferred API, but guard against MediaMetaData being undefined
                try {
                    var resolutionKey = (typeof MediaMetaData !== 'undefined' && typeof MediaMetaData.Resolution !== 'undefined') ? MediaMetaData.Resolution : 180
                    if (videoLoader.item.metaData.value) {
                        var res = videoLoader.item.metaData.value(resolutionKey);
                        if (res && res.width && res.height) { w = res.width; h = res.height; reason += '(metaData.value)'; }
                    }
                } catch(e) {
                    // ignore - fallbacks will handle
                }
                // Legacy convenience property
                if (!w && videoLoader.item.metaData.resolution) {
                    w = videoLoader.item.metaData.resolution.width;
                    h = videoLoader.item.metaData.resolution.height;
                }
            }
        } catch(e) {
            console.log('[VideoStreamTooltip] updateNaturalSize exception', e)
        }
        if (w && h && (w !== naturalWidth || h !== naturalHeight)) {
            naturalWidth = w; naturalHeight = h;
            console.log('[VideoStreamTooltip] natural resolution set to', w + 'x' + h, 'reason=' + reason);
            // Force wrapper measurement pass: tweak a benign property
            if (root.wrapper) {
                // Changing currentName to itself triggers bindings in Content implicit size functions
                Qt.callLater(function(){ root.wrapper.currentName = root.wrapper.currentName; });
            }
        } else if (reason && !w && !h) {
            console.log('[VideoStreamTooltip] natural resolution still unknown after', reason);
        }
    }

    // Retry fetching natural size a few times in case metadata arrives late
    Timer {
        id: naturalSizeRetry
        interval: 1500; running: true; repeat: true; triggeredOnStart: false
        property int attempts: 0
        onTriggered: {
            attempts++
            if (!naturalWidth || !naturalHeight) {
                updateNaturalSize('retry#'+attempts)
            } else {
                console.log('[VideoStreamTooltip] final natural', naturalWidth + 'x' + naturalHeight, 'scaled', root.implicitWidth + 'x' + root.implicitHeight)
                running = false
            }
            if (attempts >= 5 && running) {
                console.log('[VideoStreamTooltip] giving up discovering natural size; using fallback', fallbackWidth + 'x' + fallbackHeight)
                running = false
            }
        }
    }
    
    // Background with rounded corners
        Rectangle {
            anchors.fill: parent
            color: "#1a1a1a"
            radius: PopoutConfig.cornerRadius
            clip: true        
        // Snapshot preview (shown before live stream starts) - displays annotated version when available
        Image {
            id: snapshotImage
            anchors.fill: parent
            source: root.previewActive && !videoLoader.active
                ? (VideoStream.annotatedSnapshotUrl + (VideoStream.annotatedSnapshotUrl.indexOf('?') >= 0 ? '&v=' : '?v=') + VideoStream.snapshotVersion)
                : ""
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            cache: false
            visible: root.previewActive && !videoLoader.active // hide once live/hover stream requested
            smooth: true
            onStatusChanged: {
                const sourceSummary = source ? (String(source).substring(0, 96) + (String(source).length > 96 ? '…' : '')) : ''
                console.log('[VideoStreamTooltip] snapshot status changed', status, '(0=Null 1=Ready 2=Loading 3=Error)', 'source=', sourceSummary)
                if (status === Image.Ready && naturalWidth === 0 && naturalHeight === 0) {
                    if (implicitWidth > 0 && implicitHeight > 0) {
                        naturalWidth = implicitWidth
                        naturalHeight = implicitHeight
                        console.log('[VideoStreamTooltip] natural resolution from snapshot', naturalWidth + 'x' + naturalHeight)
                        if (root.wrapper) Qt.callLater(function(){ root.wrapper.currentName = root.wrapper.currentName; });
                    }
                }
            }
            // Placeholder when snapshot not yet fetched or inferencing
            Rectangle {
                anchors.fill: parent
                visible: snapshotImage.status !== Image.Ready
                color: '#222'
                Text {
                    anchors.centerIn: parent
                    text: VideoStream.isInferencing ? 'Running Detection...' : 'Loading Snapshot...'
                    color: PopoutConfig.textColor
                    font.pixelSize: 13
                }
            }
             // Refresh timer: 2s cadence only when popout visible + not live
              Timer {
                  id: snapshotTimer
                  interval: 1000
                  repeat: true
                  running: root.previewActive && !videoLoader.active
                  onTriggered: {
                     VideoStream.fetchSnapshot()
                 }
             }
            
            // Annotated snapshots come through as data URLs, so caching is not an issue
            // Kick off first fetch when becoming visible
            Connections {
              target: root.wrapper
              function onCurrentNameChanged() {
                if (!VideoStream.isPlaying && !videoLoader.active && root.wrapper.currentName === 'tooltip-video-stream') {
                  VideoStream.fetchSnapshot()
                }
              }
              function onHasCurrentChanged() {
                if (!VideoStream.isPlaying && !videoLoader.active && root.wrapper.hasCurrent && root.wrapper.currentName === 'tooltip-video-stream') {
                  VideoStream.fetchSnapshot()
                }
              }
            }
            // Also react when leaving live mode back to preview (if ever implemented)
            Connections {
              target: VideoStream
              function onIsPlayingChanged() {
                if (!VideoStream.isPlaying && !videoLoader.active && root.wrapper && root.wrapper.currentName === 'tooltip-video-stream') {
                  VideoStream.fetchSnapshot()
                }
              }
            }
            // Middle-click manual refresh
            MouseArea {
                anchors.fill: parent
                enabled: !VideoStream.isPlaying && !videoLoader.active
                acceptedButtons: Qt.MiddleButton
                onClicked: {
                    VideoStream.fetchSnapshot()
                }
                hoverEnabled: false
            }
        }

        // Video player (live) - lazily loaded to avoid importing QtMultimedia unless needed
        Loader {
            id: videoLoader
            anchors.fill: parent
            // QtMultimedia is used for both hover preview and clicked live playback.
            active: (VideoStream.isPlaying || (root.previewActive && VideoStream.isPreviewing)) && !root.liveUnavailable
            asynchronous: false

            sourceComponent: Component {
                VideoStreamVideo {
                    id: virtualVideo
                    streamUrl: VideoStream.streamUrl

                    onPlaybackStateChanged: function(state) {
                        if (state === virtualVideo.playbackState) {
                            // Translate playback state to VideoStream
                            if (virtualVideo.isPlaying) {
                                VideoStream.onStreamConnected()
                                updateNaturalSize('playbackStateChanged')
                            } else {
                                VideoStream.onStreamDisconnected()
                            }
                        }
                    }

                    onErrorOccurred: function(error, errorString) {
                        VideoStream.onStreamErrorOccurred(error, errorString)
                    }
                    // If dynamic module creation fails, set liveUnavailable and inform service
                    onCreateFailedChanged: function() {
                        root.liveUnavailable = createFailed
                        if (createFailed) {
                            // Inform VideoStream service that playback is not possible due to missing local module
                            VideoStream.onStreamErrorOccurred(1, 'Live video unavailable: QtMultimedia module missing or incompatible')
                            // Stop playback attempts to avoid reconnection loops
                            VideoStream.stopStream()
                            VideoStream.isPlaying = false
                            VideoStream.isConnected = false
                        } else if (!createFailed && VideoStream.errorMessage.indexOf('Live video unavailable') === 0) {
                            VideoStream.errorMessage = ""
                        }
                    }

                    onHasVideoChanged: function() {
                        if (virtualVideo.hasVideo) updateNaturalSize('hasVideoChanged')
                        VideoStream.hasVideo = virtualVideo.hasVideo
                    }
                    // When resolution changes, update size immediately
                    onResolutionChanged: function(w, h) {
                        if (!VideoStream.cropActive) {
                            naturalWidth = w; naturalHeight = h; updateNaturalSize('resolutionChanged')
                        } else {
                            console.log('[VideoStreamTooltip] crop resolution changed to', w + 'x' + h, '- keeping popout size')
                        }
                    }

                    onHasAudioChanged: function() {
                        VideoStream.hasAudio = virtualVideo.hasAudio
                    }

                    onDurationChanged: function() { VideoStream.duration = virtualVideo.duration }
                    onBufferProgressChanged: function() { VideoStream.bufferProgress = virtualVideo.bufferProgress }

                    Component.onCompleted: {
                        if (VideoStream.isPlaying || VideoStream.isPreviewing) play()
                    }

                    Component.onDestruction: {
                        if (VideoStream.isPlaying) VideoStream.stopStream()
                        else VideoStream.stopPreviewStream()
                    }
                }
            }

            // Forwarded controls for convenience
            function play() { if (videoLoader.item && typeof videoLoader.item.play === 'function') videoLoader.item.play() }
            function pause() { if (videoLoader.item && typeof videoLoader.item.pause === 'function') videoLoader.item.pause() }
            function stop() { if (videoLoader.item && typeof videoLoader.item.stop === 'function') videoLoader.item.stop() }
        }

        // Border overlay to ensure border visible above video content
        Rectangle {
            anchors.fill: parent
            color: 'transparent'
            radius: PopoutConfig.cornerRadius
            border.width: PopoutConfig.borderWidth
            border.color: PopoutConfig.borderColor
            z: 10
            clip: false
            activeFocusOnTab: false
        }
        
        // Loading indicator
        Rectangle {
            id: connectingOverlay
            anchors.centerIn: parent
            width: 120
            height: 40
            color: Qt.rgba(0, 0, 0, 0.7)
            radius: 8
            visible: !VideoStream.isConnected && VideoStream.isPlaying && !VideoStream.errorMessage
            
            Text {
                anchors.centerIn: parent
                text: "Connecting..."
                color: PopoutConfig.textColor
                font.pixelSize: 14
            }
            
            // Loading animation
            Rectangle {
                id: loadingDot1
                width: 6
                height: 6
                radius: 3
                color: PopoutConfig.textColor
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 20
                
                SequentialAnimation on opacity {
                    running: parent.visible
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.3; duration: 500 }
                    NumberAnimation { to: 1.0; duration: 500 }
                }
            }
            
            Rectangle {
                width: 6
                height: 6
                radius: 3
                color: PopoutConfig.textColor
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: loadingDot1.right
                anchors.leftMargin: 4
                
                SequentialAnimation on opacity {
                    running: connectingOverlay.visible
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.3; duration: 500 }
                    NumberAnimation { to: 1.0; duration: 500 }
                    PauseAnimation { duration: 200 }
                }
            }
            
            Rectangle {
                width: 6
                height: 6
                radius: 3
                color: PopoutConfig.textColor
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 20
                
                SequentialAnimation on opacity {
                    running: connectingOverlay.visible
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.3; duration: 500 }
                    NumberAnimation { to: 1.0; duration: 500 }
                    PauseAnimation { duration: 400 }
                }
            }
        }
        


        // Error message
        // Live unavailable overlay
        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width - 40, liveErrorText.implicitWidth + 32)
            height: liveErrorText.implicitHeight + 24
            color: Qt.rgba(0.1, 0.1, 0.1, 0.95)
            radius: 8
            border.width: 1
            border.color: PopoutConfig.errorColor
            visible: (VideoStream.errorMessage !== "") || root.liveUnavailable

            Text {
                id: liveErrorText
                anchors.centerIn: parent
                text: VideoStream.errorMessage !== "" ? VideoStream.errorMessage : "Live video unavailable: missing QtMultimedia"
                color: PopoutConfig.errorColor
                font.pixelSize: 13
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width - 40, errorText.implicitWidth + 32)
            height: errorText.implicitHeight + 24
            color: Qt.rgba(0.2, 0.1, 0.1, 0.9)
            radius: 8
            border.width: 1
            border.color: PopoutConfig.errorColor
            visible: VideoStream.errorMessage !== ""
            
            Text {
                id: errorText
                anchors.centerIn: parent
                text: VideoStream.errorMessage
                color: PopoutConfig.errorColor
                font.pixelSize: 13
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }
        }
        
        // Preview overlay (top-right) while hover preview is active
        Rectangle {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 8
            width: previewText.implicitWidth + 16
            height: previewText.implicitHeight + 8
            color: Qt.rgba(0, 0, 0, 0.6)
            radius: 6
            visible: root.previewActive && !VideoStream.errorMessage
            Text {
                id: previewText
                anchors.centerIn: parent
                text: "CLICK FOR LIVE"
                color: PopoutConfig.textColor
                font.pixelSize: 11
                font.bold: true
            }
        }
        // Computer vision overlay (top-left) describing the backend pipeline status
        Column {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.margins: 8
            spacing: 4
            visible: root.previewActive && !VideoStream.errorMessage
            Rectangle {
                width: cvText.implicitWidth + 16
                height: cvText.implicitHeight + 8
                color: Qt.rgba(0, 0, 0, 0.6)
                radius: 6
                border.width: 1
                border.color: VideoStream.hasAnnotatedSnapshot ? PopoutConfig.successColor : PopoutConfig.borderColor
                Text {
                    id: cvText
                    anchors.centerIn: parent
                    text: VideoStream.hasAnnotatedSnapshot ? "CV ANALYZED" : "RAW SNAPSHOT"
                    color: VideoStream.hasAnnotatedSnapshot ? PopoutConfig.successColor : PopoutConfig.textColor
                    font.pixelSize: 11
                    font.bold: true
                }
            }
            Rectangle {
                width: cvStatusText.implicitWidth + 16
                height: cvStatusText.implicitHeight + 8
                color: Qt.rgba(0.2, 0, 0, 0.7)
                radius: 6
                border.width: 1
                border.color: PopoutConfig.errorColor
                visible: VideoStream.inferenceStatusMessage !== ""
                Text {
                    id: cvStatusText
                    anchors.centerIn: parent
                    text: VideoStream.inferenceStatusMessage
                    color: PopoutConfig.errorColor
                    font.pixelSize: 11
                    font.bold: true
                    wrapMode: Text.WordWrap
                }
            }
        }
        // Stream info overlay (top-right corner)
        Rectangle {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 8
            width: infoText.implicitWidth + 16
            height: infoText.implicitHeight + 8
            color: Qt.rgba(0, 0, 0, 0.6)
            radius: 6
            visible: VideoStream.isConnected && VideoStream.hasVideo
            
            Text {
                id: infoText
                anchors.centerIn: parent
                text: "LIVE"
                color: PopoutConfig.successColor
                font.pixelSize: 11
                font.bold: true
            }
        }
        
        // Crop status overlay
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.margins: 8
            width: cropText.implicitWidth + 16
            height: cropText.implicitHeight + 8
            color: Qt.rgba(0, 0, 0, 0.7)
            radius: 6
            visible: VideoStream.cropActive
            Text {
                id: cropText
                anchors.centerIn: parent
                text: "CROPPED: " + VideoStream.cropLabel + " • click to reset"
                color: PopoutConfig.successColor
                font.pixelSize: 10
                font.bold: true
            }
        }

        // Inference info overlay (bottom-left corner)
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.margins: 8
            width: inferenceInfoText.implicitWidth + 16
            height: inferenceInfoText.implicitHeight + 8
            color: Qt.rgba(0, 0, 0, 0.7)
            radius: 6
            visible: !VideoStream.isPlaying && VideoStream.inferenceTimeMs > 0
            
            Text {
                id: inferenceInfoText
                anchors.centerIn: parent
                text: {
                    const time = VideoStream.inferenceTimeMs
                    const count = VideoStream.detectionCount
                    const timeStr = time < 1000 ? `${Math.round(time)}ms` : `${(time/1000).toFixed(1)}s`
                    return `${count} detected • ${timeStr}`
                }
                color: PopoutConfig.textColor
                font.pixelSize: 10
                font.family: "monospace"
            }
        }
        
            // Click a detection to crop/zoom to it; click again anywhere to uncrop.
            // If no detection is under the cursor, start/retry live playback.
            MouseArea {
                anchors.fill: parent
                onClicked: function(mouse) {
                    if (VideoStream.toggleCropAt(mouse.x, mouse.y, width, height)) {
                        return
                    }
                    VideoStream.popupExpanded = !VideoStream.popupExpanded
                    if (!VideoStream.isPlaying || VideoStream.errorMessage) {
                        VideoStream.startStream()
                    } else {
                        console.log('[VideoStreamTooltip] No detection under click; toggled expanded=', VideoStream.popupExpanded)
                    }
                }

            
            // Show cursor hint
            cursorShape: Qt.PointingHandCursor
        }
        
        // Do not take keyboard focus; CCTV popup is hover/click controlled.
        focus: false
        activeFocusOnTab: false
        Keys.onSpacePressed: {
            if (VideoStream.isConnected) {
                if (videoLoader.item && typeof videoLoader.item.isPlaying !== 'undefined') {
                    if (videoLoader.item.isPlaying) videoLoader.item.pause()
                    else videoLoader.item.play()
                } else if (videoLoader.item && typeof videoLoader.item.togglePlay === 'function') {
                    videoLoader.item.togglePlay()
                }
            }
        }
        
        Keys.onEscapePressed: {
            root.wrapper.close()
        }
    }
}
