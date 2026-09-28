// Based on celestia's Performance.qml ring implementation
import QtQuick
import "../services"

Item {
    id: root
    
    // Public properties
    property real value: 0.0  // 0.0 to 1.0
    property color foregroundColor: "#e6e1e5"
    property color backgroundColor: Qt.rgba(1, 1, 1, 0.1)
    property real thickness: Colors.ringThickness
    property real startAngle: -90  // Start at top
    property real sweepAngle: 270  // 3/4 circle
    
    // Make the ring size match the shared pill height by default
    implicitWidth: Colors.ringSize
    implicitHeight: Colors.ringSize
    
    Canvas {
        id: canvas
        anchors.fill: parent
        
        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            
            const centerX = width / 2;
            const centerY = height / 2;
            const radius = Math.min(width, height) / 2 - root.thickness / 2;
            
            // Convert angles to radians
            const startRad = (root.startAngle * Math.PI) / 180;
            const endRad = ((root.startAngle + root.sweepAngle) * Math.PI) / 180;
            const progressRad = startRad + (endRad - startRad) * root.value;
            
            ctx.lineWidth = root.thickness;
            ctx.lineCap = "round";
            
            // Background arc
            ctx.beginPath();
            ctx.arc(centerX, centerY, radius, startRad, endRad, false);
            ctx.strokeStyle = root.backgroundColor;
            ctx.stroke();
            
            // Progress arc (only if value > 0)
            if (root.value > 0) {
                ctx.beginPath();
                ctx.arc(centerX, centerY, radius, startRad, progressRad, false);
                ctx.strokeStyle = root.foregroundColor;
                ctx.stroke();
            }
        }
        
        // Repaint when properties change
        Connections {
            target: root
            function onValueChanged() { canvas.requestPaint(); }
            function onForegroundColorChanged() { canvas.requestPaint(); }
            function onBackgroundColorChanged() { canvas.requestPaint(); }
            function onThicknessChanged() { canvas.requestPaint(); }
        }
    }
    
    // Smooth value animation like celestia
    Behavior on value {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }
}