import QtQuick
import Quickshell
import "../services"

Item {
    id: root

    property var popouts: null

    // GPU type: "nvidia" or "amd"
    property string gpuType: "nvidia"

    // Use the general ringSize from Colors by default
    width: Colors.ringSize
    height: Colors.ringSize

    // GPU data properties (selected based on gpuType)
    property real gpuUsage: gpuType === "amd" ? Gpu.amdGpuUsage : Gpu.nvidiaGpuUsage
    property real memoryUsage: gpuType === "amd" ? Gpu.amdMemoryUsage : Gpu.nvidiaMemoryUsage
    property real powerUsage: gpuType === "amd" ? Gpu.amdPowerUsage : Gpu.nvidiaPowerUsage
    property int gpuTemp: gpuType === "amd" ? Gpu.amdTemperature : Gpu.nvidiaTemperature
    property int powerWatts: gpuType === "amd" ? Gpu.amdPowerWatts : Gpu.nvidiaPowerWatts

    // Compute temperature-based color using same logic as CPU widget
    function tempColor(temp) {
        // Levels: 50 -> tempLevel1, 70 -> tempLevel2, 100 -> tempLevel3
        const levels = [50, 70, 100];
        const cols = [Colors.tempLevel1, Colors.tempLevel2, Colors.tempLevel3];

        // Clamp temp to reasonable bounds
        const t = Math.max(0, Math.min(200, temp));

        function hexToRgb(col) {
            if (typeof col === 'string') {
                const h = col.replace('#','');
                return [parseInt(h.substring(0,2),16), parseInt(h.substring(2,4),16), parseInt(h.substring(4,6),16)];
            }
            if (col && typeof col.r !== 'undefined') {
                const to255 = v => v <= 1 ? Math.round(v * 255) : Math.round(v);
                return [to255(col.r), to255(col.g), to255(col.b)];
            }
            return [255,255,255];
        }
        function rgbToHex(r,g,b){
            return "#" + ((1<<24) + (Math.round(r)<<16) + (Math.round(g)<<8) + Math.round(b)).toString(16).slice(1);
        }

        // Find which segment the temp falls into
        var i = 0;
        while (i < levels.length && t > levels[i]) i++;

        if (i === 0) {
            // t <= first level: interpolate between base and level1
            var startLvl = 0;
            var endLvl = levels[0];
            var startCol = Colors.baseTempColor;
            var endCol = cols[0];
        } else if (i >= levels.length) {
            // above highest level, return highest color
            return cols[cols.length-1];
        } else {
            var startLvl = levels[i-1];
            var endLvl = levels[i];
            var startCol = cols[i-1];
            var endCol = cols[i];
        }

        var fraction = 0.0;
        if (endLvl - startLvl !== 0) {
            fraction = (t - startLvl) / (endLvl - startLvl);
            fraction = Math.max(0, Math.min(1, fraction));
        }

        const sc = hexToRgb(startCol);
        const ec = hexToRgb(endCol);
        const r = sc[0] + (ec[0] - sc[0]) * fraction;
        const g = sc[1] + (ec[1] - sc[1]) * fraction;
        const b = sc[2] + (ec[2] - sc[2]) * fraction;
        return rgbToHex(r,g,b);
    }

    readonly property color ringColor: tempColor(gpuTemp)

    // Ring properties - match NetworkRings configuration
    property real ringThickness: Math.max(1, Colors.ringThickness * 0.8)
    property real ringGap: 1

    // Normalized values for rings
    property real gpuValue: gpuUsage / 100.0
    property real memoryValue: memoryUsage / 100.0
    property real powerValue: powerUsage / 100.0

    // Canvas to draw three concentric rings like NetworkRings
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
            
            // Calculate ring radii: outer, middle, inner
            const rGpu = maxR - thick/2
            const rMemory = rGpu - (thick + gap)
            const rPower = rMemory - (thick + gap)
            
            ctx.lineCap = "round"

            function drawRing(radius, value, fg) {
                ctx.lineWidth = thick
                // Background circle
                ctx.beginPath()
                ctx.strokeStyle = Colors.primaryTransparent
                ctx.arc(cx, cy, radius, 0, 2*Math.PI, false)
                ctx.stroke()
                
                // Foreground arc
                if (value > 0) {
                    ctx.beginPath()
                    ctx.strokeStyle = fg
                    ctx.arc(cx, cy, radius, -Math.PI/2, -Math.PI/2 + value * 2*Math.PI, false)
                    ctx.stroke()
                }
            }

            drawRing(rGpu, root.gpuValue, ringColor)
            drawRing(rMemory, root.memoryValue, ringColor)
            drawRing(rPower, root.powerValue, ringColor)
        }
        
        // Repaint when values change
        Connections {
            target: root
            function onGpuValueChanged() { canvas.requestPaint() }
            function onMemoryValueChanged() { canvas.requestPaint() }
            function onPowerValueChanged() { canvas.requestPaint() }
            function onRingColorChanged() { canvas.requestPaint() }
        }
        
        // Repaint when GPU service values change
        Connections {
            target: Gpu
            function onGpuUsageChanged() { canvas.requestPaint() }
            function onMemoryUsageChanged() { canvas.requestPaint() }
            function onPowerUsageChanged() { canvas.requestPaint() }
            function onTemperatureChanged() { canvas.requestPaint() }
        }
    }

    // Smooth animations for ring values
    Behavior on gpuValue { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
    Behavior on memoryValue { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
    Behavior on powerValue { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

    // GPU label in center
    Text {
        id: gpuLabel
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: parent.height * 0.02
        text: "G"
        color: ringColor
        font.pixelSize: Math.round(parent.height * 0.39)
        font.bold: true
    }

    // Tooltip showing GPU stats
    property string tooltip: `${gpuType.toUpperCase()} GPU: ${Math.round(gpuUsage)}% | Memory: ${Math.round(memoryUsage)}% | Power: ${powerWatts}W | Temp: ${gpuTemp}°C`

    // Mouse interactions for hover tooltip and profile switching
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        onEntered: {
            if (root.popouts) {
                var pos = root.popouts.mapFromItem(root, root.width / 2, root.height)
                root.popouts.openPopout("tooltip-gpu-" + root.gpuType, pos.x, pos.y, root.width)
            }
        }
        onExited: {
            if (root.popouts && root.popouts.currentName === "tooltip-gpu-" + root.gpuType) {
                root.popouts.scheduleClose()
            }
        }
        onClicked: {
            if (root.gpuType === "nvidia") {
                // Cycle: 4 (Low) -> 2 (Med) -> 0 (High) -> 4
                // Or simplistic: (current - 2)
                // Actually user listed 0,1,2,3,4.
                // Let's do a simple cycle: (current + 1) % 5?
                // The buttons show High (0), M-Hi (1), Med (2), M-Lo (3), Low (4).
                // "running with no args results in ... [3] P6 (Low)".
                // Let's cycle backwards for performance? 4->0?
                // Or just cycle 0->1->2->3->4->0
                var next = (Gpu.nvidiaProfile + 1) % 5
                Gpu.setNvidiaProfile(next)
            } else if (root.gpuType === "amd") {
                // Cycle: default -> power-saving -> performance -> default
                var current = Gpu.amdProfile
                var next = "default"
                if (current === "default") next = "power-saving"
                else if (current === "power-saving") next = "performance"
                else if (current === "performance") next = "default"
                else next = "default" // fallback for unknown
                
                Gpu.setAmdProfile(next)
            }
        }
    }

    Component.onCompleted: {
        console.log("GPURing created for", root.gpuType, "- incrementing refCount")
        Gpu.refCount++
        console.log("GPU refCount is now:", Gpu.refCount)
    }

    Component.onDestruction: {
        Gpu.refCount--
    }
}