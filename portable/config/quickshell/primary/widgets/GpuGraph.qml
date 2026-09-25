import QtQuick
import "../services"

Item {
    id: root

    // GPU data - all metrics for combined graph
    property var usageHistory: []
    property var memoryHistory: []
    property var powerHistory: []
    property var tempHistory: []

    width: 300
    height: 120

    // Transparent background with grey border
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.color: "#666666"  // Grey border
        border.width: 1
        radius: 4
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        anchors.margins: 8

        onPaint: {
            const ctx = getContext("2d")
            if (!ctx) return
            
            ctx.clearRect(0, 0, width, height)

            const data = root.usageHistory
            const color = Colors.success.toString()

            // Calculate graph area
            const graphTop = 10
            const graphBottom = height - 10
            const graphHeight = graphBottom - graphTop
            const graphLeft = 10
            const graphRight = width - 10

            // Draw grid lines (horizontal)
            ctx.strokeStyle = "#444444"
            ctx.lineWidth = 1
            ctx.beginPath()
            // 0%, 50%, 100% lines
            const y0 = graphBottom
            const y50 = graphBottom - (graphHeight * 0.5)
            const y100 = graphTop
            
            ctx.moveTo(graphLeft, y0); ctx.lineTo(graphRight, y0)
            ctx.moveTo(graphLeft, y50); ctx.lineTo(graphRight, y50)
            ctx.moveTo(graphLeft, y100); ctx.lineTo(graphRight, y100)
            ctx.stroke()

            // Draw Usage Graph
            if (data && data.length > 0) {
                ctx.strokeStyle = color
                ctx.lineWidth = 2
                ctx.beginPath()

                // Data points are 0-100
                // Map to graph area
                const stepX = (graphRight - graphLeft) / 19 // 20 points = 19 segments

                for (let i = 0; i < data.length; i++) {
                    const value = Math.max(0, Math.min(100, data[i]))
                    const x = graphLeft + (i * stepX)
                    const y = graphBottom - (value / 100) * graphHeight

                    if (i === 0) {
                        ctx.moveTo(x, y)
                    } else {
                        ctx.lineTo(x, y)
                    }
                }
                
                // If only 1 point, draw a small line or dot
                if (data.length === 1) {
                    ctx.lineTo(graphLeft + 1, graphBottom - (data[0] / 100) * graphHeight)
                }
                
                ctx.stroke()
            }
        }

        // Repaint when data changes
        Connections {
            target: root
            function onUsageHistoryChanged() {
                canvas.requestPaint()
            }
            function onMemoryHistoryChanged() {
                canvas.requestPaint()
            }
            function onPowerHistoryChanged() {
                canvas.requestPaint()
            }
            function onTempHistoryChanged() {
                canvas.requestPaint()
            }
        }

        // Force initial paint
        Component.onCompleted: {
            canvas.requestPaint()
        }
    }

    // Current values display
    Row {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 15

        Text {
            text: `U:${usageHistory.length > 0 ? Math.round(usageHistory[usageHistory.length - 1]) : 0}%`
            color: Colors.success
            font.pixelSize: 10
            font.bold: true
        }

        Text {
            text: `M:${memoryHistory.length > 0 ? Math.round(memoryHistory[memoryHistory.length - 1]) : 0}%`
            color: Colors.primary
            font.pixelSize: 10
            font.bold: true
        }

        Text {
            text: `P:${powerHistory.length > 0 ? Math.round(powerHistory[powerHistory.length - 1]) : 0}%`
            color: Colors.tempLevel2
            font.pixelSize: 10
            font.bold: true
        }

        Text {
            text: `T:${tempHistory.length > 0 ? Math.round(tempHistory[tempHistory.length - 1]) : 0}°C`
            color: Colors.foregroundRed
            font.pixelSize: 10
            font.bold: true
        }
    }
}