pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
    id: root

    // ============================================================================
    // PLAYBACK STATE
    // ============================================================================
    property string status: "stopped"          // "playing" | "paused" | "stopped"
    property string currentSong: ""
    property string currentArtist: ""
    property string currentAlbum: ""
    property string currentFile: ""
    property int currentPosition: 0            // seconds
    property int currentDuration: 0            // seconds
    property int volume: 100                   // 0-100
    property bool repeat: false
    property bool random: false
    property bool single: false
    property bool consume: false

    // ============================================================================
    // QUEUE STATE
    // ============================================================================
    property var queue: []                     // [{pos, artist, album, title, file, duration}]
    property int queueLength: 0
    property int queuePosition: 0

    // ============================================================================
    // LIBRARY STATS
    // ============================================================================
    property int totalSongs: 0
    property int totalAlbums: 0
    property int totalArtists: 0
    property string dbPlayTime: ""

    // ============================================================================
    // SEARCH & BOOKMARKS
    // ============================================================================
    property var searchResults: []             // [{type, name, artist/album, file}]
    property var bookmarks: []                 // [{type, name, query}]

    // ============================================================================
    // STATE MANAGEMENT
    // ============================================================================
    property bool updating: false
    property string errorMsg: ""
    
    // ============================================================================
    // ALBUM ART HANDLING
    // ============================================================================
    property string albumArtUrl: ""
    property string albumArtCacheDir: "/tmp"
    property string _albumArtStdout: ""
    property string _albumArtSource: ""
    property string _albumArtFile: ""
    property bool _albumArtRetryPending: false
    property var _albumArtFailureState: ({})
    property int _albumArtFailureBaseCooldownMs: 15000
    property int _albumArtFailureMaxCooldownMs: 300000
    property int _albumArtFailurePruneMs: 21600000
    
    property Process albumArtProc: Process {
        id: albumArtProc
        running: false
        command: []
        stdout: SplitParser {
            onRead: function(data) {
                root._albumArtStdout += data.toString()
            }
        }
        onExited: function(code) {
            var shouldRetry = root._albumArtRetryPending
            root._albumArtRetryPending = false
            var path = root._albumArtStdout.trim()
            root._albumArtStdout = ""
            var track = root._albumArtSource
            if (code === 0 && path.length > 0) {
                root._clearAlbumArtFailure(track)
                root._setAlbumArtFromPath(path)
            } else {
                var failure = root._noteAlbumArtFailure(track)
                if (failure.count === 1 || (failure.count % 20) === 0) {
                    console.log("[MusicPlayer] Album art fetch failed (code=" + code + ", count=" + failure.count + ", cooldown=" + Math.round(failure.cooldownMs / 1000) + "s)")
                }
                root._clearAlbumArtVisualOnly()
            }
            if (shouldRetry) {
                Qt.callLater(function() {
                    root._fetchAlbumArtForCurrentTrack(true)
                })
            }
        }
    }
    
    function _fetchAlbumArtForCurrentTrack(force) {
        if (!root.currentFile || root.currentFile.length === 0) {
            _clearAlbumArt()
            return
        }
        if (!force && root.currentFile === root._albumArtSource) {
            if (root.albumArtUrl.length > 0) {
                return
            }
            if (root._shouldThrottleAlbumArt(root.currentFile)) {
                return
            }
        }
        if (albumArtProc.running) {
            if (force || root.currentFile !== root._albumArtSource) {
                root._albumArtRetryPending = true
            }
            return
        }
        root._albumArtRetryPending = false
        root._albumArtSource = root.currentFile
        var escapedUri = root.currentFile.replace(/'/g, "'\\''")
        var cacheDir = root.albumArtCacheDir || "/tmp"
        var cachePath = cacheDir + "/quickshell-musicplayer-art-" + Date.now() + ".bin"
        var escapedCache = cachePath.replace(/'/g, "'\\''")
        var script = "tmp='" + escapedCache + "'\n" +
                     "rm -f \"$tmp\"\n" +
                     "if mpc albumart '" + escapedUri + "' > \"$tmp\" 2>/dev/null; then\n" +
                     "    if [ -s \"$tmp\" ]; then\n" +
                     "        printf '%s\\n' \"$tmp\"\n" +
                     "        exit 0\n" +
                     "    fi\n" +
                     "fi\n" +
                     "rm -f \"$tmp\"\n" +
                     "printf ''\n" +
                     "exit 1\n"
        albumArtProc.running = false
        root._albumArtStdout = ""
        albumArtProc.command = ["sh", "-c", script]
        albumArtProc.running = true
    }
    
    function _setAlbumArtFromPath(path) {
        if (!path) {
            _clearAlbumArt()
            return
        }
        var url = _fileUrlForPath(path)
        if (!url) {
            _clearAlbumArt()
            return
        }
        if (root._albumArtFile && root._albumArtFile.length > 0 && root._albumArtFile !== path) {
            _deleteAlbumArtFile(root._albumArtFile)
        }
        root._albumArtFile = path
        var separator = url.includes("?") ? "&" : "?"
        root.albumArtUrl = url + separator + "ts=" + Date.now()
        console.log("[MusicPlayer] Album art ready:", root.albumArtUrl)
    }
    
    function _fileUrlForPath(path) {
        if (!path) return ""
        var encoded = path.split("/").map(function(segment) { return encodeURIComponent(segment) }).join("/")
        return "file://" + encoded
    }
    
    function _clearAlbumArt() {
        if (root.albumArtUrl.length > 0) {
            console.log("[MusicPlayer] Clearing album art")
        }
        root._clearAlbumArtVisualOnly()
        root._albumArtSource = ""
    }

    function _clearAlbumArtVisualOnly() {
        if (root._albumArtFile && root._albumArtFile.length > 0) {
            _deleteAlbumArtFile(root._albumArtFile)
            root._albumArtFile = ""
        }
        root.albumArtUrl = ""
    }

    function _shouldThrottleAlbumArt(track) {
        if (!track || track.length === 0) return false
        var failure = root._albumArtFailureState[track]
        if (!failure) return false
        return Date.now() < failure.nextRetryMs
    }

    function _clearAlbumArtFailure(track) {
        if (!track || track.length === 0) return
        if (root._albumArtFailureState[track] !== undefined) {
            delete root._albumArtFailureState[track]
        }
    }

    function _noteAlbumArtFailure(track) {
        var now = Date.now()
        var state = root._albumArtFailureState
        var failure = state[track]
        if (!failure || (now - failure.lastFailMs) > root._albumArtFailurePruneMs) {
            failure = { count: 0, lastFailMs: 0, nextRetryMs: 0, cooldownMs: root._albumArtFailureBaseCooldownMs }
        }

        var nextCount = failure.count + 1
        var cooldownMs = root._albumArtFailureBaseCooldownMs * Math.pow(2, Math.min(6, nextCount - 1))
        if (cooldownMs > root._albumArtFailureMaxCooldownMs) {
            cooldownMs = root._albumArtFailureMaxCooldownMs
        }

        failure = {
            count: nextCount,
            lastFailMs: now,
            cooldownMs: cooldownMs,
            nextRetryMs: now + cooldownMs
        }

        state[track] = failure
        root._albumArtFailureState = state

        // Prune stale entries so this map cannot grow unbounded over long sessions.
        var keys = Object.keys(state)
        for (var i = 0; i < keys.length; i++) {
            var key = keys[i]
            var item = state[key]
            if (!item || (now - item.lastFailMs) > root._albumArtFailurePruneMs) {
                delete state[key]
            }
        }

        return failure
    }
    
    function _deleteAlbumArtFile(path) {
        if (!path || path.length === 0) return
        try {
            var escaped = path.replace(/'/g, "'\\''")
            var procCode = `
                import Quickshell.Io
                Process {
                    running: false
                    command: ["sh", "-c", "rm -f '${escaped}'"]
                    onExited: function() { destroy() }
                }
            `
            var proc = Qt.createQmlObject(procCode, root)
            proc.running = true
        } catch (e) {
            console.log("[MusicPlayer] Failed to delete album art file:", path, e)
        }
    }
    
    // ============================================================================
    // INTERNAL STATE
    // ============================================================================
    property string _statusBuffer: ""
    property string _queueBuffer: ""
    property string _statsBuffer: ""
    property string _searchBuffer: ""
    property string _idleBuffer: ""
    property var _searchCallbacks: []
    property var _commandQueue: []
    property var _idleMonitor: null
    property var _queueLines: []
    property var _searchLines: []
    property string _lastSearchQuery: ""
    
    property var _statusPoll: null

    // ============================================================================
    // INITIALIZATION
    // ============================================================================

    Component.onCompleted: {
        loadBookmarks()
        refreshStats()
        refreshStatus()
        refreshQueue()
        
        // Create status polling timer
        var timerCode = `
            import QtQuick
            Timer {
                interval: 1000
                repeat: true
                running: true
                Component.onCompleted: tick()  // Force initial tick
                function tick() { root.refreshStatus() }
                onTriggered: tick()
            }
        `
        
        try {
            root._statusPoll = Qt.createQmlObject(timerCode, root)
        } catch (e) {
            console.log("[MusicPlayer] Failed to create status poll timer:", e)
        }
        
        // Start idle monitoring process
        Qt.callLater(function() {
            startIdleMonitoring()
        })
    }

    // ============================================================================
    // IDLE MONITORING (MPD idle loop)
    // ============================================================================

    function startIdleMonitoring() {
        if (root._idleMonitor) {
            root._idleMonitor.running = false
        }
        
        var procCode = `
            import Quickshell.Io
            Process {
                running: false
                command: ["sh", "-c", "mpc idleloop"]
                stdout: SplitParser { 
                    onRead: function(data) {
                        var line = data.toString().trim()
                        if (line.includes("player") || line.includes("mixer")) {
                            root.refreshStatus()
                        }
                        if (line.includes("playlist")) {
                            root.refreshQueue()
                            root.refreshStatus()
                        }
                    }
                }
                stderr: SplitParser {
                    onRead: function(line) {
                        // Discard stderr output to prevent memory accumulation
                    }
                }
                onExited: function(code) {
                    console.log("[MusicPlayer] Idle monitor exited, restarting...")
                    Qt.callLater(function() { running = true })
                }
            }
        `
        
        try {
            root._idleMonitor = Qt.createQmlObject(procCode, root)
            root._idleMonitor.running = true
        } catch (e) {
            console.log("[MusicPlayer] Failed to start idle monitoring:", e)
        }
    }

    // ============================================================================
    // STATUS REFRESH (Polling)
    // ============================================================================

    property var _statusLines: []
    
    property Process statusProc: Process {
        id: statusProc
        running: false
        command: ["sh", "-c", "mpc current -f '%artist%@@@%album%@@@%title%@@@%file%' && mpc status"]
        stdout: SplitParser {
            onRead: function(data) {
                // SplitParser calls onRead for each line (newline-separated)
                root._statusLines.push(data.toString())
            }
        }
        onExited: function(code) {
            try {
                root._parseStatusLines(root._statusLines)
                root.errorMsg = ""
            } catch (e) {
                console.log("[MusicPlayer] Parse error:", e)
                root.errorMsg = "MPD error: " + e.toString()
                root.status = "stopped"
            }
            root._statusLines = []
        }
    }

    function refreshStatus(force) {
        if (updating && !force) return
        updating = true
        statusProc.running = false
        statusProc.running = true
    }

    function _parseStatusLines(lines) {
        if (lines.length < 3) {
            status = "stopped"
            _clearAlbumArt()
            return
        }

        // Line 0: artist@@@album@@@title@@@file (from mpc current)
        var metaLine = lines[0].trim()
        
        if (metaLine.length > 0 && metaLine.includes('@@@')) {
            var parts = metaLine.split('@@@')
            if (parts.length >= 3) {
                currentArtist = parts[0].trim() || ""
                currentAlbum = parts[1].trim() || ""
                currentSong = parts[2].trim() || ""
                currentFile = parts.length > 3 ? parts[3].trim() : ""
            }
        }
 
        if (currentFile && currentFile.length > 0) {
            _fetchAlbumArtForCurrentTrack(false)
        } else {
            _clearAlbumArt()
        }
 
        // Line 1: Song title (e.g., "Black Star - Astronomy (8th Light)") - skip

        // Line 2: [status] #pos/total time (percent%)
        // Line 3: volume:X% repeat: on/off random: on/off single: on/off consume: on/off
        
        var statusLine = lines[2] || ""
        
        if (statusLine.includes('[playing]')) {
            status = "playing"
        } else if (statusLine.includes('[paused]')) {
            status = "paused"
        } else {
            status = "stopped"
        }

        // Extract position and duration from status line
        // Format: [status]  #1/105   0:06/3:24 (2%)
        var timeMatch = statusLine.match(/(\d+):(\d+)\/(\d+):(\d+)/)
        if (timeMatch) {
            currentPosition = parseInt(timeMatch[1]) * 60 + parseInt(timeMatch[2])
            currentDuration = parseInt(timeMatch[3]) * 60 + parseInt(timeMatch[4])
        }

        var queueMatch = statusLine.match(/#(\d+)\/(\d+)/)
        if (queueMatch) {
            var newPos = parseInt(queueMatch[1]) - 1  // Convert to 0-based
            if (newPos !== queuePosition) {
                console.log("[MusicPlayer] queuePosition changed from " + queuePosition + " to " + newPos + " (queue.length=" + queue.length + ")")
            }
            queuePosition = newPos
            queueLength = parseInt(queueMatch[2])
        }

        // Line 3: volume and modes
        var modeLine = lines[3] || ""
        
        var volMatch = modeLine.match(/volume:\s*(\d+)%/)
        if (volMatch) {
            volume = parseInt(volMatch[1])
        }
        
        repeat = modeLine.includes('repeat: on')
        random = modeLine.includes('random: on')
        single = modeLine.includes('single: on')
        consume = modeLine.includes('consume: on')
        
        updating = false
    }

    function _timeToSeconds(timeStr) {
        timeStr = timeStr.trim()
        var parts = timeStr.split(':')
        if (parts.length === 2) {
            return parseInt(parts[0]) * 60 + parseInt(parts[1])
        }
        return 0
    }

    function _secondsToTime(seconds) {
        seconds = Math.floor(seconds)
        var mins = Math.floor(seconds / 60)
        var secs = seconds % 60
        return (mins < 10 ? "0" : "") + mins + ":" + (secs < 10 ? "0" : "") + secs
    }

    // ============================================================================
    // QUEUE REFRESH
    // ============================================================================

    property Process queueProc: Process {
        id: queueProc
        running: false
        command: ["sh", "-c", "mpc playlist -f '%artist%@@@%album%@@@%title%@@@%file%@@@%time%'"]
        stdout: SplitParser {
            onRead: function(data) {
                // SplitParser calls onRead for each line (newline-separated)
                root._queueLines.push(data.toString())
            }
        }
        onExited: function(code) {
            try {
                console.log("[MusicPlayer] Queue process exited. Lines collected: " + root._queueLines.length + ", queuePosition: " + root.queuePosition)
                root._parseQueue(root._queueLines)
                console.log("[MusicPlayer] After parse: queue.length = " + root.queue.length + ", queuePosition = " + root.queuePosition)
            } catch (e) {
                console.log("[MusicPlayer] Queue parse error:", e)
            }
            root._queueLines = []
        }
    }

    function refreshQueue(force) {
        if (queueProc.running) {
            if (!force) {
                console.log("[MusicPlayer] Queue process already running, skipping refresh")
                return
            }
            console.log("[MusicPlayer] Force restarting queue refresh")
            queueProc.running = false
        }
        console.log("[MusicPlayer] Refreshing queue, current position: " + queuePosition)
        queueProc.running = false
        queueProc.running = true
    }

    function _parseQueue(lines) {
        var q = []
        var validCount = 0
        
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()
            if (line.length === 0) {
                console.log("[MusicPlayer] Skipping empty line at index " + i)
                continue
            }
            validCount++
            
            var parts = line.split('@@@')
            if (parts.length >= 5) {
                q.push({
                    pos: i,  // Position is just the line number
                    artist: parts[0].trim(),
                    album: parts[1].trim(),
                    title: parts[2].trim(),
                    file: parts[3].trim(),
                    duration: parts[4].trim()
                })
            }
        }
        
        queue = q
        queueLength = q.length
        console.log("[MusicPlayer] Queue updated: " + q.length + " items (had " + lines.length + " lines, " + validCount + " valid)")
    }

    // ============================================================================
    // STATS REFRESH
    // ============================================================================

    property Process statsProc: Process {
        id: statsProc
        running: false
        command: ["sh", "-c", "mpc stats"]
        stdout: SplitParser {
            onRead: function(data) {
                root._statsBuffer += data.toString()
            }
        }
        onExited: function(code) {
            try {
                root._parseStats(root._statsBuffer)
            } catch (e) {
                console.log("[MusicPlayer] Stats parse error:", e)
            }
            root._statsBuffer = ""
        }
    }

    function refreshStats(force) {
        if (statsProc.running) {
            if (!force) return
            statsProc.running = false
        }
        statsProc.running = false
        statsProc.running = true
    }
 
    function manualRefresh() {
        console.log("[MusicPlayer] Manual refresh requested")
        _statusLines = []
        _queueLines = []
        _statsBuffer = ""
        refreshStatus(true)
        refreshQueue(true)
        refreshStats(true)
        _fetchAlbumArtForCurrentTrack(true)
    }
 
     function _parseStats(output) {

        var lines = output.split('\n')
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i]
            if (line.includes('Artists:')) {
                totalArtists = parseInt(line.match(/\d+/)[0])
            } else if (line.includes('Albums:')) {
                totalAlbums = parseInt(line.match(/\d+/)[0])
            } else if (line.includes('Songs:')) {
                totalSongs = parseInt(line.match(/\d+/)[0])
            } else if (line.includes('DB Play Time:')) {
                dbPlayTime = line.replace('DB Play Time:', '').trim()
            }
        }
    }

    // ============================================================================
    // PLAYBACK CONTROL
    // ============================================================================

    function togglePlayPause() {
        _executeCommand(["mpc", "toggle"], "togglePlayPause", function() {
            refreshStatus()
        })
    }

    function play() {
        _executeCommand(["mpc", "play"], "play", function() {
            refreshStatus()
        })
    }

    function pause() {
        _executeCommand(["mpc", "pause"], "pause", function() {
            refreshStatus()
        })
    }

    function stop() {
        _executeCommand(["mpc", "stop"], "stop", function() {
            refreshStatus()
        })
    }

    function next() {
        _executeCommand(["mpc", "next"], "next", function() {
            // Single refresh - idle monitor will handle any remaining updates
            Qt.callLater(function() {
                refreshStatus()
                refreshQueue()
            })
        })
    }

    function previous() {
        _executeCommand(["mpc", "prev"], "previous", function() {
            // Single refresh - idle monitor will handle any remaining updates
            Qt.callLater(function() {
                refreshStatus()
                refreshQueue()
            })
        })
    }

    function seek(seconds) {
        var timeStr = _secondsToTime(seconds)
        _executeCommand(["mpc", "seek", timeStr], "seek", function() {
            refreshStatus()
        })
    }

    function seekRelative(delta) {
        var sign = delta >= 0 ? "+" : ""
        var timeStr = _secondsToTime(Math.abs(delta))
        _executeCommand(["mpc", "seek", sign + timeStr], "seekRelative", function() {
            refreshStatus()
        })
    }

    // ============================================================================
    // VOLUME CONTROL
    // ============================================================================

    function setVolume(level) {
        level = Math.max(0, Math.min(100, level))
        _executeCommand(["mpc", "volume", level.toString()], "setVolume", function() {
            refreshStatus()
        })
    }

    function volumeUp(delta) {
        if (!delta) delta = 5
        var newVol = Math.min(100, volume + delta)
        setVolume(newVol)
    }

    function volumeDown(delta) {
        if (!delta) delta = 5
        var newVol = Math.max(0, volume - delta)
        setVolume(newVol)
    }

    // ============================================================================
    // MODE TOGGLES
    // ============================================================================

    function toggleRepeat() {
        var newState = repeat ? "off" : "on"
        _executeCommand(["mpc", "repeat", newState], "toggleRepeat", function() {
            refreshStatus()
        })
    }

    function toggleRandom() {
        var newState = random ? "off" : "on"
        _executeCommand(["mpc", "random", newState], "toggleRandom", function() {
            refreshStatus()
        })
    }

    function toggleSingle() {
        var newState = single ? "off" : "on"
        _executeCommand(["mpc", "single", newState], "toggleSingle", function() {
            refreshStatus()
        })
    }

    function toggleConsume() {
        var newState = consume ? "off" : "on"
        _executeCommand(["mpc", "consume", newState], "toggleConsume", function() {
            refreshStatus()
        })
    }

    // ============================================================================
    // QUEUE MANAGEMENT
    // ============================================================================

    function clearQueue() {
        _executeCommand(["mpc", "clear"], "clearQueue", function() {
            refreshQueue()
            refreshStatus()
        })
    }

    function removeFromQueue(position) {
        // mpc uses 1-based indexing
        _executeCommand(["mpc", "del", (position + 1).toString()], "removeFromQueue", function() {
            refreshQueue()
            refreshStatus()
        })
    }

    function playQueuePosition(pos) {
        // mpc uses 1-based indexing
        _executeCommand(["mpc", "play", (pos + 1).toString()], "playQueuePosition", function() {
            refreshStatus()
            refreshQueue()
        })
    }

    function saveQueueAsPlaylist(name) {
        _executeCommand(["mpc", "save", name], "saveQueueAsPlaylist", function() {
            console.log("[MusicPlayer] Queue saved as playlist:", name)
        })
    }

    // ============================================================================
    // SEARCH & PLAY OPERATIONS
    // ============================================================================

    property Process searchProc: Process {
        id: searchProc
        running: false
        stdout: SplitParser {
            onRead: function(data) {
                // SplitParser calls onRead for each line
                root._searchLines.push(data.toString())
            }
        }
        onExited: function(code) {
            if (root._searchCallbacks.length > 0) {
                var cb = root._searchCallbacks.shift()
                // Join lines back together with newlines for backward compatibility
                cb(root._searchLines.join('\n'))
                
                // If there are more callbacks, trigger the next search
                if (root._searchCallbacks.length > 0) {
                    var types = ["album", "artist", "title"]
                    var nextTypeIndex = 3 - root._searchCallbacks.length  // 0=album, 1=artist, 2=title
                    root._executeSearch(types[nextTypeIndex], root._lastSearchQuery)
                }
            }
            root._searchLines = []
        }
    }

    function searchAlbums(query) {
        root._searchLines = []
        root._searchCallbacks = [function(output) {
            var results = output.split('\n').filter(function(l) { return l.trim().length > 0 })
            var filtered = []
            for (var i = 0; i < results.length && i < 20; i++) {
                filtered.push({
                    type: "album",
                    name: results[i].trim(),
                    artist: "",
                    file: ""
                })
            }
            root._updateSearchResults("albums", filtered)
        }]
        
        searchProc.running = false
        searchProc.command = ["sh", "-c", "mpc search album '" + query.replace(/'/g, "'\\''") + "' 2>/dev/null || true"]
        searchProc.running = true
    }

    function searchArtists(query) {
        root._searchLines = []
        root._searchCallbacks = [function(output) {
            var results = output.split('\n').filter(function(l) { return l.trim().length > 0 })
            var filtered = []
            for (var i = 0; i < results.length && i < 20; i++) {
                filtered.push({
                    type: "artist",
                    name: results[i].trim(),
                    album: "",
                    file: ""
                })
            }
            root._updateSearchResults("artists", filtered)
        }]
        
        searchProc.running = false
        searchProc.command = ["sh", "-c", "mpc search artist '" + query.replace(/'/g, "'\\''") + "' 2>/dev/null || true"]
        searchProc.running = true
    }

    function searchSongs(query) {
        root._searchLines = []
        root._searchCallbacks = [function(output) {
            var lines = output.split('\n').filter(function(l) { return l.trim().length > 0 })
            var filtered = []
            for (var i = 0; i < lines.length && i < 20; i++) {
                var parts = lines[i].split(' - ')
                filtered.push({
                    type: "song",
                    name: parts.slice(1).join(' - ') || lines[i],
                    artist: parts[0] || "",
                    file: lines[i]  // Full output includes filename
                })
            }
            root._updateSearchResults("songs", filtered)
        }]
        
        searchProc.running = false
        searchProc.command = ["sh", "-c", "mpc search title '" + query.replace(/'/g, "'\\''") + "' 2>/dev/null || true"]
        searchProc.running = true
    }

    function searchAll(query) {
        // Perform all three searches
        var results = { albums: [], artists: [], songs: [] }
        var completed = 0
        
        root._lastSearchQuery = query
        root._searchLines = []
        root._searchCallbacks = [
            function(output) {
                // Albums
                var lines = output.split('\n').filter(function(l) { return l.trim().length > 0 })
                for (var i = 0; i < lines.length && i < 20; i++) {
                    results.albums.push({
                        type: "album",
                        name: lines[i].trim(),
                        artist: "",
                        file: ""
                    })
                }
                completed++
                if (completed === 3) root._finalizeSearchAll(results)
            },
            function(output) {
                // Artists
                var lines = output.split('\n').filter(function(l) { return l.trim().length > 0 })
                for (var i = 0; i < lines.length && i < 20; i++) {
                    results.artists.push({
                        type: "artist",
                        name: lines[i].trim(),
                        album: "",
                        file: ""
                    })
                }
                completed++
                if (completed === 3) root._finalizeSearchAll(results)
            },
            function(output) {
                // Songs
                var lines = output.split('\n').filter(function(l) { return l.trim().length > 0 })
                for (var i = 0; i < lines.length && i < 20; i++) {
                    var parts = lines[i].split(' - ')
                    results.songs.push({
                        type: "song",
                        name: parts.slice(1).join(' - ') || lines[i],
                        artist: parts[0] || "",
                        file: lines[i]
                    })
                }
                completed++
                if (completed === 3) root._finalizeSearchAll(results)
            }
        ]
        
        // Execute all three searches in sequence
        root._executeSearch("album", query)
    }

    function _executeSearch(type, query) {
        root._searchLines = []
        searchProc.running = false
        
        var cmd = ""
        if (type === "album") {
            // Use mpc list to get album names, then filter with grep
            cmd = "mpc list album | grep -i '" + query.replace(/'/g, "'\\''") + "' 2>/dev/null || true"
        } else if (type === "artist") {
            // Use mpc list to get artist names, then filter with grep
            cmd = "mpc list artist | grep -i '" + query.replace(/'/g, "'\\''") + "' 2>/dev/null || true"
        } else if (type === "title") {
            // For titles, use mpc search and extract just the title from the file path
            cmd = "mpc search title '" + query.replace(/'/g, "'\\''") + "' 2>/dev/null || true"
        }
        
        searchProc.command = ["sh", "-c", cmd]
        searchProc.running = true
    }

    function _updateSearchResults(category, results) {
        var current = searchResults.length > 0 ? searchResults : []
        current = current.filter(function(r) { return r.type !== category })
        searchResults = current.concat(results)
    }

    function _finalizeSearchAll(results) {
        searchResults = results.albums.concat(results.artists, results.songs)
    }

    function playAlbum(albumName) {
        _executeCommand(["sh", "-c", "mpc clear && mpc findadd album '" + albumName.replace(/'/g, "'\\''") + "' && mpc play"], "playAlbum", function() {
            refreshQueue()
            refreshStatus()
        })
    }

    function playArtist(artistName) {
        _executeCommand(["sh", "-c", "mpc clear && mpc findadd artist '" + artistName.replace(/'/g, "'\\''") + "' && mpc play"], "playArtist", function() {
            refreshQueue()
            refreshStatus()
        })
    }

    function playSong(filePath) {
        // Insert song right after current song and play it next
        // This keeps the queue intact and plays the bookmarked song immediately
        var nextPos = queuePosition + 2  // Position right after current song (1-based for mpc)
        _executeCommand(
            ["sh", "-c", "mpc insert '" + filePath.replace(/'/g, "'\\''") + "' && mpc play " + nextPos + " && sleep 0.2"],
            "playSong",
            function() {
                // Ensure queue and status are fully refreshed
                refreshQueue()
                refreshStatus()
                // Add second refresh to catch any delayed metadata updates
                Qt.callLater(function() {
                    refreshStatus()
                }, 300)
            }
        )
    }

    function addAlbumToQueue(albumName) {
        _executeCommand(["mpc", "findadd", "album", albumName], "addAlbumToQueue", function() {
            refreshQueue()
        })
    }

    function addArtistToQueue(artistName) {
        _executeCommand(["mpc", "findadd", "artist", artistName], "addArtistToQueue", function() {
            refreshQueue()
        })
    }

    function addSongToQueue(filePath) {
        _executeCommand(["mpc", "add", filePath], "addSongToQueue", function() {
            refreshQueue()
        })
    }

    // ============================================================================
    // BOOKMARKS (Persistence)
    // ============================================================================

    function addBookmark(type, name, query) {
        var bm = bookmarks.slice()  // Copy array
        bm.push({ type: type, name: name, query: query })
        bookmarks = bm
        saveBookmarks()
    }

    function removeBookmark(index) {
        var bm = bookmarks.slice()
        bm.splice(index, 1)
        bookmarks = bm
        saveBookmarks()
    }

    function loadBookmarks() {
        var bookmarkFile = "/mnt/gargantua/media/music/data/bookmarks.json"
        
        try {
            var procCode = `
                import Quickshell.Io
                Process {
                    running: false
                    stdout: SplitParser { }
                }
            `
            
            var proc = Qt.createQmlObject(procCode, root)
            var output = ""
            
            proc.stdout.onRead.connect(function(data) {
                output += data.toString()
            })
            
            proc.onExited.connect(function(code) {
                try {
                    root.bookmarks = JSON.parse(output)
                } catch (e) {
                    console.log("[MusicPlayer] Failed to load bookmarks:", e)
                    root.bookmarks = []
                }
                proc.destroy()
            })
            
            proc.command = ["sh", "-c", "test -f '" + bookmarkFile + "' && cat '" + bookmarkFile + "' || echo '[]'"]
            proc.running = true
        } catch (e) {
            console.log("[MusicPlayer] Error loading bookmarks:", e)
            root.bookmarks = []
        }
    }

    function saveBookmarks() {
        var bookmarkFile = "/mnt/gargantua/media/music/data/bookmarks.json"
        
        var json = JSON.stringify(bookmarks, null, 2)
        _executeCommand(["sh", "-c", "mkdir -p '/mnt/gargantua/media/music/data' && printf '%s' '" + json.replace(/'/g, "'\\''") + "' > '" + bookmarkFile + "'"], "saveBookmarks")
    }

    // ============================================================================
    // GENERIC COMMAND EXECUTOR
    // ============================================================================

    property Process cmdProc: Process {
        id: cmdProc
        running: false
        stdout: SplitParser {
            onRead: function(data) {
                // Discard output for generic commands
            }
        }
        onExited: function(code) {
            if (root._commandQueue.length > 0) {
                var item = root._commandQueue.shift()
                if (item.callback) {
                    item.callback()
                }
                root._executeNextCommand()
            }
        }
    }

    function _executeCommand(cmd, label, callback) {
        root._commandQueue.push({ cmd: cmd, label: label, callback: callback })
        if (!cmdProc.running) {
            root._executeNextCommand()
        }
    }

    function _executeNextCommand() {
        if (root._commandQueue.length === 0) return
        
        var item = root._commandQueue[0]
        cmdProc.running = false
        cmdProc.command = item.cmd
        cmdProc.running = true
    }
}
