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
    property int interval: 2000

    property Timer pollTimer: Timer {
        id: pollTimer
        interval: root.interval
        running: false
        repeat: true
        onTriggered: update()
    }

    onRefCountChanged: {
        pollTimer.running = (root.refCount > 0)
        if (root.refCount > 0) update()
    }

    function parseVolumeOutput(out) {
        // wpctl get-volume output can be in several forms:
        // - "Volume: 0.80" (decimal 0.0-1.0)
        // - "vol: 0.26" (in wpctl status lines)
        // - percentages like "0%"
        // - multiple channel values e.g. "0.80 0.80"
        try {
            if (!out) return
            var s = out.toString()

            // Case-insensitive MUTED detection
            root.muted = /MUTED/i.test(s)

            // Try to find percentage values first (e.g., "12%")
            var percMatches = s.match(/([0-9]+(?:\.[0-9]+)?)%/g)
            if (percMatches && percMatches.length > 0) {
                 // Use the max percentage found
                var maxP = 0
                for (var i=0;i<percMatches.length;i++) {
                    var num = parseFloat(percMatches[i].replace('%',''))
                    if (!isNaN(num)) maxP = Math.max(maxP, num)
                }
                root.level = Math.round(Math.min(maxP, 100))
                return
            }

            // Next, try to find decimal values like 0.80 or 1.00 (possibly multiple channels)
            var decMatches = s.match(/([0-9]*\.[0-9]+)/g)
            if (decMatches && decMatches.length > 0) {
                var maxD = 0
                for (var j=0;j<decMatches.length;j++) {
                    var dv = parseFloat(decMatches[j])
                    if (!isNaN(dv)) maxD = Math.max(maxD, dv)
                }
                // If the value is in 0..1 range, convert to percentage
                // All decimal values from wpctl are in 0.0-N.N format, multiply by 100 for percentage
                root.level = Math.round(Math.min(maxD * 100, 100))
                return
            }

            // Next, look for 'vol: 0.26' style tokens
            var volMatch = s.match(/vol:\s*([0-9]*\.?[0-9]+)/i)
            if (volMatch) {
                var vv = parseFloat(volMatch[1])
                if (!isNaN(vv)) {
                    if (vv <= 1) root.level = Math.round(Math.min(vv*100, 100))
                    else root.level = Math.round(Math.min(vv, 100))
                    return
                }
            }

            // As a last resort, extract trailing number
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

    // Process used to query the default source volume
    property Process pollProc: Process {
        id: pollProc
        // don't keep running; spawn command each time
        running: false
        command: ["sh","-c","wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null || wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || echo \"Volume: 0%\""]
        stdout: SplitParser { onRead: function(data) { root.parseVolumeOutput(data) } }
    }

    function update() {
        if (root.refCount === 0) return
        // run process to get current source volume
        pollProc.running = false
        pollProc.running = true
    }

    // Process to run quick commands (reused)
    property Process toggleProc: Process {
        id: toggleProc
        running: false
    }

    // Process to change volume
    property Process volumeProc: Process {
        id: volumeProc
        running: false
    }

    // Process to set default device
    property Process setDefaultProc: Process {
        id: setDefaultProc
        running: false
        // Use SplitParser to react when the command produces output and refresh
        stdout: SplitParser {
            onRead: function(data) {
                // We don't need to parse the output here; just trigger an update so
                // the UI refreshes after the external script (or fallback) runs.
                root.parseVolumeOutput(data)
                update()
            }
        }
    }

    // Helper to toggle mute (use user's Waybar script)
    function toggleMute() {
        toggleProc.running = false
        toggleProc.command = ["sh","-c","/home/zarred/scripts/waybar/volume_device_switcher.sh --source --mute 2>/dev/null || wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle 2>/dev/null || wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle 2>/dev/null"]
        toggleProc.running = true
        update()
        refreshDeviceIcon()
    }

    // Signal emitted when device changes (for popout sync)
    signal deviceChanged()

    // Cycle through available input sources using the same script Waybar uses
    function cycleInputDevice() {
        setDefaultProc.running = false
        setDefaultProc.command = ["sh","-c","/home/zarred/scripts/waybar/volume_device_switcher.sh --next-source 2>/dev/null || wpctl status 2>/dev/null"]
        // remove onFinished usage (not supported); rely on stdout SplitParser to call update()
        setDefaultProc.running = true
        refreshDeviceIcon()
        deviceChanged() // Emit signal for popout sync
    }

    // Adjust volume by a delta in percent (e.g., +5 or -5) using user's script
    // Device-specific icon path based on current source
    property string deviceIconPath: "/home/zarred/pictures/icons/microphone.png"
    
    // Device icon mapping for input devices
    property var deviceIconMap: ({
        "usb-pnp-audio-device-mono": "/home/zarred/pictures/icons/microphone.png",
        "digital-microphone": "/home/zarred/pictures/icons/microphone.png",
        "airpods-pro": "/home/zarred/pictures/icons/airpods-right.png",
        "qudelix-5k-usb-dac-96khz-analog-stereo": "/home/zarred/pictures/icons/headset-white.png",
        "default": "/home/zarred/pictures/icons/microphone.png"
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

    function sanitizeDeviceName(deviceDesc) {
        // Remove parentheses and content, replace spaces/slashes with '-', lowercase
        return deviceDesc
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
        deviceDetectionProc.command = ["sh", "-c", "wpctl status | sed -n '/Sources:/,/Filters:/p' | grep \\* | head -n 1 | sed -E 's/^[ │*]+[0-9]+\\. (.*) +\\[vol:.*$/\\1/'"]
        deviceDetectionProc.running = true
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
            cmd = "wpctl set-volume @DEFAULT_AUDIO_SOURCE@ 5%+ --limit 1.0 2>/dev/null || wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ --limit 1.0 2>/dev/null"
        } else {
            cmd = "/home/zarred/scripts/waybar/volume_device_switcher.sh --source --decrease 2>/dev/null || wpctl set-volume @DEFAULT_AUDIO_SOURCE@ 5%- 2>/dev/null || wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- 2>/dev/null"
        }
        volumeProc.running = false
        volumeProc.command = ["sh","-c", cmd]
        volumeProc.running = true
        update()
        refreshDeviceIcon()
    }
}
