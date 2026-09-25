import QtQuick
import Quickshell
import "../services"

// Recording indicator showing red dot when recording, grey when idle
// Click to toggle recording or show options menu
Item {
    id: root
    objectName: "RecordingIndicator"
    property var popouts: null

    implicitHeight: Colors.ringSize
    implicitWidth: Colors.ringSize

    // Always visible but change appearance based on recording state
    visible: true

    // Activate polling
    Component.onCompleted: Recording.refCount++
    Component.onDestruction: Recording.refCount--

    property string tooltip: Recording.tooltipText

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true

        onEntered: {
            // Only show tooltip if not recording and menu is not open
            if (root.popouts && !Recording.isRecording && root.popouts.currentName !== "screen-recording-menu") {
                var pos = root.popouts.mapFromItem(root, root.width / 2, root.height)
                root.popouts.openPopout("tooltip-recording", pos.x, pos.y, root.width)
            }
        }

        onExited: {
            // Only close tooltip on exit, not the menu
            if (root.popouts && root.popouts.currentName === "tooltip-recording") {
                if (root.popouts.closeTimer) root.popouts.closeTimer.start()
            }
        }

        onClicked: {
            if (Recording.isRecording) {
                // Stop recording when clicked while recording
                Recording.stopRecording()
            } else {
                // Show menu when clicked while not recording
                if (root.popouts) {
                    var pos = root.popouts.mapFromItem(root, root.width / 2, root.height)
                    root.popouts.openPopout("screen-recording-menu", pos.x, pos.y, 320)
                }
            }
        }
    }

    Item {
        anchors.fill: parent

        Text {
            anchors.centerIn: parent
            text: ""
            font.family: "NerdFont"
            font.pixelSize: 32
            color: Recording.isRecording ? Colors.foregroundRed : Colors.primary
        }

        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 2
            width: 10
            height: 10
            radius: 5
            color: Recording.isRecording ? Colors.foregroundRed : "transparent"

            SequentialAnimation on opacity {
                running: Recording.isRecording
                loops: Animation.Infinite
                NumberAnimation { to: 0.4; duration: 1000 }
                NumberAnimation { to: 1.0; duration: 1000 }
            }

            Behavior on color { ColorAnimation { duration: 300 } }
        }
    }
}
