import QtQuick
import QtQuick.Controls
import Quickshell.Widgets
import "../../../services"
import "./"

ClippingRectangle {
    id: root
    required property Item wrapper
    property bool expanded: wrapper && wrapper.hasCurrent && wrapper.currentName === "bluetooth"
    property bool hasOwnBackground: true

    readonly property int hPadding: 16
    readonly property int vPadding: 14
    readonly property int contentWidth: 320
    readonly property int maxListHeight: 240

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

    // Live ticker for "ago" footer
    property int _tick: 0
    Timer {
        interval: 30000
        running: root.expanded
        repeat: true
        triggeredOnStart: true
        onTriggered: root._tick++
    }

    readonly property var connectedDevices: Bluetooth.devices.filter(function (d) { return d.connected })
    readonly property int pairedCount: Bluetooth.devices.filter(function (d) { return d.paired }).length

    function statusBadge() {
        if (!Bluetooth.powered) return "Off"
        if (Bluetooth.scanning) return "Scanning"
        var n = root.connectedDevices.length
        if (n === 0) return "Idle"
        return n + (n === 1 ? " connected" : " connected")
    }

    function statusAccent() {
        if (!Bluetooth.powered) return Colors.todoDateNoDue
        if (Bluetooth.scanning) return Colors.todoDateDue
        if (root.connectedDevices.length > 0) return Colors.todoPriorityLow
        return Colors.primary
    }

    function batteryColor(pct) {
        if (pct < 0) return Colors.todoDateNoDue
        if (pct < 20) return Colors.foregroundRed
        if (pct < 50) return Colors.todoPriorityMedium
        return Colors.todoPriorityLow
    }

    // Match common bluez Icon: hints first, then keywords in the device name.
    function deviceIcon(d) {
        if (!d) return "bluetooth"
        var icon = (d.icon || "").toLowerCase()
        var name = (d.name || "").toLowerCase()
        if (icon.indexOf("audio-headphones") >= 0 || /headphone|airpods|wh-|bose|sony|jbl/.test(name)) return "headphones"
        if (icon.indexOf("audio-headset") >= 0 || /headset/.test(name)) return "headset_mic"
        if (icon.indexOf("audio-card") >= 0 || /speaker|soundbar|jbl|charge/.test(name)) return "speaker"
        if (/earbud|ear \(|ear pro|buds/.test(name) || icon.indexOf("audio-earbuds") >= 0) return "earbuds"
        if (icon.indexOf("input-mouse") >= 0 || /mouse|trackpad/.test(name)) return "mouse"
        if (icon.indexOf("input-keyboard") >= 0 || /keyboard/.test(name)) return "keyboard"
        if (icon.indexOf("input-gaming") >= 0 || /controller|gamepad|joycon|xbox|dualshock/.test(name)) return "stadia_controller"
        if (icon.indexOf("phone") >= 0 || /phone|pixel|iphone|galaxy/.test(name)) return "smartphone"
        if (icon.indexOf("computer") >= 0 || /laptop|macbook|thinkpad/.test(name)) return "laptop_mac"
        if (icon.indexOf("watch") >= 0 || /watch/.test(name)) return "watch"
        return "bluetooth"
    }

    function freshness() {
        if (Bluetooth.scanning) return "scanning…"
        if (!Bluetooth.lastUpdated || Bluetooth.lastUpdated.getTime() === 0) return ""
        var s = Math.max(0, Math.floor((Date.now() - Bluetooth.lastUpdated.getTime()) / 1000))
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
                    text: "Bluetooth"
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
                    running: Bluetooth.scanning
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.30; duration: 600; easing.type: Easing.InOutQuad }
                    NumberAnimation { to: 0.85; duration: 600; easing.type: Easing.InOutQuad }
                }
            }
        }

        // ── Powered-off banner ──
        Rectangle {
            visible: !Bluetooth.powered
            width: parent.width
            height: 28
            radius: 8
            color: Qt.rgba(Colors.todoDateNoDue.r, Colors.todoDateNoDue.g, Colors.todoDateNoDue.b, 0.18)
            border.width: 1
            border.color: Qt.rgba(Colors.todoDateNoDue.r, Colors.todoDateNoDue.g, Colors.todoDateNoDue.b, 0.32)

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "bluetooth_disabled"
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 14
                    color: Colors.todoDateNoDue
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Bluetooth is off"
                    color: Colors.todoDateNoDue
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    renderType: Text.NativeRendering
                }
            }
        }

        // ── Error banner ──
        Rectangle {
            visible: Bluetooth.error.length > 0 && Bluetooth.powered
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
                text: Bluetooth.error
                color: Colors.foregroundRed
                font.pixelSize: 11
                opacity: 0.85
                elide: Text.ElideRight
                width: parent.width - 20
                renderType: Text.NativeRendering
            }
        }

        // ── Empty state ──
        Item {
            visible: Bluetooth.powered && root.connectedDevices.length === 0
            width: parent.width
            height: 36

            Row {
                anchors.centerIn: parent
                spacing: 6

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Bluetooth.scanning ? "bluetooth_searching" : "bluetooth"
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 14
                    color: Bluetooth.scanning ? Colors.todoDateDue : PopoutConfig.textColor
                    opacity: 0.7

                    SequentialAnimation on opacity {
                        running: Bluetooth.scanning
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.30; duration: 600; easing.type: Easing.InOutQuad }
                        NumberAnimation { to: 0.85; duration: 600; easing.type: Easing.InOutQuad }
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Bluetooth.scanning ? "Scanning for devices…" : "No devices connected"
                    color: PopoutConfig.textColor
                    opacity: 0.65
                    font.pixelSize: 12
                    renderType: Text.NativeRendering
                }
            }
        }

        // ── Connected devices section ──
        Item {
            visible: Bluetooth.powered && root.connectedDevices.length > 0
            width: parent.width
            height: 14

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "CONNECTED"
                color: Colors.primary
                opacity: 0.85
                font.pixelSize: 10
                font.weight: Font.Bold
                renderType: Text.NativeRendering
            }
            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: root.connectedDevices.length === 1 ? "1 device" : root.connectedDevices.length + " devices"
                color: PopoutConfig.textColor
                opacity: 0.45
                font.pixelSize: 10
                renderType: Text.NativeRendering
            }
        }

        ScrollView {
            id: deviceScroll
            visible: Bluetooth.powered && root.connectedDevices.length > 0
            width: parent.width
            implicitHeight: Math.min(deviceColumn.implicitHeight, root.maxListHeight)
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            Column {
                id: deviceColumn
                width: deviceScroll.availableWidth
                spacing: 6

                Repeater {
                    model: root.connectedDevices
                    delegate: Rectangle {
                        id: deviceItem
                        required property var modelData
                        readonly property bool hasBattery: modelData.battery >= 0
                        readonly property color battColor: root.batteryColor(modelData.battery)

                        width: deviceColumn.width
                        height: hasBattery ? 50 : 36
                        radius: 10
                        color: deviceMouse.containsMouse
                            ? Qt.rgba(1, 1, 1, 0.06)
                            : Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.06)
                        Behavior on color { ColorAnimation { duration: 120 } }
                        border.width: 1
                        border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.18)

                        MouseArea {
                            id: deviceMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: function (mouse) {
                                if (mouse.button === Qt.RightButton) {
                                    Bluetooth.disconnect(deviceItem.modelData.mac)
                                }
                            }
                        }

                        Item {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            anchors.topMargin: 6
                            anchors.bottomMargin: 6

                            // Top row: icon + name + battery %
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
                                    width: parent.width - (deviceItem.hasBattery ? battPctText.implicitWidth + 8 : 0)

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: root.deviceIcon(deviceItem.modelData)
                                        font.family: "Material Symbols Outlined"
                                        font.pixelSize: 14
                                        color: Colors.primary
                                        opacity: 0.9
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: deviceItem.modelData.name || "Unknown"
                                        color: PopoutConfig.textColor
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                        width: Math.max(0, parent.width - 22)
                                        renderType: Text.NativeRendering
                                    }
                                }

                                Text {
                                    id: battPctText
                                    visible: deviceItem.hasBattery
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: deviceItem.modelData.battery + "%"
                                    color: deviceItem.battColor
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    renderType: Text.NativeRendering
                                }
                            }

                            // Battery bar
                            Rectangle {
                                visible: deviceItem.hasBattery
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 4
                                height: 5
                                radius: 2.5
                                color: Qt.rgba(1, 1, 1, 0.07)

                                Rectangle {
                                    width: parent.width * Math.max(0, Math.min(1, deviceItem.modelData.battery / 100))
                                    height: parent.height
                                    radius: parent.radius
                                    color: deviceItem.battColor
                                    Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                                }
                            }

                            // Subtitle (no battery): MAC + signal
                            Text {
                                visible: !deviceItem.hasBattery
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                text: {
                                    var bits = []
                                    if (deviceItem.modelData.rssi !== 0) bits.push(deviceItem.modelData.rssi + " dBm")
                                    if (deviceItem.modelData.trusted) bits.push("trusted")
                                    bits.push(deviceItem.modelData.mac)
                                    return bits.join(" · ")
                                }
                                color: PopoutConfig.textColor
                                opacity: 0.45
                                font.pixelSize: 10
                                font.family: "monospace"
                                elide: Text.ElideRight
                                renderType: Text.NativeRendering
                            }
                        }
                    }
                }
            }
        }

        // ── Footer ──
        Rectangle {
            width: parent.width
            height: 24
            radius: 8
            color: footerHover.containsMouse && !Bluetooth.scanning ? Qt.rgba(1, 1, 1, 0.05) : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.pairedCount + " paired"
                    color: PopoutConfig.textColor
                    opacity: 0.45
                    font.pixelSize: 11
                    renderType: Text.NativeRendering
                }
                Text {
                    visible: Bluetooth.lastUpdated && Bluetooth.lastUpdated.getTime() > 0
                    anchors.verticalCenter: parent.verticalCenter
                    text: { var _ = root._tick; return "· " + root.freshness() }
                    color: PopoutConfig.textColor
                    opacity: 0.40
                    font.pixelSize: 11
                    renderType: Text.NativeRendering
                }
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                text: Bluetooth.scanning ? "Scanning…" : "Click to scan"
                color: Bluetooth.scanning ? Colors.todoDateDue : PopoutConfig.textColor
                opacity: Bluetooth.scanning ? 0.85 : 0.55
                font.pixelSize: 11
                font.weight: Bluetooth.scanning ? Font.DemiBold : Font.Medium
                renderType: Text.NativeRendering
            }

            MouseArea {
                id: footerHover
                anchors.fill: parent
                hoverEnabled: true
                enabled: !Bluetooth.scanning && Bluetooth.powered
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: Bluetooth.scan()
            }
        }
    }
}
