import QtQuick
import QtQuick.Controls
import Quickshell.Widgets
import "../../../services"
import "./"

ClippingRectangle {
    id: root
    property var wrapper: null
    property bool expanded: wrapper && wrapper.hasCurrent && wrapper.currentName === 'restic-tooltip'
    property bool hasOwnBackground: true

    readonly property int hPadding: 16
    readonly property int vPadding: 14
    readonly property int contentWidth: 320
    readonly property int maxListHeight: 220
    readonly property int maxDiffHeight: 180

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

    // Live ticker so "Xm ago" updates without a refetch.
    property int _tick: 0
    Timer {
        interval: 30000
        running: root.expanded
        repeat: true
        triggeredOnStart: true
        onTriggered: root._tick++
    }

    // Track which two snapshots the open diff was generated from so the rows
    // and the diff card header can highlight them.
    property string diffFromId: ""
    property string diffToId: ""

    function formatBytes(bytes) {
        if (!bytes || bytes <= 0) return "0 B"
        const k = 1024
        const sizes = ['B', 'KB', 'MB', 'GB', 'TB']
        const i = Math.min(sizes.length - 1, Math.floor(Math.log(bytes) / Math.log(k)))
        return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i]
    }

    function thousands(n) {
        var v = Number(n) || 0
        return v.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",")
    }

    function relTime(iso) {
        if (!iso) return ""
        var d = new Date(iso)
        if (isNaN(d.getTime())) return ""
        var s = Math.max(0, Math.floor((Date.now() - d.getTime()) / 1000))
        if (s < 60) return "just now"
        var m = Math.floor(s / 60)
        if (m < 60) return m + "m ago"
        var h = Math.floor(m / 60)
        if (h < 24) return h + "h ago"
        var dy = Math.floor(h / 24)
        if (dy < 7) return dy + "d ago"
        var w = Math.floor(dy / 7)
        if (w < 5) return w + "w ago"
        return Math.floor(dy / 30) + "mo ago"
    }

    function freshness() {
        if (Restic.checking) return "refreshing…"
        if (!Restic.lastUpdated || Restic.lastUpdated.getTime() === 0) return ""
        var s = Math.max(0, Math.floor((Date.now() - Restic.lastUpdated.getTime()) / 1000))
        if (s < 60) return "just now"
        var m = Math.floor(s / 60)
        if (m < 60) return m + "m ago"
        var h = Math.floor(m / 60)
        if (h < 24) return h + "h ago"
        return Math.floor(h / 24) + "d ago"
    }

    function statusBadge() {
        if (Restic.backingUp) return "Backing up"
        if (Restic.lastStatus === "success") return "Healthy"
        if (Restic.lastStatus === "error") return "Error"
        if (Restic.lastStatus === "running") return "Running"
        return "Idle"
    }

    function statusAccent() {
        if (Restic.backingUp || Restic.lastStatus === "running") return Colors.todoDateDue
        if (Restic.lastStatus === "error") return Colors.foregroundRed
        if (Restic.lastStatus === "success") return Colors.todoPriorityLow
        return Colors.primary
    }

    function shortId(id) {
        if (!id) return ""
        return id.substring(0, 8)
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onEntered: if (wrapper && wrapper.closeTimer) wrapper.closeTimer.stop()
        onExited: if (wrapper) wrapper.scheduleClose()
    }

    Column {
        id: mainColumn
        width: root.contentWidth
        spacing: 12
        anchors.top: parent.top
        anchors.topMargin: root.vPadding
        anchors.horizontalCenter: parent.horizontalCenter
        opacity: root.expanded ? Colors.opacity.foreground1 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }

        // ── Header: title + status badge + pulsing dot ──
        Item {
            width: parent.width
            height: 22

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Restic"
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
                    running: Restic.backingUp || Restic.checking
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.30; duration: 600; easing.type: Easing.InOutQuad }
                    NumberAnimation { to: 0.85; duration: 600; easing.type: Easing.InOutQuad }
                }
            }
        }

        // ── Error banner ──
        Rectangle {
            visible: Restic.error.length > 0
            width: parent.width
            height: errCol.implicitHeight + 12
            radius: 8
            color: Qt.rgba(Colors.foregroundRed.r, Colors.foregroundRed.g, Colors.foregroundRed.b, 0.12)
            border.width: 1
            border.color: Qt.rgba(Colors.foregroundRed.r, Colors.foregroundRed.g, Colors.foregroundRed.b, 0.32)

            Column {
                id: errCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 2

                Row {
                    spacing: 6
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "error"
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 14
                        color: Colors.foregroundRed
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Restic error"
                        color: Colors.foregroundRed
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        renderType: Text.NativeRendering
                    }
                }
                Text {
                    width: parent.width
                    text: Restic.error
                    color: Colors.foregroundRed
                    opacity: 0.82
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                    renderType: Text.NativeRendering
                }
            }
        }

        // ── Stat chips ──
        Row {
            visible: Restic.error.length === 0 && (Restic.stats.total_size || Restic.stats.total_file_count)
            width: parent.width
            spacing: 6

            component StatChip: Rectangle {
                property string label: ""
                property string value: ""
                property string symbol: ""
                property color accent: Colors.primary

                width: chipRow.implicitWidth + 14
                height: 22
                radius: 11
                color: Qt.rgba(accent.r, accent.g, accent.b, 0.14)
                border.width: 1
                border.color: Qt.rgba(accent.r, accent.g, accent.b, 0.30)

                Row {
                    id: chipRow
                    anchors.centerIn: parent
                    spacing: 5

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: symbol
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 12
                        color: accent
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: value
                        color: accent
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        renderType: Text.NativeRendering
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: label
                        color: accent
                        opacity: 0.7
                        font.pixelSize: 10
                        renderType: Text.NativeRendering
                    }
                }
            }

            StatChip {
                symbol: "database"
                label: "size"
                value: root.formatBytes(Restic.stats.total_size)
                accent: Colors.todoDateDue
            }
            StatChip {
                symbol: "description"
                label: "files"
                value: root.thousands(Restic.stats.total_file_count)
                accent: Colors.todoPriorityLow
            }
        }

        // ── Section header ──
        Item {
            visible: Restic.snapshots.length > 0
            width: parent.width
            height: 14

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "RECENT SNAPSHOTS"
                color: Colors.primary
                opacity: 0.85
                font.pixelSize: 10
                font.weight: Font.Bold
                renderType: Text.NativeRendering
            }
            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: Restic.snapshots.length + " kept"
                color: PopoutConfig.textColor
                opacity: 0.45
                font.pixelSize: 10
                renderType: Text.NativeRendering
            }
        }

        // ── Empty state ──
        Item {
            visible: Restic.snapshots.length === 0 && Restic.error.length === 0
            width: parent.width
            height: 36

            Row {
                anchors.centerIn: parent
                spacing: 6
                Text {
                    id: emptyIcon
                    anchors.verticalCenter: parent.verticalCenter
                    text: Restic.checking ? "sync" : "inbox"
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 14
                    color: Restic.checking ? Colors.primary : PopoutConfig.textColor
                    opacity: 0.65
                    RotationAnimation on rotation {
                        running: Restic.checking
                        loops: Animation.Infinite
                        from: 0; to: 360
                        duration: 900
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Restic.checking ? "Loading snapshots…" : "No snapshots yet"
                    color: PopoutConfig.textColor
                    opacity: 0.65
                    font.pixelSize: 12
                    renderType: Text.NativeRendering
                }
            }
        }

        // ── Snapshot list (scrollable) ──
        ScrollView {
            id: snapScroll
            visible: Restic.snapshots.length > 0
            width: parent.width
            implicitHeight: Math.min(snapColumn.implicitHeight, root.maxListHeight)
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            Column {
                id: snapColumn
                width: snapScroll.availableWidth
                spacing: 2

                Repeater {
                    model: Restic.snapshots.slice().reverse()
                    delegate: Rectangle {
                        id: snapItem
                        required property int index
                        required property var modelData
                        readonly property bool isLatest: index === 0
                        readonly property bool isDiffMember:
                            (root.diffFromId.length > 0 || root.diffToId.length > 0) &&
                            (root.diffFromId === modelData.id || root.diffToId === modelData.id)

                        width: snapColumn.width
                        height: 32
                        radius: 8
                        color: snapMouse.containsMouse
                            ? Qt.rgba(1, 1, 1, 0.06)
                            : (isDiffMember
                                ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.10)
                                : "transparent")
                        Behavior on color { ColorAnimation { duration: 120 } }

                        MouseArea {
                            id: snapMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                var snapshots = Restic.snapshots
                                var actualIndex = snapshots.length - 1 - index
                                if (actualIndex > 0) {
                                    var from = snapshots[actualIndex - 1].id
                                    var to = snapshots[actualIndex].id
                                    root.diffFromId = from
                                    root.diffToId = to
                                    Restic.getDiff(from, to)
                                } else {
                                    root.diffFromId = ""
                                    root.diffToId = ""
                                    Restic.diffOutput = "No earlier snapshot to diff against."
                                }
                            }
                        }

                        Item {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10

                            Row {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 8

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 6
                                    height: 6
                                    radius: 3
                                    color: snapItem.isLatest
                                        ? Colors.todoPriorityLow
                                        : Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.55)
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.relTime(modelData.time)
                                    color: PopoutConfig.textColor
                                    opacity: snapItem.isLatest ? 1.0 : 0.85
                                    font.pixelSize: 12
                                    font.weight: snapItem.isLatest ? Font.DemiBold : Font.Normal
                                    renderType: Text.NativeRendering
                                }

                                Rectangle {
                                    visible: snapItem.isLatest
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: latestText.implicitWidth + 8
                                    height: 12
                                    radius: 6
                                    color: Qt.rgba(Colors.todoPriorityLow.r, Colors.todoPriorityLow.g, Colors.todoPriorityLow.b, 0.22)

                                    Text {
                                        id: latestText
                                        anchors.centerIn: parent
                                        text: "LATEST"
                                        color: Colors.todoDateDue
                                        font.pixelSize: 8
                                        font.weight: Font.Bold
                                        renderType: Text.NativeRendering
                                    }
                                }
                            }

                            Text {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.shortId(modelData.id)
                                color: PopoutConfig.textColor
                                opacity: 0.5
                                font.pixelSize: 10
                                font.family: "monospace"
                                renderType: Text.NativeRendering
                            }
                        }
                    }
                }
            }
        }

        // ── Diff card ──
        Rectangle {
            id: diffCard
            visible: Restic.diffOutput !== "" || Restic.diffing
            width: parent.width
            height: visible ? (diffHeader.height + diffBody.height + 14) : 0
            radius: 10
            color: Qt.rgba(0, 0, 0, 0.30)
            border.width: 1
            border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.20)

            Item {
                id: diffHeader
                width: parent.width
                height: 26
                anchors.top: parent.top

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "compare_arrows"
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 13
                        color: Colors.primary
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Diff"
                        color: Colors.primary
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        renderType: Text.NativeRendering
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: root.diffFromId.length > 0
                        text: root.shortId(root.diffFromId) + " → " + root.shortId(root.diffToId)
                        color: PopoutConfig.textColor
                        opacity: 0.55
                        font.pixelSize: 10
                        font.family: "monospace"
                        renderType: Text.NativeRendering
                    }
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    width: 18
                    height: 18
                    radius: 9
                    color: closeMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.10) : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: "close"
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 12
                        color: PopoutConfig.textColor
                        opacity: 0.7
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Restic.diffOutput = ""
                            root.diffFromId = ""
                            root.diffToId = ""
                        }
                    }
                }
            }

            Item {
                id: diffBody
                width: parent.width
                height: Math.min(diffText.implicitHeight + 12, root.maxDiffHeight)
                anchors.top: diffHeader.bottom

                ScrollView {
                    id: diffScroll
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    anchors.topMargin: 0
                    anchors.bottomMargin: 6
                    clip: true
                    visible: !Restic.diffing && Restic.diffOutput.length > 0

                    Text {
                        id: diffText
                        text: Restic.diffOutput
                        font.family: "monospace"
                        font.pixelSize: 10
                        color: PopoutConfig.textColor
                        opacity: 0.85
                        wrapMode: Text.NoWrap
                        renderType: Text.NativeRendering
                    }
                }

                Row {
                    anchors.centerIn: parent
                    visible: Restic.diffing
                    spacing: 6

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "sync"
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 13
                        color: Colors.primary
                        RotationAnimation on rotation {
                            running: Restic.diffing
                            loops: Animation.Infinite
                            from: 0; to: 360
                            duration: 900
                        }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Calculating diff…"
                        color: PopoutConfig.textColor
                        opacity: 0.7
                        font.pixelSize: 11
                        renderType: Text.NativeRendering
                    }
                }
            }
        }

        // ── Footer (refreshable) ──
        Rectangle {
            width: parent.width
            height: 24
            radius: 8
            color: footerHover.containsMouse && !Restic.checking ? Qt.rgba(1, 1, 1, 0.05) : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                text: { var _ = root._tick; return "Updated " + root.freshness() }
                visible: Restic.lastUpdated && Restic.lastUpdated.getTime() > 0
                color: PopoutConfig.textColor
                opacity: 0.45
                font.pixelSize: 11
                renderType: Text.NativeRendering
            }
            Text {
                anchors.right: parent.right
                anchors.rightMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                text: Restic.checking ? "Refreshing…" : "Click to refresh"
                color: Restic.checking ? Colors.primary : PopoutConfig.textColor
                opacity: Restic.checking ? 0.85 : 0.55
                font.pixelSize: 11
                font.weight: Restic.checking ? Font.DemiBold : Font.Medium
                renderType: Text.NativeRendering
            }

            MouseArea {
                id: footerHover
                anchors.fill: parent
                hoverEnabled: true
                enabled: !Restic.checking
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: Restic.refresh()
            }
        }
    }
}
