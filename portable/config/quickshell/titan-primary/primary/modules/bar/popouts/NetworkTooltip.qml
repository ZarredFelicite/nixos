import QtQuick
import Quickshell.Widgets
import "../../../services"

ClippingRectangle {
    id: root
    required property Item wrapper

    property bool expanded: wrapper && wrapper.hasCurrent && wrapper.currentName === "network"
    property bool hasOwnBackground: true

    readonly property int hPadding: 16
    readonly property int vPadding: 14
    readonly property int contentWidth: 280

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

    readonly property bool isWired: Network.iface.startsWith("en") || Network.iface.startsWith("eth")
    readonly property bool isWifi: Network.connected && !isWired

    function statusColor() {
        if (!Network.connected) return Colors.foregroundRed
        if (!Network.internetAccess) return Colors.todoPriorityMedium
        return Colors.success
    }

    function connectionTitle() {
        if (!Network.connected) return "Disconnected"
        if (root.isWired) return "Wired"
        return Network.ssid && Network.ssid.length ? Network.ssid : "Wi-Fi"
    }

    function connectionIcon() {
        if (!Network.connected) return "wifi_off"
        if (root.isWired) return "settings_ethernet"
        return "wifi"
    }

    function connectionSubtitle() {
        if (!Network.connected) return "No active interface"
        if (!Network.internetAccess) return "Link only · no internet"
        return Network.iface
    }

    function signalAccent() {
        if (Network.signalPercent < 35) return Colors.foregroundRed
        if (Network.signalPercent < 60) return Colors.todoPriorityMedium
        return Colors.foregroundCyan
    }

    function fmtMbps(v) {
        if (v >= 100) return v.toFixed(0)
        if (v >= 10) return v.toFixed(1)
        return v.toFixed(2)
    }

    function detailStrip() {
        if (!Network.connected) return ""
        var parts = []
        if (root.isWifi) {
            if (Network.frequencyMhz > 0) {
                var ghz = Network.frequencyMhz / 1000
                parts.push((ghz >= 5 ? ghz.toFixed(0) : ghz.toFixed(1)) + " GHz")
            }
            if (Network.security && Network.security.length) parts.push(Network.security)
            if (Network.txRate && Network.txRate.length) parts.push("TX " + Network.txRate)
        } else if (Network.txRate && Network.txRate.length) {
            parts.push("TX " + Network.txRate)
        }
        return parts.join(" · ")
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

        // ── Header: icon + title/subtitle + status dot ──
        Item {
            width: parent.width
            height: 32

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.connectionIcon()
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 22
                    color: root.statusColor()
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1

                    Text {
                        text: root.connectionTitle()
                        color: PopoutConfig.textColor
                        font.pixelSize: 14
                        font.weight: Font.Bold
                        renderType: Text.NativeRendering
                        elide: Text.ElideRight
                        width: 200
                    }

                    Text {
                        text: root.connectionSubtitle()
                        color: PopoutConfig.textColor
                        opacity: 0.55
                        font.pixelSize: 11
                        renderType: Text.NativeRendering
                        elide: Text.ElideRight
                        width: 200
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
            }
        }

        // ── Signal bar (Wi-Fi only) ──
        Column {
            visible: root.isWifi
            width: parent.width
            spacing: 5

            Item {
                width: parent.width
                height: 14

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Signal"
                    color: PopoutConfig.textColor
                    opacity: 0.6
                    font.pixelSize: 11
                    renderType: Text.NativeRendering
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: Network.signalPercent + "%  ·  " + Network.rssiDbm + " dBm"
                    color: PopoutConfig.textColor
                    opacity: 0.85
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    renderType: Text.NativeRendering
                }
            }

            Rectangle {
                width: parent.width
                height: 4
                radius: 2
                color: Qt.rgba(1, 1, 1, 0.07)

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, Network.signalPercent / 100))
                    height: parent.height
                    radius: parent.radius
                    color: root.signalAccent()
                    Behavior on width { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                }
            }
        }

        // ── Throughput: down + up ──
        Row {
            visible: Network.connected
            width: parent.width
            spacing: 10

            component RatePane: Column {
                property string arrow: "↓"
                property color accent: Colors.foregroundCyan
                property string label: "Download"
                property real mbps: 0
                property real fillFraction: 0

                spacing: 5
                width: (mainColumn.width - 10) / 2

                Item {
                    width: parent.width
                    height: 16

                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: arrow
                            color: accent
                            font.pixelSize: 13
                            font.weight: Font.Bold
                            renderType: Text.NativeRendering
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.fmtMbps(mbps)
                            color: PopoutConfig.textColor
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            renderType: Text.NativeRendering
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Mbps"
                            color: PopoutConfig.textColor
                            opacity: 0.5
                            font.pixelSize: 10
                            renderType: Text.NativeRendering
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 4
                    radius: 2
                    color: Qt.rgba(1, 1, 1, 0.07)

                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(1, fillFraction))
                        height: parent.height
                        radius: parent.radius
                        color: accent
                        Behavior on width { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                    }
                }

                Text {
                    text: label
                    color: PopoutConfig.textColor
                    opacity: 0.45
                    font.pixelSize: 9
                    renderType: Text.NativeRendering
                }
            }

            RatePane {
                arrow: "↓"
                accent: Colors.foregroundCyan
                label: "Download"
                mbps: Network.downMbps
                fillFraction: Network.downPercent
            }

            RatePane {
                arrow: "↑"
                accent: Colors.primary
                label: "Upload"
                mbps: Network.upMbps
                fillFraction: Network.upPercent
            }
        }

        // ── Detail strip (frequency · security · TX rate) ──
        Text {
            visible: text.length > 0
            width: parent.width
            text: root.detailStrip()
            color: PopoutConfig.textColor
            opacity: 0.55
            font.pixelSize: 11
            elide: Text.ElideRight
            renderType: Text.NativeRendering
        }

        // ── VPN row ──
        Rectangle {
            width: parent.width
            height: 32
            radius: 8
            color: ProtonVpn.busy ? Qt.rgba(1, 1, 1, 0.05)
                  : (ProtonVpn.active
                      ? Qt.rgba(Colors.success.r, Colors.success.g, Colors.success.b, 0.16)
                      : Qt.rgba(1, 1, 1, 0.045))
            border.width: 1
            border.color: ProtonVpn.active
                          ? Qt.rgba(Colors.success.r, Colors.success.g, Colors.success.b, 0.40)
                          : Qt.rgba(1, 1, 1, 0.07)

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: ProtonVpn.busy ? "sync" : (ProtonVpn.active ? "shield_lock" : "shield")
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 14
                    color: ProtonVpn.active ? Colors.success
                         : ProtonVpn.busy ? Colors.todoPriorityMedium
                         : PopoutConfig.textColor
                    opacity: ProtonVpn.active ? 1 : 0.7

                    RotationAnimation on rotation {
                        running: ProtonVpn.busy
                        loops: Animation.Infinite
                        from: 0; to: 360
                        duration: 900
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "ProtonVPN · " + ProtonVpn.selectedLocationLabel
                    color: PopoutConfig.textColor
                    opacity: ProtonVpn.active ? 0.95 : 0.78
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    renderType: Text.NativeRendering
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "·"
                    color: PopoutConfig.textColor
                    opacity: 0.4
                    font.pixelSize: 12
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: ProtonVpn.busy ? "Working…" : ProtonVpn.statusText
                    color: ProtonVpn.active ? Colors.success
                          : ProtonVpn.busy ? Colors.todoPriorityMedium
                          : PopoutConfig.textColor
                    opacity: 0.78
                    font.pixelSize: 11
                    renderType: Text.NativeRendering
                }
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: ProtonVpn.busy ? "" : (ProtonVpn.active ? "Disconnect" : "Connect")
                color: PopoutConfig.textColor
                opacity: 0.62
                font.pixelSize: 11
                font.weight: Font.Medium
                renderType: Text.NativeRendering
            }

            MouseArea {
                anchors.fill: parent
                enabled: !ProtonVpn.busy
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: ProtonVpn.toggle()
            }
        }

        // ── Errors ──
        Text {
            visible: Network.error && Network.error.length > 0
            width: parent.width
            text: "Network: " + Network.error
            color: Colors.foregroundRed
            opacity: 0.9
            font.pixelSize: 11
            wrapMode: Text.WordWrap
            renderType: Text.NativeRendering
        }

        Text {
            visible: ProtonVpn.error && ProtonVpn.error.length > 0
            width: parent.width
            text: "VPN: " + ProtonVpn.error
            color: Colors.foregroundRed
            opacity: 0.9
            font.pixelSize: 11
            wrapMode: Text.WordWrap
            renderType: Text.NativeRendering
        }
    }
}
