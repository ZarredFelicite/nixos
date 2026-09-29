import QtQuick
import QtQuick.Layouts
import "../services"

Item {
    id: root
    property var popouts: null

    implicitHeight: Colors.pillHeight
    implicitWidth: Colors.ringSize + 6
    visible: BluetoothBattery.visible

    // Poll service
    Component.onCompleted: BluetoothBattery.refCount++
    Component.onDestruction: BluetoothBattery.refCount--

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: {
            if (root.popouts && BluetoothBattery.visible) {
                var pos = root.popouts.mapFromItem(root, root.width / 2, root.height)
                root.popouts.openPopout("tooltip-bluetooth-battery", pos.x, pos.y, root.width)
            }
        }
        onExited: {
            if (root.popouts && root.popouts.currentName === "tooltip-bluetooth-battery" && root.popouts.closeTimer) {
                root.popouts.closeTimer.start()
            }
        }
        onClicked: {
            // Reconnect device
            if (BluetoothBattery.deviceMac) {
                var proc = Qt.createQmlObject('import Quickshell.Io; Process { }', root)
                proc.command = ["sh", "-c", `bluetoothctl disconnect ${BluetoothBattery.deviceMac}; bluetoothctl connect ${BluetoothBattery.deviceMac}`]
                proc.onExited.connect(function() { proc.destroy() })
                proc.running = true
            }
        }
    }

    property string tooltip: BluetoothBattery.tooltipText

    Item {
        id: ringContainer
        anchors.centerIn: parent
        width: Colors.ringSize
        height: Colors.ringSize

        property real clampedValue: Math.max(0, Math.min(1, BluetoothBattery.battery / 100))
        property color ringColor: BluetoothBattery.battery >= 0 && BluetoothBattery.battery <= 15 ? Colors.foregroundRed : Colors.foregroundCyan

        ProgressRing {
            anchors.fill: parent
            value: ringContainer.clampedValue
            foregroundColor: ringContainer.ringColor
            backgroundColor: Colors.primaryTransparent
            thickness: Colors.ringThickness
            startAngle: -90
            sweepAngle: 360
        }

        Image {
            id: deviceIcon
            anchors.centerIn: parent
            width: Colors.ringSize * 0.7
            height: Colors.ringSize * 0.7
            source: BluetoothBattery.iconPath
            fillMode: Image.PreserveAspectFit
            smooth: false
            antialiasing: false
            sourceSize.width: width * ((typeof Screen !== 'undefined' && Screen.devicePixelRatio) ? Screen.devicePixelRatio : 1)
            sourceSize.height: height * ((typeof Screen !== 'undefined' && Screen.devicePixelRatio) ? Screen.devicePixelRatio : 1)
            cache: true
            visible: status === Image.Ready && source !== ""
        }

        Text {
            anchors.centerIn: parent
            text: ""
            font.family: "Material Symbols Outlined"
            font.pixelSize: 20
            color: Colors.primary
            visible: !deviceIcon.visible
        }
    }
}
