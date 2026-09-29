pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
    id: root

    // List of available networks
    property var networks: []
    property bool scanning: false
    property bool reconnecting: false
    property string error: ""
    property string currentSsid: ""

    // Scan process
    property Process scanProcess: Process {
        id: scanProcess
        running: false
        command: ["iwctl", "station", "wlan0", "get-networks"]
        stdout: SplitParser {
            onRead: function(data) {
                root.parseScanOutput(data)
            }
        }
        onStarted: {
            root.scanning = true
            root.networks = []
            root.error = ""
        }
        onExited: function(code) {
            root.scanning = false
            if (code !== 0) {
                root.error = "Scan failed (exit code: " + code + ")"
            }
        }
    }

    // Connect to network process
    property Process connectProcess: Process {
        id: connectProcess
        running: false
        command: []
        onExited: function(code) {
            if (code === 0) {
                root.error = ""
                // Refresh current network info
                Qt.callLater(function() { Network.update() })
            } else {
                root.error = "Connection failed"
            }
        }
    }

    // Disconnect process
    property Process disconnectProcess: Process {
        id: disconnectProcess
        running: false
        command: ["iwctl", "station", "wlan0", "disconnect"]
        onExited: function(code) {
            if (code === 0) {
                root.error = ""
                Qt.callLater(function() { Network.update() })
            } else {
                root.error = "Disconnect failed"
            }
        }
    }

    // Force a fresh scan before reconnecting, which helps iwd rediscover 5 GHz BSSes.
    property Process reconnectProcess: Process {
        id: reconnectProcess
        running: false
        command: []
        onStarted: {
            root.reconnecting = true
            root.error = ""
        }
        onExited: function(code) {
            root.reconnecting = false
            if (code === 0) {
                root.error = ""
                Qt.callLater(function() {
                    Network.update()
                    root.scan()
                })
            } else {
                root.error = "Reconnect failed"
            }
        }
    }

    // Parse iwctl output
    property var parseBuffer: []
    function parseScanOutput(line) {
        line = (line || "").trim()
        if (!line) return
        
        // Skip header lines and separators
        if (line.indexOf("Network name") !== -1) return
        if (line.indexOf("------") !== -1) return
        if (line.indexOf("Available networks") !== -1) return
        
        // Parse network lines: "  > OpenWrt-AX3000T                   psk                 ****"
        // Format: [>] SSID SECURITY SIGNAL
        
        // Remove ANSI escape codes
        line = line.replace(/\x1b\[[0-9;]*m/g, '')
        
        // Check if this is the current network (has >)
        var isCurrent = line.indexOf(">") !== -1
        if (isCurrent) {
            line = line.replace(/>/g, '').trim()
        }
        
        // Split by multiple spaces to separate columns
        var parts = line.split(/\s{2,}/)
        if (parts.length < 3) return
        
        var ssid = parts[0].trim()
        var security = parts[1].trim()
        var signal = parts[2].trim()
        
        if (!ssid) return
        
        // Convert signal stars to percentage (rough estimate)
        var signalPercent = 0
        var starCount = (signal.match(/\*/g) || []).length
        signalPercent = Math.min(100, starCount * 25)
        
        var network = {
            ssid: ssid,
            security: security,
            signal: signalPercent,
            connected: isCurrent
        }
        
        if (isCurrent) {
            root.currentSsid = ssid
        }
        
        // Add to networks array
        root.networks.push(network)
        root.networksChanged()
    }

    function scan() {
        if (scanProcess.running) return
        scanProcess.running = false
        scanProcess.running = true
    }

    function connect(ssid) {
        if (connectProcess.running) return
        // For now, just use iwctl without password prompt
        // In production, you'd need a password dialog
        connectProcess.command = ["iwctl", "station", "wlan0", "connect", ssid]
        connectProcess.running = true
    }

    function disconnect() {
        if (disconnectProcess.running || reconnectProcess.running) return
        disconnectProcess.running = true
    }

    function reconnect(ssid) {
        if (reconnectProcess.running || !ssid) return
        reconnectProcess.command = [
            "sh", "-c",
            "iwctl station wlan0 disconnect && "
                + "iwctl station wlan0 scan && sleep 6 && "
                + "iwctl station wlan0 connect \"$1\"",
            "wifi-reconnect", ssid
        ]
        reconnectProcess.running = true
    }

    // Auto-scan on component creation
    Component.onCompleted: {
        Qt.callLater(scan)
    }
}
