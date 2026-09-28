import QtQuick
import Quickshell
import Quickshell.Widgets
import QtQuick.Effects
import "../services"

// Reusable ring with centered icon component
Rectangle {
    id: root
    
    // Public properties
    property real ringValue: 0.0  // 0.0 to 1.0
    property string iconSource: ""
    property int ringSize: Colors.ringSize
    property int iconSize: Colors.ringSize - 4
    property real ringThickness: Colors.ringThickness

    // Allow modules to change the image fill mode (default preserves aspect fit)
    property int iconFillMode: Image.PreserveAspectFit
    
    // Styling properties
    property color ringForegroundColor: Colors.foregroundCyan
    property color ringBackgroundColor: Colors.primaryTransparent
    
     // Optional icon color (overrides default ring foreground color for icon tinting)
     property color iconColor: Qt.rgba(0,0,0,0)
     
     // When true, use brightness darkening for mute state instead of colorization
     property bool useBrightnessDarkening: false
    
    // Compact mode: render ring-only (no pill background)
    property bool compact: false

    // Pill styling (switch to compact sizing when requested)
    implicitWidth: compact ? ringSize + 4 : ringSize + 8   // Ring + padding
    // Keep the pill height consistent even in compact mode so layout alignment
    // remains stable when mixing compact and full-size children.
    implicitHeight: Colors.pillHeight
    radius: compact ? (Colors.pillHeight / 2) : (Colors.pillHeight / 2)
    color: compact ? "transparent" : Colors.bg1
    border.color: Colors.secondary
    border.width: compact ? 0 : 0
    
    // Ring with centered icon
    Item {
        anchors.centerIn: parent
        width: root.ringSize
        height: root.ringSize

        // Background ring
        ProgressRing {
            id: ring
            anchors.fill: parent
            value: root.ringValue
            foregroundColor: root.ringForegroundColor
            backgroundColor: root.ringBackgroundColor
            thickness: root.ringThickness
            startAngle: -90  // Start at top
            sweepAngle: 360  // Full circle
        }

        // Icon overlaid in the center of the ring
            Image {
            id: iconImage
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: 0
            width: root.iconSize
            height: root.iconSize
            source: root.iconSource
            fillMode: root.iconFillMode
            smooth: false
            antialiasing: false
            sourceSize.width: width * (typeof Screen !== 'undefined' && Screen.devicePixelRatio ? Screen.devicePixelRatio : 1)
            sourceSize.height: height * (typeof Screen !== 'undefined' && Screen.devicePixelRatio ? Screen.devicePixelRatio : 1)
            cache: true

            onStatusChanged: {
            }
        }
        // Icon effect: either brightness darkening or colorization tinting
        MultiEffect {
            anchors.fill: iconImage
            source: iconImage
            brightness: root.useBrightnessDarkening && root.iconColor === "#666" ? -0.5 : 0
            colorization: !root.useBrightnessDarkening ? 1.0 : 0
            colorizationColor: root.iconColor ? root.iconColor : root.ringForegroundColor
            visible: iconImage.status === Image.Ready
        }
    }
    
    // Mouse interactions (no hover highlight)
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        // Forward mouse events to parent; accept all buttons so right-clicks are captured
        acceptedButtons: Qt.AllButtons
        onClicked: mouse => parent.clicked(mouse)
        onWheel: wheel => parent.wheel(wheel)
    }
    
    // Signals for interaction
    signal clicked(var mouse)
    signal wheel(var wheel)

    // Debug: log sizes when the component is completed
    Component.onCompleted: {
    }
    
    // Also log when iconSize changes
    onIconSizeChanged: {
    }
    
    Behavior on color {
        ColorAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }
}
