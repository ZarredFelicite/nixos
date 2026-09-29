pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
  id: root

  property bool gatewayUp: false
  property bool isGenerating: false
  property string activityPhase: "idle" // idle, thinking, tool, text
  property bool isThinkingOrToolActive: isGenerating && (activityPhase === "thinking" || activityPhase === "tool")
  property bool isTextGenerating: isGenerating && activityPhase === "text"
  property int activeSessions: 0
  property string baseUrl: "https://web.manticore-lenok.ts.net"
  readonly property string apiHelperPath: String(Quickshell.env("HOME") || "")
                                         + "/.config/quickshell/primary/scripts/ember-curl.sh"
  readonly property bool lowPowerMode: Quickshell.env("QUICKSHELL_LOW_POWER_MODE") === "1"
  readonly property int pollIntervalMs: lowPowerMode ? 10000 : 2000
  property string lastError: ""
  property var heartbeatSessionIds: ({})

  function _updateFromSessions(raw) {
    var text = raw.toString().trim()
    if (text.indexOf("__EMBER_SESSIONS__") !== 0) return

    try {
      var rows = JSON.parse(text.slice(18))
      var ids = {}
      for (var i = 0; i < rows.length; i++) {
        if (rows[i] && rows[i].kind === "heartbeat")
          ids[rows[i].id] = true
      }
      heartbeatSessionIds = ids
    } catch (e) {
      lastError = "Bad Ember session JSON"
    }
  }

  function _updateFromStatus(raw) {
    var text = raw.toString().trim()
    if (!text.length) return
    if (text === "__EMBER_DOWN__") {
      gatewayUp = false
      isGenerating = false
      activityPhase = "idle"
      activeSessions = 0
      lastError = "Ember API unavailable"
      return
    }
    if (text.indexOf("__EMBER_STATUS__") !== 0) return

    gatewayUp = true
    lastError = ""

    try {
      var rows = JSON.parse(text.slice(16))
      var active = 0
      var statusPhase = ""
      for (var i = 0; i < rows.length; i++) {
        if (rows[i] && heartbeatSessionIds[rows[i].sessionID]) continue
        var type = rows[i] && rows[i].status ? rows[i].status.type : ""
        if (type && type !== "idle") {
          active++
          var lower = String(type).toLowerCase()
          if (lower.indexOf("tool") !== -1) statusPhase = "tool"
          else if (!statusPhase && (lower.indexOf("think") !== -1 || lower.indexOf("reason") !== -1)) statusPhase = "thinking"
          else if (!statusPhase && (lower.indexOf("text") !== -1 || lower.indexOf("stream") !== -1 || lower.indexOf("generat") !== -1)) statusPhase = "text"
        }
      }
      activeSessions = active
      isGenerating = active > 0
      if (active === 0) {
        activityPhase = "idle"
      } else if (statusPhase.length) {
        activityPhase = statusPhase
      } else if (activityPhase === "idle") {
        activityPhase = "thinking"
      }
    } catch (e) {
      lastError = "Bad Ember status JSON"
    }
  }

  function _updateFromEvent(raw) {
    var line = raw.toString().trim()
    if (line.indexOf("data:") !== 0)
      return
    var data = line.slice(5).trim()
    if (!data.length || data === "[DONE]")
      return

    var event
    try {
      event = JSON.parse(data)
    } catch (e) {
      return
    }

    var properties = event.properties || {}
    var sessionId = properties.sessionID
      || (properties.info && properties.info.sessionID)
      || (properties.part && properties.part.sessionID)
      || (properties.message && properties.message.info && properties.message.info.sessionID)
      || ""
    if (sessionId && heartbeatSessionIds[sessionId])
      return

    var text = JSON.stringify(event)
    if (event.type === "server.connected" || event.type === "server.heartbeat")
      return

    if (text.indexOf('"role":"toolResult"') !== -1 || text.indexOf('"toolCallId"') !== -1 || text.indexOf('"toolName"') !== -1) {
      activityPhase = "tool"
    } else if (text.indexOf('"textSignature"') !== -1 || text.indexOf('"phase":"final_answer"') !== -1 || text.indexOf('"type":"text"') !== -1) {
      activityPhase = "text"
    } else if (text.indexOf('"type":"toolCall"') !== -1) {
      activityPhase = "tool"
    } else if (text.indexOf('"type":"thinking"') !== -1 || text.indexOf('"thinkingSignature"') !== -1) {
      activityPhase = "thinking"
    }
  }

  property Process eventWatcher: Process {
    command: [
      "sh", "-c",
      "while true; do " +
      "\"" + root.apiHelperPath + "\" -fsS -N " + root.baseUrl + "/api/event 2>/dev/null || true; " +
      "sleep 2; " +
      "done"
    ]
    stdout: SplitParser { onRead: function(line) { root._updateFromEvent(line) } }
    stderr: SplitParser { onRead: function(_) {} }
    running: true
  }

  property Process watcher: Process {
    command: [
      "sh", "-c",
      "while true; do " +
      "if \"" + root.apiHelperPath + "\" -fsS --max-time 5 " + root.baseUrl + "/api/help >/dev/null 2>&1; then " +
      "printf '__EMBER_SESSIONS__'; \"" + root.apiHelperPath + "\" -fsS --max-time 5 " + root.baseUrl + "/api/session; printf '\\n'; " +
      "printf '__EMBER_STATUS__'; \"" + root.apiHelperPath + "\" -fsS --max-time 5 " + root.baseUrl + "/api/session/status; printf '\\n'; " +
      "else echo __EMBER_DOWN__; fi; " +
      "sleep " + (root.pollIntervalMs / 1000) + "; " +
      "done"
    ]
    stdout: SplitParser {
      onRead: function(line) {
        root._updateFromSessions(line)
        root._updateFromStatus(line)
      }
    }
    stderr: SplitParser {
      onRead: function(_) {}
    }
    running: true
  }
}
