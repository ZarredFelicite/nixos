pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int failedCount: 0
    property string failedUnits: ""
    property bool hasFailures: failedCount > 0

    readonly property string displayText: hasFailures ? `✗ ${failedCount}` : ""
    readonly property string tooltipText: hasFailures ? 
        `Failed systemd units (${failedCount}):\n${failedUnits}` : 
        "No failed systemd units"

    property int refCount: 0

    Timer {
        id: updateTimer
        interval: 30000  // Check every 30 seconds
        running: root.refCount > 0
        repeat: true
        triggeredOnStart: true
        onTriggered: root.checkFailedUnits()
    }

    function checkFailedUnits() {
        // Use a shell command to get failed units (more reliable than separate systemctl calls)
        const proc = Qt.createQmlObject('import Quickshell.Io; Process { running: false; stdout: SplitParser { onRead: function(data) { } } }', root)
        proc.command = ["sh", "-c", "systemctl --failed --no-legend --plain; systemctl --user --failed --no-legend --plain | sed 's/^/(user) /'"]

        let output = ""
        proc.stdout.onRead.connect(function(data) {
            output += data.toString()
        })

        proc.onExited.connect(function() {
            let allFailed = []
            if (output.trim()) {
                allFailed = output.trim().split('\n').filter(line => line.trim())
            }
            
            root.failedCount = allFailed.length
            root.failedUnits = allFailed.join('\n')
            proc.destroy()
        })
        
        proc.running = true
    }

    function refresh() {
        checkFailedUnits()
    }
}
