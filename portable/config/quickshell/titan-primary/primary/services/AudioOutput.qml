pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
    id: root

    // level 0..100
    property int level: 0
    property bool muted: false
    property int refCount: 0

    // Poll interval in ms
    readonly property bool lowPowerMode: Quickshell.env("QUICKSHELL_LOW_POWER_MODE") === "1"
    readonly property int pollIntervalMs: lowPowerMode ? 5000 : 2000

    property Timer pollTimer: Timer {
        id: pollTimer
        interval: root.pollIntervalMs
        running: false
        repeat: true
        onTriggered: update()
    }

    property bool signalRefreshPending: false

    property Timer signalThrottleTimer: Timer {
        id: signalThrottleTimer
        interval: 50
        repeat: false
        onTriggered: {
            if (root.signalRefreshPending) {
                root.signalRefreshPending = false
                root.update()
                signalThrottleTimer.restart()
            }
        }
    }

    function refreshFromExternalSignal() {
        if (signalThrottleTimer.running) {
            root.signalRefreshPending = true
            return
        }

        root.update()
        signalThrottleTimer.start()
    }

    property Process signalWatcher: Process {
        command: [
            "sh", "-c",
            "touch /tmp/quickshell-audio-output-refresh; " +
            "while true; do " +
            "inotifywait -q -e close_write,modify,create /tmp/ --include 'quickshell-audio-output-refresh' 2>/dev/null || sleep 0.25; " +
            "echo refresh; " +
            "done"
        ]
        running: true
        stdout: SplitParser {
            onRead: function(_) { root.refreshFromExternalSignal() }
        }
    }

    onRefCountChanged: {
        pollTimer.running = (root.refCount > 0)
        if (root.refCount > 0) update()
    }

    function parseVolumeOutput(out) {
        try {
            if (!out) return
            var s = out.toString()
            root.muted = /MUTED/i.test(s)

            var percMatches = s.match(/([0-9]+(?:\.[0-9]+)?)%/g)
            if (percMatches && percMatches.length > 0) {
                var maxP = 0
                for (var i=0;i<percMatches.length;i++) {
                    var num = parseFloat(percMatches[i].replace('%',''))
                    if (!isNaN(num)) maxP = Math.max(maxP, num)
                }
                root.level = Math.round(Math.min(maxP, 100))
                return
            }

            var decMatches = s.match(/([0-9]*\.[0-9]+)/g)
            if (decMatches && decMatches.length > 0) {
                var maxD = 0
                for (var j=0;j<decMatches.length;j++) {
                    var dv = parseFloat(decMatches[j])
                    if (!isNaN(dv)) maxD = Math.max(maxD, dv)
                }
                // All decimal values from wpctl are in 0.0-N.N format, multiply by 100 for percentage
                root.level = Math.round(Math.min(maxD * 100, 100))
                return
            }

            var volMatch = s.match(/vol:\s*([0-9]*\.?[0-9]+)/i)
            if (volMatch) {
                var vv = parseFloat(volMatch[1])
                if (!isNaN(vv)) {
                    if (vv <= 1) root.level = Math.round(Math.min(vv*100, 100))
                    else root.level = Math.round(Math.min(vv, 100))
                    return
                }
            }

            var trailing = s.match(/([0-9]+(?:\.[0-9]+)?)\s*$/m)
            if (trailing) {
                var tv = parseFloat(trailing[1])
                if (!isNaN(tv)) {
                    if (tv <= 1) root.level = Math.round(Math.min(tv*100, 100))
                    else root.level = Math.round(Math.min(tv, 100))
                }
            }
        } catch(e) {
            // ignore parsing errors
        }
    }

    property Process pollProc: Process {
        id: pollProc
        running: false
        command: ["sh","-c","wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null || echo \"Volume: 0%\""]
        stdout: SplitParser { onRead: function(data) { root.parseVolumeOutput(data) } }
    }

    function update() {
        if (root.refCount === 0) return
        pollProc.running = false
        pollProc.running = true
    }

    property Process toggleProc: Process { id: toggleProc; running: false }
    property Process volumeProc: Process { id: volumeProc; running: false }
    property Process setDefaultProc: Process {
        id: setDefaultProc
        running: false
        stdout: SplitParser { onRead: function(data) { root.parseVolumeOutput(data); update() } }
    }

    function toggleMute() {
        toggleProc.running = false
        toggleProc.command = ["sh","-c","/home/zarred/scripts/waybar/volume_device_switcher.sh --sink --mute 2>/dev/null"]
        toggleProc.running = true
        update()
        refreshDeviceIcon()
    }

    // Return a short identifier for current default sink (query wpctl)
    // Device-specific icon path based on current sink
    property string deviceIconPath: "/home/zarred/pictures/icons/speaker.png"

    // Device icon mapping
    property var deviceIconMap: ({
        "airpods-pro": "/home/zarred/pictures/icons/airpods-right.png",
        "qudelix-5k-usb-dac-96khz-analog-stereo": "/home/zarred/pictures/icons/headset-white.png",
        "qudelix-5k": "/home/zarred/pictures/icons/quedelix-bt.png",
        "qudelix-5k-usb-dac-96khz-digital-stereo": "/home/zarred/pictures/icons/quedelix.png",
        "starship-matisse-hd-audio-controller-digital-stereo": "/home/zarred/pictures/icons/speaker.png",
        "speaker": "/home/zarred/pictures/icons/speaker.png",
        "default": "/home/zarred/pictures/icons/speaker.png"
    })

    property Process deviceDetectionProc: Process {
        id: deviceDetectionProc
        running: false
        stdout: SplitParser {
            onRead: function(data) {
                var output = data.toString().trim()
                if (output) {
                    root.updateDeviceIcon(output)
                }
            }
        }
    }

    function friendlyDeviceName(deviceDesc) {
        if (!deviceDesc) return ""
        return deviceDesc
            .replace(/Cambridge Silicon Radio, Ltd\s*/g, "")
            .replace(/Mpow HC5 Headset in charging mode - HID \/ Mass Storage/g, "Qudelix-5K USB DAC")
            .replace(/Mpow HC5 Headset in charging mode - USB Hub/g, "Qudelix-5K USB DAC")
            .replace(/Mpow HC5 Headset in charging mode/g, "Qudelix-5K USB DAC")
    }

    function sanitizeDeviceName(deviceDesc) {
        // Remove parentheses and content, replace spaces/slashes with '-', lowercase
        return friendlyDeviceName(deviceDesc)
            .replace(/ *\([^)]*\)/g, '')
            .replace(/[ /]+/g, '-')
            .toLowerCase()
    }

    function updateDeviceIcon(deviceDesc) {
        var deviceName = sanitizeDeviceName(deviceDesc)
        var iconPath = root.deviceIconMap["default"]

        // Search for matching icon key
        for (var iconKey in root.deviceIconMap) {
            if (iconKey !== "default" && deviceName.indexOf(iconKey) !== -1) {
                iconPath = root.deviceIconMap[iconKey]
                break
            }
        }

        root.deviceIconPath = iconPath
    }

    function refreshDeviceIcon() {
        deviceDetectionProc.running = false
        deviceDetectionProc.command = ["sh", "-c", "name=$(wpctl inspect @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk -F'\\\"' '/node.nick =|api.alsa.card.name =|alsa.card_name =|node.description =/ {print $2; exit}'); if [ -n \"$name\" ]; then printf '%s\\n' \"$name\"; else wpctl status | sed -n '/Sinks:/,/Sources:/p' | grep \\* | head -n 1 | sed -E 's/^[ │*]+[0-9]+\\. (.*) +\\[vol:.*$/\\1/'; fi"]
        deviceDetectionProc.running = true
    }

    property Process sinkNameProc: Process {
        id: sinkNameProc
        running: false
        stdout: SplitParser { onRead: function(data) { if (root.sinkNameCallback) root.sinkNameCallback(data.toString().trim()) } }
    }

    property var sinkNameCallback: null

    // Return a short identifier for current default sink (query wpctl)
    function getCurrentSinkName(callback) {
        root.sinkNameCallback = callback
        sinkNameProc.running = false
        sinkNameProc.command = ["sh","-c","wpctl status 2>/dev/null | awk -F': ' '/Default Sink/ {print $2; exit}' || (wpctl status 2>/dev/null | awk -F': ' '/Default Audio Sink/ {print $2; exit}') || echo ''"]
        sinkNameProc.running = true
    }

    // Map common device substrings to icon paths
    function iconForDeviceName(name) {
        if (!name) return "/home/zarred/pictures/icons/speaker.png"
        var n = name.toLowerCase()
        if (n.indexOf('hdmi') !== -1) return "/home/zarred/pictures/icons/speaker-hdmi.png"
        if (n.indexOf('bluetooth') !== -1) return "/home/zarred/pictures/icons/speaker-bluetooth.png"
        if (n.indexOf('usb') !== -1) return "/home/zarred/pictures/icons/speaker-usb.png"
        if (n.indexOf('jack') !== -1 || n.indexOf('analog') !== -1) return "/home/zarred/pictures/icons/speaker-headphones.png"
        return "/home/zarred/pictures/icons/speaker.png"
    }

    // Signal emitted when device changes (for popout sync)
    signal deviceChanged()

    function cycleOutputDevice() {
        setDefaultProc.running = false
        setDefaultProc.command = ["sh","-c","/home/zarred/scripts/waybar/volume_device_switcher.sh --next-sink 2>/dev/null"]
        setDefaultProc.running = true
        refreshDeviceIcon()
        deviceChanged() // Emit signal for popout sync
    }

    function changeVolume(deltaPercent) {
        if (!deltaPercent) return

        // For volume increases, check if we're already at or above 100%
        if (deltaPercent > 0 && root.level >= 100) {
            return
        }

        var cmd = null
        if (deltaPercent > 0) {
            // Use wpctl with 1.0 limit to cap at 100%
            cmd = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ --limit 1.0 2>/dev/null"
        } else {
            cmd = "/home/zarred/scripts/waybar/volume_device_switcher.sh --sink --decrease 2>/dev/null"
        }
        volumeProc.running = false
        volumeProc.command = ["sh","-c", cmd]
        volumeProc.running = true
        update()
        refreshDeviceIcon()
    }
}
