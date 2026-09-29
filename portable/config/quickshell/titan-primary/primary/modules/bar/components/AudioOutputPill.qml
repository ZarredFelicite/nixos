import QtQuick
import QtQuick.Layouts 1.15
import "../../../widgets"
import "../../../services"

Pill {
    id: root
    Component.onCompleted: {
        AudioOutput.refCount++;
        if (typeof AudioOutput.update === 'function') AudioOutput.update();
    }
    Component.onDestruction: AudioOutput.refCount--
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

        // Use the same RingIcon component as the input pill
        RingIcon {
            id: speakerRing
            Layout.preferredWidth: Colors.ringSize
            Layout.preferredHeight: Colors.ringSize
            ringValue: AudioOutput.level / 100.0
            iconSource: AudioOutput.deviceIconPath
            iconSize: 12
            iconFillMode: Image.PreserveAspectFit
             ringForegroundColor: AudioOutput.muted ? "#666" : Colors.foregroundCyan
             ringBackgroundColor: Colors.primaryTransparent
             // Use brightness darkening instead of colorization
             useBrightnessDarkening: true
             iconColor: AudioOutput.muted ? "#666" : "#fff"

            Component.onCompleted: AudioOutput.refreshDeviceIcon()

            // Handle clicks via RingIcon.clicked so events forwarded by RingIcon's MouseArea are used
            onClicked: function(mouse) {
                if (mouse.button === Qt.LeftButton) {
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
                    AudioOutput.toggleMute()
                    Qt.callLater(function(){ AudioOutput.refreshDeviceIcon() })
                }
            }

            // Handle scroll events to adjust volume
            onWheel: function(wheel) {
                var step = 5;
                if (wheel.angleDelta.y > 0) AudioOutput.changeVolume(step);
                else if (wheel.angleDelta.y < 0) AudioOutput.changeVolume(-step);
                wheel.accepted = true
                Qt.callLater(function(){ AudioOutput.refreshDeviceIcon() })
            }
        }
    }

    Behavior on color { ColorAnimation { duration: 150 } }
}
