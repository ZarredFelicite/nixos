pragma Singleton

import QtQuick

QtObject {
  id: root

  // Transient by design: a restart always returns to the real activity state.
  property string mode: "auto"
  readonly property var modes: ["auto", "thinking", "generating", "compacting", "completion", "idle"]
  readonly property string label: modeLabel(mode)

  function modeLabel(value) {
    switch (value) {
    case "thinking": return "Thinking"
    case "generating": return "Generating"
    case "compacting": return "Compacting"
    case "completion": return "Completion"
    case "idle": return "Idle"
    default: return "Auto"
    }
  }

  function cycleMode() {
    var currentIndex = root.modes.indexOf(root.mode)
    root.mode = root.modes[(currentIndex + 1) % root.modes.length]
  }
}
