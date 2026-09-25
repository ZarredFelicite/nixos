import QtQuick
import QtQuick.Effects
import Quickshell
import "../services"
import "../modules/bar/popouts"
import "../utils"

// Video stream indicator that shows the RTSP camera on hover
Item {
    id: root
    objectName: "VideoStreamIndicator"
    property var popouts: null
    property string cctvIconSource: ""

    implicitHeight: Colors.ringSize
    implicitWidth: Colors.ringSize

    // Always visible for now; could add enable flag later
    visible: true
    width: visible ? implicitWidth : 0
    opacity: visible ? 1 : 0

    Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    // Tooltip name for video stream
    property string tooltipName: "tooltip-video-stream"
    property bool automaticPopupActive: false

    function refreshCctvIconSource() {
        var override = Icons.getOverrideFor("cctv")
        if (override && override.length > 0) {
            root.cctvIconSource = override
        } else {
            root.cctvIconSource = ""
        }
    }

    function openVideoPopout(reason, expanded, automatic) {
        if (!root.popouts) return
        root.automaticPopupActive = automatic === true
        if (!root.automaticPopupActive) personPopupCloseTimer.stop()
        if (expanded !== undefined) VideoStream.popupExpanded = !!expanded
        var pos = root.popouts.mapFromItem(root, root.width / 2, root.height)
        console.log('[VideoStreamIndicator] opening CCTV popout:', reason, 'expanded=', VideoStream.popupExpanded)
        root.popouts.openPopout(root.tooltipName, pos.x, pos.y, root.width)
    }

    Component.onCompleted: refreshCctvIconSource()

    Connections {
        target: Icons
        function onOverridesReady() {
            root.refreshCctvIconSource()
        }
    }

    Connections {
        target: VideoStream
        function onPersonDetected(count) {
            root.openVideoPopout('person detected (' + count + ')', undefined, true)
            personPopupCloseTimer.restart()
        }
    }

    Timer {
        id: personPopupCloseTimer
        interval: 5000
        repeat: false
        onTriggered: {
            if (root.automaticPopupActive && root.popouts && root.popouts.currentName === root.tooltipName) {
                if (root.popouts.currentHovered) {
                    // Let a user who entered the automatic popup keep it open.
                    personPopupCloseTimer.restart()
                    return
                }
                console.log('[VideoStreamIndicator] closing person-detection CCTV popout')
                root.popouts.close()
            }
            root.automaticPopupActive = false
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton

        onEntered: {
            if (VideoStream.popupExpanded) root.openVideoPopout('hover-expanded')
            else root.openVideoPopout('hover', false)
        }
        onExited: {
        }
        onClicked: function(mouse) {
            console.log('[VideoStreamIndicator] click button', mouse.button, 'playing=', VideoStream.isPlaying, 'error=', VideoStream.errorMessage)
            root.openVideoPopout('click', !VideoStream.popupExpanded)
            if (mouse.button === Qt.LeftButton) {
                // Only start (or restart on error); do not stop on left click
                if (!VideoStream.isPlaying || VideoStream.errorMessage !== "") {
                    VideoStream.startStream()
                }
            } else if (mouse.button === Qt.MiddleButton) {
                // Middle click could be used to stop if desired
                if (VideoStream.isPlaying) {
                    console.log('[VideoStreamIndicator] middle-click stop stream')
                    VideoStream.stopStream()
                }
            }
        }
    }

    // Camera icon with color based on cache availability
    Image {
        id: cctvIcon
        anchors.centerIn: parent
        width: Colors.ringSize
        height: Colors.ringSize
        source: root.cctvIconSource
        fillMode: Image.PreserveAspectFit
        smooth: true
        antialiasing: true
        cache: true
        asynchronous: true
        visible: status === Image.Ready
        opacity: VideoStream.isPlaying ? 1 : (VideoStream.hasCachedSnapshot ? 0.9 : 0.6)
        
        Behavior on opacity { NumberAnimation { duration: 300 } }
    }

    // Colorize overlay - primary color when cached, grey when not
    MultiEffect {
        anchors.fill: cctvIcon
        source: cctvIcon
        colorization: 1.0
        colorizationColor: VideoStream.hasCachedSnapshot ? Colors.primary : Colors.outline
        visible: cctvIcon.status === Image.Ready
        
        Behavior on colorizationColor { ColorAnimation { duration: 300 } }
    }

    // Fallback emoji if icon fails to load
    Text {
        anchors.centerIn: parent
        text: VideoStream.isConnected ? "📹" : "🎥"
        font.pixelSize: 16
        color: VideoStream.hasCachedSnapshot ? Colors.primary : Colors.outline
        opacity: VideoStream.isPlaying ? 1 : (VideoStream.hasCachedSnapshot ? 0.9 : 0.6)
        visible: cctvIcon.status !== Image.Ready
        
        Behavior on color { ColorAnimation { duration: 300 } }
        Behavior on opacity { NumberAnimation { duration: 300 } }
    }

    // Small status dot
    Rectangle {
        width: 6
        height: 6
        radius: 3
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 2
        anchors.bottomMargin: 2
        color: VideoStream.errorMessage !== "" ? PopoutConfig.errorColor : (VideoStream.isConnected ? PopoutConfig.successColor : "#ffaa00")
        border.width: 1
        border.color: "#222"

        SequentialAnimation on opacity {
            running: !VideoStream.isConnected && VideoStream.isPlaying && VideoStream.errorMessage === ""
            loops: Animation.Infinite
            NumberAnimation { to: 0.3; duration: 800 }
            NumberAnimation { to: 1.0; duration: 800 }
        }
    }
}
