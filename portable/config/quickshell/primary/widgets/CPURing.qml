import QtQuick
import Quickshell
import Quickshell.Io
import "../services"

RingIcon {
    id: root

    property var popouts: null

    ringSize: Colors.ringSize
    iconSize: 22

    // Mirror service state
    property real cpuUsageValue: Cpu.usagePercent
    property int cpuTemp: Cpu.temp
    property string cpuProfile: Cpu.profile

    Component.onCompleted: Cpu.refCount++
    Component.onDestruction: Cpu.refCount--

    // Three-stop temperature gradient using rose-pine palette tokens.
    function tempColor(temp) {
        const levels = [50, 70, 100]
        const cols = [Colors.tempLevel1, Colors.tempLevel2, Colors.tempLevel3]
        const t = Math.max(0, Math.min(200, temp))

        function hexToRgb(col) {
            if (typeof col === 'string') {
                const h = col.replace('#','')
                return [parseInt(h.substring(0,2),16), parseInt(h.substring(2,4),16), parseInt(h.substring(4,6),16)]
            }
            if (col && typeof col.r !== 'undefined') {
                const to255 = v => v <= 1 ? Math.round(v * 255) : Math.round(v)
                return [to255(col.r), to255(col.g), to255(col.b)]
            }
            return [255,255,255]
        }
        function rgbToHex(r,g,b){
            return "#" + ((1<<24) + (Math.round(r)<<16) + (Math.round(g)<<8) + Math.round(b)).toString(16).slice(1)
        }

        var i = 0
        while (i < levels.length && t > levels[i]) i++

        var startLvl, endLvl, startCol, endCol
        if (i === 0) {
            startLvl = 0; endLvl = levels[0]
            startCol = Colors.baseTempColor; endCol = cols[0]
        } else if (i >= levels.length) {
            return cols[cols.length-1]
        } else {
            startLvl = levels[i-1]; endLvl = levels[i]
            startCol = cols[i-1]; endCol = cols[i]
        }

        var fraction = endLvl - startLvl !== 0
            ? Math.max(0, Math.min(1, (t - startLvl) / (endLvl - startLvl)))
            : 0
        const sc = hexToRgb(startCol)
        const ec = hexToRgb(endCol)
        return rgbToHex(
            sc[0] + (ec[0] - sc[0]) * fraction,
            sc[1] + (ec[1] - sc[1]) * fraction,
            sc[2] + (ec[2] - sc[2]) * fraction
        )
    }

    ringValue: cpuUsageValue / 100.0
    ringForegroundColor: tempColor(cpuTemp)
    iconColor: tempColor(cpuTemp)

    iconSource: cpuProfile === "power-saver" || cpuProfile === "low-power"
        ? "/home/zarred/pictures/icons/cpu-low-white.png"
        : cpuProfile === "performance" ? "/home/zarred/pictures/icons/cpu-high-white.png"
        : "/home/zarred/pictures/icons/cpu-medium-white.png"

    // Hover tooltip (popouts wired by parent)
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onEntered: {
            if (root.popouts) {
                var pos = root.popouts.mapFromItem(root, root.width / 2, root.height)
                root.popouts.openPopout("tooltip-cpu", pos.x, pos.y, root.width)
            }
        }
        onExited: {
            if (root.popouts && root.popouts.currentName === "tooltip-cpu") {
                root.popouts.scheduleClose()
            }
        }
    }

    // Click cycles the power profile via the existing helper script.
    onClicked: function(mouse) {
        if (mouse.button === Qt.LeftButton) {
            // Optimistic local prediction for instant feedback
            var current = Cpu.profile
            var next = current
            if (current === "power-saver" || current === "low-power") next = "balanced"
            else if (current === "balanced") next = "performance"
            else if (current === "performance") next = (current === "performance" && _isNano() ? "low-power" : "power-saver")
            else next = "balanced"
            cpuProfile = next
            Cpu.switchProfile()
        }
    }

    function _isNano() {
        // Hostname check would require a process; treat unknown profiles like nano if 'low-power' is in cycle.
        return Cpu.profile === "low-power"
    }
}
