pragma Singleton

import QtQuick
import Quickshell.Io

QtObject {
  id: root

  property bool enabled: true
  property int intervalMs: 15000
  property int startupReportDelayMs: 10 * 60 * 1000
  property string reportLogPath: "/home/zarred/.local/state/quickshell-memory-watchdog.log"
  property double sessionStartMs: 0
  property int logEverySamples: 20
  property int warnRssMb: 700
  property int _lastWarnMb: 0
  property int sampleCount: 0

  property int rssKb: 0
  property int vmsKb: 0
  property int swapKb: 0
  property int peakRssKb: 0
  property int startupRootRssKb: 0
  property int startupTreeRssKb: 0
  property int startupProcessCount: 0

  property string _buffer: ""
  property string _startupReportBuffer: ""

  function start() {
    if (!enabled) return
    sessionStartMs = Date.now()
    sampleTimer.running = true
    startupReportTimer.running = true
    appendReportLog("session_start interval_ms=" + intervalMs + " delayed_report_ms=" + startupReportDelayMs)
    sample()
  }

  function stop() {
    sampleTimer.running = false
    startupReportTimer.running = false
    sampleProc.running = false
    startupReportProc.running = false
  }

  function sample() {
    if (!enabled || sampleProc.running) return
    _buffer = ""
    sampleProc.running = false
    sampleProc.running = true
  }

  function _formatMb(kb) {
    return (kb / 1024.0).toFixed(1)
  }

  function _minutesLabel(ms) {
    return Math.round(ms / 60000.0) + "m"
  }

  function _elapsedMinutesLabel() {
    if (!sessionStartMs) return _minutesLabel(startupReportDelayMs)
    return Math.max(1, Math.round((Date.now() - sessionStartMs) / 60000.0)) + "m"
  }

  function appendReportLog(message) {
    if (!message || reportLogProc.running) return
    var escapedMessage = message.replace(/'/g, "'\\''")
    var escapedPath = reportLogPath.replace(/'/g, "'\\''")
    reportLogProc.command = [
      "sh",
      "-c",
      "mkdir -p \"$(dirname '" + escapedPath + "')\" && printf '%s %s\\n' \"$(date -Iseconds)\" '" + escapedMessage + "' >> '" + escapedPath + "'"
    ]
    reportLogProc.running = false
    reportLogProc.running = true
  }

  function _parseBuffer() {
    var lines = (_buffer || "").split(/\n+/)
    var nextRss = rssKb
    var nextVms = vmsKb
    var nextSwap = swapKb

    for (var i = 0; i < lines.length; i++) {
      var ln = lines[i].trim()
      if (!ln) continue
      var parts = ln.split(/\s+/)
      if (parts.length < 2) continue
      var key = parts[0]
      var val = parseInt(parts[1])
      if (isNaN(val)) continue
      if (key === "VmRSS:") nextRss = val
      else if (key === "VmSize:") nextVms = val
      else if (key === "VmSwap:") nextSwap = val
    }

    rssKb = nextRss
    vmsKb = nextVms
    swapKb = nextSwap
    if (rssKb > peakRssKb) peakRssKb = rssKb

    sampleCount += 1
    if (sampleCount === 1 || sampleCount % logEverySamples === 0) {
      console.log(
        "[MemoryWatchdog] rss=" + _formatMb(rssKb) + "MB"
        + " vms=" + _formatMb(vmsKb) + "MB"
        + " swap=" + _formatMb(swapKb) + "MB"
        + " peak=" + _formatMb(peakRssKb) + "MB"
      )
    }

    var rssMb = Math.round(rssKb / 1024.0)
    if (rssMb >= warnRssMb && (rssMb - _lastWarnMb >= 100 || _lastWarnMb === 0)) {
      _lastWarnMb = rssMb
      console.log("[MemoryWatchdog] WARNING high RSS: " + rssMb + "MB")
    }
  }

  function captureStartupReport() {
    if (!enabled || startupReportProc.running) return
    _startupReportBuffer = ""
    startupReportProc.running = false
    startupReportProc.running = true
  }

  function _parseStartupReport() {
    var lines = (_startupReportBuffer || "").split(/\n+/)
    var nextRootRss = 0
    var nextTreeRss = 0
    var nextProcessCount = 0

    for (var i = 0; i < lines.length; i++) {
      var ln = lines[i].trim()
      if (!ln) continue
      var parts = ln.split(/\s+/)
      if (parts.length < 2) continue
      var key = parts[0]
      var val = parseInt(parts[1])
      if (isNaN(val)) continue
      if (key === "root_rss_kb") nextRootRss = val
      else if (key === "tree_rss_kb") nextTreeRss = val
      else if (key === "process_count") nextProcessCount = val
    }

    startupRootRssKb = nextRootRss
    startupTreeRssKb = nextTreeRss
    startupProcessCount = nextProcessCount

    var elapsedLabel = _elapsedMinutesLabel()
    var reportLine = elapsedLabel
      + " tree_rss_mb=" + _formatMb(startupTreeRssKb)
      + " process_count=" + startupProcessCount
      + " root_rss_mb=" + _formatMb(startupRootRssKb)
      + " peak_root_rss_mb=" + _formatMb(peakRssKb)

    appendReportLog(reportLine)

    console.log(
      "[MemoryWatchdog] " + elapsedLabel + " tree rss=" + _formatMb(startupTreeRssKb) + "MB"
      + " processes=" + startupProcessCount
      + " root_rss=" + _formatMb(startupRootRssKb) + "MB"
      + " peak_root_rss=" + _formatMb(peakRssKb) + "MB"
    )
  }

  property Timer sampleTimer: Timer {
    interval: root.intervalMs
    repeat: true
    running: false
    onTriggered: root.sample()
  }

  property Timer startupReportTimer: Timer {
    interval: root.startupReportDelayMs
    repeat: true
    running: false
    onTriggered: root.captureStartupReport()
  }

  property Process sampleProc: Process {
    running: false
    command: [
      "sh",
      "-c",
      "awk '/VmRSS:|VmSize:|VmSwap:/ { print $1 \" \" $2 }' /proc/$PPID/status 2>/dev/null"
    ]
    stdout: SplitParser {
      onRead: function(line) {
        root._buffer += line + "\n"
      }
    }
    stderr: SplitParser {
      onRead: function(_) {
      }
    }
    onExited: function() {
      root._parseBuffer()
      root._buffer = ""
    }
  }

  property Process startupReportProc: Process {
    running: false
    command: [
      "sh",
      "-c",
      "root_pid=$PPID; root_rss=0; sum=0; count=0; queue=\"$root_pid\"; while [ -n \"$queue\" ]; do next=\"\"; for pid in $queue; do [ -r \"/proc/$pid/status\" ] || continue; rss=$(awk '/VmRSS:/ { print $2; exit }' \"/proc/$pid/status\" 2>/dev/null); [ -n \"$rss\" ] || rss=0; [ \"$pid\" = \"$root_pid\" ] && root_rss=$rss; sum=$((sum + rss)); count=$((count + 1)); children=$(ps -o pid= --ppid \"$pid\" 2>/dev/null); [ -n \"$children\" ] && next=\"$next $children\"; done; queue=$next; done; printf 'root_rss_kb %s\\ntree_rss_kb %s\\nprocess_count %s\\n' \"$root_rss\" \"$sum\" \"$count\""
    ]
    stdout: SplitParser {
      onRead: function(line) {
        root._startupReportBuffer += line + "\n"
      }
    }
    stderr: SplitParser {
      onRead: function(_) {
      }
    }
    onExited: function() {
      root._parseStartupReport()
      root._startupReportBuffer = ""
    }
  }

  property Process reportLogProc: Process {
    running: false
    stderr: SplitParser {
      onRead: function(_) {
      }
    }
  }
}
