import QtQuick
import QtQuick.Controls
import Quickshell.Widgets
import "../../../services"
import "./"

ClippingRectangle {
    id: root
    property var wrapper: null
    property bool expanded: wrapper && wrapper.hasCurrent && wrapper.currentName === 'tooltip-disk'
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

    // Live ticker for the "ago" footer.
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
        var p = Disk.mainUsePercent || 0
        var rms = Disk.remoteMounts || []
        for (var i = 0; i < rms.length; i++) {
            if (rms[i].usePercent > p) p = rms[i].usePercent
        }
        return p
    }

    function statusBadge() {
        var p = root.worstPercent()
        if (p >= 95) return "Critical"
        if (p >= 85) return "Warning"
        if (p >= 70) return "Filling"
        return "Healthy"
    }

    function statusAccent() {
        return root.usageColor(root.worstPercent())
    }

    function freshness() {
        if (!Disk.lastUpdated || Disk.lastUpdated.getTime() === 0) return ""
        var s = Math.max(0, Math.floor((Date.now() - Disk.lastUpdated.getTime()) / 1000))
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

    // ── Reusable: a labelled disk row with a usage bar ──
    component DiskRow: Item {
        property string title: ""
        property string subtitle: ""
        property int percent: 0
        property string sizeText: ""
        property string availText: ""
        property string symbol: "hard_drive_2"

        readonly property color accent: root.usageColor(percent)

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

            // Top: icon + title + percent
            Item {
                id: topRow
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
                    Text {
                        visible: subtitle.length > 0
                        anchors.verticalCenter: parent.verticalCenter
                        text: subtitle
                        color: PopoutConfig.textColor
                        opacity: 0.45
                        font.pixelSize: 10
                        font.family: "monospace"
                        renderType: Text.NativeRendering
                    }
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: percent + "%"
                    color: accent
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    renderType: Text.NativeRendering
                }
            }

            // Usage bar
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: topRow.bottom
                anchors.topMargin: 6
                height: 5
                radius: 2.5
                color: Qt.rgba(1, 1, 1, 0.07)

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, percent / 100))
                    height: parent.height
                    radius: parent.radius
                    color: accent
                    Behavior on width { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                }
            }

            // Bottom: size · used · free
            Row {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                spacing: 12

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: sizeText.length > 0
                    text: sizeText + " total"
                    color: PopoutConfig.textColor
                    opacity: 0.55
                    font.pixelSize: 10
                    renderType: Text.NativeRendering
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: availText.length > 0
                    text: availText + " free"
                    color: PopoutConfig.textColor
                    opacity: 0.55
                    font.pixelSize: 10
                    renderType: Text.NativeRendering
                }
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
                    text: "Disks"
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
            visible: Disk.error.length > 0
            width: parent.width
            height: 28
            radius: 8
            color: Qt.rgba(Colors.foregroundRed.r, Colors.foregroundRed.g, Colors.foregroundRed.b, 0.12)
            border.width: 1
            border.color: Qt.rgba(Colors.foregroundRed.r, Colors.foregroundRed.g, Colors.foregroundRed.b, 0.32)

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "error"
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 13
                    color: Colors.foregroundRed
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Disk.error
                    color: Colors.foregroundRed
                    font.pixelSize: 11
                    opacity: 0.85
                    elide: Text.ElideRight
                    width: Math.max(0, parent.parent.width - 40)
                    renderType: Text.NativeRendering
                }
            }
        }

        // ── Local section header ──
        Item {
            visible: Disk.mainFilesystem.length > 0
            width: parent.width
            height: 14

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "LOCAL"
                color: Colors.primary
                opacity: 0.85
                font.pixelSize: 10
                font.weight: Font.Bold
                renderType: Text.NativeRendering
            }
            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: Disk.mainMount || "/"
                color: PopoutConfig.textColor
                opacity: 0.45
                font.pixelSize: 10
                font.family: "monospace"
                renderType: Text.NativeRendering
            }
        }

        // ── Main disk row ──
        DiskRow {
            visible: Disk.mainFilesystem.length > 0
            symbol: "hard_drive_2"
            title: "root"
            subtitle: Disk.mainFilesystem
            percent: Disk.mainUsePercent
            sizeText: Disk.mainSize
            availText: Disk.mainAvail
        }

        // ── Empty (no df data yet) ──
        Item {
            visible: Disk.mainFilesystem.length === 0 && Disk.error.length === 0
            width: parent.width
            height: 36

            Row {
                anchors.centerIn: parent
                spacing: 6

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "sync"
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 14
                    color: Colors.primary
                    opacity: 0.65
                    RotationAnimation on rotation {
                        running: parent.parent.visible
                        loops: Animation.Infinite
                        from: 0; to: 360
                        duration: 900
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Reading disk usage…"
                    color: PopoutConfig.textColor
                    opacity: 0.65
                    font.pixelSize: 12
                    renderType: Text.NativeRendering
                }
            }
        }

        // ── Remote section header ──
        Item {
            visible: Disk.remoteMounts.length > 0
            width: parent.width
            height: 14

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "REMOTE"
                color: Colors.primary
                opacity: 0.85
                font.pixelSize: 10
                font.weight: Font.Bold
                renderType: Text.NativeRendering
            }
            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: Disk.remoteMounts.length === 1 ? "1 mount" : Disk.remoteMounts.length + " mounts"
                color: PopoutConfig.textColor
                opacity: 0.45
                font.pixelSize: 10
                renderType: Text.NativeRendering
            }
        }

        // ── Remote disk rows ──
        Repeater {
            model: Disk.remoteMounts
            delegate: DiskRow {
                required property var modelData
                symbol: "cloud"
                title: modelData.shortName || modelData.filesystem
                subtitle: modelData.mount || ""
                percent: modelData.usePercent
                sizeText: modelData.size || ""
                availText: modelData.avail || ""
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
                visible: Disk.lastUpdated && Disk.lastUpdated.getTime() > 0
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
                onClicked: Disk.update()
            }
        }
    }
}
