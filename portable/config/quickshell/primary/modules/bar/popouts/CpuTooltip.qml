import QtQuick
import Quickshell.Widgets
import "../../../services"
import "./"

ClippingRectangle {
    id: root
    required property Item wrapper
    property bool expanded: wrapper && wrapper.hasCurrent && wrapper.currentName === "tooltip-cpu"
    property bool hasOwnBackground: true

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

    Component.onCompleted: Cpu.refCount++
    Component.onDestruction: Cpu.refCount--

    property int _tick: 0
    Timer {
        interval: 30000
        running: root.expanded
        repeat: true
        triggeredOnStart: true
        onTriggered: root._tick++
    }

    function usageColor(p) {
        if (!isFinite(p) || p < 0) return Colors.todoDateNoDue
        if (p >= 90) return Colors.foregroundRed
        if (p >= 70) return Colors.todoPriorityMedium
        if (p >= 40) return Colors.tempLevel1
        return Colors.todoPriorityLow
    }

    function tempColor(t) {
        if (!isFinite(t) || t <= 0) return Colors.todoDateNoDue
        if (t >= 90) return Colors.foregroundRed
        if (t >= 75) return Colors.todoPriorityMedium
        if (t >= 60) return Colors.tempLevel1
        return Colors.todoPriorityLow
    }

    function statusBadge() {
        var p = Cpu.usagePercent
        var t = Cpu.temp
        if (t >= 90) return "Critical"
        if (p >= 90) return "Maxed"
        if (t >= 75) return "Hot"
        if (p >= 70) return "Busy"
        if (p >= 30) return "Active"
        if (p > 5) return "Light"
        return "Idle"
    }

    function statusAccent() {
        var byUsage = root.usageColor(Cpu.usagePercent)
        var byTemp = root.tempColor(Cpu.temp)
        // Pick the more alarming of the two
        var rank = function(c) {
            if (c === Colors.foregroundRed) return 4
            if (c === Colors.todoPriorityMedium) return 3
            if (c === Colors.tempLevel1) return 2
            if (c === Colors.todoPriorityLow) return 1
            return 0
        }
        return rank(byTemp) > rank(byUsage) ? byTemp : byUsage
    }

    function formatFreqGHz(mhz) {
        if (!isFinite(mhz) || mhz <= 0) return "—"
        return (mhz / 1000).toFixed(2) + " GHz"
    }

    function formatProfile(p) {
        if (!p) return ""
        return p.split("-").map(function(w) { return w.charAt(0).toUpperCase() + w.slice(1) }).join(" ")
    }

    function formatUptime(s) {
        if (!isFinite(s) || s <= 0) return "—"
        var d = Math.floor(s / 86400)
        var h = Math.floor((s % 86400) / 3600)
        var m = Math.floor((s % 3600) / 60)
        if (d > 0) return d + "d " + h + "h"
        if (h > 0) return h + "h " + m + "m"
        return m + "m"
    }

    function freshness() {
        if (!Cpu.lastUpdated || Cpu.lastUpdated.getTime() === 0) return ""
        var s = Math.max(0, Math.floor((Date.now() - Cpu.lastUpdated.getTime()) / 1000))
        if (s < 60) return "just now"
        var m = Math.floor(s / 60)
        if (m < 60) return m + "m ago"
        return Math.floor(m / 60) + "h ago"
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

    component FreqButton: Rectangle {
        property string label: ""
        property string freq: ""
        readonly property bool active: Math.abs(Cpu.maxFrequencyMHz - (parseInt(freq) / 1000)) < 25

        width: (root.contentWidth - 18) / 4
        height: 28
        radius: 8
        color: active || freqMouse.containsMouse ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, active ? 0.22 : 0.12) : Qt.rgba(1, 1, 1, 0.04)
        border.width: 1
        border.color: active ? Colors.primary : Qt.rgba(1, 1, 1, 0.08)
        Behavior on color { ColorAnimation { duration: 120 } }

        Text {
            anchors.centerIn: parent
            text: label
            color: active ? Colors.primary : PopoutConfig.textColor
            opacity: active ? 1 : 0.72
            font.pixelSize: 11
            font.weight: active ? Font.DemiBold : Font.Medium
            renderType: Text.NativeRendering
        }

        MouseArea {
            id: freqMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Cpu.setMaxFrequency(freq)
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
                    text: "CPU"
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
                    running: Cpu.usagePercent >= 70 || Cpu.temp >= 75
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.30; duration: 700; easing.type: Easing.InOutQuad }
                    NumberAnimation { to: 0.85; duration: 700; easing.type: Easing.InOutQuad }
                }
            }
        }

        // ── Usage card ──
        Rectangle {
            id: usageCard
            width: parent.width
            height: 64
            radius: 10
            color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.06)
            border.width: 1
            border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.18)

            readonly property color accent: root.usageColor(Cpu.usagePercent)

            Item {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                anchors.topMargin: 10
                anchors.bottomMargin: 10

                Row {
                    id: usageTop
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: 24
                    spacing: 10

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "memory"
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 18
                        color: usageCard.accent
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Cpu.usagePercent + "%"
                        color: PopoutConfig.textColor
                        font.pixelSize: 22
                        font.weight: Font.Bold
                        renderType: Text.NativeRendering
                    }
                    Item { width: 1; height: 1 }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.formatFreqGHz(Cpu.frequencyMHz)
                            + (Cpu.coreCount > 0 ? "  ·  " + Cpu.coreCount + " cores" : "")
                        color: PopoutConfig.textColor
                        opacity: 0.65
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
                        width: parent.width * Math.max(0, Math.min(1, Cpu.usagePercent / 100))
                        height: parent.height
                        radius: parent.radius
                        color: usageCard.accent
                        Behavior on width { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                }
            }
        }

        // ── Per-core grid ──
        Item {
            visible: Cpu.coreUsages && Cpu.coreUsages.length > 0
            width: parent.width
            height: coresLabel.height + 6 + coreGrid.height

            Text {
                id: coresLabel
                anchors.left: parent.left
                anchors.top: parent.top
                text: "PER CORE"
                color: Colors.primary
                opacity: 0.85
                font.pixelSize: 10
                font.weight: Font.Bold
                renderType: Text.NativeRendering
            }
            Text {
                anchors.right: parent.right
                anchors.verticalCenter: coresLabel.verticalCenter
                text: Cpu.coreCount + (Cpu.coreCount === 1 ? " thread" : " threads")
                color: PopoutConfig.textColor
                opacity: 0.45
                font.pixelSize: 10
                renderType: Text.NativeRendering
            }

            Grid {
                id: coreGrid
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: coresLabel.bottom
                anchors.topMargin: 6
                columns: Math.max(8, Math.min(16, Math.ceil(Math.sqrt(Cpu.coreCount * 2))))
                spacing: 3

                readonly property int cellWidth: Math.floor((width - spacing * (columns - 1)) / columns)

                Repeater {
                    model: Cpu.coreUsages
                    delegate: Rectangle {
                        required property var modelData
                        readonly property int pct: Math.round(modelData)
                        width: coreGrid.cellWidth
                        height: 14
                        radius: 3
                        color: Qt.rgba(1, 1, 1, 0.05)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.06)

                        Rectangle {
                            anchors.left: parent.left
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: parent.height * Math.max(0.04, Math.min(1, pct / 100))
                            radius: parent.radius
                            color: root.usageColor(pct)
                            opacity: 0.92
                            Behavior on height { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                    }
                }
            }
        }

        // ── Stat chips ──
        Flow {
            width: parent.width
            spacing: 6

            InfoChip {
                visible: Cpu.temp > 0
                symbol: "thermostat"
                label: "Temp"
                value: Cpu.temp + "°C"
                accent: root.tempColor(Cpu.temp)
            }
            InfoChip {
                visible: Cpu.maxFrequencyMHz > 0
                symbol: "speed"
                label: "Max"
                value: root.formatFreqGHz(Cpu.maxFrequencyMHz)
                accent: Colors.tempLevel1
            }
            InfoChip {
                visible: Cpu.governor.length > 0
                symbol: "tune"
                label: "Gov"
                value: Cpu.governor
                accent: Colors.todoDateDue
            }
            InfoChip {
                visible: Cpu.profile.length > 0
                symbol: "bolt"
                label: "Profile"
                value: root.formatProfile(Cpu.profile)
                accent: Cpu.profile.indexOf("performance") >= 0 ? Colors.foregroundRed
                    : Cpu.profile.indexOf("power-saver") >= 0 || Cpu.profile.indexOf("low-power") >= 0 ? Colors.todoDateDue
                    : Colors.todoPriorityLow
            }
        }

        // ── Max frequency switcher ──
        Column {
            width: parent.width
            spacing: 6

            Row {
                width: parent.width
                height: 14

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "MAX CLOCK"
                    color: Colors.primary
                    opacity: 0.85
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    renderType: Text.NativeRendering
                }
                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.formatFreqGHz(Cpu.maxFrequencyMHz)
                    color: PopoutConfig.textColor
                    opacity: 0.55
                    font.pixelSize: 10
                    renderType: Text.NativeRendering
                }
            }

            Row {
                width: parent.width
                spacing: 6
                FreqButton { label: "3.4"; freq: "3401000" }
                FreqButton { label: "3.8"; freq: "3800000" }
                FreqButton { label: "4.2"; freq: "4200000" }
                FreqButton { label: "Max"; freq: "5086181" }
            }
        }

        // ── Load avg + uptime ──
        Item {
            width: parent.width
            height: 14
            visible: Cpu.loadAvg1 > 0 || Cpu.uptimeSeconds > 0

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "Load " + Cpu.loadAvg1.toFixed(2) + " · " + Cpu.loadAvg5.toFixed(2) + " · " + Cpu.loadAvg15.toFixed(2)
                color: PopoutConfig.textColor
                opacity: 0.55
                font.pixelSize: 10
                renderType: Text.NativeRendering
            }
            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "up " + root.formatUptime(Cpu.uptimeSeconds)
                color: PopoutConfig.textColor
                opacity: 0.55
                font.pixelSize: 10
                renderType: Text.NativeRendering
            }
        }

        // ── Model line ──
        Text {
            visible: Cpu.model.length > 0
            width: parent.width
            text: Cpu.model
            color: PopoutConfig.textColor
            opacity: 0.5
            font.pixelSize: 10
            elide: Text.ElideRight
            renderType: Text.NativeRendering
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
                visible: Cpu.lastUpdated && Cpu.lastUpdated.getTime() > 0
                color: PopoutConfig.textColor
                opacity: 0.45
                font.pixelSize: 11
                renderType: Text.NativeRendering
            }
            Text {
                anchors.right: parent.right
                anchors.rightMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                text: "Click ring to cycle profile"
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
                onClicked: Cpu.update()
            }
        }
    }
}
