pragma Singleton

import QtQuick

QtObject {
    readonly property color primary: "#d2c3ee"
    readonly property color primaryTransparent: "#80d2c3ee"
    readonly property color foregroundCyan: "#00FFFF"
    readonly property color foregroundRed: "#eb6f92"
    readonly property color success: "#6de59a"
    readonly property color secondary: Qt.rgba(196/255, 167/255, 231/255, 0.8)
    readonly property color bg1: "#191724"
    readonly property color bg2: "#1f1d2e"
    readonly property color bg3: "#26233a"
    readonly property color bg4: "#293A52"
    readonly property color background: "#1c1b1f"
    readonly property color surface: "#25232a"
    readonly property color surfaceText: "#e6e1e5"
    readonly property color outline: "#938f99"

    // Standardized opacity levels for popouts and overlays
    readonly property QtObject opacity: QtObject {
        readonly property real background0: 0.5
        readonly property real background1: 0.7
        readonly property real foreground0: 0.9
        readonly property real foreground1: 1.0
    }
    
    // Shared pill/ring configuration
    readonly property int pillHeight: 26

    // Shared ring configuration (used by RingIcon and ring widgets)
    // Make ringSize general and derived from pillHeight so all modules use the same base size
    readonly property int ringSize: Math.max(8, pillHeight - 6)
    // Use a fixed, slightly thinner ring thickness for all rings
    readonly property real ringThickness: 1.5

    // Clock / calendar sizing (make these a bit larger than default to increase legibility)
    readonly property int clockIconSize: 42
    readonly property int clockFontSize: Math.round(pillHeight * 0.6)
    readonly property int dayNumberFontSize: Math.round(pillHeight * 0.42)

    // Temperature coloring (used for CPU temp -> icon/ring color)
    // Matches create_cpu_icon.sh TEMP_COLOR_LEVELS: 50:c4a7e7, 70:ebbcba, 100:eb6f92
    readonly property color baseTempColor: "#00ffff"    // same as 'cyan' used by the script
    readonly property color tempLevel1: "#c4a7e7"
    readonly property color tempLevel2: "#ebbcba"
    readonly property color tempLevel3: "#eb6f92"

    // Todo priority colors (Rose Pine)
    readonly property color todoPriorityLow: "#31748f"
    readonly property color todoPriorityMedium: "#ebbcba"
    readonly property color todoPriorityHigh: "#eb6f92"

    // Todo date colors (Rose Pine)
    readonly property color todoDateNoDue: "#6e6a86"
    readonly property color todoDateDue: "#9ccfd8"
    readonly property color todoDateOverdue: "#eb6f92"
}