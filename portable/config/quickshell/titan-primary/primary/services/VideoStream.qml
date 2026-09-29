pragma Singleton
import QtQuick
import QtQml

import Quickshell.Io

Item {
    id: root

    property string serverUrl: "http://localhost:8154"  // unified CV server URL
    property string pipelineName: "cctv-watch"

    // RTSP source for the backend pipeline. Live widget playback uses the annotated pipeline stream.
    // NOTE: Credentials intentionally committed per user decision; treat as low-sensitivity LAN scope.
    readonly property string cameraRtspUrl: "rtsp://zarred:8OGZQ6tla802wFTVgtA0@192.168.8.247/Preview_01_main"
    readonly property string annotatedStreamBaseUrl: serverUrl + "/pipeline/jobs/" + encodeURIComponent(pipelineName) + "/annotated-stream?fps_limit=8"
    readonly property string cropQuery: cropActive ? ("&crop=" + encodeURIComponent(cropBox.join(","))) : ""
    readonly property string streamUrl: annotatedStreamBaseUrl + cropQuery
    readonly property string annotatedSnapshotUrl: serverUrl + "/pipeline/jobs/" + encodeURIComponent(pipelineName) + "/annotated-snapshot" + (cropActive ? ("?crop=" + encodeURIComponent(cropBox.join(","))) : "")
    // Snapshot JPEG URL for preview-on-hover mode
    // Hostname for the camera (mDNS or DNS). If HTTPS redirection causes SSL hostname errors
    // set snapshotIp to the numeric IP to avoid certificate CN mismatch (camera often uses IP in cert).
    property string host: "RLC-520A.lan"
    // Optional numeric IP override for snapshot (leave blank to use host). Example: "192.168.1.50".
    property string snapshotIp: "192.168.8.247"
    // Control whether to request snapshot over HTTPS (camera currently returns an HTTPS URL per user input)
    property bool snapshotUseHttps: true
    // Snapshot URL (physical channel method). If snapshotUseHttps false, will use HTTP.
    readonly property string snapshotUrl: (snapshotUseHttps ? "https://" : "http://") + (snapshotIp !== "" ? snapshotIp : host)
        + "/cgi-bin/api.cgi?cmd=Snap&channel=0&rs=wuuPhkmUCeI9WG7C&user=zarred&password=8OGZQ6tla802wFTVgtA0"

    // Stream state
    property bool isConnected: false
    property bool isPlaying: false
    property bool isPreviewing: false
    property bool pendingPipelineStart: false
    property bool pendingPreviewStart: false
    property string errorMessage: ""
    property int connectionAttempts: 0
    property bool autoReconnect: true

    // Stream info
    property bool hasVideo: false
    property bool hasAudio: false
    property int duration: 0
    property real bufferProgress: 0.0

    // Connection timeout
    property int connectionTimeout: 10000 // 10 seconds

    signal streamStarted()
    signal streamStopped()
    signal streamError(string error)
    signal connectionStateChanged(bool connected)

    // Legacy local snapshot path kept for old inference code; hover now loads backend HTTP JPEGs directly.
    property string fallbackSnapshotPath: "/tmp/reolink_snapshot_0.jpg"
    // Indicates we are using curl-backed snapshots (always true after first successful fetch)
    property bool fallbackMode: false
    // Incrementing version used for cache-busting in tooltip (image source query string)
    property int snapshotVersion: 0
    // Last fetch timestamp (msec) to avoid overlapping fetches
    property double lastSnapshotFetch: 0
    // Indicates if we have a valid cached snapshot (updated on successful fetch)
    property bool hasCachedSnapshot: false
    property string annotatedImageDataUrl: ""

    // Inference state
    property string faceSearchEndpoint: "/faces/search"
    property bool hasAnnotatedSnapshot: false
    property bool isInferencing: false
    property int inferenceAttempts: 0
    property double inferenceStartTime: 0
    property double inferenceTimeMs: 0
    property double lastInferenceRunMs: 0
    property int inferenceMinIntervalMs: 1000
    property int detectionCount: 0
    property bool inferenceServerAvailable: true
    property string inferenceStatusMessage: ""

    // Person/person-like detection popup state. Polls only the lightweight
    // pipeline job JSON and asks the bar indicator to open the existing CCTV
    // popout when the latest pipeline result contains a person label.
    property bool personPopupEnabled: true
    property int personPollIntervalMs: 2000
    property int personPopupCooldownMs: 45000
    property double lastPersonPopupMs: 0
    property int personDetectionCount: 0
    property bool personPresent: false
    property int personFastIntervalMs: 200
    property int personFastIntervalTtlMs: 15000
    property int personFastIntervalRequestMinMs: 3000
    property double lastPersonFastIntervalRequestMs: 0

    // Click-to-crop state for the live CCTV popout.
    property bool cropActive: false
    property var cropBox: []
    property var annotations: []
    property int annotationFrameWidth: 0
    property int annotationFrameHeight: 0
    property string cropLabel: ""

    // Hover uses the compact preview size; clicking the widget or empty popup
    // space expands the popout to a larger view.
    property bool popupExpanded: false

    signal personDetected(int count)
    signal personDetectionObserved(int count)

    function clearPreviewArtifacts() {
        hasAnnotatedSnapshot = false
        annotatedImageDataUrl = ""
        inferenceStatusMessage = ""
    }

    function fetchSnapshot() {
        const now = Date.now()
        if (now - lastSnapshotFetch < 250) return
        lastSnapshotFetch = now
        console.log('VideoStream: refreshing annotated pipeline snapshot URL')
        if (!pipelineProc.running) ensurePipelineRunning()
        if (pipelineProc.running) return
        snapshotVersion++
        fallbackMode = false
        hasCachedSnapshot = true
        hasAnnotatedSnapshot = true
        inferenceServerAvailable = true
        inferenceStatusMessage = ""
    }



    function runInference() {
        if (!hasCachedSnapshot || isInferencing) {
            return
        }
        var now = Date.now()
        if (now - lastInferenceRunMs < inferenceMinIntervalMs) {
            return
        }

        isInferencing = true
        inferenceAttempts = 0
        inferenceStartTime = now
        lastInferenceRunMs = now
        inferenceProc.responseBuffer = ""
        inferenceStatusMessage = ""
        console.log('VideoStream: sending inference request to server')

        // Use curl to POST image and get JSON response
        const curlCmd = `curl -s -w "\\n" -X POST -F "image=@${fallbackSnapshotPath}" "${serverUrl}${faceSearchEndpoint}"`

        inferenceProc.command = ["sh", "-c", curlCmd]
        inferenceProc.running = true

    }

    function ensurePipelineRunning() {
        if (pipelineProc.running) return
        const name = encodeURIComponent(pipelineName)
        // Do not POST a pipeline config here: the backend pipeline is user-owned
        // and may have saved model choices such as RF-DETR. Only start the
        // existing saved pipeline so Quickshell cannot overwrite its methods.
        pipelineProc.command = ["sh", "-c", `curl -fsS '${serverUrl}/pipeline/jobs' | grep -q '"${pipelineName}"' && curl -fsS -X POST '${serverUrl}/pipeline/jobs/${name}/start' >/dev/null`]
        pipelineProc.running = true
    }

    function startPlaybackAfterPipelineReady() {
        const masked = streamUrl.replace(/:\/\//, '://').replace(/([^:]+):([^@]+)@/, function(_, u, p){return u + ':***@'})
        console.log("VideoStream: Starting annotated pipeline stream...", masked)
        connectionTimer.restart()
        streamStarted()
    }

    function startPreviewStream() {
        if (isPlaying || isPreviewing || pendingPreviewStart) return
        console.log("VideoStream: ensuring CCTV pipeline before hover preview")
        pendingPreviewStart = true
        errorMessage = ""
        ensurePipelineRunning()
    }

    function stopPreviewStream() {
        if (!isPreviewing && !pendingPreviewStart) return
        console.log("VideoStream: stopping hover preview")
        pendingPreviewStart = false
        isPreviewing = false
        if (!isPlaying) {
            isConnected = false
            connectionStateChanged(false)
        }
    }

    function startStream() {
        console.log("VideoStream: ensuring CCTV pipeline before live playback")
        connectionAttempts++
        pendingPipelineStart = true
        pendingPreviewStart = false
        isPreviewing = false
        errorMessage = ""
        ensurePipelineRunning()
    }

    function stopStream() {
        console.log("VideoStream: Stopping RTSP stream...")
        pendingPipelineStart = false
        pendingPreviewStart = false
        isPreviewing = false
        isPlaying = false
        isConnected = false
        connectionAttempts = 0
        clearCrop()
        reconnectTimer.stop()
        connectionTimer.stop()
        streamStopped()
    }

    function reconnect() {
        if (autoReconnect && isPlaying && connectionAttempts < 3) {
            console.log("VideoStream: Attempting reconnection...")
            Qt.callLater(startStream)
        } else {
            console.log("VideoStream: Max reconnection attempts reached")
            errorMessage = "Failed to connect after 3 attempts"
            isPlaying = false
        }
    }

    // Reset connection attempts after successful connection
    function onStreamConnected() {
        if (!isPlaying && !isPreviewing) return // Ignore stale callback
        isConnected = true
        connectionAttempts = 0
        errorMessage = ""
        connectionTimer.stop()
        // streamStarted already emitted in start; avoid duplicate unless first connection after reconnect
        connectionStateChanged(true)
    }

    function onStreamDisconnected() {
        isConnected = false
        connectionStateChanged(false)
        if (isPlaying && autoReconnect) {
            reconnectTimer.start()
        }
    }

    function onStreamErrorOccurred(error, errorString) {
        console.log("VideoStream error:", errorString)
        errorMessage = errorString
        isConnected = false
        streamError(errorString)
        connectionTimer.stop()

        if (autoReconnect && isPlaying && connectionAttempts < 3) {
            reconnectTimer.start()
        }
    }

    function isPersonLabel(label) {
        if (label === null || label === undefined) return false
        var value = ("" + label).toLowerCase().trim()
        return value === "person" || value === "people" || value === "pedestrian"
            || value === "human" || value === "man" || value === "woman"
            || value === "child" || value.indexOf("person") >= 0
    }

    function countPersonDetections(value) {
        if (value === null || value === undefined) return 0
        if (typeof value === "string") return isPersonLabel(value) ? 1 : 0
        if (Array.isArray(value)) {
            var total = 0
            for (var i = 0; i < value.length; i++) total += countPersonDetections(value[i])
            return total
        }
        if (typeof value !== "object") return 0

        var count = 0
        var labelKeys = { "label": true, "class": true, "class_name": true, "name": true, "category": true }
        for (var key in labelKeys) {
            if (value[key] !== undefined && isPersonLabel(value[key])) {
                count++
                break
            }
        }
        for (var prop in value) {
            if (labelKeys[prop]) continue
            count += countPersonDetections(value[prop])
        }
        return count
    }

    function requestTemporaryPipelineInterval(intervalMs, ttlMs, reason) {
        var now = Date.now()
        if (now - lastPersonFastIntervalRequestMs < personFastIntervalRequestMinMs) return
        lastPersonFastIntervalRequestMs = now
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== 4) return
            if (xhr.status < 200 || xhr.status >= 300) {
                console.log("VideoStream: failed to boost pipeline interval - HTTP", xhr.status)
            }
        }
        var url = serverUrl + "/pipeline/jobs/" + encodeURIComponent(pipelineName)
        url += "/temporary-interval"
        xhr.open("POST", url, true)
        xhr.setRequestHeader("Content-Type", "application/json")
        xhr.send(JSON.stringify({
            "interval_ms": intervalMs,
            "ttl_ms": ttlMs,
            "reason": reason || "quickshell"
        }))
    }

    function fetchAnnotations() {
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== 4) return
            if (xhr.status < 200 || xhr.status >= 300) return
            try {
                var response = JSON.parse(xhr.responseText)
                var size = response.frame_size || []
                annotationFrameWidth = Number(size[0]) || 0
                annotationFrameHeight = Number(size[1]) || 0
                annotations = response.stale ? [] : (response.annotations || [])
            } catch (e) {
                console.log("VideoStream: failed to parse annotation boxes -", e)
            }
        }
        xhr.open("GET", serverUrl + "/pipeline/jobs/" + encodeURIComponent(pipelineName) + "/annotations", true)
        xhr.send()
    }

    function clearCrop() {
        if (!cropActive) return
        console.log("VideoStream: clearing CCTV crop")
        cropActive = false
        cropBox = []
        cropLabel = ""
        snapshotVersion++
    }

    function setCrop(box, label) {
        if (!box || box.length !== 4) return
        cropBox = [Math.round(box[0]), Math.round(box[1]), Math.round(box[2]), Math.round(box[3])]
        cropLabel = label || "detection"
        cropActive = true
        snapshotVersion++
        console.log("VideoStream: cropping CCTV popup to", cropLabel, cropBox.join(","))
    }

    function detectionAt(localX, localY, viewW, viewH) {
        if (!annotations || annotations.length === 0 || !annotationFrameWidth || !annotationFrameHeight || !viewW || !viewH) return null
        var frameRatio = annotationFrameWidth / annotationFrameHeight
        var viewRatio = viewW / viewH
        var drawW = viewW
        var drawH = viewH
        var offX = 0
        var offY = 0
        if (viewRatio > frameRatio) {
            drawH = viewH
            drawW = drawH * frameRatio
            offX = (viewW - drawW) / 2
        } else {
            drawW = viewW
            drawH = drawW / frameRatio
            offY = (viewH - drawH) / 2
        }
        if (localX < offX || localY < offY || localX > offX + drawW || localY > offY + drawH) return null
        var imageX = (localX - offX) / drawW * annotationFrameWidth
        var imageY = (localY - offY) / drawH * annotationFrameHeight
        var best = null
        var bestArea = 0
        for (var i = 0; i < annotations.length; i++) {
            var item = annotations[i]
            var box = item.box || []
            if (box.length !== 4) continue
            if (imageX >= box[0] && imageX <= box[2] && imageY >= box[1] && imageY <= box[3]) {
                var area = Math.max(1, (box[2] - box[0]) * (box[3] - box[1]))
                if (!best || area < bestArea) {
                    best = item
                    bestArea = area
                }
            }
        }
        return best
    }

    function toggleCropAt(localX, localY, viewW, viewH) {
        if (cropActive) {
            clearCrop()
            return true
        }
        var item = detectionAt(localX, localY, viewW, viewH)
        if (!item) return false
        setCrop(item.box, item.text || item.label)
        return true
    }

    function pollPersonDetections() {
        fetchAnnotations()
        if (!personPopupEnabled) return
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== 4) return
            if (xhr.status < 200 || xhr.status >= 300) return
            try {
                var response = JSON.parse(xhr.responseText)
                var job = response[pipelineName]
                if (!job || !job.last_result) return
                var count = countPersonDetections(job.last_result)
                personDetectionCount = count
                personPresent = count > 0
                if (count > 0) {
                    requestTemporaryPipelineInterval(
                        personFastIntervalMs,
                        personFastIntervalTtlMs,
                        "quickshell person detected"
                    )
                    personDetectionObserved(count)
                }
                var now = Date.now()
                if (count > 0 && now - lastPersonPopupMs >= personPopupCooldownMs) {
                    lastPersonPopupMs = now
                    console.log("VideoStream: person detected in CCTV pipeline, opening popup; count=", count)
                    personDetected(count)
                }
            } catch (e) {
                console.log("VideoStream: failed to parse pipeline detections -", e)
            }
        }
        xhr.open("GET", serverUrl + "/pipeline/jobs", true)
        xhr.send()
    }

    // Reconnection timer
    Timer {
        id: reconnectTimer
        interval: 2000 // 2 seconds
        onTriggered: reconnect()
    }

    // Connection timeout timer
    Timer {
        id: connectionTimer
        interval: root.connectionTimeout
        onTriggered: {
            if (!isConnected && isPlaying) {
                onStreamErrorOccurred("timeout", "Connection timeout")
            }
        }
    }

    // Process to create/start the backend CCTV pipeline before live playback.
    Process {
        id: pipelineProc

        stdout: SplitParser {
            onRead: function(line) {
                if (line.length > 0) console.log('VideoStream: pipeline setup:', line)
            }
        }

        onExited: function(exitCode) {
            if (exitCode === 0 && root.pendingPipelineStart) {
                root.pendingPipelineStart = false
                root.errorMessage = ""
                root.isPlaying = true
                root.startPlaybackAfterPipelineReady()
            } else if (exitCode === 0 && root.pendingPreviewStart) {
                root.pendingPreviewStart = false
                root.errorMessage = ""
                root.isPreviewing = true
            } else if (exitCode === 0) {
                root.errorMessage = ""
                root.snapshotVersion++
                root.hasCachedSnapshot = true
                root.hasAnnotatedSnapshot = true
            } else if (exitCode !== 0) {
                console.log('VideoStream: pipeline setup failed with code', exitCode)
                root.errorMessage = "Could not start saved CCTV pipeline"
                root.pendingPipelineStart = false
                root.pendingPreviewStart = false
                root.isPreviewing = false
                root.isPlaying = false
                root.isConnected = false
            }
        }
    }

    // Process to fetch snapshot via curl (fallback for TLS errors)
    Process {
        id: snapshotProc
        property string pendingPath: ""
        property int pendingVersion: 0
        stdout: SplitParser {
            onRead: function(line) {
                if (line.indexOf('OK') === 0) {
                    console.log('VideoStream: snapshot fetch succeeded')
                    fallbackMode = true
                    hasCachedSnapshot = true
                    annotatedImageDataUrl = ""
                    if (snapshotProc.pendingPath !== "") fallbackSnapshotPath = snapshotProc.pendingPath
                    if (snapshotProc.pendingVersion > snapshotVersion) snapshotVersion = snapshotProc.pendingVersion
                    hasAnnotatedSnapshot = true
                    inferenceServerAvailable = true
                    inferenceStatusMessage = ""
                } else if (line.indexOf('FAIL') === 0) {
                    console.log('VideoStream: snapshot fetch failed')
                    hasCachedSnapshot = false
                    hasAnnotatedSnapshot = false
                    inferenceServerAvailable = false
                    inferenceStatusMessage = "Pipeline snapshot unavailable"
                }
            }
        }
    }

    // Process to run inference via HTTP API
    Process {
        id: inferenceProc

        stdout: SplitParser {
            onRead: function(line) {
                // Capture the full JSON response
                inferenceProc.responseBuffer += line + "\n"
            }
        }

        property string responseBuffer: ""

        function finalizeResponse() {
            const trimmed = inferenceProc.responseBuffer.trim()
            inferenceProc.responseBuffer = ""
            if (trimmed.length === 0) {
                console.log('VideoStream: inference produced no output (CV server offline?)')
                inferenceServerAvailable = false
                inferenceStatusMessage = "CV server offline"
                annotatedImageDataUrl = ""
                hasAnnotatedSnapshot = false
                isInferencing = false
                return
            }

            try {
                const annotatedMatch = trimmed.match(/"annotated_image"\s*:\s*"([^"]*)"/)
                const annotatedImageBase64 = annotatedMatch ? annotatedMatch[1] : ""
                const sanitized = trimmed.replace(/"annotated_image"\s*:\s*"[^"]*"/, '"annotated_image":""')
                const response = JSON.parse(sanitized)
                if (response.success) {
                    inferenceTimeMs = response.processing_time_ms
                    detectionCount = response.detections.length
                    console.log('VideoStream: inference succeeded -', detectionCount, 'detections in', inferenceTimeMs, 'ms')

                    if (annotatedImageBase64.length > 0) {
                        annotatedImageDataUrl = 'data:image/jpeg;base64,' + annotatedImageBase64
                        hasAnnotatedSnapshot = true
                    } else {
                        annotatedImageDataUrl = ""
                        hasAnnotatedSnapshot = false
                    }
                    inferenceServerAvailable = true
                    inferenceStatusMessage = ""
                    isInferencing = false
                } else {
                    console.log('VideoStream: inference failed - server returned success=false')
                    annotatedImageDataUrl = ""
                    hasAnnotatedSnapshot = false
                    inferenceServerAvailable = true
                    isInferencing = false
                }
            } catch (e) {
                console.log('VideoStream: failed to parse server response -', e, 'Response:', trimmed)
                annotatedImageDataUrl = ""
                hasAnnotatedSnapshot = false
                inferenceServerAvailable = false
                inferenceStatusMessage = "CV server error"
                isInferencing = false
            }
        }

        onRunningChanged: {
            if (!running) {
                Qt.callLater(finalizeResponse)
            }
        }

        onExited: function(exitCode) {
            if (exitCode !== 0) {
                console.log('VideoStream: inference curl exited with code', exitCode)
                inferenceServerAvailable = false
                inferenceStatusMessage = "CV server offline"
                annotatedImageDataUrl = ""
                hasAnnotatedSnapshot = false
                isInferencing = false
                inferenceProc.responseBuffer = ""
            }
        }
    }

    // Component lifecycle
    Component.onCompleted: {
        console.log('VideoStream: component initialized, server URL:', serverUrl)
        personDetectionTimer.start()
    }

    Timer {
        id: personDetectionTimer
        interval: root.personPollIntervalMs
        repeat: true
        running: false
        triggeredOnStart: true
        onTriggered: root.pollPersonDetections()
    }

    // Disabled global polling: snapshots are fetched on-demand by the tooltip
    // while visible. Continuous background polling caused unnecessary memory churn.
    Timer {
        id: periodicSnapshotTimer
        interval: 10000 // 10 seconds
        repeat: true
        running: false
        triggeredOnStart: false
        onTriggered: {
            if (!isPlaying) {
                // Only fetch when not streaming live
                fetchSnapshot()
            }
        }
    }
}
