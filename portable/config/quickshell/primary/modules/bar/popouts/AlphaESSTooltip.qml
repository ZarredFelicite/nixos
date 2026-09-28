import QtQuick
import Quickshell.Widgets
import "../../../services"
import "./"

ClippingRectangle {
    id: root
    property var wrapper: null
    property bool hasOwnBackground: true
    property bool expanded: wrapper && wrapper.hasCurrent && wrapper.currentName === "tooltip-alphaess"

    readonly property int hPadding: 16
    readonly property int vPadding: 14
    readonly property int contentWidth: 320

    implicitWidth: expanded ? contentWidth + hPadding * 2 : 0
    implicitHeight: expanded ? mainColumn.implicitHeight + vPadding * 2 : 0

    layer.enabled: true
    layer.smooth: false

    color: PopoutConfig.backgroundColor
    border.width: PopoutConfig.borderWidth
    border.color: PopoutConfig.borderColor
    radius: PopoutConfig.cornerRadius
    contentInsideBorder: false

    Behavior on implicitHeight { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

    property int _tick: 0
    Timer {
        interval: 30000
        running: root.expanded
        repeat: true
        triggeredOnStart: true
        onTriggered: root._tick++
    }

    // ── Sign conventions ──
    // battery: negative = charging (in), positive = discharging (out)
    // grid:    negative = exporting (out), positive = importing (in)
    readonly property real solar: isFinite(AlphaESS.solarWatts) ? AlphaESS.solarWatts : 0
    readonly property real load: isFinite(AlphaESS.loadWatts) ? AlphaESS.loadWatts : 0
    readonly property real battery: isFinite(AlphaESS.batteryWatts) ? AlphaESS.batteryWatts : 0
    readonly property real grid: isFinite(AlphaESS.gridWatts) ? AlphaESS.gridWatts : 0
    readonly property real soc: isFinite(AlphaESS.batterySoc) ? AlphaESS.batterySoc : 0

    readonly property bool batteryCharging: battery < -50
    readonly property bool batteryDischarging: battery > 50
    readonly property bool gridExporting: grid < -50
    readonly property bool gridImporting: grid > 50
    readonly property bool solarActive: solar > 50

    function fmtW(value) {
        if (!isFinite(value)) return "—"
        var v = Math.abs(value)
        if (v >= 1000) return (v / 1000).toFixed(v >= 10000 ? 0 : 1) + " kW"
        return Math.round(v) + " W"
    }

    function socColor(p) {
        if (!isFinite(p) || p < 0) return Colors.todoDateNoDue
        if (p >= 50) return Colors.todoPriorityLow      // pine (healthy)
        if (p >= 30) return Colors.todoDateDue          // foam
        if (p >= 15) return Colors.todoPriorityMedium   // rose
        return Colors.foregroundRed                     // love
    }

    function statusBadge() {
        if (AlphaESS.error && AlphaESS.error.length) return "Error"
        if (!AlphaESS.available) return AlphaESS.loading ? "Syncing" : "No data"
        if (gridExporting) return "Exporting"
        if (gridImporting) return "Importing"
        if (solarActive && batteryCharging) return "Charging"
        if (batteryDischarging) return "On Battery"
        if (solarActive) return "Self-sufficient"
        return "Idle"
    }

    function statusAccent() {
        if (AlphaESS.error && AlphaESS.error.length) return Colors.foregroundRed
        if (!AlphaESS.available) return Colors.todoDateNoDue
        if (gridExporting) return Colors.todoPriorityLow
        if (gridImporting) return Colors.foregroundRed
        if (solarActive) return Colors.todoDateDue
        if (batteryDischarging) return Colors.todoPriorityMedium
        return Colors.todoDateNoDue
    }

    function batteryFlowText() {
        if (batteryCharging) return "Charging at " + root.fmtW(battery)
        if (batteryDischarging) return "Discharging at " + root.fmtW(battery)
        if (!AlphaESS.available) return ""
        return "Idle"
    }

    function selfSufficiency() {
        if (load <= 0) return -1
        var fromSolar = Math.min(solar, load)
        var pct = Math.round((fromSolar / load) * 100)
        return Math.max(0, Math.min(100, pct))
    }

    function freshness() {
        if (!AlphaESS.lastUpdated || AlphaESS.lastUpdated.getTime() === 0) return ""
        var s = Math.max(0, Math.floor((Date.now() - AlphaESS.lastUpdated.getTime()) / 1000))
        if (s < 60) return "just now"
        var m = Math.floor(s / 60)
        if (m < 60) return m + "m ago"
        var h = Math.floor(m / 60)
        if (h < 24) return h + "h ago"
        return Math.floor(h / 24) + "d ago"
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onEntered: if (root.wrapper && root.wrapper.closeTimer) root.wrapper.closeTimer.stop()
        onExited: if (root.wrapper && root.wrapper.closeTimer) root.wrapper.closeTimer.start()
    }

    component FlowCard: Rectangle {
        property string symbol: ""
        property string title: ""
        property real watts: 0
        property string direction: ""   // "in" | "out" | "idle" | ""
        property color accent: Colors.primary
        property bool dim: false

        implicitHeight: 50
        radius: 10
        color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.06)
        border.width: 1
        border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.18)

        Item {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            anchors.topMargin: 6
            anchors.bottomMargin: 6

            Item {
                id: cardTop
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 14

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 5

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: symbol
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 12
                        color: dim ? Colors.todoDateNoDue : accent
                        opacity: 0.95
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: title
                        color: PopoutConfig.textColor
                        opacity: 0.6
                        font.pixelSize: 10
                        font.weight: Font.Medium
                        renderType: Text.NativeRendering
                    }
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: direction === "in" ? "↓"
                        : direction === "out" ? "↑"
                        : direction === "idle" ? "·"
                        : ""
                    color: dim ? Colors.todoDateNoDue : accent
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    renderType: Text.NativeRendering
                }
            }

            Text {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                text: dim ? "—" : root.fmtW(watts)
                color: dim ? Colors.todoDateNoDue : PopoutConfig.textColor
                font.pixelSize: 14
                font.weight: Font.DemiBold
                renderType: Text.NativeRendering
            }
        }
    }

    Column {
        id: mainColumn
        width: root.contentWidth
        spacing: 10
        anchors.top: parent.top
        anchors.topMargin: root.vPadding
        anchors.horizontalCenter: parent.horizontalCenter
        opacity: root.expanded ? Colors.opacity.foreground1 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }

        // ── Header ──
        Item {
            width: parent.width
            height: 22

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: AlphaESS.systemName && AlphaESS.systemName !== AlphaESS.serial
                        ? AlphaESS.systemName
                        : "Solar System"
                    color: PopoutConfig.textColor
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    renderType: Text.NativeRendering
                    elide: Text.ElideRight
                    width: Math.min(implicitWidth, 180)
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: badgeText.implicitWidth + 12
                    height: 16
                    radius: 8
                    color: Qt.rgba(root.statusAccent().r, root.statusAccent().g, root.statusAccent().b, 0.16)

                    Text {
                        id: badgeText
                        anchors.centerIn: parent
                        text: root.statusBadge().toUpperCase()
                        color: root.statusAccent()
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        renderType: Text.NativeRendering
                    }
                }
            }

            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 8
                height: 8
                radius: 4
                color: root.statusAccent()
                opacity: 0.85
                SequentialAnimation on opacity {
                    running: root.solarActive || root.batteryDischarging || root.gridImporting || root.gridExporting
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.30; duration: 750; easing.type: Easing.InOutQuad }
                    NumberAnimation { to: 0.85; duration: 750; easing.type: Easing.InOutQuad }
                }
            }
        }

        // ── Error banner ──
        Rectangle {
            visible: AlphaESS.error && AlphaESS.error.length > 0
            width: parent.width
            height: 28
            radius: 8
            color: Qt.rgba(Colors.foregroundRed.r, Colors.foregroundRed.g, Colors.foregroundRed.b, 0.12)
            border.width: 1
            border.color: Qt.rgba(Colors.foregroundRed.r, Colors.foregroundRed.g, Colors.foregroundRed.b, 0.32)

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: AlphaESS.error
                color: Colors.foregroundRed
                font.pixelSize: 11
                opacity: 0.85
                elide: Text.ElideRight
                renderType: Text.NativeRendering
            }
        }

        // ── Battery card ──
        Rectangle {
            id: batteryCard
            visible: AlphaESS.available
            width: parent.width
            height: 64
            radius: 10
            color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.06)
            border.width: 1
            border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.18)

            readonly property color accent: root.socColor(root.soc)

            Item {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                anchors.topMargin: 10
                anchors.bottomMargin: 10

                Row {
                    id: batteryTop
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: 24
                    spacing: 10

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.batteryCharging ? "battery_charging_full" : "battery_full"
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 20
                        color: batteryCard.accent
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Math.round(root.soc) + "%"
                        color: PopoutConfig.textColor
                        font.pixelSize: 22
                        font.weight: Font.Bold
                        renderType: Text.NativeRendering
                    }
                    Item { width: 1; height: 1 }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.batteryFlowText()
                        visible: text.length > 0
                        color: PopoutConfig.textColor
                        opacity: 0.7
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        renderType: Text.NativeRendering
                    }
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 6
                    radius: 3
                    color: Qt.rgba(1, 1, 1, 0.07)

                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(1, root.soc / 100))
                        height: parent.height
                        radius: parent.radius
                        color: batteryCard.accent
                        Behavior on width { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                }
            }
        }

        // ── Energy flow grid (2×2) ──
        Item {
            visible: AlphaESS.available
            width: parent.width
            height: flowGrid.implicitHeight

            Grid {
                id: flowGrid
                anchors.fill: parent
                columns: 2
                rowSpacing: 8
                columnSpacing: 8

                readonly property real cellWidth: (width - columnSpacing) / 2

                FlowCard {
                    width: flowGrid.cellWidth
                    symbol: "wb_sunny"
                    title: "Solar"
                    watts: root.solar
                    direction: root.solarActive ? "out" : "idle"
                    accent: Colors.todoDateDue
                    dim: !root.solarActive
                }
                FlowCard {
                    width: flowGrid.cellWidth
                    symbol: "home"
                    title: "Load"
                    watts: root.load
                    direction: root.load > 0 ? "in" : "idle"
                    accent: Colors.tempLevel1
                    dim: root.load < 10
                }
                FlowCard {
                    width: flowGrid.cellWidth
                    symbol: "electric_meter"
                    title: "Grid"
                    watts: root.grid
                    direction: root.gridExporting ? "out" : root.gridImporting ? "in" : "idle"
                    accent: root.gridExporting ? Colors.todoPriorityLow
                        : root.gridImporting ? Colors.foregroundRed
                        : Colors.todoDateNoDue
                    dim: !root.gridExporting && !root.gridImporting
                }
                FlowCard {
                    width: flowGrid.cellWidth
                    symbol: "battery_charging_full"
                    title: "Battery"
                    watts: root.battery
                    direction: root.batteryCharging ? "in" : root.batteryDischarging ? "out" : "idle"
                    accent: root.batteryCharging ? Colors.todoPriorityLow
                        : root.batteryDischarging ? Colors.todoPriorityMedium
                        : Colors.todoDateNoDue
                    dim: !root.batteryCharging && !root.batteryDischarging
                }
            }
        }

        // ── Self-sufficiency line ──
        Item {
            visible: AlphaESS.available && root.selfSufficiency() >= 0
            width: parent.width
            height: 14

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "SELF-SUFFICIENCY"
                color: Colors.primary
                opacity: 0.85
                font.pixelSize: 10
                font.weight: Font.Bold
                renderType: Text.NativeRendering
            }
            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: root.selfSufficiency() + "% solar"
                color: root.selfSufficiency() >= 100 ? Colors.todoPriorityLow
                    : root.selfSufficiency() >= 50 ? Colors.todoDateDue
                    : Colors.todoPriorityMedium
                font.pixelSize: 11
                font.weight: Font.DemiBold
                renderType: Text.NativeRendering
            }
        }

        // ── Footer ──
        Rectangle {
            width: parent.width
            height: 24
            radius: 8
            color: footerHover.containsMouse && !AlphaESS.loading ? Qt.rgba(1, 1, 1, 0.05) : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                text: { var _ = root._tick; return "Updated " + root.freshness() }
                visible: AlphaESS.lastUpdated && AlphaESS.lastUpdated.getTime() > 0
                color: PopoutConfig.textColor
                opacity: 0.45
                font.pixelSize: 11
                renderType: Text.NativeRendering
            }
            Text {
                anchors.right: parent.right
                anchors.rightMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                text: AlphaESS.loading ? "Syncing…" : "Click to refresh"
                color: AlphaESS.loading ? Colors.todoDateDue : PopoutConfig.textColor
                opacity: AlphaESS.loading ? 0.85 : 0.55
                font.pixelSize: 11
                font.weight: AlphaESS.loading ? Font.DemiBold : Font.Medium
                renderType: Text.NativeRendering
            }

            MouseArea {
                id: footerHover
                anchors.fill: parent
                hoverEnabled: true
                enabled: !AlphaESS.loading
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: AlphaESS.refresh()
            }
        }
    }
}
