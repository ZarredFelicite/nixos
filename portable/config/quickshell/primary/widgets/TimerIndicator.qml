import QtQuick
import Quickshell
import "../services"

// Timer indicator showing current timer status with icon and time
// Matches waybar custom/timer functionality
Item {
    id: root
    property var popouts: null

    implicitWidth: textItem.implicitWidth
    implicitHeight: Colors.pillHeight

    // Always visible (timer shows "0" when no timer set)
    visible: true

    // Activate polling
    Component.onCompleted: CustomTimer.refCount++
    Component.onDestruction: CustomTimer.refCount--

    property string tooltip: CustomTimer.tooltipText

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        
        onEntered: {
            if (root.popouts) {
                var pos = root.popouts.mapFromItem(root, root.width / 2, root.height)
                root.popouts.openPopout("tooltip-timer", pos.x, pos.y, root.width)
            }
        }
        
        onExited: {
        }
        
        onClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton) {
                // Each click adds 15 minutes; if no timer exists, start at 15
                if (CustomTimer.hasTimer) {
                    CustomTimer.increaseTimer(15 * 60)
                } else {
                    CustomTimer.newTimer(15, "notify-send -u critical 'Timer expired.'; pw-play /home/zarred/audio/notifications/soft-4.mp3")
                }
            } else if (mouse.button === Qt.RightButton) {
                if (CustomTimer.hasTimer) CustomTimer.togglePause()
                else CustomTimer.toggleStopwatch()
            } else if (mouse.button === Qt.MiddleButton) {
                if (CustomTimer.hasTimer) CustomTimer.cancelTimer()
                else CustomTimer.resetStopwatch()
            }
        }
        
        onWheel: function(wheel) {
            if (wheel.angleDelta.y > 0) {
                // Scroll up: increase by 60 seconds or start new 1-minute timer
                if (CustomTimer.hasTimer) {
                    CustomTimer.increaseTimer(60)
                } else {
                    CustomTimer.newTimer(1, "notify-send -u critical 'Timer expired.'; pw-play /home/zarred/audio/notifications/soft-4.mp3")
                }
            } else if (wheel.angleDelta.y < 0) {
                // Scroll down: decrease by 60 seconds
                CustomTimer.increaseTimer(-60)
            }
            wheel.accepted = true
        }
    }

    // Container with clipping
    Item {
        id: clipper
        anchors.fill: parent
        anchors.leftMargin: 0
        anchors.rightMargin: 0
        clip: true

        Text {
            id: textItem
            text: CustomTimer.formattedText || `${CustomTimer.statusIcon} ${CustomTimer.displayText}`
            font.pixelSize: 14
            font.weight: Font.Medium
            color: {
                switch (CustomTimer.state) {
                    case "running": return Colors.primary
                    case "paused": return Colors.foregroundYellow || Colors.primary
                    case "standby":
                    default: return Colors.primaryTransparent || Colors.primary
                }
            }
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
