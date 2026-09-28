pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property string deviceMac: ""
    property string deviceName: ""
    property int battery: -1
    property string iconPath: ""
    property bool visible: battery >= 0
    property string tooltipText: visible ? `${deviceName}: ${battery}%` : ""
    property int refCount: 0
    property string error: ""

    property int pollInterval: 10000
    property Timer pollTimer: Timer {
        interval: root.pollInterval
        repeat: true
        running: root.refCount > 0
        onTriggered: root.refresh()
    }

    onRefCountChanged: {
        if (root.refCount > 0) refresh()
    }

    function refresh() {
        var proc = Qt.createQmlObject('import Quickshell.Io; Process { stdout: SplitParser { onRead: function(line) { root._parse(line) } } }', root)
        proc.onExited.connect(function(code) {
            if (code !== 0) root.error = "Poll failed"
            proc.destroy()
        })
        proc.command = ["sh", "-c", `
connected=\$(bluetoothctl devices Connected | awk 'tolower(\$0) ~ /(headset|headphones|earbuds|ear|airpods|qudelix|5k|dac)/ {print \$2}')
[ -z "\$connected" ] && echo "NONE" && exit
for mac in \$connected; do
  info=\$(bluetoothctl info \$mac 2>/dev/null)
  name=\$(echo "\$info" | grep "^\\s*Name:" | sed 's/.*://' | xargs)
  bat_hex=\$(echo "\$info" | grep "Battery Percentage:" | sed 's/.*0x\\([0-9a-fA-F]*\\).*/\\1/')
  bat=\$(echo \$((16#\$bat_hex)) 2>/dev/null || echo -1)
  [ \$bat -ge 0 ] && echo "\$mac|\$name|\$bat" && break  # First valid
done
`]
        proc.running = true
    }

    function _parse(line) {
        line = (line === undefined || line === null) ? "" : line.toString().trim()
        if (line.length === 0) return
        if (line === "NONE") {
            deviceMac = ""; deviceName = ""; battery = -1; iconPath = ""; return
        }
        var parts = line.split("|")
        if (parts.length >= 3) {
            deviceMac = parts[0]
            deviceName = parts[1]
            battery = parseInt(parts[2])
            iconPath = _getIconPath(deviceName)
            tooltipText = `${deviceName}: ${battery}%`
        }
    }

    function _getIconPath(name) {
        if (!name) return "/home/zarred/pictures/icons/headset-white.png"
        if (name.includes("Qudelix-5K")) return "/home/zarred/pictures/icons/iem_silhouette_logo_cutout.svg"
        if (name.includes("Nothing Ear (a)")) return "/home/zarred/pictures/icons/nothing-ear-a.png"
        if (name.includes("AirPods")) return "/home/zarred/pictures/icons/headset-white.png"
        return "/home/zarred/pictures/icons/headset-white.png"
    }
}
