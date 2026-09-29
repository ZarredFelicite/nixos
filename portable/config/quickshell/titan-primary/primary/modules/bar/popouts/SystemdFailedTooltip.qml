import QtQuick
import QtQuick.Controls
import Quickshell.Widgets
import "../../../services"
import "./"

ClippingRectangle {
    id: root
    required property Item wrapper
    property bool expanded: wrapper && wrapper.hasCurrent && wrapper.currentName === "tooltip-systemd"
    property bool hasOwnBackground: true

    readonly property int hPadding: 16
    readonly property int vPadding: 14
    readonly property int contentWidth: 340
    readonly property int maxListHeight: 260
    readonly property color accent: Colors.foregroundRed

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

    function units() {
        if (!SystemdFailed.failedUnits || !SystemdFailed.failedUnits.trim()) return []
        return SystemdFailed.failedUnits.split("\n").filter(function(line) { return line.trim().length > 0 })
    }

    function unitName(line) {
        var trimmed = (line || "").trim()
        if (trimmed.indexOf("(user) ") === 0) {
            var userRest = trimmed.substring(7).trim()
            return userRest.split(/\s+/)[0] || userRest
        }
        return trimmed.split(/\s+/)[0] || trimmed
    }

    function unitScope(line) {
        return (line || "").trim().indexOf("(user) ") === 0 ? "USER" : "SYSTEM"
    }

    function unitDetail(line) {
        var trimmed = (line || "").trim()
        if (trimmed.indexOf("(user) ") === 0) trimmed = trimmed.substring(7).trim()
        var parts = trimmed.split(/\s+/)
        if (parts.length <= 4) return trimmed
        return parts.slice(4).join(" ")
    }

    function statusLabel() {
        return SystemdFailed.hasFailures ? (SystemdFailed.failedCount + " FAILED") : "HEALTHY"
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

        Item {
            width: parent.width
            height: 22

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Systemd"
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
                    color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.16)

                    Text {
                        id: badgeText
                        anchors.centerIn: parent
                        text: root.statusLabel()
                        color: root.accent
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
                color: SystemdFailed.hasFailures ? root.accent : Colors.todoPriorityLow
                opacity: 0.85
                SequentialAnimation on opacity {
                    running: SystemdFailed.hasFailures
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.30; duration: 600; easing.type: Easing.InOutQuad }
                    NumberAnimation { to: 0.85; duration: 600; easing.type: Easing.InOutQuad }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: summaryRow.implicitHeight + 14
            radius: 10
            color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.10)
            border.width: 1
            border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.30)

            Row {
                id: summaryRow
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "error"
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 18
                    color: root.accent
                    renderType: Text.NativeRendering
                }

                Column {
                    width: parent.width - 28
                    spacing: 2
                    Text {
                        width: parent.width
                        text: SystemdFailed.failedCount === 1 ? "1 failed unit needs attention" : SystemdFailed.failedCount + " failed units need attention"
                        color: PopoutConfig.textColor
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        renderType: Text.NativeRendering
                    }
                    Text {
                        width: parent.width
                        text: "Click the pill to refresh after fixing services."
                        color: Colors.outline
                        font.pixelSize: 10
                        elide: Text.ElideRight
                        renderType: Text.NativeRendering
                    }
                }
            }
        }

        ScrollView {
            width: parent.width
            height: Math.min(unitList.implicitHeight, root.maxListHeight)
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: unitList.implicitHeight > root.maxListHeight ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff

            Column {
                id: unitList
                width: parent.width
                spacing: 8

                Repeater {
                    model: root.units()

                    delegate: Rectangle {
                        required property string modelData
                        width: unitList.width
                        height: unitColumn.implicitHeight + 16
                        radius: 10
                        color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.07)
                        border.width: 1
                        border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.20)

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: 3
                            radius: 2
                            color: root.accent
                            opacity: 0.8
                        }

                        Column {
                            id: unitColumn
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 12
                            anchors.rightMargin: 10
                            spacing: 6

                            Row {
                                width: parent.width
                                spacing: 8

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "warning"
                                    font.family: "Material Symbols Outlined"
                                    font.pixelSize: 14
                                    color: root.accent
                                    renderType: Text.NativeRendering
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - scopeBadge.width - 36
                                    text: root.unitName(modelData)
                                    color: PopoutConfig.textColor
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                    renderType: Text.NativeRendering
                                }

                                Rectangle {
                                    id: scopeBadge
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: scopeText.implicitWidth + 10
                                    height: 16
                                    radius: 8
                                    color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.12)

                                    Text {
                                        id: scopeText
                                        anchors.centerIn: parent
                                        text: root.unitScope(modelData)
                                        color: Colors.primary
                                        font.pixelSize: 8
                                        font.weight: Font.DemiBold
                                        renderType: Text.NativeRendering
                                    }
                                }
                            }

                            Text {
                                width: parent.width
                                text: root.unitDetail(modelData)
                                color: Colors.outline
                                font.pixelSize: 10
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                                renderType: Text.NativeRendering
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: PopoutConfig.borderColor
            opacity: 0.7
        }

        Text {
            width: parent.width
            text: "systemctl --failed  •  systemctl --user --failed"
            color: Colors.outline
            font.pixelSize: 10
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            renderType: Text.NativeRendering
        }
    }
}
