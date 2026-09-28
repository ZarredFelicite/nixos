pragma Singleton

import QtQuick

// Portable mode has no Ember service. Keep the Bar's state interface idle.
QtObject {
  readonly property bool gatewayUp: false
  readonly property bool isGenerating: false
  readonly property string activityPhase: "idle"
  readonly property bool isCompacting: false
  readonly property bool isThinkingOrToolActive: false
  readonly property bool isTextGenerating: false
  readonly property int activeSessions: 0
}
