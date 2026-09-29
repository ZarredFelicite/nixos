pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Disk usage service parses `df -h` output periodically.
// Focus:
//  - Main disk: first line whose Filesystem matches /dev/mapper/root
//  - Remote mounts: sankara:/mnt/eros, /ceres, /gargantua (match by Mounted on)
// Exposes structured data for tooltip & ring widget.
QtObject {
  id: root

  // Polling
  property int interval: 30000 // 30s
  property Timer pollTimer: Timer {
    interval: root.interval
    repeat: true
    running: true
    onTriggered: root.update()
  }

  // Raw df lines captured (excluding header)
  property var lines: []

  // Main disk fields
  property string mainFilesystem: ""
  property string mainMount: ""
  property string mainSize: ""   // human-readable e.g. 932G
  property string mainUsed: ""
  property string mainAvail: ""
  property int mainUsePercent: 0  // integer percent 0-100

  // Remote mounts of interest (array of objects: {filesystem, shortName, mount, size, used, avail, usePercent})
  property var remoteMounts: []

  // Remote detection now matches only filesystem pattern: sankara:/mnt/(eros|ceres|gargantua)
  // Mount points are ignored for identification; shortName captured from filesystem.

  // Public error string
  property string error: ""

  // When the most recent df run completed
  property date lastUpdated: new Date(0)

  // Helper: parse percentage string like "45%" -> 45
  function parsePercent(p) {
    if (!p) return 0
    const m = /([0-9]+)/.exec(p)
    return m ? Math.min(100, Math.max(0, parseInt(m[1]))) : 0
  }

  // Execute df -h
  function update() {
    root.lines = []
    root._headerSeen = false
    dfProcess.running = false
    dfProcess.running = true
  }

  // Extract first matching /dev/mapper/root line
  function extractMain(lines) {
    for (let i=0;i<lines.length;i++) {
      const rec = parseLine(lines[i])
      if (!rec) continue
      if (rec.filesystem === '/dev/mapper/root') {
        root.mainFilesystem = rec.filesystem
        root.mainMount = rec.mount
        root.mainSize = rec.size
        root.mainUsed = rec.used
        root.mainAvail = rec.avail
        root.mainUsePercent = rec.usePercent
        return
      }
    }
  }

  function isRemoteTarget(rec) {
    if (!rec) return false
    return /^sankara:\/mnt\/(eros|ceres|gargantua)$/.test(rec.filesystem)
  }

  function extractRemotes(lines) {
    const map = {}
    for (let i=0;i<lines.length;i++) {
      const rec = parseLine(lines[i])
      if (!rec) continue
      if (!isRemoteTarget(rec)) continue
      const m = /^sankara:\/mnt\/(eros|ceres|gargantua)$/.exec(rec.filesystem)
      if (!m) continue
      const shortName = m[1]
      // Deduplicate by shortName; prefer first occurrence
      if (map[shortName]) continue
      rec.shortName = shortName
      map[shortName] = rec
    }
    const arr = []
    for (const k in map) arr.push(map[k])
    // Stable order preferred
    arr.sort(function(a,b){ return a.shortName.localeCompare(b.shortName) })
    root.remoteMounts = arr
  }

  // Generic df -h line parser.
  // Standard columns: Filesystem Size Used Avail Use% Mounted on
  // Some FS names may contain spaces (rare) so rely on splitting into at least 6 fields then consolidate extras.
  function parseLine(line) {
    if (!line || line.trim() === '') return null
    const parts = line.trim().split(/\s+/)
    if (parts.length < 6) return null
    // When more than 6 parts, assume filesystem column had spaces; join leading extras until remaining 5 columns.
    while (parts.length > 6) {
      // Merge first two tokens
      parts[0] = parts[0] + '_' + parts[1]
      parts.splice(1,1)
    }
    const filesystem = parts[0]
    const size = parts[1]
    const used = parts[2]
    const avail = parts[3]
    const usePercent = parsePercent(parts[4])
    const mount = parts[5]
    return { filesystem, size, used, avail, usePercent, mount }
  }

  // Provide aggregated numeric usage for ring (main disk). If no data yet, 0.
  property int mainPercent: mainUsePercent

  // Kick initial update shortly after load
  Component.onCompleted: update()

  // df process executed on demand
  // Internal state for parsing
  property bool _headerSeen: false

  property Process dfProcess: Process {
    id: dfProcess
    running: false
    // Ignore SSHFS mounts: a disconnected FUSE server can block df in uninterruptible I/O.
    command: ["df", "-h", "-x", "fuse.sshfs"]
    stdout: SplitParser {
      onRead: function(line) {
        if (!root._headerSeen) {
          if (/^Filesystem\s+/.test(line)) {
            root._headerSeen = true
          }
          return
        }
        if (line.trim() === '') return
        root.lines = root.lines.concat([line])
      }
    }
    onExited: function() {
      try {
        extractMain(root.lines)
        extractRemotes(root.lines)
        root.error = ''
      } catch (e) {
        root.error = '' + e
      }
      root.lastUpdated = new Date()
      root.lines = []
      root._headerSeen = false
    }
  }
}
