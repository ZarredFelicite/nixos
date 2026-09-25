pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../utils"

// Simple playerctl integration to list players and active player name
Singleton {
    id: root

    // Public state
    property var players: []            // array of player names (strings)
    property string activePlayer: ""    // name of active player

    // Polling timer
    Timer {
        id: poll
        interval: 3000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            root.refreshPlayers();
            root.refreshActive();
        }
    }

    // Processes
    property string _bufList: ""
    property Process listProc: Process {
        stdout: SplitParser { onRead: function(data){ root._bufList += data + "\n" } }
        onExited: {
            try {
                var lines = (root._bufList || "")
                    .split(/\n+/)
                    .map(s => s.trim())
                    .filter(Boolean)
                    // Use only the part before the first dot (instance suffix)
                    .map(s => s.split('.')[0])
                // Deduplicate while preserving order
                var seen = {}
                var unique = []
                for (var i=0;i<lines.length;i++) {
                    var key = lines[i]
                    if (!seen[key]) { seen[key] = true; unique.push(key) }
                }
                root.players = unique
            } finally {
                root._bufList = ""
            }
        }
    }

    property string _bufActive: ""
    property Process activeProc: Process {
        stdout: SplitParser { onRead: function(data){ root._bufActive += data + "\n" } }
        onExited: {
            try {
                var txt = (root._bufActive || "").trim()
                // Use the first word from metadata output as requested
                var name = txt.split(/\s+/)[0] || ""
                // Strip instance suffix after first dot
                var base = name.split('.')[0]
                root.activePlayer = base
            } finally {
                root._bufActive = ""
            }
        }
    }

    function refreshPlayers() {
        listProc.running = false
        listProc.command = ["sh","-lc","playerctl -l 2>/dev/null || true"]
        listProc.running = true
    }

    function refreshActive() {
        activeProc.running = false
        // Print player name first; if format is unavailable, fallback to raw metadata
        activeProc.command = ["sh","-lc","playerctl metadata --format '{{playerName}} {{status}}' 2>/dev/null || playerctl metadata 2>/dev/null || true"]
        activeProc.running = true
    }

    // Resolve an icon source for a given player using overrides first, then theme
    function iconFor(name) {
        if (!name) return ""
        // Try common aliases and case variants
        var key = String(name).toLowerCase()
        var candidates = []
        var map = { spotify: "spotify", mpv: "mpv", vlc: "vlc", chromium: "chromium", firefox: "firefox", brave: "brave", spotifyd: "spotify" }
        if (map[key]) candidates.push(map[key])
        candidates.push(name)
        candidates.push(key)
        // Prefer repo-level overrides
        for (var i=0;i<candidates.length;i++) {
            var override = Icons.getOverrideFor(candidates[i])
            if (override && override.length > 0) {
                if (Icons.debug) console.log(`[Playerctl] matched override for ${name}: ${override}`)
                return override
            }
        }
        // Resolve to an absolute file path via icon theme
        for (var i=0;i<candidates.length;i++) {
            var path = Quickshell.iconPath(candidates[i], "application-x-executable")
            if (path && path.length > 0) return path
        }
        return ""
    }
}
