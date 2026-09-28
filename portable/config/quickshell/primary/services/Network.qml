pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
    id: root

    // Public properties
    property bool connected: false
    property bool internetAccess: false
    property string iface: "wlan0"
    property string ssid: ""
    property int rssiDbm: -100
    property int signalPercent: 0
    property int expectedThroughputKbps: 0
    property int downScore: 0 // 0-100
    property int upScore: 0   // 0-20 (from script scaling)
    property int frequencyMhz: 0
    property string security: ""
    property string txRate: ""
    property string rxRate: ""
    property real downMbps: 0.0
    property real upMbps: 0.0
    property real downPercent: 0.0
    property real upPercent: 0.0
    property string error: ""
    property date lastUpdated: new Date(0)

    // Scaling configuration (user adjustable)
    property real maxDownMbps: 100.0
    property real maxUpMbps: 20.0

    // Reference counting for polling (match pattern in AudioInput/Bluetooth)
    property int refCount: 0
    property int interval: 2000 // ms

    onRefCountChanged: {
        pollTimer.running = (root.refCount > 0)
        if (root.refCount > 0) update()
    }

    property Timer pollTimer: Timer {
        id: pollTimer
        interval: root.interval
        running: false
        repeat: true
        onTriggered: update()
    }

    // Process executing the script
    property Process pollProcess: Process {
        id: pollProcess
        running: false
        command: ["/home/zarred/.config/quickshell/primary/scripts/net_quickshell.sh"]
        stdout: SplitParser {
            onRead: function(data) { root.parseLine(data) }
        }
        onExited: function() {
            if (root.connected) {
                checkInternetAccess()
            } else {
                root.internetAccess = false
            }
        }
    }

    property Process pingProcess: Process {
        id: pingProcess
        running: false
        command: ["ping", "-c", "1", "-W", "2", "8.8.8.8"]
        onExited: function(code) {
            root.internetAccess = (code === 0)
        }
    }

    function checkInternetAccess() {
        if (!pingProcess.running) {
            pingProcess.running = true
        }
    }

    function decodePlus(v) {
        if (!v) return "";
        return v.replace(/\+/g, ' ').trim()
    }

    function clamp(v, lo, hi) {
        return Math.max(lo, Math.min(hi, v))
    }

    function parseLine(line) {
        line = (line || "").trim()
        if (!line) return
        try {
            var parts = line.split(/\s+/)
            var map = {}
            for (var i=0;i<parts.length;i++) {
                var kv = parts[i].split('=')
                if (kv.length >= 2) {
                    var key = kv[0]
                    var val = parts[i].substring(key.length+1) // preserve embedded '=' if any
                    map[key] = val
                }
            }
            // Basic fields
            root.connected = map.connected === '1'
            if (map.interface) root.iface = map.interface
            if (map.ssid) root.ssid = decodePlus(map.ssid)
            if (map.rssi) {
                var r = parseInt(map.rssi)
                if (!isNaN(r)) root.rssiDbm = r
            }
            if (map.freq_mhz) {
                var f = parseInt(map.freq_mhz)
                if (!isNaN(f)) root.frequencyMhz = f
            }
            if (map.security) root.security = decodePlus(map.security)
            if (map.txrate_mbps) root.txRate = decodePlus(map.txrate_mbps)
            if (map.rxrate_mbps) root.rxRate = decodePlus(map.rxrate_mbps)
            if (map.down_mbps) {
                var d = parseFloat(map.down_mbps)
                if (!isNaN(d)) root.downMbps = d
            }
            if (map.up_mbps) {
                var u = parseFloat(map.up_mbps)
                if (!isNaN(u)) root.upMbps = u
            }
            // Prefer script-provided signal_percent; fallback to deriving from RSSI
            if (map.signal_percent) {
                var sp2 = parseInt(map.signal_percent)
                if (!isNaN(sp2)) root.signalPercent = clamp(sp2, 0, 100)
            } else {
                var sp = Math.round(((root.rssiDbm + 100) * 100) / 70)
                root.signalPercent = clamp(sp, 0, 100)
            }
            if (map.expected_kbps) {
                var ek = parseInt(map.expected_kbps)
                if (!isNaN(ek)) root.expectedThroughputKbps = ek
            }
            if (map.down_score) {
                var ds = parseInt(map.down_score)
                if (!isNaN(ds)) root.downScore = clamp(ds, 0, 100)
            }
            if (map.up_score) {
                var us = parseInt(map.up_score)
                if (!isNaN(us)) root.upScore = clamp(us, 0, 100) // clamp to 100 though script caps at 20
            }
            // Scale down/up
            root.downPercent = root.maxDownMbps > 0 ? clamp(root.downMbps / root.maxDownMbps, 0, 1) : 0
            root.upPercent = root.maxUpMbps > 0 ? clamp(root.upMbps / root.maxUpMbps, 0, 1) : 0
            root.lastUpdated = new Date()
            root.error = ""
        } catch (e) {
            root.error = e.toString()
        }
    }

    function update() {
        if (root.refCount === 0) return
        pollProcess.running = false
        pollProcess.running = true
    }
}
