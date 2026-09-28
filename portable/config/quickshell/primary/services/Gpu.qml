 pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
    id: root

    property bool hasNvidiaGpu: false
    property bool hasAmdGpu: false

    // NVIDIA GPU properties
    property real nvidiaGpuUsage: 0.0      // 0.0 to 100.0
    property real nvidiaMemoryUsage: 0.0   // 0.0 to 100.0
    property real nvidiaPowerUsage: 0.0    // 0.0 to 100.0
    property int nvidiaTemperature: 0      // Temperature in Celsius
    property int nvidiaPowerWatts: 0       // Power draw in watts
    property int nvidiaProfile: 4          // 0 (high) to 4 (low), default to 4 safe

    // AMD GPU properties
    property real amdGpuUsage: 0.0      // 0.0 to 100.0
    property real amdMemoryUsage: 0.0   // 0.0 to 100.0
    property real amdPowerUsage: 0.0    // 0.0 to 100.0
    property int amdTemperature: 0      // Temperature in Celsius
    property int amdPowerWatts: 0       // Power draw in watts
    property string amdProfile: "unknown" // "default", "power-saving", "performance"

    // Historical data for graphing (last 20 points = 60 seconds at 3s intervals)
    property var nvidiaUsageHistory: []
    property var nvidiaMemoryHistory: []
    property var nvidiaPowerHistory: []
    property var nvidiaTempHistory: []
    property var amdUsageHistory: []
    property var amdMemoryHistory: []
    property var amdPowerHistory: []
    property var amdTempHistory: []

    // Legacy properties (for backward compatibility, map to NVIDIA)
    property real gpuUsage: nvidiaGpuUsage
    property real memoryUsage: nvidiaMemoryUsage
    property real powerUsage: nvidiaPowerUsage
    property int temperature: nvidiaTemperature
    property int powerWatts: nvidiaPowerWatts

    property int refCount: 0

    function detectAvailableGpus() {
        var output = ""
        var procCode = 'import Quickshell.Io; Process { running: false; stdout: SplitParser { onRead: function(data) { } } }'
        var proc = Qt.createQmlObject(procCode, root)
        proc.command = [
            "sh", "-c",
            "has_nvidia=0; has_amd=0; "
            + "if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi -L >/dev/null 2>&1; then has_nvidia=1; fi; "
            + "for vendor_file in /sys/class/drm/card*/device/vendor; do "
            + "[ -f \"$vendor_file\" ] || continue; "
            + "vendor=$(cat \"$vendor_file\" 2>/dev/null || true); "
            + "if [ \"$vendor\" = \"0x1002\" ]; then has_amd=1; break; fi; "
            + "done; "
            + "printf '%s,%s\\n' \"$has_nvidia\" \"$has_amd\""
        ]

        proc.stdout.onRead.connect(function(data) {
            output += data.toString()
        })

        proc.onExited.connect(function() {
            var parts = output.trim().split(',')
            if (parts.length >= 2) {
                root.hasNvidiaGpu = parts[0] === "1"
                root.hasAmdGpu = parts[1] === "1"
            }
            console.log("GPU detection:", "nvidia=", root.hasNvidiaGpu, "amd=", root.hasAmdGpu)
            proc.destroy()
        })

        proc.running = true
    }

    function updateHistory(currentHistory, value) {
        var newHistory = currentHistory.slice()
        newHistory.push(value)
        if (newHistory.length > 20) {
            newHistory.shift()
        }
        return newHistory
    }

    // Functions to change profiles
    function setNvidiaProfile(profileIndex) {
        var proc = Qt.createQmlObject('import Quickshell.Io; Process { }', root)
        proc.command = ["pkexec", "python", "/home/zarred/scripts/sys/gpu_manager.py", "-p", profileIndex.toString()]
        proc.onExited.connect(function() {
            root.nvidiaProfile = profileIndex
            proc.destroy()
        })
        proc.running = true
    }

    function setAmdProfile(profileName) {
        var proc = Qt.createQmlObject('import Quickshell.Io; Process { }', root)
        proc.command = ["lact", "cli", "profile", "set", profileName]
        proc.onExited.connect(function() {
            // amdProfile will be updated by monitor loop
            proc.destroy()
        })
        proc.running = true
    }
    
    // Initial NVIDIA profile check (requires auth, so optional/lazy)
    function checkNvidiaProfile() {
        var proc = Qt.createQmlObject('import Quickshell.Io; Process { }', root)
        proc.command = ["pkexec", "python", "/home/zarred/scripts/sys/gpu_manager.py"]
        proc.stdout = Qt.createQmlObject('import Quickshell.Io; SplitParser { }', proc)
        proc.stdout.onRead.connect(function(data) {
            // Parse "Derived Profile : [3]"
            var match = data.toString().match(/Derived Profile\s*:\s*\[(\d+)\]/)
            if (match && match[1]) {
                root.nvidiaProfile = parseInt(match[1])
            }
        })
        proc.onExited.connect(function() {
            proc.destroy()
        })
        proc.running = true
    }

    onRefCountChanged: {
        console.log("GPU refCount changed to:", root.refCount)
        if (root.refCount > 0) {
            console.log("Starting GPU processes")
            if (root.hasNvidiaGpu && !nvidiaProcess.running) {
                nvidiaProcess.running = true
                console.log("NVIDIA process started")
            }
            if (root.hasAmdGpu && !amdProcess.running) {
                amdProcess.running = true
                console.log("AMD process started")
            }
        } else {
            console.log("Stopping GPU processes")
            if (nvidiaProcess.running) nvidiaProcess.running = false
            if (amdProcess.running) amdProcess.running = false
        }
    }

    Component.onCompleted: detectAvailableGpus()

    // Update historical data when values change
    // onNvidiaGpuUsageChanged: nvidiaUsageHistory = updateHistory(nvidiaUsageHistory, nvidiaGpuUsage)
    // onNvidiaMemoryUsageChanged: nvidiaMemoryHistory = updateHistory(nvidiaMemoryHistory, nvidiaMemoryUsage)
    // onNvidiaPowerUsageChanged: nvidiaPowerHistory = updateHistory(nvidiaPowerHistory, nvidiaPowerUsage)
    // onNvidiaTemperatureChanged: nvidiaTempHistory = updateHistory(nvidiaTempHistory, nvidiaTemperature)
    // onAmdGpuUsageChanged: amdUsageHistory = updateHistory(amdUsageHistory, amdGpuUsage)
    // onAmdMemoryUsageChanged: amdMemoryHistory = updateHistory(amdMemoryHistory, amdMemoryUsage)
    // onAmdPowerUsageChanged: amdPowerHistory = updateHistory(amdPowerHistory, amdPowerUsage)
    // onAmdTemperatureChanged: amdTempHistory = updateHistory(amdTempHistory, amdTemperature)

    // NVIDIA GPU process
    property Process nvidiaProcess: Process {
        id: nvidiaProcess
        running: false
        command: ["/home/zarred/.config/quickshell/primary/scripts/gpu_quickshell.sh", "--monitor"]
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(',');
                // Expect: usage,memory_usage,power_usage,temp,power_watts
                if (parts.length >= 4) {
                    const usage = parseFloat(parts[0]);
                    const memUsage = parseFloat(parts[1]);
                    const powerUsage = parseFloat(parts[2]);
                    const temp = parseInt(parts[3]);
                    const powerWatts = parts.length >= 5 ? parseInt(parts[4]) : 0;

                    if (!isNaN(usage)) {
                        var val = Math.max(0, Math.min(100, usage));
                        root.nvidiaGpuUsage = val;
                        root.nvidiaUsageHistory = updateHistory(root.nvidiaUsageHistory, val);
                    }
                    if (!isNaN(memUsage)) {
                        var val = Math.max(0, Math.min(100, memUsage));
                        root.nvidiaMemoryUsage = val;
                        root.nvidiaMemoryHistory = updateHistory(root.nvidiaMemoryHistory, val);
                    }
                    if (!isNaN(powerUsage)) {
                        var val = Math.max(0, Math.min(100, powerUsage));
                        root.nvidiaPowerUsage = val;
                        root.nvidiaPowerHistory = updateHistory(root.nvidiaPowerHistory, val);
                    }
                    if (!isNaN(temp)) {
                        root.nvidiaTemperature = temp;
                        root.nvidiaTempHistory = updateHistory(root.nvidiaTempHistory, temp);
                    }
                    if (!isNaN(powerWatts)) {
                        root.nvidiaPowerWatts = Math.max(0, powerWatts);
                    }
                }
            }
        }

        // Discard stderr to prevent accumulation
        stderr: SplitParser {
            onRead: function(line) {
                // Discard stderr output to prevent memory accumulation
            }
        }
    }

    // AMD GPU process
    property Process amdProcess: Process {
        id: amdProcess
        running: false
        command: ["/home/zarred/.config/quickshell/primary/scripts/gpu_quickshell_amd.sh", "--monitor"]
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(',');
                // Expect: usage,memory_usage,power_usage,temp,power_watts
                if (parts.length >= 4) {
                    const usage = parseFloat(parts[0]);
                    const memUsage = parseFloat(parts[1]);
                    const powerUsage = parseFloat(parts[2]);
                    const temp = parseInt(parts[3]);
                    const powerWatts = parts.length >= 5 ? parseInt(parts[4]) : 0;

                    if (!isNaN(usage)) {
                        var val = Math.max(0, Math.min(100, usage));
                        root.amdGpuUsage = val;
                        root.amdUsageHistory = updateHistory(root.amdUsageHistory, val);
                    }
                    if (!isNaN(memUsage)) {
                        var val = Math.max(0, Math.min(100, memUsage));
                        root.amdMemoryUsage = val;
                        root.amdMemoryHistory = updateHistory(root.amdMemoryHistory, val);
                    }
                    if (!isNaN(powerUsage)) {
                        var val = Math.max(0, Math.min(100, powerUsage));
                        root.amdPowerUsage = val;
                        root.amdPowerHistory = updateHistory(root.amdPowerHistory, val);
                    }
                    if (!isNaN(temp)) {
                        root.amdTemperature = temp;
                        root.amdTempHistory = updateHistory(root.amdTempHistory, temp);
                    }
                    if (!isNaN(powerWatts)) {
                        root.amdPowerWatts = Math.max(0, powerWatts);
                    }
                    if (parts.length >= 6) {
                        root.amdProfile = parts[5];
                    }
                }
            }
        }

        // Discard stderr to prevent accumulation
        stderr: SplitParser {
            onRead: function(line) {
                // Discard stderr output to prevent memory accumulation
            }
        }
    }
}
