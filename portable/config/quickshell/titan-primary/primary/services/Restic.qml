pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
    id: root

    property bool backingUp: false
    property var snapshots: []
    property var stats: ({})
    property string lastStatus: "unknown"
    property bool checking: false
    property date lastUpdated: new Date(0)
    property string error: ""

    // Diff data
    property string diffOutput: ""
    property bool diffing: false

    property int intervalMs: 15 * 60 * 1000 // 15 minutes

    property Timer pollTimer: Timer {
        interval: root.intervalMs
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: refresh()

    function refresh() {
        if (checking) return
        checking = true
        error = ""
        
        let output = ""
        const procCode = 'import Quickshell.Io; Process { running: false; command: ["/home/zarred/.config/quickshell/primary/scripts/restic_quickshell.sh"]; stdout: SplitParser { onRead: function(data) { } } }'
        const proc = Qt.createQmlObject(procCode, root)
        
        proc.stdout.onRead.connect(function(data) {
            output += data.toString()
        })
        
        proc.onExited.connect(function(code) {
            if (code !== 0) {
                // If script fails, output might contain error from restic
                root.error = "Script exited with code " + code + ". " + output.substring(0, 100)
                root.lastStatus = "error"
            } else {
                try {
                    const data = JSON.parse(output)
                    root.backingUp = data.backingUp
                    root.snapshots = data.snapshots || []
                    root.stats = data.stats || {}
                    root.lastStatus = data.lastStatus
                    root.lastUpdated = new Date()
                    root.error = "" // Clear error on success
                } catch (e) {
                    root.error = "Parse failed: " + e + " | Output: " + output.substring(0, 100)
                    root.lastStatus = "error"
                }
            }
            root.checking = false
            proc.destroy()
        })
        
        proc.running = true
    }

    function getDiff(snapshotId1, snapshotId2) {
        if (diffing) return
        diffing = true
        diffOutput = "Calculating diff..."
        
        let output = ""
        const procCode = 'import Quickshell.Io; Process { running: false; stdout: SplitParser { onRead: function(data) { } } }'
        const proc = Qt.createQmlObject(procCode, root)
        
        // Wrap with SSH_AUTH_SOCK search for the diff command as well
        const cmd = `
            if [ -z "$SSH_AUTH_SOCK" ]; then
                for sock in "/run/user/$(id -u)/gnupg/S.gpg-agent.ssh" "/run/user/$(id -u)/ssh-agent.socket"; do
                    if [ -S "$sock" ]; then
                        export SSH_AUTH_SOCK="$sock"
                        break
                    fi
                done
            fi
            restic diff ${snapshotId1} ${snapshotId2}
        `
        proc.command = ["sh", "-c", cmd]
        
        proc.stdout.onRead.connect(function(data) {
            output += data.toString()
        })
        
        proc.onExited.connect(function(code) {
            root.diffOutput = output || "No changes found or error occurred."
            root.diffing = false
            proc.destroy()
        })
        
        proc.running = true
    }
}
