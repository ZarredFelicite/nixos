import QtQuick
import "../services"

Item {
    id: root
    property var popouts: null

    // Reference count management
    Component.onCompleted: {
        Network.refCount++
        ProtonVpn.refCount++
    }
    Component.onDestruction: {
        Network.refCount--
        ProtonVpn.refCount--
    }

    // Overall size derived from base ring size (use pill ring size)
    readonly property int baseSize: Colors.ringSize
    width: baseSize
    height: baseSize

    // (Icon removed)

    // Check if connected via wired interface
    readonly property bool isWired: Network.iface.startsWith("en") || Network.iface.startsWith("eth")

    // Colors (can be customized externally)
    property color signalColor: {
        if (!Network.connected) return Colors.primaryTransparent
        if (!Network.internetAccess) return Colors.foregroundRed
        if (root.isWired) return "#9ccfd8"
        return Colors.foregroundCyan
    }
    property color downColor: {
        if (!Network.connected) return Colors.primaryTransparent
        if (!Network.internetAccess) return Colors.foregroundRed
        return Colors.foregroundCyan
    }
    property color upColor: {
        if (!Network.connected) return Colors.primaryTransparent
        if (!Network.internetAccess) return Colors.foregroundRed
        return Colors.foregroundCyan
    }
    property color bgColor: Colors.primaryTransparent

    // Thinner rings & minimal gaps
    property real ringThickness: Math.max(1, Colors.ringThickness * 0.8)
    property real ringGap: 1

    // Derived animated values
    property real signalValue: {
        if (!Network.connected) return 0.0
        if (!Network.internetAccess) return 1.0
        if (root.isWired) return 1.0
        return Network.signalPercent / 100.0
    }
    property real downValue: {
        if (!Network.connected) return 0.0
        if (!Network.internetAccess) return 1.0
        return Network.downPercent
    }
    property real upValue: {
        if (!Network.connected) return 0.0
        if (!Network.internetAccess) return 1.0
        return Network.upPercent
    }

    // Canvas to draw three concentric full-circle rings
    Canvas {
        id: canvas
        anchors.fill: parent
        onPaint: {
            const ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            const cx = width / 2
            const cy = height / 2
            const maxR = Math.min(width, height) / 2
            // Use custom thin thickness & minimal gaps
            const thick = root.ringThickness
            const gap = root.ringGap
            // Place rings tightly: outer, then subtract (thick+gap) successively
            const rSignal = maxR - thick/2
            const rDown = rSignal - (thick + gap)
            const rUp = rDown - (thick + gap)
            ctx.lineCap = "round"

            function drawRing(radius, value, fg) {
                ctx.lineWidth = thick
                // Background
                ctx.beginPath()
                ctx.strokeStyle = bgColor
                ctx.arc(cx, cy, radius, -Math.PI/2, 1.5*Math.PI, false)
                ctx.stroke()
                if (value > 0) {
                    ctx.beginPath()
                    ctx.strokeStyle = fg
                    ctx.arc(cx, cy, radius, -Math.PI/2, -Math.PI/2 + value * 2*Math.PI, false)
                    ctx.stroke()
                }
            }

            drawRing(rSignal, root.signalValue, signalColor)
            drawRing(rDown, root.downValue, downColor)
            drawRing(rUp, root.upValue, upColor)
        }
        Connections {
            target: root
            function onSignalValueChanged(){ canvas.requestPaint() }
            function onDownValueChanged(){ canvas.requestPaint() }
            function onUpValueChanged(){ canvas.requestPaint() }
            function onSignalColorChanged(){ canvas.requestPaint() }
            function onDownColorChanged(){ canvas.requestPaint() }
            function onUpColorChanged(){ canvas.requestPaint() }
            function onBgColorChanged(){ canvas.requestPaint() }
        }
        Connections {
            target: Network
            function onSignalPercentChanged(){ canvas.requestPaint() }
            function onDownPercentChanged(){ canvas.requestPaint() }
            function onUpPercentChanged(){ canvas.requestPaint() }
            function onConnectedChanged(){ canvas.requestPaint() }
            function onInternetAccessChanged(){ canvas.requestPaint() }
        }
    }



    Behavior on signalValue { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
    Behavior on downValue { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
    Behavior on upValue { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

    Rectangle {
        anchors.centerIn: parent
        width: Math.round(root.baseSize * 0.34)
        height: width
        radius: width / 2
        visible: ProtonVpn.active || ProtonVpn.busy
        color: ProtonVpn.active ? Colors.success : "#f6c177"
        opacity: 0.9

        Text {
            anchors.centerIn: parent
            text: ProtonVpn.busy ? "sync" : "shield_lock"
            font.family: "Material Symbols Outlined"
            font.pixelSize: Math.round(parent.width * 0.62)
            color: "#1e1e2e"

            RotationAnimation on rotation {
                running: ProtonVpn.busy
                loops: Animation.Infinite
                from: 0
                to: 360
                duration: 900
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onEntered: {
            if (root.popouts) {
                var pos = root.popouts.mapFromItem(root, root.width / 2, root.height)
                root.popouts.openPopout("networks-menu", pos.x, pos.y, root.width)
            }
        }
        onExited: {
            // networks-menu is interactive; keep it open until dismissed by focus/click-away.
        }
        onClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton) {
                if (root.popouts) {
                    var pos = root.popouts.mapFromItem(root, root.width / 2, root.height)
                    root.popouts.openPopout("networks-menu", pos.x, pos.y, root.width)
                }
            } else if (mouse.button === Qt.RightButton) {
                ProtonVpn.toggle()
            }
        }
    }
}
