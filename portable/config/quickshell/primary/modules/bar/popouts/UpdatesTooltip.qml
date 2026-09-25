import QtQuick
import QtQuick.Controls
import Quickshell.Widgets
import "../../../services"

ClippingRectangle {
    id: root
    required property Item wrapper

    property bool expanded: wrapper && wrapper.hasCurrent && wrapper.currentName === "tooltip-updates"
    property bool hasOwnBackground: true

    readonly property int hPadding: 16
    readonly property int vPadding: 14
    readonly property int contentWidth: 340
    readonly property int maxListHeight: 280

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

    // Live ticker for "Xm ago" footer.
    property int _tick: 0
    Timer {
        interval: 30000
        running: root.expanded
        repeat: true
        triggeredOnStart: true
        onTriggered: root._tick++
    }

    function statusColor() {
        if (Updates.nixosUpgradeServiceFailed) return Colors.foregroundRed
        if (Updates.checking) return Colors.primary
        if (Updates.rebootRequired) return Colors.todoPriorityMedium
        if (Updates.hasChanges) return Colors.foregroundCyan
        return Colors.success
    }

    function summaryText() {
        if (Updates.checking && !Updates.hasChanges && Updates.additionCount === 0 && Updates.removalCount === 0)
            return "Checking…"
        var total = Updates.upgradeCount + Updates.downgradeCount + Updates.additionCount + Updates.removalCount
        if (total === 0) return "Up to date"
        return total + (total === 1 ? " change" : " changes")
    }

    function freshness() {
        if (!Updates.lastUpdated || Updates.lastUpdated.getTime() === 0) return ""
        var seconds = Math.max(0, Math.floor((Date.now() - Updates.lastUpdated.getTime()) / 1000))
        if (seconds < 60) return "just now"
        var mins = Math.floor(seconds / 60)
        if (mins < 60) return mins + "m ago"
        var hours = Math.floor(mins / 60)
        if (hours < 24) return hours + "h ago"
        return Math.floor(hours / 24) + "d ago"
    }

    function condenseError(text) {
        if (!text) return ""
        var lines = text.split("\n")
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()
            if (line.length === 0) continue
            // Skip systemctl decoration lines
            if (line.indexOf("●") === 0) continue
            if (line.indexOf("Loaded:") === 0) continue
            if (line.indexOf("Active:") === 0) {
                // Active: failed (Result: exit-code) since … — keep the parenthesized cause
                var match = line.match(/Active:\s*(.+?)\s+since/)
                if (match) return match[1]
                return line.substring(8).trim()
            }
            return line
        }
        return text.substring(0, 80).trim()
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onEntered: if (root.wrapper && root.wrapper.closeTimer) root.wrapper.closeTimer.stop()
        onExited: if (root.wrapper && root.wrapper.closeTimer) root.wrapper.closeTimer.start()
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
                    text: "Updates"
                    color: PopoutConfig.textColor
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    renderType: Text.NativeRendering
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: summaryText.implicitWidth + 10
                    height: 16
                    radius: 8
                    color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.16)

                    Text {
                        id: summaryText
                        anchors.centerIn: parent
                        text: root.summaryText()
                        color: Colors.primary
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
                color: root.statusColor()
                opacity: 0.85
                SequentialAnimation on opacity {
                    running: Updates.checking
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.30; duration: 600; easing.type: Easing.InOutQuad }
                    NumberAnimation { to: 0.85; duration: 600; easing.type: Easing.InOutQuad }
                }
            }
        }

        // ── Reboot banner ──
        Rectangle {
            visible: Updates.rebootRequired
            width: parent.width
            height: 28
            radius: 8
            color: Qt.rgba(Colors.todoPriorityMedium.r, Colors.todoPriorityMedium.g, Colors.todoPriorityMedium.b, 0.14)
            border.width: 1
            border.color: Qt.rgba(Colors.todoPriorityMedium.r, Colors.todoPriorityMedium.g, Colors.todoPriorityMedium.b, 0.32)

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "restart_alt"
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 14
                    color: Colors.todoPriorityMedium
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Reboot recommended"
                    color: Colors.todoPriorityMedium
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    renderType: Text.NativeRendering
                }
            }
        }

        // ── Service-failed banner (click to re-summarize) ──
        Rectangle {
            id: failureBanner
            visible: Updates.nixosUpgradeServiceFailed
            width: parent.width
            height: errCol.implicitHeight + 12
            radius: 8
            color: failureHover.containsMouse
                   ? Qt.rgba(Colors.foregroundRed.r, Colors.foregroundRed.g, Colors.foregroundRed.b, 0.18)
                   : Qt.rgba(Colors.foregroundRed.r, Colors.foregroundRed.g, Colors.foregroundRed.b, 0.12)
            Behavior on color { ColorAnimation { duration: 120 } }
            border.width: 1
            border.color: Qt.rgba(Colors.foregroundRed.r, Colors.foregroundRed.g, Colors.foregroundRed.b, 0.32)

            MouseArea {
                id: failureHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Updates.forceResummarizeError()
            }

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
                        text: "nixos-upgrade.service failed"
                        color: Colors.foregroundRed
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        renderType: Text.NativeRendering
                    }
                }
                Text {
                    width: parent.width
                    text: Updates.nixosUpgradeErrorSummarizing
                          ? "Summarizing failure…"
                          : (Updates.nixosUpgradeErrorSummary.length > 0
                                ? Updates.nixosUpgradeErrorSummary
                                : root.condenseError(Updates.nixosUpgradeError))
                    color: Colors.foregroundRed
                    opacity: Updates.nixosUpgradeErrorSummarizing ? 0.55 : 0.82
                    font.pixelSize: 11
                    font.italic: Updates.nixosUpgradeErrorSummarizing
                    wrapMode: Text.WordWrap
                    renderType: Text.NativeRendering
                }
            }
        }

        // ── Count chips ──
        Row {
            visible: Updates.hasChanges || Updates.additionCount > 0 || Updates.removalCount > 0
            width: parent.width
            spacing: 6

            component CountChip: Rectangle {
                property string symbol: ""
                property int count: 0
                property color accent: Colors.primary

                visible: count > 0
                width: chipRow.implicitWidth + 14
                height: 22
                radius: 11
                color: Qt.rgba(accent.r, accent.g, accent.b, 0.14)
                border.width: 1
                border.color: Qt.rgba(accent.r, accent.g, accent.b, 0.30)

                Row {
                    id: chipRow
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: symbol
                        color: accent
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        renderType: Text.NativeRendering
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: count
                        color: accent
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        renderType: Text.NativeRendering
                    }
                }
            }

            CountChip { symbol: "↑"; count: Updates.upgradeCount;  accent: Colors.foregroundCyan }
            CountChip { symbol: "↓"; count: Updates.downgradeCount; accent: Colors.todoPriorityMedium }
            CountChip { symbol: "+"; count: Updates.additionCount;  accent: Colors.success }
            CountChip { symbol: "−"; count: Updates.removalCount;   accent: Colors.foregroundRed }
        }

        // ── Empty state ──
        Item {
            visible: !Updates.hasChanges && Updates.additionCount === 0 && Updates.removalCount === 0
                     && !Updates.nixosUpgradeServiceFailed
            width: parent.width
            height: 36

            Row {
                anchors.centerIn: parent
                spacing: 6

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Updates.checking ? "sync" : "check_circle"
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 14
                    color: Updates.checking ? Colors.primary : Colors.success
                    opacity: 0.85

                    RotationAnimation on rotation {
                        running: Updates.checking
                        loops: Animation.Infinite
                        from: 0; to: 360
                        duration: 900
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Updates.checking ? "Checking for updates…" : "System is up to date"
                    color: PopoutConfig.textColor
                    opacity: 0.65
                    font.pixelSize: 12
                    renderType: Text.NativeRendering
                }
            }
        }

        // ── Scrollable package list ──
        ScrollView {
            id: scroll
            visible: Updates.hasChanges || Updates.additionCount > 0 || Updates.removalCount > 0
            width: parent.width
            implicitHeight: Math.min(packageColumn.implicitHeight, root.maxListHeight)
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            Column {
                id: packageColumn
                width: scroll.availableWidth
                spacing: 10

                component Section: Column {
                    property string title: ""
                    property color accent: Colors.primary
                    property var items: []
                    property bool useFromTo: true   // true: {from,to}; false: {version}

                    visible: items.length > 0
                    width: parent.width
                    spacing: 3

                    Text {
                        text: title.toUpperCase()
                        color: accent
                        opacity: 0.85
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        renderType: Text.NativeRendering
                    }

                    Repeater {
                        model: items
                        delegate: Item {
                            required property var modelData
                            width: parent.width
                            height: 18

                            Row {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4
                                width: parent.width * 0.55

                                Text {
                                    visible: modelData.star === true
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "★"
                                    color: Colors.primary
                                    font.pixelSize: 9
                                    renderType: Text.NativeRendering
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.name || ""
                                    color: modelData.star === true ? Colors.primary : PopoutConfig.textColor
                                    opacity: modelData.star === true ? 1.0 : 0.85
                                    font.pixelSize: 12
                                    font.weight: modelData.star === true ? Font.DemiBold : Font.Normal
                                    elide: Text.ElideRight
                                    width: parent.width - (modelData.star === true ? 12 : 0)
                                    renderType: Text.NativeRendering
                                }
                            }

                            Text {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width * 0.42
                                text: useFromTo
                                      ? ((modelData.from || "?") + "  →  " + (modelData.to || "?"))
                                      : (modelData.version || "")
                                color: PopoutConfig.textColor
                                opacity: 0.55
                                font.pixelSize: 10
                                font.family: "monospace"
                                horizontalAlignment: Text.AlignRight
                                elide: Text.ElideLeft
                                renderType: Text.NativeRendering
                            }
                        }
                    }
                }

                Section {
                    title: "Upgrades"
                    accent: Colors.foregroundCyan
                    items: Updates.upgradedPackages
                    useFromTo: true
                }
                Section {
                    title: "Downgrades"
                    accent: Colors.todoPriorityMedium
                    items: Updates.downgradedPackages
                    useFromTo: true
                }
                Section {
                    title: "Additions"
                    accent: Colors.success
                    items: Updates.addedPackages
                    useFromTo: false
                }
                Section {
                    title: "Removals"
                    accent: Colors.foregroundRed
                    items: Updates.removedPackages
                    useFromTo: false
                }
            }
        }

        // ── Footer (refreshable) ──
        Rectangle {
            width: parent.width
            height: 24
            radius: 8
            color: footerHover.containsMouse && !Updates.checking ? Qt.rgba(1, 1, 1, 0.05) : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                text: { var _ = root._tick; return "Updated " + root.freshness() }
                visible: Updates.lastUpdated && Updates.lastUpdated.getTime() > 0
                color: PopoutConfig.textColor
                opacity: 0.45
                font.pixelSize: 11
                renderType: Text.NativeRendering
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                text: Updates.checking ? "Refreshing…" : "Click to refresh"
                color: Updates.checking ? Colors.primary : PopoutConfig.textColor
                opacity: Updates.checking ? 0.85 : 0.55
                font.pixelSize: 11
                font.weight: Updates.checking ? Font.DemiBold : Font.Medium
                renderType: Text.NativeRendering
            }

            MouseArea {
                id: footerHover
                anchors.fill: parent
                hoverEnabled: true
                enabled: !Updates.checking
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: Updates.refresh()
            }
        }
    }
}
