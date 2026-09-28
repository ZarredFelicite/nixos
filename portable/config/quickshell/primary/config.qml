pragma Singleton
import QtQuick

QtObject {
    id: config

    property string primaryMonitorModel: ""
    property string primaryMonitorSerialNumber: ""
    property var fallbackMonitors: []
    property bool showFullBarOnPrimary: true
    property bool showWorkspacesOnlyOnSecondary: true
    property bool debugPopoutsEnabled: false
    property string debugPopoutName: ""
    property string debugPopoutAnchorObjectName: ""
    property int debugPopoutDelayMs: 2000
    property bool debugPopoutKeepOpen: true

    function _getArgValue(args, key) {
        if (!args || args.length === 0) return ""
        var prefix = "--" + key + "="
        for (var i = 0; i < args.length; i++) {
            var a = args[i]
            if (a.indexOf(prefix) === 0) return a.slice(prefix.length)
            if (a === "--" + key && i + 1 < args.length) return args[i + 1]
        }
        return ""
    }

    function _hasArg(args, key) {
        if (!args || args.length === 0) return false
        var flag = "--" + key
        for (var i = 0; i < args.length; i++) {
            if (args[i] === flag) return true
        }
        return false
    }

    function _applyDebugPopoutArgs() {
        var args = (Qt.application && Qt.application.arguments) ? Qt.application.arguments : []
        if (!args || args.length === 0) return

        var name = _getArgValue(args, "debug-popout")
        if (name) {
            debugPopoutName = name
            debugPopoutsEnabled = true
        }

        var delayStr = _getArgValue(args, "debug-popout-delay")
        if (delayStr) {
            var delayInt = parseInt(delayStr)
            if (!isNaN(delayInt) && delayInt >= 0) debugPopoutDelayMs = delayInt
        }

        var anchor = _getArgValue(args, "debug-popout-anchor")
        if (anchor) debugPopoutAnchorObjectName = anchor

        if (_hasArg(args, "debug-popout-keep-open")) debugPopoutKeepOpen = true
        if (_hasArg(args, "debug-popout-allow-close")) debugPopoutKeepOpen = false
    }

    function _applyDebugPopoutEnv(envLines) {
        var lines = envLines || []
        for (var i = 0; i < lines.length; i++) {
            var line = (lines[i] || "").trim()
            if (!line) continue
            var idx = line.indexOf("=")
            if (idx === -1) continue
            var key = line.slice(0, idx)
            var value = line.slice(idx + 1)

            if (key === "DEBUG_POPOUT" && value) {
                debugPopoutName = value
                debugPopoutsEnabled = true
            }
            if (key === "DEBUG_DELAY" && value) {
                var delayInt = parseInt(value)
                if (!isNaN(delayInt) && delayInt >= 0) debugPopoutDelayMs = delayInt
            }
            if (key === "DEBUG_ANCHOR" && value) {
                debugPopoutAnchorObjectName = value
            }
            if (key === "DEBUG_KEEP" && value) {
                var lower = value.toLowerCase()
                if (lower === "1" || lower === "true" || lower === "yes" || lower === "on") {
                    debugPopoutKeepOpen = true
                } else if (lower === "0" || lower === "false" || lower === "no" || lower === "off") {
                    debugPopoutKeepOpen = false
                }
            }
        }

        if (debugPopoutsEnabled) {
            console.log("[DebugPopout] env applied name=", debugPopoutName,
                        "delay=", debugPopoutDelayMs,
                        "anchor=", debugPopoutAnchorObjectName,
                        "keepOpen=", debugPopoutKeepOpen)
        }
    }

    Component.onCompleted: {
        _applyDebugPopoutArgs()
        var envLines = []
        var procCode = 'import Quickshell.Io; Process { running: false; stdout: SplitParser { onRead: function(line) { } } }'
        var proc = Qt.createQmlObject(procCode, config)
        proc.stdout.onRead.connect(function(line) {
            envLines = envLines.concat(line.toString().split(/\n+/))
        })
        proc.onExited.connect(function() {
            config._applyDebugPopoutEnv(envLines)
            proc.destroy()
        })
        proc.command = ["env", "sh", "-c", "printf 'DEBUG_POPOUT=%s\\nDEBUG_DELAY=%s\\nDEBUG_ANCHOR=%s\\nDEBUG_KEEP=%s\\n' \"${QUICKSHELL_DEBUG_POPOUT:-}\" \"${QUICKSHELL_DEBUG_POPOUT_DELAY:-}\" \"${QUICKSHELL_DEBUG_POPOUT_ANCHOR:-}\" \"${QUICKSHELL_DEBUG_POPOUT_KEEP_OPEN:-}\"" ]
        proc.running = true
    }

    function isPrimaryScreen(screen) {
        if (!screen) return false
        if (primaryMonitorSerialNumber && screen.serialNumber === primaryMonitorSerialNumber) {
            return true
        }
        return primaryMonitorModel && screen.model === primaryMonitorModel
    }

    function resolvePrimaryMonitor(availableScreens) {
        for (let i = 0; i < availableScreens.length; i++) {
            if (isPrimaryScreen(availableScreens[i])) return availableScreens[i].name
        }

        let availableMonitorNames = []
        for (let i = 0; i < availableScreens.length; i++) {
            availableMonitorNames.push(availableScreens[i].name)
        }
        for (let i = 0; i < fallbackMonitors.length; i++) {
            if (availableMonitorNames.includes(fallbackMonitors[i])) return fallbackMonitors[i]
        }
        return availableMonitorNames.length > 0 ? availableMonitorNames[0] : ""
    }
}
