import QtQuick
import Quickshell
import "../services"

Item {
    id: root
    objectName: "ResticIndicator"
    property var popouts: null

    readonly property bool active: Restic.backingUp || Restic.checking
    readonly property color statusColor: {
        if (Restic.lastStatus === "error") return Colors.foregroundRed
        if (Restic.lastStatus === "success") return Colors.primary
        return Colors.primaryTransparent
    }

    implicitWidth: Colors.ringSize
    width: implicitWidth
    height: Colors.pillHeight

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: {
            if (root.popouts) {
                var pos = root.popouts.mapFromItem(root, root.width / 2, root.height)
                root.popouts.openPopout("restic-tooltip", pos.x, pos.y, root.width)
            }
        }
        onExited: {
            if (root.popouts && root.popouts.currentName === "restic-tooltip") {
                root.popouts.scheduleClose()
            }
        }
        onClicked: Restic.refresh()
    }

    Item {
        id: activityRing
        anchors.centerIn: parent
        width: Colors.ringSize
        height: width
        visible: root.active
        transformOrigin: Item.Center

        Canvas {
            anchors.fill: parent
            antialiasing: true

            onPaint: {
                var ctx = getContext("2d")
                var center = width / 2
                var radius = center - Colors.ringThickness / 2
                ctx.reset()
                ctx.lineWidth = Colors.ringThickness
                ctx.lineCap = "round"
                ctx.strokeStyle = Colors.primary
                ctx.beginPath()
                ctx.arc(center, center, radius, -Math.PI / 2, Math.PI * 1.15, false)
                ctx.stroke()
            }
        }

        RotationAnimation on rotation {
            from: 0
            to: 360
            duration: 1200
            loops: Animation.Infinite
            running: root.active
        }
    }

    Text {
        id: icon
        anchors.centerIn: parent
        text: "database"
        font.family: "Material Symbols Outlined"
        font.pixelSize: 15
        color: root.active ? Colors.primary : root.statusColor
        opacity: root.active ? 0.9 : 1
        renderType: Text.NativeRendering

        Behavior on color { ColorAnimation { duration: 160 } }
    }
}
