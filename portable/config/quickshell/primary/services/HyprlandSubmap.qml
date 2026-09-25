pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    property string currentSubmap: ""
    property bool hasSubmap: currentSubmap !== ""

    readonly property string displayText: hasSubmap ? ` ${currentSubmap}` : ""
    readonly property string tooltipText: hasSubmap ? `Submap: ${currentSubmap}` : "No active submap"

    property int refCount: 0

    // Listen to Hyprland raw events when active
    Connections {
        target: root.refCount > 0 ? Hyprland : null
        function onRawEvent(event) {
            if (event.name === "submap") {
                // Parse the submap event data
                const submapName = event.data.trim()
                root.currentSubmap = submapName
            }
        }
    }

    // Initialize current submap state when first activated
    Timer {
        id: initTimer
        interval: 100
        running: false
        repeat: false
        onTriggered: root.refreshSubmap()
    }

    onRefCountChanged: {
        if (refCount > 0 && refCount === 1) {
            // First activation - get current state
            initTimer.start()
        } else if (refCount === 0) {
            // No longer needed - clear state
            root.currentSubmap = ""
        }
    }

    function refreshSubmap() {
        // Query current submap via hyprctl
        const proc = Qt.createQmlObject('import Quickshell.Io; Process { }', root)
        proc.command = ["hyprctl", "getoption", "general:submap", "-j"]
        proc.running = true
        
        proc.exited.connect(function() {
            if (proc.exitCode === 0) {
                try {
                    const result = JSON.parse(proc.stdout.trim())
                    // The submap option contains the current submap name
                    root.currentSubmap = result.str || ""
                } catch (e) {
                    // Fallback - assume no submap if parsing fails
                    root.currentSubmap = ""
                }
            }
            // CRITICAL: Destroy process to prevent memory leak
            proc.destroy()
        })
    }
}