import QtQuick
import QtQuick.Layouts 1.15
import "../../../widgets"
import "../../../services"

Pill {
    id: root
    Component.onCompleted: {
        AudioInput.refCount++;
        // Request an immediate update so the ring shows the current level right away
        if (typeof AudioInput.update === 'function') AudioInput.update();
    }
    Component.onDestruction: AudioInput.refCount--
    implicitWidth: 56
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight
    Layout.alignment: Qt.AlignVCenter

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        spacing: 6
        Layout.alignment: Qt.AlignVCenter

        // Use the same ring component as other system rings
        RingIcon {
            id: micRing
            Layout.preferredWidth: Colors.ringSize
            Layout.preferredHeight: Colors.ringSize
            ringValue: AudioInput.level / 100.0
            iconSource: AudioInput.deviceIconPath
            iconSize: 14
            iconFillMode: Image.PreserveAspectFit
             ringForegroundColor: AudioInput.muted ? "#666" : Colors.foregroundCyan
             ringBackgroundColor: Colors.primaryTransparent
             // Use brightness darkening instead of colorization
             useBrightnessDarkening: true
             iconColor: AudioInput.muted ? "#666" : "#fff"

            Component.onCompleted: AudioInput.refreshDeviceIcon()

            // Handle clicks forwarded from RingIcon's MouseArea
            onClicked: function(mouse) {
                if (mouse.button === Qt.LeftButton) {
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
                    AudioInput.toggleMute()
                    Qt.callLater(function(){ AudioInput.refreshDeviceIcon() })
                }
            }

            // Handle scroll events to adjust mic level
            onWheel: function(wheel) {
                // Wheel angleDelta is in degrees*8 for Qt Quick; use angleDelta.y to determine direction
                var step = 5; // percent per scroll step
                if (wheel.angleDelta.y > 0) AudioInput.changeVolume(step);
                else if (wheel.angleDelta.y < 0) AudioInput.changeVolume(-step);
                wheel.accepted = true
                Qt.callLater(function(){ AudioInput.refreshDeviceIcon() })
            }
        }
    }

    Behavior on color { ColorAnimation { duration: 150 } }
}
