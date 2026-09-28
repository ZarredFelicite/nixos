import QtQuick
import Quickshell.Widgets
import "../../../services"
import "./"

ClippingRectangle {
    id: root
    required property Item wrapper
    property bool expanded: wrapper && wrapper.hasCurrent && wrapper.currentName === "tooltip-memory"
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
        if (p >= 95) return Colors.foregroundRed
        if (p >= 85) return Colors.todoPriorityMedium
        if (p >= 70) return Colors.todoDateDue
        return Colors.todoPriorityLow
    }

    function worstPercent() {
        return Math.max(Math.round(Memory.memPercent * 100), Math.round(Memory.swapPercent * 100))
    }

    function statusBadge() {
        var p = root.worstPercent()
        if (p >= 95) return "Critical"
        if (p >= 85) return "Pressure"
        if (p >= 70) return "Busy"
        return "Healthy"
    }

    function statusAccent() {
        return root.usageColor(root.worstPercent())
    }

    function freshness() {
        if (!Memory.lastUpdated || Memory.lastUpdated.getTime() === 0) return ""
        var s = Math.max(0, Math.floor((Date.now() - Memory.lastUpdated.getTime()) / 1000))
        if (s < 60) return "just now"
        var m = Math.floor(s / 60)
        if (m < 60) return m + "m ago"
        var h = Math.floor(m / 60)
        if (h < 24) return h + "h ago"
        return Math.floor(h / 24) + "d ago"
    }

    function fmtGiB(kb) {
        if (!isFinite(kb) || kb <= 0) return "0"
        var n = kb / (1024 * 1024)
        var s = n.toFixed(1)
        if (s.indexOf(".") !== -1) s = s.replace(/0+$/, "").replace(/\.$/, "")
        return s
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onEntered: if (root.wrapper && root.wrapper.closeTimer) root.wrapper.closeTimer.stop()
        onExited: if (root.wrapper && root.wrapper.closeTimer) root.wrapper.closeTimer.start()
    }

    component UsageRow: Item {
        property string title: ""
        property string symbol: "memory"
        property int percent: 0
        property string usedText: ""
        property string totalText: ""
        property string subtitleOverride: ""
        property bool dim: false

        readonly property color accent: dim ? Colors.todoDateNoDue : root.usageColor(percent)

        width: parent ? parent.width : 0
        height: 56

        Rectangle {
            anchors.fill: parent
            radius: 10
            color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.06)
            border.width: 1
            border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.18)
        }

        Item {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            anchors.topMargin: 8
            anchors.bottomMargin: 8

            Item {
                id: top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 16

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: symbol
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 14
                        color: Colors.primary
                        opacity: 0.9
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: title
                        color: PopoutConfig.textColor
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        renderType: Text.NativeRendering
                    }
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: dim ? "—" : (percent + "%")
                    color: accent
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    renderType: Text.NativeRendering
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: top.bottom
                anchors.topMargin: 6
                height: 5
                radius: 2.5
                color: Qt.rgba(1, 1, 1, 0.07)

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, percent / 100))
                    height: parent.height
                    radius: parent.radius
                    color: accent
                    visible: !dim
                    Behavior on width { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                }
            }

            Text {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                text: subtitleOverride.length > 0
                    ? subtitleOverride
                    : (usedText + " GiB used · " + totalText + " GiB total")
                color: PopoutConfig.textColor
                opacity: 0.55
                font.pixelSize: 10
                elide: Text.ElideRight
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
                    text: "Memory"
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
            }
        }

        // ── Error banner ──
        Rectangle {
            visible: Memory.error.length > 0
            width: parent.width
            height: 28
            radius: 8
            color: Qt.rgba(Colors.foregroundRed.r, Colors.foregroundRed.g, Colors.foregroundRed.b, 0.12)
            border.width: 1
            border.color: Qt.rgba(Colors.foregroundRed.r, Colors.foregroundRed.g, Colors.foregroundRed.b, 0.32)

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: Memory.error
                color: Colors.foregroundRed
                font.pixelSize: 11
                opacity: 0.85
                elide: Text.ElideRight
                width: parent.width - 20
                renderType: Text.NativeRendering
            }
        }

        // ── RAM ──
        UsageRow {
            symbol: "memory"
            title: "RAM"
            percent: Math.round(Memory.memPercent * 100)
            usedText: root.fmtGiB(Memory.memUsedKb)
            totalText: root.fmtGiB(Memory.memTotalKb)
        }

        // ── Swap ──
        UsageRow {
            symbol: "swap_horiz"
            title: "Swap"
            dim: Memory.swapTotalKb <= 0
            percent: Memory.swapTotalKb > 0 ? Math.round(Memory.swapPercent * 100) : 0
            usedText: root.fmtGiB(Memory.swapUsedKb)
            totalText: root.fmtGiB(Memory.swapTotalKb)
            subtitleOverride: Memory.swapTotalKb <= 0 ? "Swap disabled" : ""
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
                visible: Memory.lastUpdated && Memory.lastUpdated.getTime() > 0
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
                onClicked: Memory.update()
            }
        }
    }
}
