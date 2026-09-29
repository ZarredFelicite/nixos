pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
    id: root

    // ── Public state ──
    property real usage: 0.0          // 0..1 overall CPU
    property int usagePercent: 0      // 0..100 rounded
    property var coreUsages: []       // array of 0..100 per logical core
    property int coreCount: 0
    property int temp: 0              // °C (0 = unknown)
    property string tempSource: ""    // hwmon label/source for tooltip
    property int frequencyMHz: 0      // average current frequency across cores
    property int maxFrequencyMHz: 0      // current scaling max/cap
    property int cpuInfoMaxFrequencyMHz: 0
    property int minFrequencyMHz: 0
    property string governor: ""
    property string profile: ""       // active power profile (powerprofilesctl) — "" if unavailable
    property string model: ""
    property real loadAvg1: 0
    property real loadAvg5: 0
    property real loadAvg15: 0
    property int procRunning: 0
    property int procTotal: 0
    property real uptimeSeconds: 0
    property string error: ""
    property date lastUpdated: new Date(0)

    // ── Polling control ──
    property int refCount: 0
    property int interval: 3000

    onRefCountChanged: {
        pollTimer.running = (refCount > 0)
        if (refCount > 0) {
            if (!_initialized) discoverHwmon()
            update()
        }
    }

    property Timer pollTimer: Timer {
        id: pollTimer
        interval: root.interval
        running: false
        repeat: true
        onTriggered: root.update()
    }

    // ── Internal sampling state ──
    property bool _initialized: false
    property string _tempPath: ""           // resolved /sys/.../tempN_input or empty
    property var _prevTotals: ({})          // map: cpuName -> {total, idle}
    property string _statBuf: ""
    property string _freqBuf: ""
    property string _miscBuf: ""

    // ── Hwmon discovery (one-shot at first poll) ──
    property Process hwmonProc: Process {
        running: false
        // Walk hwmon* names, prefer k10temp/coretemp/zenpower/cpu_thermal, pick a Tctl/Tdie/Package input.
        command: ["sh", "-c",
            "best=''; for d in /sys/class/hwmon/hwmon*; do n=$(cat \"$d/name\" 2>/dev/null); case \"$n\" in " +
            "k10temp|coretemp|zenpower|cpu_thermal) " +
            "  for lf in \"$d\"/temp*_label; do " +
            "    [ -f \"$lf\" ] || { f=\"$d/temp1_input\"; [ -f \"$f\" ] && { echo \"$f|$n|cpu\"; exit 0; }; continue; }; " +
            "    lbl=$(cat \"$lf\" 2>/dev/null); " +
            "    case \"$lbl\" in Tctl|Tdie|Package*|Composite|Core*0*) echo \"${lf%_label}_input|$n|$lbl\"; exit 0;; esac; " +
            "  done; " +
            "  f=\"$d/temp1_input\"; [ -f \"$f\" ] && { echo \"$f|$n|temp1\"; exit 0; };; " +
            "esac; done"
        ]
        stdout: SplitParser {
            onRead: function(line) {
                var s = (line || "").trim()
                if (!s) return
                var parts = s.split("|")
                if (parts.length >= 1) root._tempPath = parts[0]
                if (parts.length >= 3) root.tempSource = parts[1] + "/" + parts[2]
            }
        }
        onExited: function() {
            root._initialized = true
            // After discovery, fire a /proc/cpuinfo + governor + profile read once
            cpuinfoProc.running = false
            cpuinfoProc.running = true
            governorProc.running = false
            governorProc.running = true
            profileProc.running = false
            profileProc.running = true
        }
    }

    function discoverHwmon() {
        hwmonProc.running = false
        hwmonProc.running = true
    }

    // ── /proc/stat (overall + per-core) ──
    property Process statProc: Process {
        running: false
        command: ["cat", "/proc/stat"]
        stdout: SplitParser {
            onRead: function(line) { root._statBuf += line + "\n" }
        }
        onExited: function() {
            root._parseStat(root._statBuf)
            root._statBuf = ""
        }
    }

    function _parseStat(text) {
        var lines = (text || "").split("\n")
        var newTotals = {}
        var cores = []
        var overall = -1
        for (var i = 0; i < lines.length; i++) {
            var ln = lines[i]
            if (!ln || ln.indexOf("cpu") !== 0) continue
            var f = ln.split(/\s+/)
            var name = f[0]
            if (name === "cpu" || /^cpu\d+$/.test(name)) {
                var user = parseInt(f[1]) || 0
                var nice = parseInt(f[2]) || 0
                var system = parseInt(f[3]) || 0
                var idle = parseInt(f[4]) || 0
                var iowait = parseInt(f[5]) || 0
                var irq = parseInt(f[6]) || 0
                var softirq = parseInt(f[7]) || 0
                var steal = parseInt(f[8]) || 0
                var total = user + nice + system + idle + iowait + irq + softirq + steal
                var idleSum = idle + iowait
                newTotals[name] = { total: total, idle: idleSum }

                var prev = root._prevTotals[name]
                if (prev) {
                    var dT = total - prev.total
                    var dI = idleSum - prev.idle
                    var pct = dT > 0 ? Math.max(0, Math.min(100, ((dT - dI) / dT) * 100)) : 0
                    if (name === "cpu") overall = pct
                    else cores.push(pct)
                }
            } else if (ln.indexOf("procs_running") === 0) {
                root.procRunning = parseInt(ln.split(/\s+/)[1]) || 0
            }
        }
        root._prevTotals = newTotals
        if (overall >= 0) {
            root.usage = overall / 100
            root.usagePercent = Math.round(overall)
        }
        if (cores.length > 0) {
            root.coreUsages = cores
            root.coreCount = cores.length
        }
        root.lastUpdated = new Date()
    }

    // ── CPU frequencies (all cores) ──
    property Process freqProc: Process {
        running: false
        command: ["sh", "-c", "cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq 2>/dev/null"]
        stdout: SplitParser {
            onRead: function(line) { root._freqBuf += line + "\n" }
        }
        onExited: function() {
            var lines = root._freqBuf.split("\n")
            var sum = 0, n = 0
            for (var i = 0; i < lines.length; i++) {
                var v = parseInt(lines[i])
                if (isFinite(v) && v > 0) { sum += v; n++ }
            }
            root.frequencyMHz = n > 0 ? Math.round(sum / n / 1000) : 0
            root._freqBuf = ""
        }
    }

    // ── Misc one-time / slow-changing readers ──
    property Process cpuinfoProc: Process {
        running: false
        command: ["sh", "-c", "grep -m1 'model name' /proc/cpuinfo | sed 's/.*: //'"]
        stdout: SplitParser {
            onRead: function(line) {
                var s = (line || "").trim()
                if (s) root.model = s
            }
        }
    }

    property Process governorProc: Process {
        running: false
        command: ["sh", "-c", "cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null; echo ---; cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq 2>/dev/null; cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq 2>/dev/null; cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_min_freq 2>/dev/null"]
        stdout: SplitParser {
            onRead: function(line) { root._miscBuf += line + "\n" }
        }
        onExited: function() {
            var parts = root._miscBuf.split("---")
            if (parts.length >= 1) {
                var g = parts[0].trim()
                if (g.length > 0) root.governor = g
            }
            if (parts.length >= 2) {
                var rest = parts[1].trim().split(/\s+/)
                var mx = parseInt(rest[0])
                var infoMx = parseInt(rest[1])
                var mn = parseInt(rest[2])
                if (isFinite(mx) && mx > 0) root.maxFrequencyMHz = Math.round(mx / 1000)
                if (isFinite(infoMx) && infoMx > 0) root.cpuInfoMaxFrequencyMHz = Math.round(infoMx / 1000)
                if (isFinite(mn) && mn > 0) root.minFrequencyMHz = Math.round(mn / 1000)
            }
            root._miscBuf = ""
        }
    }

    property Process profileProc: Process {
        running: false
        command: ["sh", "-c",
            "if command -v powerprofilesctl >/dev/null 2>&1; then " +
            "  powerprofilesctl get 2>/dev/null; " +
            "elif [ -f /sys/firmware/acpi/platform_profile ]; then " +
            "  cat /sys/firmware/acpi/platform_profile; " +
            "fi"
        ]
        stdout: SplitParser {
            onRead: function(line) {
                var s = (line || "").trim()
                if (s) root.profile = s
            }
        }
    }

    // ── Temperature ──
    property Process tempProc: Process {
        running: false
        command: ["cat", root._tempPath]
        stdout: SplitParser {
            onRead: function(line) {
                var v = parseInt((line || "").trim())
                if (isFinite(v) && v > 0) root.temp = Math.round(v / 1000)
            }
        }
    }

    // ── Load average + uptime ──
    property Process loadProc: Process {
        running: false
        command: ["sh", "-c", "cat /proc/loadavg; echo ---; cat /proc/uptime"]
        stdout: SplitParser {
            onRead: function(line) {
                var s = (line || "").trim()
                if (!s || s === "---") return
                var parts = s.split(/\s+/)
                if (parts.length >= 5 && parts[3].indexOf("/") > 0) {
                    var l1 = parseFloat(parts[0])
                    var l5 = parseFloat(parts[1])
                    var l15 = parseFloat(parts[2])
                    var slash = parts[3].split("/")
                    if (isFinite(l1)) root.loadAvg1 = l1
                    if (isFinite(l5)) root.loadAvg5 = l5
                    if (isFinite(l15)) root.loadAvg15 = l15
                    if (slash.length >= 2) root.procTotal = parseInt(slash[1]) || 0
                } else if (parts.length >= 2) {
                    var up = parseFloat(parts[0])
                    if (isFinite(up)) root.uptimeSeconds = up
                }
            }
        }
    }

    function update() {
        if (refCount === 0) return
        statProc.running = false
        statProc.running = true
        freqProc.running = false
        freqProc.running = true
        loadProc.running = false
        loadProc.running = true
        if (root._tempPath.length > 0) {
            tempProc.command = ["cat", root._tempPath]
            tempProc.running = false
            tempProc.running = true
        }
        // Refresh slower-changing fields every ~30s
        if (_slowTick++ % 10 === 0) {
            governorProc.running = false
            governorProc.running = true
            profileProc.running = false
            profileProc.running = true
        }
    }
    property int _slowTick: 0

    // ── Optional: trigger a profile change via the existing helper script ──
    property Process switchModeProc: Process {
        running: false
    }

    property Process maxFreqProc: Process {
        running: false
        onExited: function() { root.update() }
    }

    function setMaxFrequency(freq) {
        maxFreqProc.command = ["pkexec", "/run/current-system/sw/bin/set-cpu-max-freq", String(freq)]
        maxFreqProc.running = false
        maxFreqProc.running = true
    }

    function switchProfile() {
        switchModeProc.command = ["/home/zarred/.config/quickshell/primary/scripts/cpu_quickshell.sh", "--switch-mode"]
        switchModeProc.running = false
        switchModeProc.running = true
        // Refresh profile shortly after
        Qt.callLater(function() {
            profileProc.running = false
            profileProc.running = true
        })
    }
}
