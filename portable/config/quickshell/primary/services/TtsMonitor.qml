pragma Singleton

import QtQuick

// Portable profile has no TTS, recording, Nanobot, or Ava wake services.
// Keep the public state interface so existing bar bindings remain valid.
QtObject {
    id: root

    property bool isTtsActive: false
    property bool isTtsPlaying: false
    property bool isRecordingActive: false
    property real recordingLevel: 0
    property real ttsLevel: 0
    property bool keepTtsOutputMonitor: false
    property bool isAvaWakeActive: false
    property string brainSpeedMode: "low"

    property bool isNanobotGenerating: false
    property bool isNanobotUsingTools: false
    property bool isNanobotGatewayUp: false
    property int nanobotActiveToolCount: 0
    property int nanobotPort: 4096

    function toggleSpeedMode() {
        brainSpeedMode = (brainSpeedMode === "low") ? "high" : "low"
    }
}
