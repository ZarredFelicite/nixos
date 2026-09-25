pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property int refCount: 0
    property bool loading: false
    property bool available: false
    property string error: ""
    property string version: ""
    property int connected: 0
    property int working: 0
    property int needsAttention: 0
    property int idle: 0
    property int unread: 0
    property int totalSessions: 0
    property var sessions: []
    property int lastUpdated: 0
    property string _buffer: ""
    property string _errors: ""

    readonly property string apiUrl: "http://100.64.1.150:9998"
    readonly property string publicUrl: "https://sankara.manticore-lenok.ts.net:10000"
    readonly property string scriptPath: String(Quickshell.env("HOME") || "")
                                         + "/.config/quickshell/primary/scripts/pi_dashboard_status.py"

    property Timer pollTimer: Timer {
        interval: 5000
        repeat: true
        running: root.refCount > 0
        onTriggered: root.refresh()
    }

    property Process statusProcess: Process {
        running: false
        stdout: SplitParser { onRead: function(data) { root._buffer += data } }
        stderr: SplitParser { onRead: function(data) { root._errors += data } }
        onExited: function(code) { root._handleComplete(code) }
    }

    onRefCountChanged: {
        if (refCount > 0 && !loading)
            refresh()
    }

    function refresh() {
        if (loading)
            return
        loading = true
        _buffer = ""
        _errors = ""
        statusProcess.command = ["python3", scriptPath, "--url", apiUrl]
        statusProcess.running = true
    }

    function _handleComplete(code) {
        loading = false
        lastUpdated = Date.now()
        var raw = String(_buffer || "").trim()
        _buffer = ""
        if (code !== 0 || raw === "") {
            available = false
            error = String(_errors || "").trim() || "Pi Dashboard is unavailable"
            _errors = ""
            return
        }
        _errors = ""

        try {
            var parsed = JSON.parse(raw)
            available = parsed.ok === true
            error = available ? "" : "Pi Dashboard reported an error"
            version = parsed.version || ""
            connected = Number(parsed.connected || 0)
            working = Number(parsed.working || 0)
            needsAttention = Number(parsed.needsAttention || 0)
            idle = Number(parsed.idle || 0)
            unread = Number(parsed.unread || 0)
            totalSessions = Number(parsed.totalSessions || 0)
            sessions = parsed.sessions || []
        } catch (e) {
            available = false
            error = "Could not parse Pi Dashboard status"
        }
    }
}
