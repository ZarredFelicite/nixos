import QtQuick
import Quickshell
import "../services"

// Displays three images (left, case, right) representing AirPods battery icons.
// Tooltip shows parsed percentages from AirpodsBattery singleton.
// Click triggers bluetooth reconnect (same MAC as waybar config) for convenience.
Item {
    id: root
    property var popouts: null

    implicitHeight: Colors.pillHeight
    implicitWidth: row.implicitWidth

    // Needed so service polls
// Conditional refCount - only poll if AirPods connected
Timer {
    interval: 5000
    repeat: true
    running: true
    onTriggered: {
        var proc = Qt.createQmlObject('import Quickshell.Io; Process { }', root)
        proc.command = ["bluetoothctl", "info", "14:28:76:9E:F5:60"]
        proc.onExited.connect(function(code) {
            var connected = code === 0 // assumes success means connected/paired
            AirpodsBattery.refCount = connected ? 1 : 0
            proc.destroy()
        })
        proc.running = true
    }
}

    property string tooltip: AirpodsBattery.tooltipText

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onEntered: {
            if (root.popouts) {
                var pos = root.popouts.mapFromItem(root, root.width / 2, root.height)
                root.popouts.openPopout("tooltip-airpods", pos.x, pos.y, root.width)
            }
        }
        onExited: {
        }
        onClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton) {
                // Reconnect sequence
                var proc = Qt.createQmlObject('import Quickshell.Io; Process { }', root)
                proc.command = ["sh", "-c", "bluetoothctl disconnect 14:28:76:9E:F5:60; bluetoothctl connect 14:28:76:9E:F5:60"]
                proc.onExited.connect(function() {
                    proc.destroy()
                })
                proc.running = true
            }
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 2

        property int iconSize: Colors.ringSize
        // Approximate device pixel ratio (Screen singleton available when inside a window)
        readonly property real dpr: (typeof Screen !== 'undefined' && Screen.devicePixelRatio) ? Screen.devicePixelRatio : 1

        // Direct Image elements (simpler than dynamic creation but with improved properties)
        Image {
            id: leftImage
            source: AirpodsBattery.leftPath
            width: row.iconSize
            height: row.iconSize
            fillMode: Image.PreserveAspectFit
            smooth: false
            antialiasing: false
            sourceSize.width: width * row.dpr
            sourceSize.height: height * row.dpr
            cache: true
            asynchronous: true
            visible: source !== '' && status === Image.Ready
        }
        Image {
            id: caseImage
            source: AirpodsBattery.casePath
            width: row.iconSize
            height: row.iconSize
            fillMode: Image.PreserveAspectFit
            smooth: false
            antialiasing: false
            sourceSize.width: width * row.dpr
            sourceSize.height: height * row.dpr
            cache: true
            asynchronous: true
            visible: source !== '' && status === Image.Ready
        }
        Image {
            id: rightImage
            source: AirpodsBattery.rightPath
            width: row.iconSize
            height: row.iconSize
            fillMode: Image.PreserveAspectFit
            smooth: false
            antialiasing: false
            sourceSize.width: width * row.dpr
            sourceSize.height: height * row.dpr
            cache: true
            asynchronous: true
            visible: source !== '' && status === Image.Ready
        }

        // Placeholder when no icons available (or loading / error)
        Text {
            text: "" // bluetooth glyph as fallback
            font.pixelSize: 14
            color: Colors.primary
            visible: !leftImage.visible && !caseImage.visible && !rightImage.visible
        }
    }
}
