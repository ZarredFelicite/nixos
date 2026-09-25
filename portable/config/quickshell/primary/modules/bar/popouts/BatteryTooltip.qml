import QtQuick
import Quickshell.Widgets
import "../../../services"
import "./"

ClippingRectangle {
    id: root
    required property Item wrapper
    property bool expanded: wrapper && wrapper.hasCurrent && wrapper.currentName === "tooltip-battery"
    property bool hasOwnBackground: true

    readonly property int hPadding: 16
    readonly property int vPadding: 14
    readonly property int contentWidth: 300

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

    Component.onCompleted: Battery.refCount++
    Component.onDestruction: Battery.refCount--

    property int _tick: 0
    Timer {
        interval: 30000
        running: root.expanded
        repeat: true
        triggeredOnStart: true
        onTriggered: root._tick++
    }

    function capacityColor(p) {
        if (!isFinite(p) || p < 0) return Colors.todoDateNoDue
        if (Battery.isCharging) return Colors.todoDateDue
        if (p <= 10) return Colors.foregroundRed
        if (p <= 25) return Colors.todoPriorityMedium
        if (p <= 50) return Colors.tempLevel1
        return Colors.todoPriorityLow
    }

    function statusBadge() {
        if (!Battery.available) return "Absent"
        if (Battery.isFull) return "Full"
        if (Battery.isCharging) return "Charging"
        if (Battery.capacity <= 10) return "Critical"
        if (Battery.capacity <= 25) return "Low"
        if (Battery.isDischarging) return "On battery"
        return Battery.status
    }

    function statusAccent() {
        if (!Battery.available) return Colors.todoDateNoDue
        if (Battery.isFull) return Colors.todoPriorityLow
        if (Battery.isCharging) return Colors.todoDateDue
        return root.capacityColor(Battery.capacity)
    }

    function statusIconName() {
        if (!Battery.available) return "battery_unknown"
        if (Battery.isCharging) return "battery_charging_full"
        if (Battery.isFull) return "battery_full"
        var p = Battery.capacity
        if (p <= 10) return "battery_alert"
        if (p <= 25) return "battery_2_bar"
        if (p <= 50) return "battery_4_bar"
        if (p <= 75) return "battery_5_bar"
        return "battery_6_bar"
    }

    function freshness() {
        if (!Battery.lastUpdated || Battery.lastUpdated.getTime() === 0) return ""
        var s = Math.max(0, Math.floor((Date.now() - Battery.lastUpdated.getTime()) / 1000))
        if (s < 60) return "just now"
        var m = Math.floor(s / 60)
        if (m < 60) return m + "m ago"
        var h = Math.floor(m / 60)
        if (h < 24) return h + "h ago"
        return Math.floor(h / 24) + "d ago"
    }

    function fmtDuration(seconds) {
        if (!isFinite(seconds) || seconds < 0) return ""
        if (seconds < 60) return seconds + "s"
        var m = Math.round(seconds / 60)
        if (m < 60) return m + "m"
        var h = Math.floor(m / 60)
        var mm = m % 60
        if (mm === 0) return h + "h"
        return h + "h " + mm + "m"
    }

    function timeRemainingLabel() {
        var s = Battery.timeRemainingSeconds
        if (s < 0) return ""
        if (Battery.isCharging) return "Full in " + root.fmtDuration(s)
        if (Battery.isDischarging) return root.fmtDuration(s) + " remaining"
        return ""
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onEntered: if (root.wrapper && root.wrapper.closeTimer) root.wrapper.closeTimer.stop()
        onExited: if (root.wrapper && root.wrapper.closeTimer) root.wrapper.closeTimer.start()
    }

    component InfoChip: Rectangle {
        property string symbol: ""
        property string label: ""
        property string value: ""
        property color accent: Colors.primary

        implicitWidth: chipRow.implicitWidth + 18
        implicitHeight: 26
        radius: 8
        color: Qt.rgba(accent.r, accent.g, accent.b, 0.10)
        border.width: 1
        border.color: Qt.rgba(accent.r, accent.g, accent.b, 0.22)

        Row {
            id: chipRow
            anchors.centerIn: parent
            spacing: 6

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: symbol
                visible: symbol.length > 0
                font.family: "Material Symbols Outlined"
                font.pixelSize: 12
                color: accent
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: label
                color: PopoutConfig.textColor
                opacity: 0.6
                font.pixelSize: 10
                font.weight: Font.Medium
                renderType: Text.NativeRendering
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: value
                color: accent
                font.pixelSize: 11
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
                    text: "Battery"
                    color: PopoutConfig.textColor
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    renderType: Text.NativeRendering
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
                    running: Battery.isCharging
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.30; duration: 700; easing.type: Easing.InOutQuad }
                    NumberAnimation { to: 0.85; duration: 700; easing.type: Easing.InOutQuad }
                }
            }
        }

        // ── Empty state ──
        Item {
            visible: !Battery.available
            width: parent.width
            height: 36

            Row {
                anchors.centerIn: parent
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "battery_unknown"
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 16
                    color: PopoutConfig.textColor
                    opacity: 0.55
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "No battery detected"
                    color: PopoutConfig.textColor
                    opacity: 0.6
                    font.pixelSize: 12
                    renderType: Text.NativeRendering
                }
            }
        }

        // ── Capacity card ──
        Rectangle {
            visible: Battery.available
            width: parent.width
            height: 64
            radius: 10
            color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.06)
            border.width: 1
            border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.18)

            readonly property color accent: root.capacityColor(Battery.capacity)

            Item {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                anchors.topMargin: 10
                anchors.bottomMargin: 10

                Row {
                    id: capTop
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: 24
                    spacing: 10

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.statusIconName()
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 22
                        color: parent.parent.parent.accent
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Battery.capacity + "%"
                        color: PopoutConfig.textColor
                        font.pixelSize: 22
                        font.weight: Font.Bold
                        renderType: Text.NativeRendering
                    }

                    Item { width: 1; height: 1 }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.timeRemainingLabel()
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
                        width: parent.width * Math.max(0, Math.min(1, Battery.capacity / 100))
                        height: parent.height
                        radius: parent.radius
                        color: parent.parent.parent.accent
                        Behavior on width { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                }
            }
        }

        // ── Stat chips ──
        Flow {
            visible: Battery.available
            width: parent.width
            spacing: 6

            InfoChip {
                symbol: "bolt"
                label: "Power"
                value: Battery.powerWatts > 0 ? Battery.powerWatts + " W" : "—"
                accent: Battery.isCharging ? Colors.todoDateDue : Colors.primary
            }
            InfoChip {
                symbol: "electric_bolt"
                label: "Voltage"
                value: Battery.voltageVolts > 0 ? Battery.voltageVolts.toFixed(2) + " V" : "—"
                accent: Colors.tempLevel1
            }
            InfoChip {
                visible: Battery.currentAmps !== 0
                symbol: "tune"
                label: "Current"
                value: Math.abs(Battery.currentAmps).toFixed(2) + " A"
                accent: Colors.todoDateDue
            }
            InfoChip {
                visible: Battery.healthPercent >= 0
                symbol: "favorite"
                label: "Health"
                value: Battery.healthPercent + "%"
                accent: Battery.healthPercent >= 80 ? Colors.todoPriorityLow
                    : Battery.healthPercent >= 60 ? Colors.todoPriorityMedium
                    : Colors.foregroundRed
            }
            InfoChip {
                visible: Battery.cycleCount > 0
                symbol: "loop"
                label: "Cycles"
                value: String(Battery.cycleCount)
                accent: Colors.primary
            }
        }

        // ── Energy detail row ──
        Item {
            visible: Battery.available && Battery.energyFullWh > 0
            width: parent.width
            height: 14

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "ENERGY"
                color: Colors.primary
                opacity: 0.85
                font.pixelSize: 10
                font.weight: Font.Bold
                renderType: Text.NativeRendering
            }
            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: Battery.energyNowWh.toFixed(1) + " / " + Battery.energyFullWh.toFixed(1) + " Wh"
                    + (Battery.energyFullDesignWh > 0
                        ? " · design " + Battery.energyFullDesignWh.toFixed(1) + " Wh"
                        : "")
                color: PopoutConfig.textColor
                opacity: 0.55
                font.pixelSize: 10
                renderType: Text.NativeRendering
            }
        }

        // ── Device line ──
        Item {
            visible: Battery.available && (Battery.modelName.length > 0 || Battery.manufacturer.length > 0)
            width: parent.width
            height: 14

            Text {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: Text.AlignLeft
                text: {
                    var parts = []
                    if (Battery.manufacturer.length > 0) parts.push(Battery.manufacturer)
                    if (Battery.modelName.length > 0) parts.push(Battery.modelName)
                    if (Battery.technology.length > 0) parts.push(Battery.technology)
                    return parts.join(" · ")
                }
                color: PopoutConfig.textColor
                opacity: 0.5
                font.pixelSize: 10
                elide: Text.ElideRight
                renderType: Text.NativeRendering
            }
        }

        // ── Footer ──
        Rectangle {
            width: parent.width
            height: 24
            radius: 8
            color: footerHover.containsMouse ? Qt.rgba(1, 1, 1, 0.05) : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                text: { var _ = root._tick; return "Updated " + root.freshness() }
                visible: Battery.lastUpdated && Battery.lastUpdated.getTime() > 0
                color: PopoutConfig.textColor
                opacity: 0.45
                font.pixelSize: 11
                renderType: Text.NativeRendering
            }
            Text {
                anchors.right: parent.right
                anchors.rightMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                text: "Click to refresh"
                color: PopoutConfig.textColor
                opacity: 0.55
                font.pixelSize: 11
                font.weight: Font.Medium
                renderType: Text.NativeRendering
            }

            MouseArea {
                id: footerHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Battery.update()
            }
        }
    }
}
