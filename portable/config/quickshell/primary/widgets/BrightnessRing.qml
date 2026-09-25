import QtQuick
import Quickshell
import Quickshell.Io
import "../services"

RingIcon {
    id: root

    // For popout hover
    property var popouts: null

    // Use the general ringSize from Colors by default; modules can override if desired
    ringSize: Colors.ringSize

    // Restore the previous fixed appearance: use a fixed icon size (25) which looked best
    iconSize: 28

    // Use a normal fill mode to preserve the expected icon rendering
    iconFillMode: Image.PreserveAspectFit

    property real brightnessValue: 0.0  // 0.0 to 100.0 from brillo
    property bool vigilandRunning: false

    // Configure the ring
    ringValue: brightnessValue / 100.0  // Convert percentage to 0.0-1.0
    iconSource: vigilandRunning ?
        "/home/zarred/pictures/icons/brightness_idle.png" :
        "/home/zarred/pictures/icons/brightness.png"

    Process {
        id: brightnessProcess
        command: ["/home/zarred/scripts/waybar/brightness.sh", "--quickshell"]

        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(',');
                if (parts.length === 2) {
                    const brightness = parseFloat(parts[0]);
                    const vigiland = parts[1] === 'true';

                    if (!isNaN(brightness)) {
                        root.brightnessValue = Math.max(0, Math.min(100, brightness));
                    }
                    root.vigilandRunning = vigiland;
                }
            }
        }
    }

    Timer {
        id: updateTimer
        interval: 2000  // Update every 2 seconds
        running: true
        repeat: true

        onTriggered: {
            brightnessProcess.running = false;
            brightnessProcess.running = true;
        }
    }

    Component.onCompleted: {
        brightnessProcess.running = true;
    }

    // Handle mouse interactions - match Waybar behavior
    onClicked: function(mouse) {
        if (mouse.button === Qt.LeftButton) {
            // Immediately toggle vigiland state for instant visual feedback
            vigilandRunning = !vigilandRunning;
            
            // Toggle vigiland (idle mode) - same as Waybar on-click
            brightnessAdjustProcess.command = ["/home/zarred/scripts/waybar/brightness.sh", "--idle"];
            brightnessAdjustProcess.running = true;
        } else if (mouse.button === Qt.RightButton) {
            // Right click: set all monitors to 100% brightness
            brightnessAdjustProcess.command = ["/home/zarred/scripts/waybar/brightness.sh", "--max"];
            brightnessAdjustProcess.running = true;
        } else if (mouse.button === Qt.MiddleButton) {
            // Middle click can increase brightness
            brightnessAdjustProcess.command = ["/home/zarred/scripts/waybar/brightness.sh", "--increase"];
            brightnessAdjustProcess.running = true;
        }
    }

    onWheel: function(wheel) {
        if (wheel.angleDelta.y > 0) {
            brightnessAdjustProcess.command = ["/home/zarred/scripts/waybar/brightness.sh", "--increase"];
        } else {
            brightnessAdjustProcess.command = ["/home/zarred/scripts/waybar/brightness.sh", "--decrease"];
        }
        brightnessAdjustProcess.running = true;
    }

    Process {
        id: brightnessAdjustProcess

        onExited: {
            // Update brightness after adjustment to sync with actual state
            updateTimer.restart();
        }
    }

    // Hover to show brightness popup
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        propagateComposedEvents: true
        onEntered: {
            if (root.popouts) {
                var pos = root.popouts.mapFromItem(root, root.width / 2, root.height)
                root.popouts.openPopout("brightness", pos.x, pos.y, root.width)
            }
        }
        onExited: {
        }
    }
}
