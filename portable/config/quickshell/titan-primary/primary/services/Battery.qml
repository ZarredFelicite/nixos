pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property string batteryName: ""
    property string batteryPath: ""
    property bool _discovered: false

    property int capacity: 0
    property int powerWatts: 0
    property real powerWattsExact: 0.0
    property string status: "Unknown"
    property real voltageVolts: 0.0
    property real currentAmps: 0.0
    property real energyNowWh: 0.0
    property real energyFullWh: 0.0
    property real energyFullDesignWh: 0.0
    property int cycleCount: -1
    property string manufacturer: ""
    property string modelName: ""
    property string technology: ""
    property bool available: false
    property date lastUpdated: new Date(0)

    readonly property int healthPercent: energyFullDesignWh > 0
        ? Math.max(0, Math.min(100, Math.round((energyFullWh / energyFullDesignWh) * 100)))
        : -1

    readonly property bool isCharging: status === "Charging"
    readonly property bool isDischarging: status === "Discharging"
    readonly property bool isFull: status === "Full" || (capacity >= 99 && status !== "Discharging")

    // Estimated seconds until full (charging) or empty (discharging). -1 if unknown / not applicable.
    readonly property int timeRemainingSeconds: {
        if (powerWattsExact <= 0.05) return -1
        if (isCharging) {
            var remainingWh = energyFullWh - energyNowWh
            if (remainingWh <= 0) return 0
            return Math.round((remainingWh / powerWattsExact) * 3600)
        }
        if (isDischarging && energyNowWh > 0) {
            return Math.round((energyNowWh / powerWattsExact) * 3600)
        }
        return -1
    }

    readonly property string tooltipText: available
        ? `Battery: ${capacity}%\nStatus: ${status}\nPower: ${powerWatts}W\nVoltage: ${voltageVolts.toFixed(2)}V`
        : "No battery detected"

    property int refCount: 0

    property Timer updateTimer: Timer {
        interval: 5000
        running: root.refCount > 0 && (!root._discovered || root.batteryName.length > 0)
        repeat: true
        triggeredOnStart: true
        onTriggered: root.update()
    }

    // Discover laptop battery once. Falls back to BAT0.
    property Process discoverProc: Process {
        running: false
        command: ["sh", "-c", "for d in /sys/class/power_supply/*; do n=$(basename \"$d\"); [ -f \"$d/capacity\" ] || continue; t=$(cat \"$d/type\" 2>/dev/null); s=$(cat \"$d/scope\" 2>/dev/null); case \"$n\" in BAT*|*battery*) [ \"$t\" = Battery ] && [ \"$s\" != Device ] && { echo \"$n\"; exit 0; } ;; esac; done"]
        stdout: SplitParser {
            onRead: function(line) {
                var name = (line || "").trim()
                if (!name) return
                root.batteryName = name
                root.batteryPath = "/sys/class/power_supply/" + name
                root.update()
            }
        }
        onExited: function(code) {
            root._discovered = true
            if (!root.batteryName) root.available = false
        }
    }

    // Single uevent read covers everything we need.
    property Process ueventProc: Process {
        running: false
        command: ["cat", root.batteryPath + "/uevent"]
        stdout: SplitParser {
            onRead: function(line) {
                var s = (line || "").trim()
                if (!s) return
                var eq = s.indexOf("=")
                if (eq < 0) return
                var key = s.substring(0, eq)
                var val = s.substring(eq + 1)
                switch (key) {
                    case "POWER_SUPPLY_CAPACITY":
                        root.capacity = parseInt(val) || 0
                        root.available = true
                        break
                    case "POWER_SUPPLY_STATUS":
                        root.status = val || "Unknown"
                        break
                    case "POWER_SUPPLY_VOLTAGE_NOW":
                        root.voltageVolts = (parseInt(val) || 0) / 1e6
                        break
                    case "POWER_SUPPLY_CURRENT_NOW":
                        root.currentAmps = (parseInt(val) || 0) / 1e6
                        break
                    case "POWER_SUPPLY_POWER_NOW":
                        var pw = (parseInt(val) || 0) / 1e6
                        root.powerWattsExact = Math.abs(pw)
                        root.powerWatts = Math.round(root.powerWattsExact)
                        break
                    case "POWER_SUPPLY_ENERGY_NOW":
                        root.energyNowWh = (parseInt(val) || 0) / 1e6
                        break
                    case "POWER_SUPPLY_ENERGY_FULL":
                        root.energyFullWh = (parseInt(val) || 0) / 1e6
                        break
                    case "POWER_SUPPLY_ENERGY_FULL_DESIGN":
                        root.energyFullDesignWh = (parseInt(val) || 0) / 1e6
                        break
                    case "POWER_SUPPLY_CHARGE_NOW":
                        if (root.energyNowWh === 0 && root.voltageVolts > 0) {
                            root.energyNowWh = ((parseInt(val) || 0) / 1e6) * root.voltageVolts
                        }
                        break
                    case "POWER_SUPPLY_CHARGE_FULL":
                        if (root.energyFullWh === 0 && root.voltageVolts > 0) {
                            root.energyFullWh = ((parseInt(val) || 0) / 1e6) * root.voltageVolts
                        }
                        break
                    case "POWER_SUPPLY_CHARGE_FULL_DESIGN":
                        if (root.energyFullDesignWh === 0 && root.voltageVolts > 0) {
                            root.energyFullDesignWh = ((parseInt(val) || 0) / 1e6) * root.voltageVolts
                        }
                        break
                    case "POWER_SUPPLY_CYCLE_COUNT":
                        root.cycleCount = parseInt(val)
                        if (isNaN(root.cycleCount)) root.cycleCount = -1
                        break
                    case "POWER_SUPPLY_MANUFACTURER":
                        root.manufacturer = val
                        break
                    case "POWER_SUPPLY_MODEL_NAME":
                        root.modelName = val
                        break
                    case "POWER_SUPPLY_TECHNOLOGY":
                        root.technology = val
                        break
                }
            }
        }
        onExited: function(code) {
            if (code === 0) root.lastUpdated = new Date()
        }
    }

    function update() {
        if (root.refCount <= 0) return
        if (!root.batteryName) {
            discoverProc.running = false
            discoverProc.running = true
            return
        }
        ueventProc.command = ["cat", root.batteryPath + "/uevent"]
        ueventProc.running = false
        ueventProc.running = true
    }
}
