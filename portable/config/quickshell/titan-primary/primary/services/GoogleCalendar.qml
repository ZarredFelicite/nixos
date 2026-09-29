pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
  id: root

  readonly property string cliPath: "/home/zarred/scripts/notes/tasknotes-cli-go/tn"
  readonly property int agendaDays: 7
  property int refCount: 0
  property bool connected: false
  property bool checking: false
  property string error: ""
  property var events: []
  property date lastUpdated: new Date(0)
  property double lastManualRefreshMs: 0

  readonly property int refreshIntervalMs: 5 * 60 * 1000
  readonly property int minManualRefreshMs: 10 * 1000

  property string _statusOutput: ""
  property string _eventsOutput: ""

  property Timer refreshTimer: Timer {
    interval: root.refreshIntervalMs
    repeat: true
    running: root.refCount > 0
    onTriggered: root.refresh(false)
  }

  property Process statusProcess: Process {
    running: false
    stdout: SplitParser {
      onRead: function(data) { root._statusOutput += data.toString() }
    }
    onExited: function(code) { root._handleStatusResult(code) }
  }

  property Process eventsProcess: Process {
    running: false
    stdout: SplitParser {
      onRead: function(data) { root._eventsOutput += data.toString() }
    }
    onExited: function(code) { root._handleEventsResult(code) }
  }

  onRefCountChanged: {
    if (refCount > 0 && lastUpdated.getTime() === 0 && !checking) refresh(false)
  }

  function refresh(manual) {
    if (checking) return
    if (manual === true) {
      var nowMs = Date.now()
      if (nowMs - lastManualRefreshMs < minManualRefreshMs) return
      lastManualRefreshMs = nowMs
    }

    checking = true
    error = ""
    _statusOutput = ""
    statusProcess.command = [cliPath, "calendars", "google", "--json"]
    statusProcess.running = true
  }

  function _handleStatusResult(code) {
    var output = _statusOutput
    _statusOutput = ""
    if (code !== 0) {
      connected = false
      events = []
      error = "Calendar service unavailable"
      checking = false
      lastUpdated = new Date()
      return
    }

    try {
      var payload = JSON.parse(output.trim())
      if (!payload || payload.success !== true || !payload.data
          || typeof payload.data.connected !== "boolean") {
        throw new Error("Unexpected status response")
      }
      connected = payload.data.connected
    } catch (e) {
      connected = false
      events = []
      error = "Could not read Google Calendar status"
      checking = false
      lastUpdated = new Date()
      return
    }

    if (!connected) {
      events = []
      checking = false
      lastUpdated = new Date()
      return
    }

    _eventsOutput = ""
    eventsProcess.command = [
      cliPath,
      "calendars",
      "events",
      "--start", _localDateString(new Date()),
      "--end", _localDateString(_addDays(new Date(), agendaDays)),
      "--json"
    ]
    eventsProcess.running = true
  }

  function _handleEventsResult(code) {
    var output = _eventsOutput
    _eventsOutput = ""
    if (code !== 0) {
      events = []
      error = "Could not load upcoming events"
      checking = false
      lastUpdated = new Date()
      return
    }

    try {
      var payload = JSON.parse(output.trim())
      if (!payload || payload.success !== true || !payload.data
          || !Array.isArray(payload.data.events)) {
        throw new Error("Unexpected events response")
      }
      var rawEvents = payload.data.events
      var normalized = []
      var nowMs = Date.now()

      for (var i = 0; i < rawEvents.length; i++) {
        var event = rawEvents[i]
        if (String(event.provider || "").toLowerCase() !== "google") continue
        var parsed = _normalizeEvent(event)
        if (!parsed) continue
        if (!parsed.allDay && parsed.endMs > 0 && parsed.endMs < nowMs) continue
        normalized.push(parsed)
      }

      normalized.sort(function(a, b) { return a.startMs - b.startMs })
      events = normalized
      error = ""
    } catch (e) {
      events = []
      error = "Could not read upcoming events"
    }

    checking = false
    lastUpdated = new Date()
  }

  function _normalizeEvent(event) {
    var startRaw = String(event.start || "")
    if (!startRaw) return null

    var allDay = !!event.allDay || /^\d{4}-\d{2}-\d{2}$/.test(startRaw)
    var startDate = allDay ? _parseLocalDate(startRaw.slice(0, 10)) : new Date(startRaw)
    if (!startDate || isNaN(startDate.getTime())) return null

    var endRaw = String(event.end || "")
    var endDate = endRaw
      ? (allDay && /^\d{4}-\d{2}-\d{2}$/.test(endRaw)
          ? _parseLocalDate(endRaw)
          : new Date(endRaw))
      : null
    var endMs = endDate && !isNaN(endDate.getTime()) ? endDate.getTime() : 0

    return {
      id: String(event.id || startRaw + "-" + (event.summary || event.title || "event")),
      title: String(event.summary || event.title || "Untitled event"),
      location: String(event.location || ""),
      allDay: allDay,
      startMs: startDate.getTime(),
      endMs: endMs,
      dayKey: _localDateString(startDate),
      dayLabel: _dayLabel(startDate),
      timeLabel: allDay ? "All day" : _timeRange(startDate, endDate)
    }
  }

  function _timeRange(startDate, endDate) {
    var start = Qt.formatDateTime(startDate, "h:mm AP")
    if (!endDate || isNaN(endDate.getTime())) return start
    return start + " – " + Qt.formatDateTime(endDate, "h:mm AP")
  }

  function _dayLabel(date) {
    var today = _localDateString(new Date())
    var tomorrow = _localDateString(_addDays(new Date(), 1))
    var key = _localDateString(date)
    if (key === today) return "Today"
    if (key === tomorrow) return "Tomorrow"
    return Qt.formatDateTime(date, "dddd, d MMMM")
  }

  function _parseLocalDate(value) {
    var parts = String(value).split("-")
    if (parts.length !== 3) return null
    return new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]), 0, 0, 0, 0)
  }

  function _localDateString(date) {
    return date.getFullYear() + "-" + _pad2(date.getMonth() + 1) + "-" + _pad2(date.getDate())
  }

  function _addDays(date, days) {
    var result = new Date(date.getTime())
    result.setDate(result.getDate() + days)
    return result
  }

  function _pad2(value) {
    return value < 10 ? "0" + value : String(value)
  }
}
