pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    readonly property string configPath: String(Quickshell.env("HOME") || "")
                                         + "/.config/home-assistant/config.json"
    readonly property string presetPath: String(Quickshell.env("HOME") || "")
                                         + "/.config/quickshell/home-assistant-beam-presets.json"

    property bool configured: false
    property bool available: false
    property bool loading: false
    property bool actionBusy: false
    property string error: ""

    property string beamState: "unknown"
    property string beam1State: "unknown"
    property string beam2State: "unknown"
    property real beamHue: 0
    property real beamSaturation: 0
    property real beamBrightnessPct: 100
    property bool beamColorReady: false
    property var presets: [null, null, null, null, null]

    property string _apiUrl: ""
    property string _token: ""
    property var _actionXhr: null
    property var _stateXhrs: ({})
    property int _pendingRequests: 0

    readonly property var entities: [
        "light.beam",
        "light.beam_1",
        "light.beam_2"
    ]

    property FileView configFile: FileView {
        path: root.configPath
        preload: true
        watchChanges: true
        printErrors: false

        onLoaded: root._readConfig(text())
        onLoadFailed: root._setConfigError("Home Assistant config unavailable")
        onFileChanged: reload()
    }

    property FileView presetFile: FileView {
        path: root.presetPath
        preload: true
        printErrors: false
        blockWrites: true
        atomicWrites: true

        onLoaded: {
            root._readPresets(text())
            root._writePendingPresets()
        }
        onLoadFailed: {
            root._presetsLoaded = true
            root._writePendingPresets()
        }
        onSaveFailed: root.error = "Beam preset save failed"
    }

    property bool _presetsLoaded: false
    property bool _presetSavePending: false

    property Timer pollTimer: Timer {
        interval: 10000
        repeat: true
        running: true
        onTriggered: root.configured ? root.refresh() : root.configFile.reload()
    }

    function _readConfig(raw) {
        try {
            var config = JSON.parse(String(raw || ""))
            var url = String(config.url || "").trim().replace(/\/+$/, "")
            var token = String(config.token || "").trim()
            if (!url || !token)
                throw new Error("missing url or token")

            _apiUrl = url
            _token = token
            configured = true
            error = ""
            refresh()
        } catch (e) {
            _setConfigError("Home Assistant config invalid")
        }
    }

    function loadConfig() {
        if (!configured)
            configFile.reload()
    }

    function _readPresets(raw) {
        var loaded = [null, null, null, null, null]
        try {
            var parsed = JSON.parse(String(raw || ""))
            var entries = Array.isArray(parsed) ? parsed : parsed.presets
            if (Array.isArray(entries)) {
                for (var i = 0; i < Math.min(5, entries.length); i++) {
                    var preset = entries[i]
                    if (preset && isFinite(Number(preset.hue))
                            && isFinite(Number(preset.saturation))
                            && isFinite(Number(preset.brightness))) {
                        loaded[i] = _normalizePreset(preset)
                    }
                }
            }
        } catch (e) {
            // Missing or malformed presets fall back to empty slots.
        }
        presets = loaded
        _presetsLoaded = true
    }

    function _normalizePreset(preset) {
        var hue = Number(preset.hue) % 360
        if (hue < 0) hue += 360
        return {
            hue: hue,
            saturation: Math.max(0, Math.min(100, Number(preset.saturation))),
            brightness: Math.max(0, Math.min(100, Number(preset.brightness)))
        }
    }

    function presetAt(index) {
        return index >= 0 && index < 5 ? presets[index] : null
    }

    function savePreset(index, hue, saturation, brightness) {
        if (index < 0 || index >= 5)
            return
        var next = presets.slice(0)
        next[index] = _normalizePreset({
            hue: hue,
            saturation: saturation,
            brightness: brightness
        })
        presets = next
        if (_presetsLoaded)
            _writePresets()
        else
            _presetSavePending = true
    }

    function _writePendingPresets() {
        if (!_presetSavePending)
            return
        _presetSavePending = false
        _writePresets()
    }

    function _writePresets() {
        presetFile.setText(JSON.stringify({ "presets": presets }, null, 2))
    }

    function applyPreset(index) {
        var preset = presetAt(index)
        if (preset)
            applyBeamColor(preset.hue, preset.saturation, preset.brightness)
    }

    function _setConfigError(message) {
        configured = false
        available = false
        loading = false
        _apiUrl = ""
        _token = ""
        error = message
    }

    function refresh() {
        if (!configured) {
            loadConfig()
            return
        }
        if (loading)
            return

        loading = true
        available = false
        error = ""
        _pendingRequests = 0
        for (var i = 0; i < entities.length; i++)
            _requestState(entities[i])
        if (_pendingRequests === 0)
            loading = false
    }

    function _requestState(entityId) {
        var existing = _stateXhrs[entityId]
        if (existing && existing.readyState !== XMLHttpRequest.DONE)
            return

        var xhr = new XMLHttpRequest()
        _stateXhrs[entityId] = xhr
        _pendingRequests++
        xhr.timeout = 5000
        xhr.onreadystatechange = function() {
            if (root._stateXhrs[entityId] !== xhr || xhr.readyState !== XMLHttpRequest.DONE)
                return

            root._stateXhrs[entityId] = null
            if (xhr.status >= 200 && xhr.status < 300) {
                try {
                    var response = JSON.parse(String(xhr.responseText || ""))
                    root._setState(entityId, String(response.state || "unknown"), response.attributes || {})
                    root.available = true
                } catch (e) {
                    root.error = "Beam state response invalid"
                }
            } else {
                root.error = "Beam state request failed"
            }
            root._finishStateRequest()
        }
        xhr.onerror = function() {
            if (root._stateXhrs[entityId] !== xhr)
                return
            root._stateXhrs[entityId] = null
            root.error = "Home Assistant unavailable"
            root._finishStateRequest()
        }
        xhr.ontimeout = function() {
            if (root._stateXhrs[entityId] !== xhr)
                return
            root._stateXhrs[entityId] = null
            root.error = "Home Assistant request timed out"
            root._finishStateRequest()
        }
        xhr.open("GET", _apiUrl + "/api/states/" + entityId, true)
        xhr.setRequestHeader("Authorization", "Bearer " + _token)
        xhr.send()
    }

    function _finishStateRequest() {
        _pendingRequests = Math.max(0, _pendingRequests - 1)
        if (_pendingRequests === 0)
            loading = false
    }

    function _setState(entityId, state, attributes) {
        if (entityId === "light.beam") {
            beamState = state
            var brightness = Number(attributes.brightness)
            if (!isFinite(brightness) && isFinite(Number(attributes.brightness_pct)))
                brightness = Number(attributes.brightness_pct) * 2.55
            if (isFinite(brightness))
                beamBrightnessPct = Math.max(0, Math.min(100, brightness / 2.55))

            var hs = attributes.hs_color
            if (Array.isArray(hs) && hs.length >= 2 && isFinite(Number(hs[0]))
                    && isFinite(Number(hs[1]))) {
                beamHue = _normalizePreset({ hue: hs[0], saturation: hs[1], brightness: 0 }).hue
                beamSaturation = Math.max(0, Math.min(100, Number(hs[1])))
                beamColorReady = true
            } else {
                beamColorReady = false
            }
        } else if (entityId === "light.beam_1") {
            beam1State = state
        } else if (entityId === "light.beam_2") {
            beam2State = state
        }
    }

    function toggle(entityId) {
        _sendLightService("light.toggle", { "entity_id": entityId }, "Beam update failed")
    }

    function applyBeamColor(hue, saturation, brightness) {
        if (!configured || actionBusy)
            return
        var preset = _normalizePreset({ hue: hue, saturation: saturation, brightness: brightness })
        _sendLightService("light.turn_on", {
            "entity_id": "light.beam",
            "hs_color": [preset.hue, preset.saturation],
            "brightness_pct": Math.max(1, Math.round(preset.brightness))
        }, "Beam color update failed")
    }

    function _sendLightService(service, payload, failureMessage) {
        if (!configured || actionBusy)
            return

        actionBusy = true
        error = ""
        if (_actionXhr && _actionXhr.readyState !== XMLHttpRequest.DONE)
            _actionXhr.abort()

        var xhr = new XMLHttpRequest()
        _actionXhr = xhr
        xhr.timeout = 5000
        xhr.onreadystatechange = function() {
            if (root._actionXhr !== xhr || xhr.readyState !== XMLHttpRequest.DONE)
                return
            root._actionXhr = null
            root.actionBusy = false
            if (xhr.status >= 200 && xhr.status < 300)
                root.refresh()
            else
                root.error = failureMessage
        }
        xhr.onerror = function() {
            if (root._actionXhr !== xhr)
                return
            root._actionXhr = null
            root.actionBusy = false
            root.error = failureMessage
        }
        xhr.ontimeout = function() {
            if (root._actionXhr !== xhr)
                return
            root._actionXhr = null
            root.actionBusy = false
            root.error = failureMessage + " timed out"
        }
        xhr.open("POST", _apiUrl + "/api/services/" + service.replace(".", "/"), true)
        xhr.setRequestHeader("Authorization", "Bearer " + _token)
        xhr.setRequestHeader("Content-Type", "application/json")
        xhr.send(JSON.stringify(payload))
    }
}
