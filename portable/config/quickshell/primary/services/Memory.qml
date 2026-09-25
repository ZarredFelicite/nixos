pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Memory usage service reading /proc/meminfo
QtObject {
  id: root

  // Public properties
  property int memTotalKb: 0
  property int memAvailableKb: 0
  property int memUsedKb: 0
  property real memPercent: 0.0 // 0..1

  property int swapTotalKb: 0
  property int swapFreeKb: 0
  property int swapUsedKb: 0
  property real swapPercent: 0.0 // 0..1

  property string error: ""
  property date lastUpdated: new Date(0)
  property string tooltipText: ""

  // Polling control
  property int refCount: 0
  property int interval: 3000

  onRefCountChanged: {
    pollTimer.running = (root.refCount > 0)
    if (root.refCount > 0) update()
  }

  property Timer pollTimer: Timer {
    id: pollTimer
    interval: root.interval
    running: false
    repeat: true
    onTriggered: update()
  }

  // Process to read meminfo
  property Process pollProcess: Process {
    id: pollProcess
    running: false
    command: ["/run/current-system/sw/bin/cat", "/proc/meminfo"]
    stdout: SplitParser {
      onRead: function(line) { root._buffer += line + "\n" }
    }
    onExited: function() { root.parseMeminfo(root._buffer); root._buffer = "" }
  }
  property string _buffer: ""

  function parseMeminfo(text) {
    try {
      var total = 0, avail = 0, swapTotal = 0, swapFree = 0
      var lines = (text || "").split(/\n+/)
      for (var i=0;i<lines.length;i++) {
        var ln = lines[i]
        if (!ln) continue
        // Format: Key: value kB
        if (ln.indexOf('MemTotal:') === 0) {
          total = parseInt(ln.replace(/[^0-9]/g, ''))
        } else if (ln.indexOf('MemAvailable:') === 0) {
          avail = parseInt(ln.replace(/[^0-9]/g, ''))
        } else if (ln.indexOf('SwapTotal:') === 0) {
          swapTotal = parseInt(ln.replace(/[^0-9]/g, ''))
        } else if (ln.indexOf('SwapFree:') === 0) {
          swapFree = parseInt(ln.replace(/[^0-9]/g, ''))
        }
      }
      if (!isFinite(total) || total <= 0) total = 0
      if (!isFinite(avail) || avail < 0) avail = 0
      if (!isFinite(swapTotal) || swapTotal < 0) swapTotal = 0
      if (!isFinite(swapFree) || swapFree < 0) swapFree = 0

      root.memTotalKb = total
      root.memAvailableKb = avail
      var used = Math.max(0, total - avail)
      root.memUsedKb = used
      root.memPercent = total > 0 ? Math.max(0, Math.min(1, used / total)) : 0

      root.swapTotalKb = swapTotal
      root.swapFreeKb = swapFree
      var swapUsed = Math.max(0, swapTotal - swapFree)
      root.swapUsedKb = swapUsed
      root.swapPercent = swapTotal > 0 ? Math.max(0, Math.min(1, swapUsed / swapTotal)) : 0

      root.lastUpdated = new Date()
      root.error = ""
      root.tooltipText = buildTooltip()
    } catch (e) {
      root.error = e.toString()
    }
  }

  function update() {
    if (root.refCount === 0) return
    pollProcess.running = false
    pollProcess.running = true
  }

  function kbToGiB(kb) {
    if (!isFinite(kb) || kb <= 0) return 0
    return kb / (1024 * 1024)
  }
  function pctStr(p01) {
    var p = Math.round((Math.max(0, Math.min(1, p01))) * 100)
    return p + '%'
  }
  function fmtGiB(n) {
    if (!isFinite(n) || n <= 0) return '0.0'
    var s = n.toFixed(1)
    if (s.indexOf('.') !== -1) s = s.replace(/0+$/,'').replace(/\.$/,'')
    return s
  }
  function buildTooltip() {
    var memT = kbToGiB(root.memTotalKb)
    var memU = kbToGiB(root.memUsedKb)
    var swapT = kbToGiB(root.swapTotalKb)
    var swapU = kbToGiB(root.swapUsedKb)
    var lines = []
    if (root.memTotalKb > 0) lines.push(`Memory: ${fmtGiB(memU)}/${fmtGiB(memT)} GiB (${pctStr(root.memPercent)})`)
    else lines.push('Memory: —')
    if (root.swapTotalKb > 0) lines.push(`Swap: ${fmtGiB(swapU)}/${fmtGiB(swapT)} GiB (${pctStr(root.swapPercent)})`)
    else lines.push('Swap: disabled')
    return lines.join('\n')
  }
}
