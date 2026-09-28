import QtQuick
import Quickshell.Widgets
import "../../../services"
import "./"

ClippingRectangle {
    id: root
    required property Item wrapper
    required property string gpuType   // "nvidia" or "amd"
    property bool hasOwnBackground: true

    readonly property int hPadding: 16
    readonly property int vPadding: 14
    readonly property int contentWidth: 320

    readonly property string popoutName: "tooltip-gpu-" + gpuType
    readonly property bool expanded: wrapper && wrapper.hasCurrent && wrapper.currentName === popoutName

    // Service field accessors (avoid sprinkling "Gpu.<gpuType><field>" everywhere)
    readonly property real usagePercent: gpuType === "nvidia" ? Gpu.nvidiaGpuUsage : Gpu.amdGpuUsage
    readonly property real memoryPercent: gpuType === "nvidia" ? Gpu.nvidiaMemoryUsage : Gpu.amdMemoryUsage
    readonly property real powerPercent: gpuType === "nvidia" ? Gpu.nvidiaPowerUsage : Gpu.amdPowerUsage
    readonly property int powerWatts: gpuType === "nvidia" ? Gpu.nvidiaPowerWatts : Gpu.amdPowerWatts
    readonly property int temperature: gpuType === "nvidia" ? Gpu.nvidiaTemperature : Gpu.amdTemperature
    readonly property var usageHistory: gpuType === "nvidia" ? Gpu.nvidiaUsageHistory : Gpu.amdUsageHistory
    readonly property var nvidiaProfileLabels: ["High", "M-Hi", "Med", "M-Lo", "Low"]

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

    Component.onCompleted: Gpu.refCount++
    Component.onDestruction: Gpu.refCount--

    function usageColor(p) {
        if (!isFinite(p) || p < 0) return Colors.todoDateNoDue
        if (p >= 90) return Colors.foregroundRed
        if (p >= 70) return Colors.todoPriorityMedium
        if (p >= 40) return Colors.tempLevel1
        return Colors.todoPriorityLow
    }

    function tempColor(t) {
        if (!isFinite(t) || t <= 0) return Colors.todoDateNoDue
        if (t >= 85) return Colors.foregroundRed
        if (t >= 75) return Colors.todoPriorityMedium
        if (t >= 60) return Colors.tempLevel1
        return Colors.todoPriorityLow
    }

    function statusBadge() {
        var t = root.temperature
        var u = root.usagePercent
        if (t >= 85) return "Critical"
        if (u >= 95) return "Maxed"
        if (t >= 75) return "Hot"
        if (u >= 70) return "Busy"
        if (u >= 30) return "Active"
        if (u > 5) return "Light"
        return "Idle"
    }

    function statusAccent() {
        var byU = root.usageColor(root.usagePercent)
        var byT = root.tempColor(root.temperature)
        var rank = function(c) {
            if (c === Colors.foregroundRed) return 4
            if (c === Colors.todoPriorityMedium) return 3
            if (c === Colors.tempLevel1) return 2
            if (c === Colors.todoPriorityLow) return 1
            return 0
        }
        return rank(byT) > rank(byU) ? byT : byU
    }

    function profileAccent(active) {
        return active ? Colors.todoDateDue : Colors.primary
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onEntered: if (root.wrapper && root.wrapper.closeTimer) root.wrapper.closeTimer.stop()
        onExited: if (root.wrapper && root.wrapper.closeTimer) root.wrapper.closeTimer.start()
    }

    component MetricBar: Item {
        property string symbol: ""
        property string title: ""
        property int percent: 0
        property string trailing: ""
        property color accent: Colors.primary

        width: parent ? parent.width : 0
        height: 38

        Item {
            anchors.fill: parent

            Item {
                id: barTop
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 18

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: symbol
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 13
                        color: accent
                        opacity: 0.9
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: title
                        color: PopoutConfig.textColor
                        opacity: 0.75
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        renderType: Text.NativeRendering
                    }
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: trailing.length > 0 ? trailing : (percent + "%")
                    color: accent
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    renderType: Text.NativeRendering
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 5
                radius: 2.5
                color: Qt.rgba(1, 1, 1, 0.07)

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, percent / 100))
                    height: parent.height
                    radius: parent.radius
                    color: accent
                    Behavior on width { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }
        }
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

    component ProfileChip: Rectangle {
        property string label: ""
        property bool active: false
        property color accent: Colors.todoDateDue
        signal triggered

        implicitHeight: 24
        radius: 7
        color: active
            ? Qt.rgba(accent.r, accent.g, accent.b, 0.22)
            : Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.06)
        border.width: 1
        border.color: active
            ? Qt.rgba(accent.r, accent.g, accent.b, 0.45)
            : Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.18)

        Behavior on color { ColorAnimation { duration: 140 } }
        Behavior on border.color { ColorAnimation { duration: 140 } }

        Text {
            anchors.centerIn: parent
            text: label
            color: active ? accent : PopoutConfig.textColor
            opacity: active ? 1.0 : 0.75
            font.pixelSize: 10
            font.weight: active ? Font.Bold : Font.Medium
            renderType: Text.NativeRendering
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.triggered()
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
                    text: root.gpuType.toUpperCase() + " GPU"
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
                    running: root.usagePercent >= 70 || root.temperature >= 75
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

            readonly property color accent: root.usageColor(root.usagePercent)

            Item {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                anchors.topMargin: 10
                anchors.bottomMargin: 10

                Row {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: 24
                    spacing: 10

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "developer_board"
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 18
                        color: usageCard.accent
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Math.round(root.usagePercent) + "%"
                        color: PopoutConfig.textColor
                        font.pixelSize: 22
                        font.weight: Font.Bold
                        renderType: Text.NativeRendering
                    }
                    Item { width: 1; height: 1 }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.powerWatts > 0 ? root.powerWatts + " W draw" : ""
                        visible: text.length > 0
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
                        width: parent.width * Math.max(0, Math.min(1, root.usagePercent / 100))
                        height: parent.height
                        radius: parent.radius
                        color: usageCard.accent
                        Behavior on width { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                }
            }
        }

        // ── Usage sparkline (last ~60s) ──
        Item {
            width: parent.width
            height: 38
            visible: root.usageHistory && root.usageHistory.length >= 2

            readonly property color trace: root.usageColor(root.usagePercent)

            Canvas {
                id: spark
                anchors.fill: parent

                onPaint: {
                    var ctx = getContext("2d")
                    if (!ctx) return
                    ctx.clearRect(0, 0, width, height)

                    var data = root.usageHistory
                    if (!data || data.length < 2) return

                    var pad = 1
                    var w = width - pad * 2
                    var h = height - pad * 2
                    var n = data.length
                    var stepX = n > 1 ? w / (n - 1) : w

                    function pt(i) {
                        var v = Math.max(0, Math.min(100, data[i] || 0))
                        return {
                            x: pad + i * stepX,
                            y: pad + (1 - v / 100) * h
                        }
                    }

                    // Soft area fill under the trace
                    ctx.beginPath()
                    var p0 = pt(0)
                    ctx.moveTo(p0.x, pad + h)
                    ctx.lineTo(p0.x, p0.y)
                    for (var i = 1; i < n; i++) {
                        var p = pt(i)
                        ctx.lineTo(p.x, p.y)
                    }
                    ctx.lineTo(pad + (n - 1) * stepX, pad + h)
                    ctx.closePath()
                    var fill = parent.trace
                    ctx.fillStyle = Qt.rgba(fill.r, fill.g, fill.b, 0.14)
                    ctx.fill()

                    // The trace itself
                    ctx.beginPath()
                    ctx.lineWidth = 1.5
                    ctx.lineJoin = "round"
                    ctx.lineCap = "round"
                    ctx.strokeStyle = parent.trace
                    var s0 = pt(0)
                    ctx.moveTo(s0.x, s0.y)
                    for (var j = 1; j < n; j++) {
                        var sp = pt(j)
                        ctx.lineTo(sp.x, sp.y)
                    }
                    ctx.stroke()

                    // Tip dot
                    var last = pt(n - 1)
                    ctx.beginPath()
                    ctx.fillStyle = parent.trace
                    ctx.arc(last.x, last.y, 2, 0, Math.PI * 2)
                    ctx.fill()
                }

                Connections {
                    target: root
                    function onUsageHistoryChanged() { spark.requestPaint() }
                    function onUsagePercentChanged() { spark.requestPaint() }
                }
            }
        }

        // ── VRAM + Power bars ──
        Column {
            width: parent.width
            spacing: 8

            MetricBar {
                symbol: "memory"
                title: "VRAM"
                percent: Math.round(root.memoryPercent)
                accent: root.usageColor(root.memoryPercent)
            }

            MetricBar {
                symbol: "bolt"
                title: "Power"
                percent: Math.round(root.powerPercent)
                trailing: root.powerWatts > 0 ? (root.powerWatts + " W (" + Math.round(root.powerPercent) + "%)") : ""
                accent: root.usageColor(root.powerPercent)
            }
        }

        // ── Stat chips ──
        Flow {
            width: parent.width
            spacing: 6

            InfoChip {
                visible: root.temperature > 0
                symbol: "thermostat"
                label: "Temp"
                value: root.temperature + "°C"
                accent: root.tempColor(root.temperature)
            }
            InfoChip {
                visible: root.gpuType === "nvidia"
                symbol: "tune"
                label: "Profile"
                value: {
                    var idx = Gpu.nvidiaProfile
                    return (idx >= 0 && idx < root.nvidiaProfileLabels.length)
                        ? root.nvidiaProfileLabels[idx]
                        : "—"
                }
                accent: Gpu.nvidiaProfile === 0 ? Colors.foregroundRed
                    : Gpu.nvidiaProfile === 4 ? Colors.todoDateDue
                    : Colors.primary
            }
            InfoChip {
                visible: root.gpuType === "amd" && Gpu.amdProfile && Gpu.amdProfile !== "unknown"
                symbol: "tune"
                label: "Profile"
                value: Gpu.amdProfile.charAt(0).toUpperCase() + Gpu.amdProfile.slice(1)
                accent: Gpu.amdProfile === "performance" ? Colors.foregroundRed
                    : Gpu.amdProfile === "power-saving" ? Colors.todoDateDue
                    : Colors.primary
            }
        }

        // ── Section header ──
        Item {
            width: parent.width
            height: 14

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "POWER PROFILE"
                color: Colors.primary
                opacity: 0.85
                font.pixelSize: 10
                font.weight: Font.Bold
                renderType: Text.NativeRendering
            }
            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: root.gpuType === "nvidia" ? "click to set" : "click to switch"
                color: PopoutConfig.textColor
                opacity: 0.45
                font.pixelSize: 10
                renderType: Text.NativeRendering
            }
        }

        // ── NVIDIA profile chips: 5 levels ──
        Row {
            visible: root.gpuType === "nvidia"
            width: parent.width
            spacing: 6

            readonly property real chipWidth: (width - spacing * 4) / 5

            Repeater {
                model: root.nvidiaProfileLabels.length
                delegate: ProfileChip {
                    required property int index
                    width: parent.chipWidth
                    label: root.nvidiaProfileLabels[index]
                    active: Gpu.nvidiaProfile === index
                    accent: index === 0 ? Colors.foregroundRed
                        : index === 4 ? Colors.todoDateDue
                        : Colors.primary
                    onTriggered: Gpu.setNvidiaProfile(index)
                }
            }
        }

        // ── AMD profile chips: 3 named ──
        Row {
            visible: root.gpuType === "amd"
            width: parent.width
            spacing: 6

            readonly property var amdProfiles: [
                { id: "power-saving", label: "Power-saving", accent: Colors.todoDateDue },
                { id: "default", label: "Default", accent: Colors.primary },
                { id: "performance", label: "Performance", accent: Colors.foregroundRed }
            ]
            readonly property real chipWidth: (width - spacing * 2) / 3

            Repeater {
                model: parent.amdProfiles
                delegate: ProfileChip {
                    required property var modelData
                    width: parent.chipWidth
                    label: modelData.label
                    accent: modelData.accent
                    active: Gpu.amdProfile === modelData.id
                    onTriggered: Gpu.setAmdProfile(modelData.id)
                }
            }
        }

        // ── Footer ──
        Rectangle {
            width: parent.width
            height: 24
            radius: 8
            color: "transparent"

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                text: "Sampled every 3s"
                color: PopoutConfig.textColor
                opacity: 0.45
                font.pixelSize: 11
                renderType: Text.NativeRendering
            }
            Text {
                anchors.right: parent.right
                anchors.rightMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                text: "Click ring to cycle"
                color: PopoutConfig.textColor
                opacity: 0.55
                font.pixelSize: 11
                font.weight: Font.Medium
                renderType: Text.NativeRendering
            }
        }
    }
}
