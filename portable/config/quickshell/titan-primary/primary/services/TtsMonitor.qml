pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
    id: root

    property bool isTtsActive: false
    property bool isTtsPlaying: false
    property bool isRecordingActive: false
    property real recordingLevel: recordingInputLevel.level
    property real ttsLevel: ttsOutputLevel.level
    property bool keepTtsOutputMonitor: false
    // Only AvaWake's process-state polling is cadence-limited in low-power mode.
    readonly property bool lowPowerMode: Quickshell.env("QUICKSHELL_LOW_POWER_MODE") === "1"
    readonly property int avaWakePollIntervalMs: lowPowerMode ? 3000 : 1000
    readonly property int ttsInactivePollIntervalMs: lowPowerMode ? 1000 : 250
    // True only for "ava" wake flow (agent+deliver), not plain transcribe mode.
    property bool isAvaWakeActive: false
    property string brainSpeedMode: "low" // "low" or "high" for normal brain mode

    // Nanobot activity tracking
    property bool isNanobotGenerating: false
    property bool isNanobotUsingTools: false
    property bool isNanobotGatewayUp: false
    property int nanobotActiveToolCount: 0
    property int nanobotPort: 4096

    // Internal counter for active tool calls
    property int _pendingToolStarts: 0
    property double _lastNanobotEventMs: 0
    property int nanobotStateTtlMs: 15000

    function _setNanobotGenerating(active) {
        if (isNanobotGenerating !== active) {
            isNanobotGenerating = active
            console.log("[TtsMonitor] Nanobot generating: " + active)
        }
    }

    function _setNanobotUsingTools(active) {
        if (isNanobotUsingTools !== active) {
            isNanobotUsingTools = active
            console.log("[TtsMonitor] Nanobot tools active: " + active)
        }
    }

    function _handleNanobotLogLine(rawLine) {
        if (!_nanobotLogReady) return

        var s = rawLine.toString()

        // Nanobot log stream emits JSON lines: {"message": "...", "module": "...", ...}
        // Fast path: only care about agent loop messages
        if (s.indexOf("nanobot.agent.loop") === -1) return

        _lastNanobotEventMs = Date.now()

        // "Processing message session=..." → agent starts generating
        if (s.indexOf("Processing message") !== -1) {
            _setNanobotGenerating(true)
            return
        }

        // "Tool call: ..." → tool execution
        if (s.indexOf("Tool call:") !== -1) {
            _pendingToolStarts += 1
            nanobotActiveToolCount = _pendingToolStarts
            _setNanobotUsingTools(true)
            return
        }

        // "Response session=..." → agent done generating
        if (s.indexOf("Response session=") !== -1) {
            _setNanobotGenerating(false)
            _pendingToolStarts = 0
            nanobotActiveToolCount = 0
            _setNanobotUsingTools(false)
            return
        }
    }

    // Health check: poll nanobot gateway
    property Process nanobotGatewayWatcher: Process {
        command: [
            "sh", "-c",
            "while true; do " +
            "if curl -s -o /dev/null --max-time 1 http://127.0.0.1:" + root.nanobotPort + "/global/health; then echo 'up'; else echo 'down'; fi; " +
            "sleep 10; " +
            "done"
        ]
        stdout: SplitParser {
            onRead: function(line) {
                var isUp = (line.toString().trim() === "up")
                if (root.isNanobotGatewayUp !== isUp) {
                    root.isNanobotGatewayUp = isUp
                    console.log("[TtsMonitor] Nanobot gateway up: " + isUp)
                }
            }
        }
        stderr: SplitParser {
            onRead: function(_) {}
        }
        running: true
    }

    // Watch nanobot log stream SSE for agent activity
    // Skip initial buffer replay by ignoring events older than startup
    property bool _nanobotLogReady: false
    property Process nanobotLogWatcher: Process {
        command: [
            "sh", "-c",
            "exec 9>/tmp/quickshell-nanobot-watcher.lock; " +
            "flock -n 9 || exit 0; " +
            "while true; do " +
            "curl -sN --max-time 0 http://127.0.0.1:" + root.nanobotPort + "/log/stream 2>/dev/null | " +
            "while IFS= read -r line; do " +
            "case \"$line\" in data:*) echo \"${line#data: }\" ;; esac; " +
            "done; " +
            "sleep 3; " +
            "done"
        ]
        stdout: SplitParser {
            onRead: function(line) {
                root._handleNanobotLogLine(line)
            }
        }
        stderr: SplitParser {
            onRead: function(_) {}
        }
        running: false
    }

    // Delay processing log events until after initial buffer replay
    property Timer _nanobotLogReadyTimer: Timer {
        interval: 3000
        running: false
        repeat: false
        onTriggered: root._nanobotLogReady = true
    }

    property Timer nanobotStateGuard: Timer {
        interval: 3000
        repeat: true
        running: false
        onTriggered: {
            if (!root._lastNanobotEventMs) return
            if ((Date.now() - root._lastNanobotEventMs) > root.nanobotStateTtlMs) {
                root._setNanobotGenerating(false)
                root._pendingToolStarts = 0
                root.nanobotActiveToolCount = 0
                root._setNanobotUsingTools(false)
            }
        }
    }

    // Watch the TTS flag plus the queue lock. The flag can disappear just before
    // the lock is released, so wait for both to clear before reporting inactive.
    property Process ttsWatcher: Process {
        command: [
            "sh", "-c",
            "exec 9>/tmp/quickshell-tts-watcher.lock; " +
            "flock -n 9 || exit 0; " +
            "prev=''; " +
            "while true; do " +
            "if [ -f /tmp/quickshell-tts-active ] || ! flock -n /tmp/tts-queue.lock true 2>/dev/null; then state='active'; else state='inactive'; fi; " +
            "if [ \"$state\" != \"$prev\" ]; then echo \"$state\"; prev=\"$state\"; fi; " +
            "if [ \"$state\" = 'active' ]; then sleep 0.25; else sleep " +
            (root.ttsInactivePollIntervalMs / 1000) + "; fi; " +
            "done"
        ]
        stdout: SplitParser {
            onRead: function(line) {
                var trimmed = line.toString().trim()
                var newState = (trimmed === "active")
                if (root.isTtsActive !== newState) {
                    root.isTtsActive = newState
                }
            }
        }
        stderr: SplitParser {
            onRead: function(line) {
                // Discard stderr to prevent memory accumulation
            }
        }
        running: true
    }
    
    // Watch for actual TTS playback. This is separate from isTtsActive, which can
    // include pre-playback generation/network time.
    property Process ttsPlayingWatcher: Process {
        command: [
            "sh", "-c",
            "exec 9>/tmp/quickshell-tts-playing-watcher.lock; " +
            "flock -n 9 || exit 0; " +
            "prev=''; " +
            "while true; do " +
            "if [ -f /tmp/quickshell-tts-playing ]; then state='active'; else state='inactive'; fi; " +
            "if [ \"$state\" != \"$prev\" ]; then echo \"$state\"; prev=\"$state\"; fi; " +
            "inotifywait -q -e create,delete,modify /tmp/ --include 'quickshell-tts-playing' 2>/dev/null || sleep 0.25; " +
            "done"
        ]
        stdout: SplitParser {
            onRead: function(line) {
                var trimmed = line.toString().trim()
                var newState = (trimmed === "active")
                if (root.isTtsPlaying !== newState) {
                    root.isTtsPlaying = newState
                }
            }
        }
        stderr: SplitParser { onRead: function(_) {} }
        running: true
    }

    // Watch for audio recording flag file changes using inotifywait
    property Process recordingWatcher: Process {
        command: [
            "sh", "-c",
            "exec 9>/tmp/quickshell-recording-watcher.lock; " +
            "flock -n 9 || exit 0; " +
            "while true; do " +
            "if [ -f /tmp/audio_recording_running.tmp ]; then echo 'active'; else echo 'inactive'; fi; " +
            "inotifywait -q -e create,delete,modify /tmp/ --include 'audio_recording_running.tmp' 2>/dev/null || sleep 0.5; " +
            "done"
        ]
        stdout: SplitParser {
            onRead: function(line) {
                var trimmed = line.toString().trim()
                var newState = (trimmed === "active")
                if (root.isRecordingActive !== newState) {
                    root.isRecordingActive = newState
                }
            }
        }
        stderr: SplitParser {
            onRead: function(line) {
                // Discard stderr to prevent memory accumulation
            }
        }
        running: true
    }

    property PipewireLevelMonitor recordingInputLevel: PipewireLevelMonitor {
        nodeName: "@DEFAULT_AUDIO_SOURCE@"
        enabled: root.isRecordingActive
    }

    property PipewireLevelMonitor ttsOutputLevel: PipewireLevelMonitor {
        nodeName: "@DEFAULT_AUDIO_SINK@"
        enabled: root.isTtsActive || root.keepTtsOutputMonitor
        monitorSink: true
        isDefault: true
    }

    // Detect only the "ava" wake flow by process args (agent+deliver),
    // so plain transcribe does not trigger fullscreen.
    property Process avaWakeWatcher: Process {
        command: [
            "sh", "-c",
            "exec 9>/tmp/quickshell-avawake-watcher.lock; " +
            "flock -n 9 || exit 0; " +
            "prev=''; " +
            "while true; do " +
            "if pgrep -fa 'record-transcribe.py' | grep -E -q -- '--agent( |$).*--deliver|--deliver( |$).*--agent'; then state='active'; else state='inactive'; fi; " +
            "if [ \"$state\" != \"$prev\" ]; then echo \"$state\"; prev=\"$state\"; fi; " +
            "sleep " + (root.avaWakePollIntervalMs / 1000) + "; " +
            "done"
        ]
        stdout: SplitParser {
            onRead: function(line) {
                var trimmed = line.toString().trim()
                var newState = (trimmed === "active")
                if (root.isAvaWakeActive !== newState) {
                    root.isAvaWakeActive = newState
                }
            }
        }
        stderr: SplitParser {
            onRead: function(_) {
                // Discard stderr to prevent memory accumulation
            }
        }
        running: true
    }

    Component.onCompleted: {
        console.log("[TtsMonitor] Started watchers for TTS/recording and Ava wake")
    }

    function toggleSpeedMode() {
        brainSpeedMode = (brainSpeedMode === "low") ? "high" : "low"
        console.log("[TtsMonitor] Brain speed mode: " + brainSpeedMode)
    }
}
