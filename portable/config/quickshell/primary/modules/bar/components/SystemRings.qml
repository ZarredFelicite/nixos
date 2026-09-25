import QtQuick
import QtQuick.Layouts 1.15
import "../../../widgets"
import "../../../services"

// Pill containing system rings (no internal expansion; popouts handled externally)
Pill {
    id: root

    property var popouts: null  // Will be set by parent
    // Expansion handled by external popout system; keep fixed height
    // (previous internal expansion removed in favor of external popout)
    property int baseHeight: Colors.pillHeight

    // Width calculation unchanged (we keep width tight to content)
    implicitWidth: innerLayout ? innerLayout.implicitWidth + 12 : (Colors.ringSize * 2) + 8 + 12
    Behavior on implicitWidth { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    // Fixed implicitHeight provided at end (no expand/collapse)

    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight
    Layout.minimumHeight: baseHeight
    Layout.alignment: Qt.AlignVCenter

    // Top row remains fixed at the bar height
    RowLayout {
        id: innerLayout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: root.implicitHeight
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        spacing: 2
        Layout.alignment: Qt.AlignVCenter

        // Order: codex, alphaess, screenshot, todos, video stream, updates, etc.
        // Portable profile: omit machine-specific and excluded service indicators.
        NotificationRing {
            id: notificationRing
            objectName: "NotificationRing"
            // Notification icon normalized to base pill height sizing
            // Reduce spacing specifically between UpdatesIndicator and NotificationRing
            Layout.leftMargin: -2
            Layout.preferredWidth: Colors.pillHeight - 2
            Layout.preferredHeight: baseHeight
            Layout.alignment: Qt.AlignVCenter
            popouts: root.popouts
        }
        // NetworkRings calls a workstation-only script; use the system network UI instead.
        BluetoothBatteryWidget {
            id: bluetoothBatteryWidget
            objectName: "AirpodsBatteryPill"
            Layout.preferredWidth: BluetoothBattery.visible ? implicitWidth : 0
            Layout.preferredHeight: baseHeight
            Layout.alignment: Qt.AlignVCenter
            popouts: root.popouts
        }
        BluetoothRing {
            id: bluetoothRing
            objectName: "BluetoothRing"
            Layout.preferredWidth: Colors.ringSize
            Layout.preferredHeight: baseHeight
            Layout.alignment: Qt.AlignVCenter
            popouts: root.popouts
        }
        RingIcon {
            id: speakerIcon
            objectName: "AudioOutputRing"
            visible: false // original device actions require workstation-only scripts
            Component.onCompleted: {
                AudioOutput.refCount++ ; if (typeof AudioOutput.update === 'function') AudioOutput.update();
                if (typeof AudioOutput.refreshDeviceIcon === 'function') AudioOutput.refreshDeviceIcon();
            }
            Component.onDestruction: { AudioOutput.refCount-- }
            compact: true
            Layout.preferredWidth: 0
            Layout.alignment: Qt.AlignVCenter
            ringSize: Colors.ringSize
            iconSize: 12
            iconFillMode: Image.PreserveAspectFit
            iconSource: AudioOutput.deviceIconPath
            ringValue: AudioOutput.level / 100.0
            ringForegroundColor: AudioOutput.muted ? "#666" : Colors.foregroundCyan
            ringBackgroundColor: Colors.primaryTransparent
            iconColor: AudioOutput.muted ? "#666" : Colors.primary
            onClicked: function(mouse) {
                if (mouse.button === Qt.LeftButton) {
                    // Left click: cycle through output devices directly
                    AudioOutput.cycleOutputDevice()
                    Qt.callLater(function(){ 
                        var timer = Qt.createQmlObject('import QtQuick; Timer { interval: 200; repeat: false }', root)
                        timer.triggered.connect(function() {
                            AudioOutput.refreshDeviceIcon()
                            timer.destroy()
                        })
                        timer.start()
                    })
                } else if (mouse.button === Qt.RightButton) {
                    AudioOutput.toggleMute(); Qt.callLater(function(){ AudioOutput.refreshDeviceIcon() })
                }
            }
            onWheel: function(wheel) {
                var step = 5;
                if (wheel.angleDelta.y > 0) AudioOutput.changeVolume(step)
                else if (wheel.angleDelta.y < 0) AudioOutput.changeVolume(-step)
                wheel.accepted = true
                Qt.callLater(function(){ AudioOutput.refreshDeviceIcon() })
            }
            // Hover to open device popup
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
                onEntered: {
                    if (root.popouts) {
                        var pos = root.popouts.mapFromItem(speakerIcon, speakerIcon.width / 2, speakerIcon.height)
                        root.popouts.openPopout("audio-out", pos.x, pos.y, speakerIcon.width)
                    }
                }
                onExited: {
                    // Audio popout has interactive buttons (device switching, filter/sink toggles)
                    // so it behaves as a menu - stays open until dismissed via HyprlandFocusGrab
                }
            }
        }
        RingIcon { /* micIcon */
            id: micIcon
            objectName: "AudioInputRing"
            visible: false // original device actions require workstation-only scripts
            Component.onCompleted: {
                AudioInput.refCount++ ; if (typeof AudioInput.update === 'function') AudioInput.update();
                if (typeof AudioInput.refreshDeviceIcon === 'function') AudioInput.refreshDeviceIcon();
            }
            Component.onDestruction: { AudioInput.refCount-- }
            compact: true
            Layout.preferredWidth: 0
            Layout.alignment: Qt.AlignVCenter
            ringSize: Colors.ringSize
            iconSize: 14
            iconFillMode: Image.PreserveAspectFit
            iconSource: AudioInput.deviceIconPath
            ringValue: AudioInput.level / 100.0
            ringForegroundColor: AudioInput.muted ? "#666" : Colors.foregroundCyan
            ringBackgroundColor: Colors.primaryTransparent
            iconColor: AudioInput.muted ? "#666" : Colors.primary
            onClicked: function(mouse) {
                if (mouse.button === Qt.LeftButton) {
                    // Left click: cycle through input devices directly
                    AudioInput.cycleInputDevice()
                    Qt.callLater(function(){ 
                        var timer = Qt.createQmlObject('import QtQuick; Timer { interval: 200; repeat: false }', root)
                        timer.triggered.connect(function() {
                            AudioInput.refreshDeviceIcon()
                            timer.destroy()
                        })
                        timer.start()
                    })
                } else if (mouse.button === Qt.RightButton) {
                    AudioInput.toggleMute(); Qt.callLater(function(){ AudioInput.refreshDeviceIcon() })
                }
            }
            onWheel: function(wheel) {
                var step = 5;
                if (wheel.angleDelta.y > 0) AudioInput.changeVolume(step)
                else if (wheel.angleDelta.y < 0) AudioInput.changeVolume(-step)
                wheel.accepted = true
                Qt.callLater(function(){ AudioInput.refreshDeviceIcon() })
            }
            // Hover to open device popup
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
                onEntered: {
                    if (root.popouts) {
                        var pos = root.popouts.mapFromItem(micIcon, micIcon.width / 2, micIcon.height)
                        root.popouts.openPopout("audio-in", pos.x, pos.y, micIcon.width)
                    }
                }
                onExited: {
                    // Audio popout has interactive buttons (device switching, filter/sink toggles)
                    // so it behaves as a menu - stays open until dismissed via HyprlandFocusGrab
                }
            }
        }
         // CPU profile action depends on the workstation's custom script.
         DiskRing {
             objectName: "DiskRing"
             Layout.preferredWidth: Colors.ringSize
             Layout.preferredHeight: baseHeight
             Layout.alignment: Qt.AlignVCenter
             popouts: root.popouts
         }
         MemoryRings {
             id: memoryRings
             objectName: "MemoryRings"
             Layout.preferredWidth: Colors.ringSize
             Layout.preferredHeight: baseHeight
             Layout.alignment: Qt.AlignVCenter
             popouts: root.popouts
         }
         // Brightness is controlled by Hyprland media keys (brightnessctl).
         BatteryIndicator { 
             objectName: "BatteryIndicator"
             Layout.preferredWidth: Colors.ringSize
             Layout.alignment: Qt.AlignVCenter
             popouts: root.popouts
         }
    }

    // (Internal bluetooth tooltip removed; external popout handles tooltip)

    // No overlap strategy: keep fixed pill height and rounded bottom corners
    implicitHeight: baseHeight
    mergedBottom: false  // do not square bottom corners since no popup overlap
    extraHeight: 0
    border.width: 1

    // Keep popouts informed of current pill width for width-locked popouts
    function updatePillGeometry() {
        if (!popouts) return;
        try {
            // Map pill top-left into popouts (full-screen overlay) coordinate space
            const pt = root.mapToItem(popouts, 0, 0);
            popouts.sourcePillLeft = pt.x;
            popouts.sourcePillBottom = pt.y + root.implicitHeight;
        } catch (e) {
            // Fallback: approximate using global mapping
            try {
                const pg = root.mapToItem(null, 0, 0);
                popouts.sourcePillLeft = pg.x;
                popouts.sourcePillBottom = pg.y + root.implicitHeight;
            } catch (e2) {
                // Last resort: leave existing values
            }
        }
        // sourcePillWidth no longer used for popout sizing
    }

    Component.onCompleted: updatePillGeometry()
    onImplicitWidthChanged: updatePillGeometry()
    onXChanged: updatePillGeometry()
    onYChanged: updatePillGeometry()

    Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutCubic } }
}
