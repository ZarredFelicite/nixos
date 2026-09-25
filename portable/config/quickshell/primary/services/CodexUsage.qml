pragma Singleton

import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property int refCount: 0
    property bool loading: false
    property bool available: false
    property string error: ""
    property string planType: ""
    property var primary: null
    property var secondary: null
    property var credits: null
    property int lastUpdated: 0
    property string _buffer: ""

    readonly property string scriptPath: "/home/zarred/.config/quickshell/primary/scripts/codex_usage.py"

    property Timer pollTimer: Timer {
        interval: 900000
        repeat: true
        running: root.refCount > 0
        onTriggered: root.refresh(false)
    }

    property Process usageProcess: Process {
        id: usageProcess
        running: false
        stdout: SplitParser {
            onRead: function(data) {
                root._buffer += data
            }
        }
        stderr: SplitParser {
            onRead: function(data) {
                root._buffer += data
            }
        }
        onExited: function(code) {
            root._handleComplete(code)
        }
    }

    onRefCountChanged: {
        if (refCount > 0 && lastUpdated === 0 && !loading) {
            refresh(false)
        }
    }

    function refresh(manual) {
        if (loading) return
        loading = true
        error = ""
        _buffer = ""
        usageProcess.running = false
        usageProcess.command = ["python3", scriptPath]
        usageProcess.running = true
    }

    function reset() {
        available = false
        planType = ""
        primary = null
        secondary = null
        credits = null
    }

    function _handleComplete(code) {
        loading = false
        var raw = (_buffer || "").trim()
        _buffer = ""
        lastUpdated = Date.now()

        if (!raw) {
            error = code === 0 ? "No Codex usage data returned" : ("Codex usage check failed (" + code + ")")
            reset()
            return
        }

        var start = raw.indexOf("{")
        if (start > 0) raw = raw.slice(start)

        try {
            var parsed = JSON.parse(raw)
            if (!parsed.ok) {
                error = parsed.error || "Codex usage unavailable"
                reset()
                return
            }
            available = true
            error = ""
            planType = parsed.plan_type || ""
            primary = parsed.primary || null
            secondary = parsed.secondary || null
            credits = parsed.credits || null
        } catch (e) {
            error = "Failed to parse Codex usage"
            reset()
        }
    }
}
