import QtQuick
import Quickshell
import "../services"

// Battery indicator showing dual ring display (outer=capacity, inner=power)
Item {
    id: root
    objectName: "BatteryIndicator"
    property var popouts: null

    implicitHeight: Colors.ringSize
    implicitWidth: Colors.ringSize

    // Only show if battery is available
    visible: Battery.available
    width: visible ? implicitWidth : 0
    opacity: visible ? 1 : 0

    Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    // Activate polling
    Component.onCompleted: Battery.refCount++
    Component.onDestruction: Battery.refCount--

    property string tooltip: Battery.tooltipText

    // Appearance
    property color bgColor: Colors.primaryTransparent
    property real ringThickness: 1.7
    property real ringGap: 1

    // Values (0..1)
    property real capacityValue: Battery.capacity / 100.0
    property real powerValue: Math.min(1.0, Battery.powerWatts / 100.0)

    // Color based on battery level
    function batteryColor(pct01) {
        if (Battery.isCharging) return Colors.todoDateDue
        if (pct01 <= 0.1) return Colors.foregroundRed
        if (pct01 <= 0.25) return Colors.todoPriorityMedium
        if (pct01 <= 0.5) return Colors.tempLevel1
        return Colors.todoPriorityLow
    }

    // Color based on power draw
    function powerColor(watts) {
        if (watts > 50) return Colors.foregroundRed
        if (watts > 25) return Colors.todoPriorityMedium
        return Colors.todoDateDue
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        onPaint: {
            const ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            const cx = width / 2
            const cy = height / 2
            const maxR = Math.min(width, height) / 2
            const thick = root.ringThickness
            const gap = root.ringGap
            // outer = capacity, inner = power
            const rCapacity = maxR - thick/2
            const rPower = rCapacity - (thick + gap)
            ctx.lineCap = "round"

            function drawRing(radius, value, fg) {
                ctx.lineWidth = thick
                // background
                ctx.beginPath()
                ctx.strokeStyle = root.bgColor
                ctx.arc(cx, cy, radius, -Math.PI/2, 1.5*Math.PI, false)
                ctx.stroke()
                if (value > 0) {
                    ctx.beginPath()
                    ctx.strokeStyle = fg
                    ctx.arc(cx, cy, radius, -Math.PI/2, -Math.PI/2 + value * 2*Math.PI, false)
                    ctx.stroke()
                }
            }

            drawRing(rCapacity, root.capacityValue, batteryColor(root.capacityValue))
            drawRing(rPower, root.powerValue, powerColor(Battery.powerWatts))
        }
        Connections {
            target: root
            function onCapacityValueChanged() { canvas.requestPaint() }
            function onPowerValueChanged() { canvas.requestPaint() }
            function onBgColorChanged() { canvas.requestPaint() }
        }
        Connections {
            target: Battery
            function onCapacityChanged() { canvas.requestPaint() }
            function onPowerWattsChanged() { canvas.requestPaint() }
        }
    }

    // Center label: capacity number (charging shows bolt instead)
    Text {
        anchors.centerIn: parent
        text: Battery.isCharging ? "⚡" : String(Battery.capacity)
        color: batteryColor(root.capacityValue)
        font.pixelSize: Battery.isCharging
            ? Math.round(parent.height * 0.7)
            : Math.round(parent.height * 0.42)
        font.bold: true
        renderType: Text.NativeRendering
    }

    Behavior on capacityValue { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
    Behavior on powerValue { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        
        onEntered: {
            if (root.popouts && Battery.available) {
                var pos = root.popouts.mapFromItem(root, root.width / 2, root.height)
                root.popouts.openPopout("tooltip-battery", pos.x, pos.y, root.width)
            }
        }
        
        onExited: {
        }
    }
}