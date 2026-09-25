pragma Singleton

import Quickshell
import Quickshell.Services.Mpris
import "."

Singleton {
    id: root

    readonly property list<MprisPlayer> players: Mpris.players.values
    readonly property MprisPlayer activePlayer: {
        if (players.length === 0) return null
        
        // First priority: player that's currently playing
        const playing = players.find(p => p.isPlaying)
        if (playing) return playing
        
        // Second priority: match playerctl's active player
        if (Playerctl.activePlayer) {
            const target = Playerctl.activePlayer.toLowerCase()
            const matched = players.find(p => {
                const identity = (p.identity || "").toLowerCase()
                return identity === target || identity.startsWith(target)
            })
            if (matched) return matched
        }
        
        // Fallback: first available player
        return players[0] ?? null
    }

    // Simplified properties for the widget
    readonly property string displayText: {
        if (!activePlayer) return ""
        
        const title = activePlayer.trackTitle || "Unknown"
        const artist = activePlayer.trackArtist || "Unknown"
        
        // Format similar to waybar config: "status_icon dynamic"
        const statusIcon = activePlayer.isPlaying ? "▶" : "⏸"
        return `${statusIcon} ${title} - ${artist}`
    }

    readonly property string tooltipText: {
        if (!activePlayer) return "No media player"
        
        const title = activePlayer.trackTitle || "Unknown"
        const artist = activePlayer.trackArtist || "Unknown"
        const album = activePlayer.trackAlbum || "Unknown"
        const player = activePlayer.identity || "Unknown"
        
        return `${player}\n${title}\n${artist}\n${album}`
    }

    readonly property string artUrl: normalizeArtUrl(activePlayer?.trackArtUrl || "")

    readonly property bool hasActivePlayer: activePlayer !== null
    readonly property bool isPlaying: activePlayer?.isPlaying ?? false

    // Normalize player-provided values so Image can load the art reliably.
    function normalizeArtUrl(raw) {
        if (!raw) return ""
        const trimmed = String(raw).trim()
        if (!trimmed) return ""
        if (trimmed.startsWith("data:")) return trimmed
        if (trimmed.includes("://")) return trimmed
        if (trimmed.startsWith("/")) {
            return `file://${trimmed.replace(/ /g, "%20")}`
        }
        return trimmed
    }

    function togglePlayback() {
        if (activePlayer?.canTogglePlaying) {
            activePlayer.togglePlaying()
        }
    }

    function next() {
        if (activePlayer?.canGoNext) {
            activePlayer.next()
        }
    }

    function previous() {
        if (activePlayer?.canGoPrevious) {
            activePlayer.previous()
        }
    }

    // Find MPRIS player by playerctl name (bus name)
    // Maps playerctl names (mpd, firefox, mpv) to MPRIS player objects
    function findPlayerByName(playerctlName) {
        if (!playerctlName) return null
        const target = playerctlName.toLowerCase()
        
        // Create a map of common aliases for known players
        const aliases = {
            "mpd": ["music player daemon", "mpd"],
            "mpv": ["mpv"],
            "firefox": ["mozilla firefox", "firefox"],
            "vlc": ["vlc"],
            "spotify": ["spotify"],
            "brave": ["brave"],
            "chromium": ["chromium"],
        }
        
        const targetAliases = aliases[target] || [target]
        
        // Try to find by matching against known aliases
        for (const p of players) {
            if (!p.identity) continue
            const identity = p.identity.toLowerCase()
            
            // Check if identity matches any of the target's aliases
            for (const alias of targetAliases) {
                if (identity === alias || identity === alias.toLowerCase()) {
                    return p
                }
            }
            
            // Check if identity contains the playerctl name
            if (identity.includes(target)) {
                return p
            }
        }
        
        return null
    }
}