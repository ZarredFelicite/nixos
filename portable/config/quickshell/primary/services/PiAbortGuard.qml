pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property bool enabled: true
    property int modelStallMs: 90000
    property int maxModelRetries: 2
    property bool ready: false
    property bool saving: false
    property string error: ""
    property var _pending: ({})
    property string _stderr: ""

    readonly property string configPath: {
        var state = String(Quickshell.env("XDG_STATE_HOME") || "").trim()
        if (state === "")
            state = String(Quickshell.env("HOME") || "") + "/.local/state"
        return state + "/pi/abort-guard.json"
    }
    readonly property string scriptPath: String(Quickshell.env("HOME") || "")
                                         + "/.config/quickshell/primary/scripts/pi_abort_guard_config.py"

    property FileView configFile: FileView {
        path: root.configPath
        preload: true
        watchChanges: true
        printErrors: false

        onLoaded: root._read(text())
        onLoadFailed: function(_) {
            root.ready = false
            root.error = "Pi abort-guard config is unavailable"
        }
        onFileChanged: {
            if (!root.saving)
                reload()
        }
    }

    property Timer saveTimer: Timer {
        interval: 100
        repeat: false
        onTriggered: root._savePending()
    }

    property Process saveProcess: Process {
        running: false
        stdout: SplitParser { onRead: function(_) {} }
        stderr: SplitParser {
            onRead: function(data) { root._stderr += data }
        }
        onExited: function(code) {
            root.saving = false
            if (code !== 0)
                root.error = root._stderr.trim() || "Could not save Pi abort-guard settings"
            else
                root.error = ""

            if (Object.keys(root._pending).length > 0)
                root.saveTimer.restart()
            else
                root.configFile.reload()
        }
    }

    function _read(raw) {
        try {
            var parsed = JSON.parse(String(raw || ""))
            enabled = parsed.enabled !== false
            modelStallMs = Math.max(5000, Math.min(3600000, Number(parsed.modelStallMs ?? 90000)))
            maxModelRetries = Math.max(0, Math.min(10, Number(parsed.maxModelRetries ?? 2)))
            ready = true
            error = ""
        } catch (e) {
            ready = false
            error = "Pi abort-guard config contains invalid JSON"
        }
    }

    function setSetting(key, value) {
        if (["enabled", "modelStallMs", "maxModelRetries"].indexOf(key) < 0)
            return

        root[key] = value
        var next = Object.assign({}, _pending)
        next[key] = value
        _pending = next
        error = ""
        saveTimer.restart()
    }

    function _savePending() {
        if (saving || Object.keys(_pending).length === 0)
            return

        var updates = _pending
        _pending = ({})
        _stderr = ""
        saving = true
        saveProcess.command = ["python3", scriptPath, "--path", configPath,
                               "--update", JSON.stringify(updates)]
        saveProcess.running = true
    }
}
