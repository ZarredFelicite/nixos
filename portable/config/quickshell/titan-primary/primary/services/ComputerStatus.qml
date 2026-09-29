pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
    id: root

    // Computer definitions - adjust IPs/hostnames for your network
    property var computers: [
        { name: "nano", hostname: "nano", online: false, lastSeen: null },
        { name: "sankara", hostname: "sankara", online: false, lastSeen: null }
    ]

    // Public properties for easy access
    property bool nanoOnline: computers[0].online
    property bool sankaraOnline: computers[1].online
    property int onlineCount: (nanoOnline ? 1 : 0) + (sankaraOnline ? 1 : 0)

    // Reference counting for polling
    property int refCount: 0
    property int interval: 10000 // 10 seconds between pings

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

    function update() {
        if (root.refCount === 0) return
        
        // Ping each computer
        for (let i = 0; i < root.computers.length; i++) {
            pingComputer(i)
        }
    }

    function pingComputer(index) {
        const computer = root.computers[index]
        
        // Create process for ping with proper stdout handling per AGENTS.md
        const procCode = 'import Quickshell.Io; Process { running: false; stdout: SplitParser { onRead: function(data) { } } }'
        const proc = Qt.createQmlObject(procCode, root)
        
        proc.command = ["ping", "-c", "1", "-W", "3", computer.hostname]
        
        proc.onExited.connect(function(code) {
            const wasOnline = root.computers[index].online
            const isOnline = (code === 0)
            
            // Only update if changed to avoid unnecessary UI updates
            if (wasOnline !== isOnline) {
                let newComputers = [...root.computers]
                newComputers[index].online = isOnline
                newComputers[index].lastSeen = isOnline ? new Date() : newComputers[index].lastSeen
                root.computers = newComputers
                
                // Update convenience properties
                if (index === 0) root.nanoOnline = isOnline
                if (index === 1) root.sankaraOnline = isOnline
                
                // Recalculate online count
                root.onlineCount = (root.computers[0].online ? 1 : 0) + (root.computers[1].online ? 1 : 0)
            }
            
            // CRITICAL: Destroy process to prevent memory leak
            proc.destroy()
        })
        
        proc.running = true
    }

    // Get status text for tooltip
    function getStatusText(index) {
        const computer = root.computers[index]
        const status = computer.online ? "Online" : "Offline"
        const icon = computer.online ? "󰌘" : "󰌙"
        return `${icon} ${computer.name}: ${status}`
    }

    // Get tooltip text showing all computers
    function getTooltipText() {
        let text = "Computers\n"
        for (let i = 0; i < root.computers.length; i++) {
            text += getStatusText(i) + "\n"
        }
        return text.trim()
    }
}
