import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../../services"
import "./"

Rectangle {
    id: root

    property bool hasOwnBackground: true
    property var wrapper: null

    implicitWidth: 360
    implicitHeight: 560

    color: PopoutConfig.backgroundColor
    radius: PopoutConfig.cornerRadius
    border.width: PopoutConfig.borderWidth
    border.color: PopoutConfig.borderColor

    Component.onCompleted: Bluetooth.scan()

    // ── Helpers ──
    readonly property var connectedDevices: Bluetooth.devices.filter(function (d) { return d.connected })
    readonly property var availableDevices: {
        var unconnected = Bluetooth.devices.filter(function (d) { return !d.connected })
        unconnected.sort(function (a, b) { return b.rssi - a.rssi })
        return unconnected
    }

    function statusBadge() {
        if (!Bluetooth.powered) return "Off"
        if (Bluetooth.scanning) return "Scanning"
        var n = root.connectedDevices.length
        if (n === 0) return "Idle"
        return n + " connected"
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

    function deviceIcon(d) {
        if (!d) return "bluetooth"
        var icon = (d.icon || "").toLowerCase()
        var name = (d.name || "").toLowerCase()
        if (icon.indexOf("audio-headphones") >= 0 || /headphone|airpods|wh-|bose|sony|jbl/.test(name)) return "headphones"
        if (icon.indexOf("audio-headset") >= 0 || /headset/.test(name)) return "headset_mic"
        if (icon.indexOf("audio-card") >= 0 || /speaker|soundbar|charge/.test(name)) return "speaker"
        if (/earbud|ear \(|ear pro|buds/.test(name) || icon.indexOf("audio-earbuds") >= 0) return "earbuds"
        if (icon.indexOf("input-mouse") >= 0 || /mouse|trackpad/.test(name)) return "mouse"
        if (icon.indexOf("input-keyboard") >= 0 || /keyboard/.test(name)) return "keyboard"
        if (icon.indexOf("input-gaming") >= 0 || /controller|gamepad|joycon|xbox|dualshock/.test(name)) return "stadia_controller"
        if (icon.indexOf("phone") >= 0 || /phone|pixel|iphone|galaxy/.test(name)) return "smartphone"
        if (icon.indexOf("computer") >= 0 || /laptop|macbook|thinkpad/.test(name)) return "laptop_mac"
        if (icon.indexOf("watch") >= 0 || /watch/.test(name)) return "watch"
        return "bluetooth"
    }

    function signalLabel(rssi) {
        if (!rssi || rssi === 0) return ""
        if (rssi >= -55) return "strong"
        if (rssi >= -70) return "good"
        if (rssi >= -85) return "fair"
        return "weak"
    }

    function signalAccent(rssi) {
        if (rssi >= -55) return Colors.todoPriorityLow
        if (rssi >= -70) return Colors.todoDateDue
        if (rssi >= -85) return Colors.todoPriorityMedium
        return Colors.foregroundRed
    }

    // ── Reusable: icon button (power/refresh) ──
    component IconButton: Rectangle {
        id: btn
        property string symbol: ""
        property color tint: PopoutConfig.textColor
        property real tintOpacity: 1.0
        property bool spinning: false
        signal triggered

        width: 28
        height: 28
        radius: 8
        color: btnHover.containsMouse ? Qt.rgba(1, 1, 1, 0.07) : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }

        Text {
            id: btnIcon
            anchors.centerIn: parent
            text: btn.symbol
            font.family: "Material Symbols Outlined"
            font.pixelSize: 17
            color: btn.tint
            opacity: btn.tintOpacity

            RotationAnimation on rotation {
                running: btn.spinning
                loops: Animation.Infinite
                from: 0; to: 360
                duration: 900
            }
        }

        MouseArea {
            id: btnHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.triggered()
        }
    }

    // ── Reusable: chip (paired/trusted/signal) ──
    component MetaChip: Rectangle {
        property string label: ""
        property color accent: Colors.primary

        visible: label.length > 0
        width: chipText.implicitWidth + 10
        height: 14
        radius: 7
        color: Qt.rgba(accent.r, accent.g, accent.b, 0.14)

        Text {
            id: chipText
            anchors.centerIn: parent
            text: parent.label.toUpperCase()
            color: parent.accent
            font.pixelSize: 8
            font.weight: Font.Bold
            renderType: Text.NativeRendering
        }
    }

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // ── Header ──
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 28

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Bluetooth"
                    color: PopoutConfig.textColor
                    font.pixelSize: 16
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

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                IconButton {
                    symbol: Bluetooth.powered ? "bluetooth" : "bluetooth_disabled"
                    tint: Bluetooth.powered ? Colors.todoPriorityLow : Colors.todoDateNoDue
                    onTriggered: Bluetooth.toggleBluetooth()
                }
                IconButton {
                    symbol: "refresh"
                    tint: Colors.primary
                    spinning: Bluetooth.scanning
                    onTriggered: Bluetooth.scan()
                }
            }
        }

        // ── Off banner ──
        Rectangle {
            visible: !Bluetooth.powered
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            radius: 8
            color: Qt.rgba(Colors.todoDateNoDue.r, Colors.todoDateNoDue.g, Colors.todoDateNoDue.b, 0.18)
            border.width: 1
            border.color: Qt.rgba(Colors.todoDateNoDue.r, Colors.todoDateNoDue.g, Colors.todoDateNoDue.b, 0.32)

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "bluetooth_disabled"
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 16
                    color: Colors.todoDateNoDue
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Bluetooth is off — tap the icon to enable"
                    color: Colors.todoDateNoDue
                    font.pixelSize: 12
                    renderType: Text.NativeRendering
                }
            }
        }

        // ── Error banner ──
        Rectangle {
            visible: Bluetooth.error.length > 0 && Bluetooth.powered
            Layout.fillWidth: true
            Layout.preferredHeight: 28
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

        // ── Connected section header ──
        Item {
            visible: Bluetooth.powered && root.connectedDevices.length > 0
            Layout.fillWidth: true
            Layout.preferredHeight: 14

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

        // ── Connected device cards ──
        ColumnLayout {
            id: connectedColumn
            visible: Bluetooth.powered && root.connectedDevices.length > 0
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: root.connectedDevices
                delegate: Rectangle {
                    id: connItem
                    required property var modelData
                    readonly property bool hasBattery: modelData.battery >= 0
                    readonly property color battColor: root.batteryColor(modelData.battery)

                    Layout.fillWidth: true
                    Layout.preferredHeight: hasBattery ? 64 : 50
                    radius: 10
                    color: connHover.containsMouse
                        ? Qt.rgba(1, 1, 1, 0.06)
                        : Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.06)
                    Behavior on color { ColorAnimation { duration: 120 } }
                    border.width: 1
                    border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.18)

                    MouseArea {
                        id: connHover
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                    }

                    Item {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 8
                        anchors.topMargin: 8
                        anchors.bottomMargin: 8

                        Item {
                            id: connTopRow
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            height: 18

                            Row {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 8
                                width: parent.width - disconnectBtn.width - (connItem.hasBattery ? connBattPct.implicitWidth + 8 : 0) - 12

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.deviceIcon(connItem.modelData)
                                    font.family: "Material Symbols Outlined"
                                    font.pixelSize: 16
                                    color: Colors.primary
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: connItem.modelData.name || "Unknown"
                                    color: PopoutConfig.textColor
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                    width: Math.max(0, parent.width - 24)
                                    renderType: Text.NativeRendering
                                }
                            }

                            Text {
                                id: connBattPct
                                visible: connItem.hasBattery
                                anchors.right: disconnectBtn.left
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                text: connItem.modelData.battery + "%"
                                color: connItem.battColor
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                renderType: Text.NativeRendering
                            }

                            Rectangle {
                                id: disconnectBtn
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: discText.implicitWidth + 16
                                height: 18
                                radius: 9
                                color: discMouse.containsMouse
                                    ? Qt.rgba(Colors.foregroundRed.r, Colors.foregroundRed.g, Colors.foregroundRed.b, 0.28)
                                    : Qt.rgba(Colors.foregroundRed.r, Colors.foregroundRed.g, Colors.foregroundRed.b, 0.16)
                                Behavior on color { ColorAnimation { duration: 120 } }
                                border.width: 1
                                border.color: Qt.rgba(Colors.foregroundRed.r, Colors.foregroundRed.g, Colors.foregroundRed.b, 0.36)

                                Text {
                                    id: discText
                                    anchors.centerIn: parent
                                    text: "DISCONNECT"
                                    color: Colors.foregroundRed
                                    font.pixelSize: 9
                                    font.weight: Font.Bold
                                    renderType: Text.NativeRendering
                                }

                                MouseArea {
                                    id: discMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Bluetooth.disconnect(connItem.modelData.mac)
                                }
                            }
                        }

                        // Battery bar (when present)
                        Rectangle {
                            visible: connItem.hasBattery
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: connSubLine.top
                            anchors.bottomMargin: 4
                            anchors.rightMargin: 0
                            height: 5
                            radius: 2.5
                            color: Qt.rgba(1, 1, 1, 0.07)

                            Rectangle {
                                width: parent.width * Math.max(0, Math.min(1, connItem.modelData.battery / 100))
                                height: parent.height
                                radius: parent.radius
                                color: connItem.battColor
                                Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                            }
                        }

                        Row {
                            id: connSubLine
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            spacing: 6

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: connItem.modelData.mac
                                color: PopoutConfig.textColor
                                opacity: 0.45
                                font.pixelSize: 10
                                font.family: "monospace"
                                renderType: Text.NativeRendering
                            }
                            MetaChip {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: connItem.modelData.paired
                                label: "paired"
                                accent: Colors.todoPriorityLow
                            }
                            MetaChip {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: connItem.modelData.trusted
                                label: "trusted"
                                accent: Colors.todoDateDue
                            }
                        }
                    }
                }
            }
        }

        // ── Available section header ──
        Item {
            visible: Bluetooth.powered && root.availableDevices.length > 0
            Layout.fillWidth: true
            Layout.preferredHeight: 14

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "AVAILABLE"
                color: Colors.primary
                opacity: 0.85
                font.pixelSize: 10
                font.weight: Font.Bold
                renderType: Text.NativeRendering
            }
            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "by signal"
                color: PopoutConfig.textColor
                opacity: 0.45
                font.pixelSize: 10
                renderType: Text.NativeRendering
            }
        }

        // ── Available devices (scrollable) ──
        ScrollView {
            id: availScroll
            visible: Bluetooth.powered && root.availableDevices.length > 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            Column {
                id: availColumn
                width: availScroll.availableWidth
                spacing: 4

                Repeater {
                    model: root.availableDevices
                    delegate: Rectangle {
                        id: availItem
                        required property var modelData

                        width: availColumn.width
                        height: 50
                        radius: 10
                        color: availHover.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }

                        MouseArea {
                            id: availHover
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.NoButton
                        }

                        Item {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 8
                            anchors.topMargin: 6
                            anchors.bottomMargin: 6

                            // Top: icon + name + action button
                            Item {
                                id: availTop
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                height: 20

                                Row {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 8
                                    width: parent.width - actionBtn.width - 8

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: root.deviceIcon(availItem.modelData)
                                        font.family: "Material Symbols Outlined"
                                        font.pixelSize: 15
                                        color: PopoutConfig.textColor
                                        opacity: 0.65
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: availItem.modelData.name || "Unknown"
                                        color: PopoutConfig.textColor
                                        opacity: 0.92
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                        width: Math.max(0, parent.width - 22)
                                        renderType: Text.NativeRendering
                                    }
                                }

                                Rectangle {
                                    id: actionBtn
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: actionText.implicitWidth + 16
                                    height: 18
                                    radius: 9

                                    readonly property bool isPair: !availItem.modelData.paired
                                    readonly property color actionAccent: isPair ? Colors.todoDateDue : Colors.todoPriorityLow

                                    color: actionMouse.containsMouse
                                        ? Qt.rgba(actionAccent.r, actionAccent.g, actionAccent.b, 0.30)
                                        : Qt.rgba(actionAccent.r, actionAccent.g, actionAccent.b, 0.16)
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                    border.width: 1
                                    border.color: Qt.rgba(actionAccent.r, actionAccent.g, actionAccent.b, 0.36)

                                    Text {
                                        id: actionText
                                        anchors.centerIn: parent
                                        text: actionBtn.isPair ? "PAIR" : "CONNECT"
                                        color: actionBtn.actionAccent
                                        font.pixelSize: 9
                                        font.weight: Font.Bold
                                        renderType: Text.NativeRendering
                                    }

                                    MouseArea {
                                        id: actionMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (actionBtn.isPair) Bluetooth.pair(availItem.modelData.mac)
                                            else Bluetooth.connect(availItem.modelData.mac)
                                        }
                                    }
                                }
                            }

                            Row {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                spacing: 6

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: availItem.modelData.mac
                                    color: PopoutConfig.textColor
                                    opacity: 0.42
                                    font.pixelSize: 10
                                    font.family: "monospace"
                                    renderType: Text.NativeRendering
                                }
                                MetaChip {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: availItem.modelData.rssi !== 0
                                    label: root.signalLabel(availItem.modelData.rssi)
                                    accent: root.signalAccent(availItem.modelData.rssi)
                                }
                                MetaChip {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: availItem.modelData.paired
                                    label: "paired"
                                    accent: Colors.todoPriorityLow
                                }
                                MetaChip {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: availItem.modelData.trusted
                                    label: "trusted"
                                    accent: Colors.todoDateDue
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── Empty / loading states ──
        Item {
            visible: Bluetooth.powered && root.connectedDevices.length === 0 && root.availableDevices.length === 0
            Layout.fillWidth: true
            Layout.fillHeight: true

            Column {
                anchors.centerIn: parent
                spacing: 8

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Bluetooth.scanning ? "bluetooth_searching" : "bluetooth"
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 32
                    color: Bluetooth.scanning ? Colors.todoDateDue : PopoutConfig.textColor
                    opacity: 0.5
                    SequentialAnimation on opacity {
                        running: Bluetooth.scanning
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.20; duration: 700; easing.type: Easing.InOutQuad }
                        NumberAnimation { to: 0.55; duration: 700; easing.type: Easing.InOutQuad }
                    }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Bluetooth.scanning ? "Scanning for nearby devices…" : "No devices found"
                    color: PopoutConfig.textColor
                    opacity: 0.6
                    font.pixelSize: 12
                    renderType: Text.NativeRendering
                }
            }
        }

        // Spacer when there's content but no available list to fill
        Item {
            visible: Bluetooth.powered
                     && root.connectedDevices.length > 0
                     && root.availableDevices.length === 0
                     && !Bluetooth.scanning
            Layout.fillWidth: true
            Layout.fillHeight: true

            Text {
                anchors.centerIn: parent
                text: "No nearby devices"
                color: PopoutConfig.textColor
                opacity: 0.45
                font.pixelSize: 11
                renderType: Text.NativeRendering
            }
        }
    }
}
