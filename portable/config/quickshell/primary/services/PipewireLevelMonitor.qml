import QtQuick
import Quickshell.Io

QtObject {
  id: root

  property int nodeId: -1
  property string nodeName: ""
  property bool enabled: false
  property bool monitorSink: false
  // Normalized level 0-1
  property real level: 0
  // Only monitor the default sink to reduce overhead, but monitor all sources
  property bool isDefault: false
  readonly property bool active: enabled && (nodeId > 0 || nodeName.length > 0) && scriptPath.length > 0 && (!monitorSink || isDefault)

  readonly property string scriptPath: (function() {
    var resolved = Qt.resolvedUrl("../scripts/pipewire_level_monitor.py")
    if (!resolved)
      return ""
    var path = resolved.toString ? resolved.toString() : resolved
    return String(path).replace(/^file:\/\//, "")
  })()

  property Process meterProcess: Process {
    id: meterProcess
    running: false
    stdout: SplitParser {
      onRead: function(data) {
        var line = (data || "").trim()
        if (!line)
          return
        var value = parseFloat(line)
        if (!isNaN(value))
          root.level = Math.max(0, Math.min(1, value))
      }
    }
    stderr: SplitParser { onRead: function() {} }
    onExited: {
      root.level = 0
      if (root.active)
        restartTimer.restart()
    }
  }

  property Timer restartTimer: Timer {
    interval: 400
    repeat: false
    onTriggered: root._updateProcess()
  }

  function _updateProcess() {
    restartTimer.stop()
    if (!root.active) {
      if (meterProcess.running)
        meterProcess.running = false
      root.level = 0
      return
    }

    var nodeTarget = root.nodeName.length > 0 ? root.nodeName : String(root.nodeId)
    var command = [
      "python3",
      root.scriptPath,
      "--node",
      nodeTarget,
      "--interval",
      "0.08"
    ]
    if (root.monitorSink)
      command.push("--monitor")

    meterProcess.running = false
    meterProcess.command = command
    meterProcess.running = true
  }

  onActiveChanged: _updateProcess()
  onNodeIdChanged: _updateProcess()
  onNodeNameChanged: _updateProcess()
  onEnabledChanged: _updateProcess()

  Component.onDestruction: meterProcess.running = false
}
