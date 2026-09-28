// Based on celestia's dual-ring system from Performance.qml
import QtQuick

Item {
    id: root
    
    // Public properties for two metrics
    property real value1: 0.0  // 0.0 to 1.0
    property real value2: 0.0  // 0.0 to 1.0
    property color color1: "#e6e1e5"
    property color color2: "#a6a1a5"
    property color backgroundColor: Qt.rgba(1, 1, 1, 0.1)
    property real thickness: 3
    
    implicitWidth: 32
    implicitHeight: 32
    
    Canvas {
        id: canvas
        anchors.fill: parent
        
        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            
            const centerX = width / 2;
            const centerY = height / 2;
            const radius = Math.min(width, height) / 2 - root.thickness / 2;
            
            // Arc 1: 45° to 220° (bottom-left to top-right)
            const a1Start = (45 * Math.PI) / 180;
            const a1End = (220 * Math.PI) / 180;
            const a1Progress = a1Start + (a1End - a1Start) * root.value1;
            
            // Arc 2: 230° to 360° (top-right to bottom)
            const a2Start = (230 * Math.PI) / 180;
            const a2End = (360 * Math.PI) / 180;
            const a2Progress = a2Start + (a2End - a2Start) * root.value2;
            
            ctx.lineWidth = root.thickness;
            ctx.lineCap = "round";
            
            // Background arcs
            ctx.beginPath();
            ctx.arc(centerX, centerY, radius, a1Start, a1End, false);
            ctx.strokeStyle = root.backgroundColor;
            ctx.stroke();
            
            ctx.beginPath();
            ctx.arc(centerX, centerY, radius, a2Start, a2End, false);
            ctx.strokeStyle = root.backgroundColor;
            ctx.stroke();
            
            // Progress arcs
            if (root.value1 > 0) {
                ctx.beginPath();
                ctx.arc(centerX, centerY, radius, a1Start, a1Progress, false);
                ctx.strokeStyle = root.color1;
                ctx.stroke();
            }
            
            if (root.value2 > 0) {
                ctx.beginPath();
                ctx.arc(centerX, centerY, radius, a2Start, a2Progress, false);
                ctx.strokeStyle = root.color2;
                ctx.stroke();
            }
        }
        
        Connections {
            target: root
            function onValue1Changed() { canvas.requestPaint(); }
            function onValue2Changed() { canvas.requestPaint(); }
            function onColor1Changed() { canvas.requestPaint(); }
            function onColor2Changed() { canvas.requestPaint(); }
            function onBackgroundColorChanged() { canvas.requestPaint(); }
        }
    }
    
    // Smooth animations like celestia
    Behavior on value1 {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }
    
    Behavior on value2 {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }
}