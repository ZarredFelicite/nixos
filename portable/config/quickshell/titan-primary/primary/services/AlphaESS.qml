pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    // Configuration
    readonly property string scriptPath: (function() {
        var resolved = Qt.resolvedUrl("../scripts/alphaess_status.py")
        var path = resolved
        if (resolved && resolved.toString)
            path = resolved.toString()
        return String(path).replace(/^file:\/\//, "")
    })()
    property string systemSerial: ""
    readonly property bool lowPowerMode: Quickshell.env("QUICKSHELL_LOW_POWER_MODE") === "1"
    readonly property int pollIntervalMs: lowPowerMode ? 120 * 1000 : 10 * 1000

    // State
    property bool loading: false
    property bool available: false
    property string error: ""
    property real solarWatts: Number.NaN
    property real batteryWatts: Number.NaN
    property real loadWatts: Number.NaN
    property real gridWatts: Number.NaN
    property real batterySoc: Number.NaN
    property string systemName: ""
    property string serial: ""
    property string model: ""
    property string batteryModel: ""
    property date lastUpdated: new Date(0)

    property Timer pollTimer: Timer {
        interval: root.pollIntervalMs
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    property string _pendingOutput: ""
    property string _pendingError: ""

    function refresh() {
        if (loading)
            return

        loading = true
        error = ""
        _pendingOutput = ""
        _pendingError = ""

        var command = ["python3", scriptPath]
        if (systemSerial && systemSerial.length > 0) {
            command.push("--sys-sn")
            command.push(systemSerial)
        }

        alphaProc.running = false
        alphaProc.command = command
        alphaProc.running = true
    }

    function _appendOutput(chunk) {
        if (!chunk)
            return
        _pendingOutput += chunk
    }

    function _appendError(chunk) {
        if (!chunk)
            return
        _pendingError += chunk
    }

    function _finalizeProcess(exitCode) {
        loading = false

        if (exitCode !== 0) {
            var detail = (_pendingError || "").trim()
            if (!detail)
                detail = "alphaess_status failed (" + exitCode + ")"
            _setError(detail)
            return
        }

        var trimmed = (_pendingOutput || "").trim()
        if (!trimmed) {
            _setError("alphaess_status returned empty payload")
            return
        }

        try {
            var data = JSON.parse(trimmed)
            _applySnapshot(data)
        } catch (e) {
            _setError("alphaess_status parse error: " + e)
        }
    }

    function _applySnapshot(data) {
        var power = data.power_watts || {}
        solarWatts = _toNumber(power.solar)
        batteryWatts = _toNumber(power.battery)
        loadWatts = _toNumber(power.load)
        gridWatts = _toNumber(power.grid)
        batterySoc = _toNumber(data.battery_soc)
        systemName = data.system_name || ""
        serial = data.serial || ""
        model = data.model || ""
        batteryModel = data.battery_model || ""
        available = true
        error = ""
        var ts = Number(data.timestamp)
        lastUpdated = isNaN(ts) ? new Date() : new Date(ts * 1000)
    }

    function _toNumber(value) {
        if (value === null || value === undefined)
            return Number.NaN
        var num = Number(value)
        return isNaN(num) ? Number.NaN : num
    }

    function wattsToKw(value) {
        var num = Number(value)
        if (isNaN(num))
            return Number.NaN
        return num / 1000.0
    }

    function hasValidPower(value) {
        return !isNaN(value)
    }

    function _setError(message) {
        error = message
        console.warn("[AlphaESS]", message)
    }

    property Process alphaProc: Process {
        id: alphaProc
        running: false
        stdout: SplitParser {
            onRead: function(chunk) {
                root._appendOutput(chunk)
            }
        }
        stderr: SplitParser {
            onRead: function(chunk) {
                root._appendError(chunk)
            }
        }
        onExited: function(code) {
            root._finalizeProcess(code)
        }
    }

    Component.onCompleted: refresh()
}
