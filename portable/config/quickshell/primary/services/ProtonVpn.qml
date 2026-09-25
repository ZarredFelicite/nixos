pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
    id: root

    property string systemctlPath: "/run/current-system/sw/bin/systemctl"
    property string serviceName: selectedLocation.service
    property var locations: [
        { label: "Default", service: "wg-quick-proton.service" },
        { label: "Australia", service: "wg-quick-proton-au.service" },
        { label: "New Zealand", service: "wg-quick-proton-nz.service" },
        { label: "United States", service: "wg-quick-proton-us.service" },
        { label: "United Kingdom", service: "wg-quick-proton-uk.service" },
        { label: "Japan", service: "wg-quick-proton-jp.service" },
        { label: "Netherlands", service: "wg-quick-proton-nl.service" },
        { label: "Germany", service: "wg-quick-proton-de.service" },
        { label: "Singapore", service: "wg-quick-proton-sg.service" }
    ]
    property int selectedLocationIndex: 0
    readonly property var selectedLocation: locations[selectedLocationIndex] || locations[0]
    readonly property string selectedLocationLabel: selectedLocation.label || "Default"
    property bool active: false
    property bool busy: false
    property string activeState: "unknown"
    property string subState: "unknown"
    property string loadState: "unknown"
    property string activeServiceName: ""
    property string error: ""
    property date lastUpdated: new Date(0)

    property int refCount: 0
    property int interval: 10000

    readonly property string statusText: {
        if (busy) return active ? "Disconnecting…" : "Connecting…"
        if (active) return "Connected"
        if (activeState === "failed") return "Failed"
        if (activeState === "activating") return "Connecting…"
        if (activeState === "deactivating") return "Disconnecting…"
        return "Disconnected"
    }

    property string _statusBuffer: ""

    Component.onCompleted: refresh()

    onRefCountChanged: {
        pollTimer.running = (root.refCount > 0)
        if (root.refCount > 0) refresh()
    }

    property Timer pollTimer: Timer {
        id: pollTimer
        interval: root.interval
        running: false
        repeat: true
        onTriggered: root.refresh()
    }

    property Process statusProc: Process {
        id: statusProc
        running: false
        command: []
        stdout: SplitParser {
            onRead: function(data) {
                root._statusBuffer += data.toString() + "\n"
            }
        }
        onExited: function(code) {
            root._applyStatus(root._statusBuffer)
            root._statusBuffer = ""
            root.lastUpdated = new Date()
        }
    }

    property Process toggleProc: Process {
        id: toggleProc
        running: false
        stdout: SplitParser {
            onRead: function(data) {
                root.error = data.toString().trim()
            }
        }
        stderr: SplitParser {
            onRead: function(data) {
                var msg = data.toString().trim()
                if (msg) root.error = msg
            }
        }
        onExited: function(code) {
            console.log("[ProtonVpn] toggle exited", code, "error=", root.error)
            root.busy = false
            if (code !== 0 && !root.error) {
                root.error = "VPN toggle failed"
            }
            refreshDelay.restart()
        }
    }

    property Timer refreshDelay: Timer {
        id: refreshDelay
        interval: 500
        repeat: false
        onTriggered: root.refresh()
    }

    function _applyStatus(output) {
        var map = {}
        var lines = (output || "").split(/\n/)
        for (var i = 0; i < lines.length; ++i) {
            var line = lines[i].trim()
            if (!line) continue
            var idx = line.indexOf("=")
            if (idx === -1) continue
            map[line.slice(0, idx)] = line.slice(idx + 1)
        }

        root.loadState = map.LoadState || "unknown"
        root.activeState = map.ActiveState || "unknown"
        root.subState = map.SubState || "unknown"
        root.activeServiceName = map.ActiveService || ""
        root.active = root.activeServiceName !== "" || root.activeState === "active" || root.subState === "exited"

        if (root.activeServiceName !== "") {
            for (var j = 0; j < root.locations.length; ++j) {
                if (root.locations[j].service === root.activeServiceName) {
                    root.selectedLocationIndex = j
                    break
                }
            }
        }

        if (root.loadState === "not-found") {
            root.error = `Missing service: ${root.serviceName}`
        } else if (root.activeState !== "failed" && !root.busy) {
            root.error = ""
        }
    }

    function _quotedServices() {
        var services = []
        for (var i = 0; i < root.locations.length; ++i) {
            services.push("'" + root.locations[i].service.replace(/'/g, "'\\''") + "'")
        }
        return services.join(" ")
    }

    function _statusCommand() {
        return `selected='${root.serviceName}'
active_service=''
for unit in ${root._quotedServices()}; do
  load=$(${root.systemctlPath} show "$unit" --property=LoadState --value 2>/dev/null || true)
  active=$(${root.systemctlPath} is-active "$unit" 2>/dev/null || true)
  sub=$(${root.systemctlPath} show "$unit" --property=SubState --value 2>/dev/null || true)
  if [ "$unit" = "$selected" ]; then
    printf 'LoadState=%s\nActiveState=%s\nSubState=%s\n' "$load" "$active" "$sub"
  fi
  if [ -z "$active_service" ] && { [ "$active" = active ] || [ "$sub" = exited ]; }; then
    active_service=$unit
  fi
done
printf 'ActiveService=%s\n' "$active_service"`
    }

    function _stopAllCommand() {
        return `${root.systemctlPath} --no-ask-password stop ${root._quotedServices()} >/dev/null 2>&1 || true`
    }

    function refresh() {
        // Avoid killing/restarting systemctl checks; that can churn the QML/process layer
        // and contribute to freezes if systemctl is slow or temporarily stuck.
        if (statusProc.running) return
        root._statusBuffer = ""
        statusProc.command = ["/run/current-system/sw/bin/sh", "-lc", root._statusCommand()]
        statusProc.running = true
    }

    function connectVpn() {
        connectLocation(root.selectedLocationIndex)
    }

    function connectLocation(index) {
        if (toggleProc.running || index < 0 || index >= root.locations.length) return
        root.selectedLocationIndex = index
        console.log("[ProtonVpn] connect location requested", root.selectedLocationLabel)
        root.busy = true
        root.error = ""
        toggleProc.command = [
            "/run/current-system/sw/bin/sh",
            "-lc",
            `${root._stopAllCommand()}; exec ${root.systemctlPath} --no-ask-password start '${root.serviceName}'`
        ]
        toggleProc.running = true
    }

    function disconnectVpn() {
        if (toggleProc.running) return
        console.log("[ProtonVpn] disconnect requested")
        root.busy = true
        root.error = ""
        toggleProc.command = ["/run/current-system/sw/bin/sh", "-lc", root._stopAllCommand()]
        toggleProc.running = true
    }

    function toggle() {
        if (root.busy) {
            console.log("[ProtonVpn] toggle ignored: busy")
            return
        }
        console.log("[ProtonVpn] toggle clicked; active=", root.active, "state=", root.activeState, "sub=", root.subState)
        if (root.active) disconnectVpn()
        else connectVpn()
    }
}
