pragma Singleton
import QtQuick
import Quickshell
import "../../../services"

QtObject {
    // Timing
    readonly property int openDuration: 280
    readonly property int closeDuration: 150
    readonly property int scaleDuration: 300
    readonly property int opacityInDuration: 240
    readonly property int opacityOutDuration: 120

    // Easing
    readonly property int openEasing: Easing.OutCubic
    readonly property int closeEasing: Easing.InCubic
    readonly property int scaleEasing: Easing.OutBack

    // Geometry factors
    readonly property real unfoldYOffsetFactor: 0.35
    readonly property real startScale: 0.88
    readonly property real endScale: 1.02

    // Theme
    readonly property color backgroundColor: Qt.rgba(31/255, 29/255, 46/255, 0.50)
    readonly property color secondaryBackgroundColor: Qt.rgba(40/255, 38/255, 54/255, 0.50)
    readonly property color borderColor: Colors.primary
    readonly property color innerBorderColor: Colors.primaryTransparent
    readonly property int borderWidth: 1
    readonly property real cornerRadius: 16
    readonly property real innerRadius: 10
    
    // Text colors
    readonly property color textColor: "#cdd6f4"
    readonly property color errorColor: "#ff6699"
    readonly property color successColor: "#9ccfd8"
    readonly property color warningColor: "#fab387"

    // Tooltip specific
    readonly property int tooltipPadding: 16
    readonly property int tooltipVerticalPadding: 10
    readonly property int tooltipMaxWidth: 500
    readonly property int tooltipTextSize: 13

    // Stocks specific
    readonly property int stocksMaxWidth: 1000
    readonly property int stocksSummaryWidth: 220
}
