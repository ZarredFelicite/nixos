import QtQuick

Canvas {
    id: root
    
    property int segmentCount: 5
    property int filledSegments: 0
    property real ringRadius: width / 2 - lineWidth / 2
    property real lineWidth: 3
    property color segmentColor: "#00ffff"
    property color backgroundColor: "#333333"
    property real gapAngle: 0.4  // Gap between segments as fraction of segment angle
    property real maxGapRadians: Math.PI / 14
    property bool enableGapCap: false
    property var segmentPalette: []   // Optional per-segment colors
    
    width: 20
    height: 20
    
    onPaint: {
        var ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)
        
        var centerX = width / 2
        var centerY = height / 2
        var segments = Math.max(1, segmentCount || 1)
        var totalAngle = 2 * Math.PI
        var segmentAngle = totalAngle / segments
        var rawGap = segmentAngle * gapAngle
        var gapSize = segments <= 1 ? 0 : (enableGapCap ? Math.min(rawGap, maxGapRadians) : rawGap)
        var drawAngle = segmentAngle - gapSize
        var usePalette = segmentPalette && segmentPalette.length > 0
        
        ctx.lineWidth = lineWidth
        ctx.lineCap = "round"
        
        if (usePalette) {
            for (var i = 0; i < segments; i++) {
                var paletteEntry = segmentPalette[i] || null
                var stroke = backgroundColor
                if (paletteEntry && paletteEntry.color) {
                    stroke = paletteEntry.color
                }
                var startAngle = -Math.PI / 2 - (i * segmentAngle)
                var endAngle = startAngle - drawAngle
                ctx.strokeStyle = stroke
                ctx.beginPath()
                ctx.arc(centerX, centerY, ringRadius, startAngle, endAngle, true)
                ctx.stroke()
            }
        } else {
            // Draw all segments (background)
            for (var i = 0; i < segments; i++) {
                var startAngle = -Math.PI / 2 - (i * segmentAngle)  // Start from top, go clockwise
                var endAngle = startAngle - drawAngle
                
                ctx.strokeStyle = backgroundColor
                ctx.beginPath()
                ctx.arc(centerX, centerY, ringRadius, startAngle, endAngle, true)
                ctx.stroke()
            }
            
            // Draw filled segments sequentially
            for (var j = 0; j < Math.min(filledSegments, segments); j++) {
                var fillStartAngle = -Math.PI / 2 - (j * segmentAngle)
                var fillEndAngle = fillStartAngle - drawAngle
                
                ctx.strokeStyle = segmentColor
                ctx.beginPath()
                ctx.arc(centerX, centerY, ringRadius, fillStartAngle, fillEndAngle, true)
                ctx.stroke()
            }
        }
    }
    
    onFilledSegmentsChanged: requestPaint()
    onSegmentColorChanged: requestPaint()
    onBackgroundColorChanged: requestPaint()
    onSegmentPaletteChanged: requestPaint()
    onSegmentCountChanged: requestPaint()
}
