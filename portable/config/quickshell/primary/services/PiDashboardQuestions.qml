pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "."

QtObject {
  id: root

  // Portable shell has no Pi Dashboard endpoint; keep the service offline.
  readonly property string apiUrl: ""
  readonly property string scriptPath: String(Qt.resolvedUrl("../scripts/pi_dashboard_questions.py")).replace("file://", "")

  property bool available: false
  property bool loading: true
  property string error: ""
  property var questions: []
  property var finalMessages: []
  property string focusedFinalSessionId: ""
  readonly property var visibleFinalMessages: focusedFinalSessionId
    ? finalMessages.filter(function(item) { return item.sessionId === focusedFinalSessionId })
    : finalMessages
  readonly property int minimumFinalMessageMs: 5000
  // Latest manually dismissed reply per regular session. These are no longer
  // notifications, but remain available to the session list for this shell run.
  property var archivedFinalMessages: []
  readonly property bool hasQuestions: questions.length > 0
  readonly property bool hasFinalMessages: finalMessages.length > 0
  readonly property bool hasItems: hasQuestions || hasFinalMessages

  // Emitted only for genuinely new items. The bar uses these to surface the
  // pinned view again after the user dismissed it.
  signal newQuestion()
  signal newFinalMessage(string sessionId)

  property var _sessions: ({})
  property string _activeAnswerId: ""
  property string _answerOutput: ""
  property string _answerErrors: ""
  property var _finalMessageRemovalDeadlines: ({})

  property Timer finalMessageRemovalTimer: Timer {
    interval: 0
    repeat: false
    onTriggered: root._removeExpiredFinalMessages()
  }

  property Timer restartTimer: Timer {
    interval: 5000
    repeat: false
    onTriggered: root._startListener()
  }

  property Process listenerProcess: Process {
    running: false
    command: ["python3", root.scriptPath, "listen", "--url", root.apiUrl]
    stdout: SplitParser { onRead: function(data) { root._handleHelperLine(String(data)) } }
    // Discard helper diagnostics so a long-running monitor cannot accumulate stderr.
    stderr: SplitParser { onRead: function(_) {} }
    onExited: {
      root.available = false
      root.loading = false
      if (root._shouldListen() && !root.restartTimer.running)
        root.restartTimer.restart()
    }
  }

  property Process answerProcess: Process {
    running: false
    stdout: SplitParser { onRead: function(data) { root._answerOutput += String(data) } }
    stderr: SplitParser { onRead: function(data) { root._answerErrors += String(data) } }
    onExited: function(code) { root._answerFinished(code) }
  }

  Component.onCompleted: root._syncListener()

  property Connections piNotifyConnections: Connections {
    target: PiNotify
    function onReadyChanged() { root._syncListener() }
    function onDashboardQuestionsListenerEnabledChanged() { root._syncListener() }
  }

  function _shouldListen() {
    // Pi CLI does not require the dashboard listener on portable installs.
    return false
  }

  function _clearLocalState() {
    available = false
    loading = false
    error = ""
    _sessions = ({})
    questions = []
    finalMessages = []
    archivedFinalMessages = []
    focusedFinalSessionId = ""
    _finalMessageRemovalDeadlines = ({})
    finalMessageRemovalTimer.stop()
    _activeAnswerId = ""
    _answerOutput = ""
    _answerErrors = ""
  }

  function _stopListener() {
    restartTimer.stop()
    if (listenerProcess.running)
      listenerProcess.running = false
    _clearLocalState()
  }

  function _syncListener() {
    if (!_shouldListen()) {
      _stopListener()
      return
    }
    if (!listenerProcess.running && !restartTimer.running)
      _startListener()
  }

  function _startListener() {
    if (!_shouldListen() || listenerProcess.running)
      return
    loading = true
    listenerProcess.running = true
  }

  function _safeString(value, maximum) {
    if (typeof value !== "string")
      return ""
    var text = value.trim()
    return maximum === undefined ? text : text.slice(0, maximum)
  }

  function _replaceSession(session) {
    if (!session || typeof session !== "object")
      return
    var id = _safeString(session.id, 200)
    if (!id)
      return
    var next = {}
    for (var key in _sessions)
      next[key] = _sessions[key]
    next[id] = {
      name: _safeString(session.name) || "Pi session",
      needsYou: session.needsYou === true,
    }
    _sessions = next
  }

  function _removeSession(sessionId) {
    var next = {}
    for (var key in _sessions) {
      if (key !== sessionId)
        next[key] = _sessions[key]
    }
    _sessions = next

    var remaining = []
    for (var i = 0; i < questions.length; i++) {
      if (questions[i].sessionId !== sessionId)
        remaining.push(questions[i])
    }
    questions = remaining
  }

  function _removeFinalMessagesForSession(sessionId) {
    var next = []
    for (var i = 0; i < finalMessages.length; i++) {
      if (finalMessages[i].sessionId !== sessionId)
        next.push(finalMessages[i])
    }
    finalMessages = next

    var deadlines = {}
    for (var key in _finalMessageRemovalDeadlines) {
      if (key !== sessionId)
        deadlines[key] = _finalMessageRemovalDeadlines[key]
    }
    _finalMessageRemovalDeadlines = deadlines
  }

  function _removeExpiredFinalMessages() {
    var now = Date.now()
    var nextDeadline = 0
    var expired = []
    for (var sessionId in _finalMessageRemovalDeadlines) {
      var deadline = _finalMessageRemovalDeadlines[sessionId]
      if (deadline <= now)
        expired.push(sessionId)
      else if (!nextDeadline || deadline < nextDeadline)
        nextDeadline = deadline
    }
    for (var i = 0; i < expired.length; i++)
      _removeFinalMessagesForSession(expired[i])
    if (nextDeadline) {
      finalMessageRemovalTimer.interval = Math.max(1, nextDeadline - Date.now())
      finalMessageRemovalTimer.start()
    }
  }

  function _scheduleFinalMessageRemoval(sessionId) {
    var id = _safeString(sessionId, 200)
    if (!id)
      return
    var shownAt = 0
    for (var i = 0; i < finalMessages.length; i++) {
      if (finalMessages[i].sessionId === id) {
        shownAt = finalMessages[i].shownAt || Date.now()
        break
      }
    }
    if (!shownAt)
      return
    var deadlines = {}
    for (var key in _finalMessageRemovalDeadlines)
      deadlines[key] = _finalMessageRemovalDeadlines[key]
    deadlines[id] = shownAt + minimumFinalMessageMs
    _finalMessageRemovalDeadlines = deadlines
    _removeExpiredFinalMessages()
  }

  function _upsertQuestion(clean) {
    if (!clean || typeof clean !== "object")
      return
    var id = _safeString(clean.id, 200)
    var sessionId = _safeString(clean.sessionId, 200)
    // The helper only emits allowlisted PromptBus requests from subscribed live
    // sessions; currentTool is not reliable while ask_user is waiting.
    if (!id || !sessionId)
      return

    var next = []
    var found = false
    for (var i = 0; i < questions.length; i++) {
      var existing = questions[i]
      if (existing.id === id) {
        found = true
        clean.answering = existing.answering === true
      }
      next.push(existing.id === id ? clean : existing)
    }
    if (!found)
      next.push(clean)

    questions = next
    if (!found)
      newQuestion()
  }

  function _removeQuestion(promptId) {
    var id = _safeString(promptId, 200)
    var next = []
    for (var i = 0; i < questions.length; i++) {
      if (questions[i].id !== id)
        next.push(questions[i])
    }
    questions = next
  }

  function _upsertFinalMessage(clean) {
    if (!clean || typeof clean !== "object")
      return
    var id = _safeString(clean.id, 200)
    var sessionId = _safeString(clean.sessionId, 200)
    var text = _safeString(clean.text, 2400)
    if (!id || !sessionId || !text)
      return

    var item = {
      id: id,
      sessionId: sessionId,
      sessionName: _safeString(clean.sessionName) || "Pi session",
      text: text,
      shownAt: Date.now(),
    }
    var next = []
    var found = false
    for (var i = 0; i < finalMessages.length; i++) {
      if (finalMessages[i].sessionId === sessionId) {
        found = found || finalMessages[i].id === id
        continue
      }
      next.push(finalMessages[i])
    }
    next.unshift(item)
    finalMessages = next

    var deadlines = {}
    for (var key in _finalMessageRemovalDeadlines) {
      if (key !== sessionId)
        deadlines[key] = _finalMessageRemovalDeadlines[key]
    }
    _finalMessageRemovalDeadlines = deadlines
    if (!found)
      newFinalMessage(sessionId)
  }

  function dismissFinalMessage(messageId) {
    var id = _safeString(messageId, 200)
    var dismissed = null
    var next = []
    for (var i = 0; i < finalMessages.length; i++) {
      if (finalMessages[i].id === id)
        dismissed = finalMessages[i]
      else
        next.push(finalMessages[i])
    }
    if (!dismissed)
      return

    // Keep only the newest dismissed reply for each session so the session
    // list remains compact and bounded.
    var archived = []
    for (var j = 0; j < archivedFinalMessages.length; j++) {
      if (archivedFinalMessages[j].sessionId !== dismissed.sessionId)
        archived.push(archivedFinalMessages[j])
    }
    archived.push(dismissed)
    archivedFinalMessages = archived.slice(Math.max(0, archived.length - 3))
    finalMessages = next
  }

  function _setAnswering(promptId, value) {
    var next = []
    for (var i = 0; i < questions.length; i++) {
      var item = questions[i]
      if (item.id !== promptId) {
        next.push(item)
        continue
      }
      next.push({
        id: item.id,
        sessionId: item.sessionId,
        sessionName: item.sessionName,
        type: item.type,
        question: item.question,
        message: item.message,
        options: item.options,
        placeholder: item.placeholder,
        batchQuestions: item.batchQuestions,
        answering: value,
      })
    }
    questions = next
  }

  function _handleHelperLine(raw) {
    var message
    try {
      message = JSON.parse(raw)
    } catch (e) {
      return
    }
    if (!message || typeof message.type !== "string")
      return

    if (message.type === "status") {
      available = message.available === true
      loading = false
      if (!available)
        error = _safeString(message.error, 240) || "Pi Dashboard unavailable"
      return
    }

    if (message.type === "sessions_snapshot") {
      _sessions = {}
      questions = []
      var sessions = Array.isArray(message.sessions) ? message.sessions : []
      for (var i = 0; i < sessions.length; i++)
        _replaceSession(sessions[i])
      available = true
      loading = false
      error = ""
      return
    }

    if (message.type === "session_added" || message.type === "session_updated") {
      _replaceSession(message.session)
      return
    }

    if (message.type === "session_activity") {
      _scheduleFinalMessageRemoval(_safeString(message.sessionId, 200))
      return
    }

    if (message.type === "session_removed") {
      _removeSession(_safeString(message.sessionId, 200))
      return
    }

    if (message.type === "prompt_request") {
      _upsertQuestion(message.prompt)
      return
    }

    if (message.type === "final_message") {
      _upsertFinalMessage(message.message)
      return
    }

    if (message.type === "prompt_dismiss" || message.type === "prompt_cancel")
      _removeQuestion(message.promptId)
  }

  function _encodeAnswer(result) {
    if (result && typeof result === "object") {
      if (Array.isArray(result.answers))
        return JSON.stringify(result.answers)
      if (Array.isArray(result.values))
        return JSON.stringify(result.values)
      if (Object.prototype.hasOwnProperty.call(result, "value"))
        return String(result.value === undefined || result.value === null ? "" : result.value)
      if (Object.prototype.hasOwnProperty.call(result, "confirmed"))
        return result.confirmed ? "true" : "false"
    }
    return String(result === undefined || result === null ? "" : result)
  }

  function answer(questionId, result) {
    return _sendAnswer(questionId, result, false)
  }

  function cancel(questionId) {
    return _sendAnswer(questionId, "", true)
  }

  function _sendAnswer(questionId, result, cancelled) {
    var id = _safeString(questionId, 200)
    if (!apiUrl || !id || answerProcess.running)
      return false

    var item = null
    for (var i = 0; i < questions.length; i++) {
      if (questions[i].id === id) {
        item = questions[i]
        break
      }
    }
    if (!item || item.answering)
      return false

    var command = [
      "python3", scriptPath, "answer",
      "--url", apiUrl,
      "--session-id", _safeString(item.sessionId, 200),
      "--prompt-id", id,
    ]
    if (cancelled)
      command.push("--cancelled")
    else
      command.push("--answer=" + _encodeAnswer(result))

    _activeAnswerId = id
    _answerOutput = ""
    _answerErrors = ""
    _setAnswering(id, true)
    answerProcess.command = command
    answerProcess.running = true
    return true
  }

  function _answerFinished(code) {
    var id = _activeAnswerId
    _activeAnswerId = ""
    if (!id) {
      _answerOutput = ""
      _answerErrors = ""
      return
    }
    if (code !== 0) {
      _setAnswering(id, false)
      error = _safeString(_answerErrors, 240) || "Could not answer Pi question"
    }
    _answerOutput = ""
    _answerErrors = ""
  }
}
