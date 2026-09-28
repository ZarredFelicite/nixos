pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
    id: root

    property int generation: -1
    property bool loading: false
    property string error: ""
    
    property var upgrades: []
    property var downgrades: []
    property var additions: []
    property var removals: []
    property bool rebootRequired: false
    property int upgradeCount: 0
    property int downgradeCount: 0
    property int additionCount: 0
    property int removalCount: 0

    function loadGeneration(gen) {
        if (loading) return
        generation = gen
        loading = true
        error = ""
        var p = Qt.createQmlObject('import Quickshell.Io; import QtQuick; Process { \n  id: diffProc; \n  stdout: SplitParser { onRead: function(data){ root._handleOutput(data) } } \n}', root)
        p.onExited.connect(function() {
            // CRITICAL: Destroy process to prevent memory leak
            p.destroy()
        })
        p.command = ["/home/zarred/scripts/nix/nix-update", String(gen)]
        p.running = true
    }

    function _handleOutput(data) {
        var trimmed = (data||"").trim()
        if (!trimmed) return
        try {
            var obj = JSON.parse(trimmed)
            if (obj) {
                upgrades = obj.upgrades || []
                downgrades = obj.downgrades || []
                additions = obj.additions || []
                removals = obj.removals || []
                rebootRequired = obj.reboot === true
                upgradeCount = obj.upgradeCount || 0
                downgradeCount = obj.downgradeCount || 0
                additionCount = obj.additionCount || 0
                removalCount = obj.removalCount || 0
            }
        } catch (e) {
            error = "Parse failed: " + e
        }
        loading = false
    }
}
