import QtQuick
import "../services" as Services

Item {
    id: root
    objectName: "AlphaESSFlow"

    property var popouts: null
    property string tooltipName: "tooltip-alphaess"
    readonly property var dataSource: Services.AlphaESS

    property real batteryValue: {
        var soc = dataSource.batterySoc
        if (isNaN(soc)) return 0
        return Math.max(0, Math.min(1, soc / 100))
    }

    property real solarValue: {
        var watts = dataSource.solarWatts
        if (isNaN(watts)) return 0
        return Math.max(0, Math.min(1, watts / 5000))
    }

    property real loadValue: {
        var watts = dataSource.loadWatts
        if (isNaN(watts)) return 0
        return Math.max(0, Math.min(1, watts / 3000))
    }

    readonly property bool feedInActive: !isNaN(dataSource.gridWatts) && dataSource.gridWatts < -500
    readonly property bool gridImportActive: !isNaN(dataSource.gridWatts) && dataSource.gridWatts > 100

    readonly property color solarColor: feedInActive ? Services.Colors.todoPriorityLow
        : (gridImportActive ? Services.Colors.foregroundRed : Services.Colors.tempLevel1)
    readonly property color loadColor: gridImportActive ? Services.Colors.foregroundRed : Services.Colors.todoDateDue
    readonly property color batteryColor: Services.Colors.todoPriorityMedium

    readonly property real baseSize: Services.Colors.ringSize
    readonly property real ringThickness: Math.max(1, Services.Colors.ringThickness * 0.8)
    readonly property real ringGap: 1

    implicitWidth: baseSize
    implicitHeight: baseSize
    width: implicitWidth
    height: implicitHeight

    function formattedWatts(value) {
        if (isNaN(value)) return "--"
        if (Math.abs(value) >= 1000)
            return (value / 1000).toFixed(1) + "kW"
        return Math.round(value) + "W"
    }


    Canvas {
        id: canvas
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            var cx = width / 2
            var cy = height / 2
            var maxR = Math.min(width, height) / 2
            var thick = root.ringThickness
            var gap = root.ringGap

            function drawRing(radius, value, fgColor) {
                ctx.lineWidth = thick
                ctx.strokeStyle = Services.Colors.primaryTransparent
                ctx.beginPath()
                ctx.arc(cx, cy, radius, -Math.PI / 2, 1.5 * Math.PI)
                ctx.stroke()
                if (value <= 0) return
                ctx.strokeStyle = fgColor
                ctx.beginPath()
                ctx.arc(cx, cy, radius, -Math.PI / 2, -Math.PI / 2 + value * 2 * Math.PI)
                ctx.stroke()
            }

            var outerR = maxR - thick / 2
            var middleR = outerR - (thick + gap)
            var innerR = middleR - (thick + gap)
            if (innerR < thick)
                innerR = thick

            drawRing(outerR, root.batteryValue, root.batteryColor)
            drawRing(middleR, root.solarValue, root.solarColor)
            drawRing(innerR, root.loadValue, root.loadColor)
        }

        Connections {
            target: root
            function onBatteryValueChanged() { canvas.requestPaint() }
            function onSolarValueChanged() { canvas.requestPaint() }
            function onLoadValueChanged() { canvas.requestPaint() }
            function onSolarColorChanged() { canvas.requestPaint() }
            function onLoadColorChanged() { canvas.requestPaint() }
        }
        Connections {
            target: dataSource
            function onSolarWattsChanged() { canvas.requestPaint() }
            function onLoadWattsChanged() { canvas.requestPaint() }
            function onBatterySocChanged() { canvas.requestPaint() }
            function onGridWattsChanged() { canvas.requestPaint() }
        }
    }


    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        propagateComposedEvents: true
        onEntered: {
            if (root.popouts) {
                var pos = root.popouts.mapFromItem(root, root.width / 2, root.height)
                root.popouts.openPopout(root.tooltipName, pos.x, pos.y, root.width)
            }
        }
        onExited: {
            if (root.popouts)
                root.popouts.scheduleClose()
        }
    }

    Behavior on batteryValue { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    Behavior on solarValue { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    Behavior on loadValue { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
}
