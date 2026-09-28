pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Enhanced updates service reading scripts/updates_quickshell.sh JSON output.
// Exposes:
//  - upgradeCount / downgradeCount / additionCount / removalCount
//  - totalCount (sum of upgrade+downgrade) for badge logic
//  - hasChanges: totalCount > 0
//  - upgradedPackages / downgradedPackages arrays (objects with name/from/to/star)
//  - addedPackages / removedPackages arrays (objects with name/version/star)
//  - rebootRequired: bool
//  - tooltipText: formatted multiline string
//  - checking / lastUpdated / error
//  - nixosUpgradeServiceFailed: bool - tracks nixos-upgrade.service status
//  - nixosUpgradeError: string - error message from failed service
// Left-click widget triggers refresh().
QtObject {
    id: root

    // Counts
    property int upgradeCount: 0
    property int downgradeCount: 0
    property int additionCount: 0
    property int removalCount: 0
    property int totalCount: upgradeCount + downgradeCount
    property bool hasChanges: totalCount > 0

    // Data arrays
    property var upgradedPackages: []    // [{name, from, to, star}]
    property var downgradedPackages: []  // [{name, from, to, star}]
    property var addedPackages: []       // [{name, version, star}]
    property var removedPackages: []     // [{name, version, star}]

    property bool rebootRequired: false
    property string tooltipText: ""   // lazily built after refresh

    property bool checking: false
    property date lastUpdated: new Date(0)
    property string error: ""
    
    // nixos-upgrade.service status
    property bool nixosUpgradeServiceFailed: false
    property string nixosUpgradeError: ""

    // One-line LLM summary of nixos-upgrade failure (lazy, cached per error)
    property string nixosUpgradeErrorSummary: ""
    property bool nixosUpgradeErrorSummarizing: false
    // Track attempts, not only successful summaries, so failed calls stay terminal
    // until the error changes or the user explicitly requests a retry.
    property var _summaryAttemptedErrorKeys: []
    property string _summarizedErrorKey: ""
    property string _summaryBuffer: ""

    onNixosUpgradeServiceFailedChanged: {
        if (!nixosUpgradeServiceFailed) {
            nixosUpgradeErrorSummary = ""
            _summaryAttemptedErrorKeys = []
            _summarizedErrorKey = ""
        } else {
            _maybeSummarizeError()
        }
    }
    onNixosUpgradeErrorChanged: _maybeSummarizeError()

    function _summaryOut(line) {
        _summaryBuffer += (line || "") + "\n"
    }

    // Watchdog: if a summary call hangs (no exit signal), force-clear after 60s.
    property Timer _summaryWatchdog: Timer {
        interval: 60000
        repeat: false
        running: false
        onTriggered: {
            if (root.nixosUpgradeErrorSummarizing) {
                console.log("[Updates] summary watchdog: clearing stuck summarizing flag")
                root.nixosUpgradeErrorSummarizing = false
                root._summaryBuffer = ""
            }
        }
    }

    function forceResummarizeError() {
        var err = (nixosUpgradeError || "").trim()
        var remaining = []
        for (var i = 0; i < _summaryAttemptedErrorKeys.length; i++) {
            if (_summaryAttemptedErrorKeys[i] !== err) remaining.push(_summaryAttemptedErrorKeys[i])
        }
        _summaryAttemptedErrorKeys = remaining
        _summarizedErrorKey = ""
        nixosUpgradeErrorSummary = ""
        nixosUpgradeErrorSummarizing = false
        _maybeSummarizeError()
    }

    function _maybeSummarizeError() {
        if (!nixosUpgradeServiceFailed) {
            console.log("[Updates] _maybeSummarizeError: skip, service not failed")
            return
        }
        var err = (nixosUpgradeError || "").trim()
        if (!err) {
            console.log("[Updates] _maybeSummarizeError: skip, empty error")
            return
        }
        if (_summaryAttemptedErrorKeys.indexOf(err) >= 0) {
            console.log("[Updates] _maybeSummarizeError: skip, already attempted")
            return
        }
        if (nixosUpgradeErrorSummarizing) {
            console.log("[Updates] _maybeSummarizeError: skip, already in flight")
            return
        }

        console.log("[Updates] _maybeSummarizeError: starting (err len=" + err.length + ")")
        // Record before launching so a nonzero exit cannot trigger an automatic retry.
        _summaryAttemptedErrorKeys = _summaryAttemptedErrorKeys.concat([err])
        nixosUpgradeErrorSummarizing = true
        _summaryBuffer = ""
        _summaryWatchdog.restart()
        var attemptKey = err

        var procCode =
            'import Quickshell.Io; ' +
            'Process { running: false; ' +
            '  command: ["/home/zarred/.config/quickshell/primary/scripts/summarize_nixos_failure.sh", ""]; ' +
            '  stdout: SplitParser { onRead: function(d) {} } ' +
            '  stderr: SplitParser { onRead: function(d) {} } ' +
            '}'
        var proc
        try {
            proc = Qt.createQmlObject(procCode, root)
        } catch (e) {
            console.log("[Updates] failed to create Process: " + e)
            nixosUpgradeErrorSummarizing = false
            _summaryWatchdog.stop()
            return
        }

        proc.command = ["/home/zarred/.config/quickshell/primary/scripts/summarize_nixos_failure.sh", err]

        proc.stdout.onRead.connect(function(line) {
            root._summaryBuffer += (line || "") + "\n"
        })

        proc.onExited.connect(function(code) {
            _summaryWatchdog.stop()
            var summary = ""
            if (code === 0) {
                var lines = root._summaryBuffer.split("\n")
                for (var i = lines.length - 1; i >= 0; i--) {
                    var t = lines[i].trim()
                    if (t.length > 0) {
                        summary = t
                        break
                    }
                }
            }
            root.nixosUpgradeErrorSummary = summary
            if (summary.length > 0) root._summarizedErrorKey = attemptKey
            root.nixosUpgradeErrorSummarizing = false
            root._summaryBuffer = ""
            proc.destroy()
            var currentError = (root.nixosUpgradeError || "").trim()
            if (root.nixosUpgradeServiceFailed
                && currentError.length > 0
                && root._summaryAttemptedErrorKeys.indexOf(currentError) < 0) {
                root._maybeSummarizeError()
            }
        })

        proc.running = true
    }

    // Computed tooltip with service error prepended if present
    readonly property string finalTooltipText: {
        var text = tooltipText
        if (nixosUpgradeServiceFailed && nixosUpgradeError) {
            var lines = []
            lines.push("⚠ NixOS Upgrade Failed:")
            lines.push("")
            var errorLines = nixosUpgradeError.split("\n").slice(0, 5)
            for (var i = 0; i < errorLines.length; i++) {
                if (errorLines[i].trim()) {
                    lines.push(errorLines[i])
                }
            }
            if (text) {
                lines.push("")
                lines.push(text)
            }
            return lines.join("\n")
        }
        return text
    }

    // Poll every 5 minutes; rely on external script to be cheap.
    property int intervalMs: 5 * 60 * 1000

    property Timer pollTimer: Timer {
        interval: root.intervalMs
        repeat: true
        running: true
        onTriggered: root.refresh()
    }
    
    // Check nixos-upgrade service every 30 seconds
    property Timer serviceCheckTimer: Timer {
        interval: 30000
        repeat: true
        running: true
        onTriggered: root.checkNixosUpgradeService()
    }

    function checkNixosUpgradeService() {
        // Check if service is failed, and if so, get the status details
        var output = ""
        var procCode = 'import Quickshell.Io; Process { running: false; command: ["sh", "-c", "if systemctl is-failed nixos-upgrade.service 2>/dev/null | grep -q \'^failed$\'; then echo \'FAILED\'; systemctl status nixos-upgrade.service 2>&1 | tail -15; else echo \'OK\'; fi"]; stdout: SplitParser { onRead: function(data) { } } }'
        const proc = Qt.createQmlObject(procCode, root)
        
        // Capture stdout
        proc.stdout.onRead.connect(function(data) {
            output += data.toString()
        })
        
        proc.onExited.connect(function(code) {
            if (output.indexOf("FAILED") === 0) {
                // Extract everything after "FAILED\n"
                var errorText = output.substring(7).trim() // Skip "FAILED\n"
                root.nixosUpgradeServiceFailed = true
                root.nixosUpgradeError = errorText
            } else {
                root.nixosUpgradeServiceFailed = false
                root.nixosUpgradeError = ""
            }
            
            // CRITICAL: Destroy process to prevent memory leak
            proc.destroy()
        })
        
        proc.running = true
    }

    function refresh() {
        if (checking) return
        checking = true
        error = ""
        checkNixosUpgradeService()
        var p = Qt.createQmlObject('import Quickshell.Io; import QtQuick; Process { \n  id: updProc; \n  stdout: SplitParser { onRead: function(line){ root._handle(line) } } \n}', root)
        p.command = ["/home/zarred/scripts/nix/nix-update"]
        p.onExited.connect(function() {
            // CRITICAL: Destroy process to prevent memory leak
            p.destroy()
        })
        p.running = true
    }

    function _handle(line) {
        var trimmed = (line||"").trim()
        if (!trimmed) return
        // Expect full JSON emitted in a single line; attempt parse
        try {
            var obj = JSON.parse(trimmed)
            if (obj) {
                upgradeCount = obj.upgradeCount || (obj.upgrades ? obj.upgrades.length : 0)
                downgradeCount = obj.downgradeCount || (obj.downgrades ? obj.downgrades.length : 0)
                additionCount = obj.additionCount || (obj.additions ? obj.additions.length : 0)
                removalCount = obj.removalCount || (obj.removals ? obj.removals.length : 0)
                upgradedPackages = obj.upgrades || []
                downgradedPackages = obj.downgrades || []
                addedPackages = obj.additions || []
                removedPackages = obj.removals || []
                rebootRequired = obj.reboot === true
                // Build tooltip text
                var lines = []
                if (rebootRequired) lines.push("(reboot recommended)")
                if (downgradedPackages.length > 0) {
                    lines.push("Downgrades:")
                    // Sort alpha
                    var dgs = downgradedPackages.slice().sort(function(a,b){ return a.name.localeCompare(b.name) })
                    for (var i=0;i<dgs.length;i++) {
                        var d = dgs[i]
                        lines.push("  " + d.name + " " + d.from + " -> " + d.to)
                    }
                }
                if (upgradedPackages.length > 0) {
                    if (lines.length > 0) lines.push("")
                    lines.push("Upgrades:")
                    var ups = upgradedPackages.slice().sort(function(a,b){ return a.name.localeCompare(b.name) })
                    for (var j=0;j<ups.length;j++) {
                        var u = ups[j]
                        lines.push("  " + u.name + " " + u.from + " -> " + u.to)
                    }
                }
                if (addedPackages.length > 0) {
                    if (lines.length > 0) lines.push("")
                    lines.push("Additions:")
                    var ads = addedPackages.slice().sort(function(a,b){ return a.name.localeCompare(b.name) })
                    for (var k=0;k<ads.length;k++) {
                        var a = ads[k]
                        lines.push("  + " + a.name + " " + a.version)
                    }
                }
                if (removedPackages.length > 0) {
                    if (lines.length > 0) lines.push("")
                    lines.push("Removals:")
                    var rms = removedPackages.slice().sort(function(a,b){ return a.name.localeCompare(b.name) })
                    for (var m=0;m<rms.length;m++) {
                        var r = rms[m]
                        lines.push("  - " + r.name + " " + r.version)
                    }
                }
                if (lines.length === 0) lines.push("System up to date")
                tooltipText = lines.join("\n")
                lastUpdated = new Date()
            }
        } catch (e) {
            // Fallback: maybe legacy integer
            var val = parseInt(trimmed)
            if (!isNaN(val)) {
                upgradeCount = val
                tooltipText = val > 0 ? (val + " pending updates") : "System up to date"
                lastUpdated = new Date()
            } else {
                error = "Parse failed: " + e
            }
        }
        checking = false
    }
}
