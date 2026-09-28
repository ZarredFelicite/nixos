import QtQuick
import Quickshell
import "../services"

// Systemd failed units indicator showing count of failed services
// Matches waybar systemd-failed-units functionality
Item {
    id: root
    property var popouts: null

    implicitWidth: contentRow.implicitWidth
    implicitHeight: Colors.pillHeight

    // Only show when there are failures (hide-on-ok: true)
    visible: SystemdFailed.hasFailures
    width: visible ? implicitWidth : 0
    opacity: visible ? 1 : 0

    Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    // Activate polling
    Component.onCompleted: SystemdFailed.refCount++
    Component.onDestruction: SystemdFailed.refCount--

    property string tooltip: SystemdFailed.tooltipText
    property int iconFontSize: 20

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        
        onEntered: {
            if (root.popouts && SystemdFailed.hasFailures) {
                var pos = root.popouts.mapFromItem(root, root.width / 2, root.height)
                root.popouts.openPopout("tooltip-systemd", pos.x, pos.y, root.width)
            }
        }
        
        onExited: {
            if (root.popouts && root.popouts.currentName === "tooltip-systemd") {
                root.popouts.scheduleClose()
            }
        }
        
        onClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton) {
                // Refresh failed units
                SystemdFailed.refresh()
            } else if (mouse.button === Qt.RightButton) {
                // Could open systemctl status or journal viewer
                SystemdFailed.refresh()
            }
        }
    }

    // Container with clipping
    Item {
        id: clipper
        anchors.fill: parent
        anchors.leftMargin: 0
        anchors.rightMargin: 0
        clip: true

        Item {
            id: contentRow
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: icon.implicitWidth + badge.implicitWidth - 3
            implicitHeight: Math.max(icon.implicitHeight, badge.y + badge.implicitHeight)

            Text {
                id: icon
                anchors.verticalCenter: parent.verticalCenter
                text: "error"
                font.family: "Material Symbols Outlined"
                font.pixelSize: root.iconFontSize
                color: Colors.foregroundRed
                renderType: Text.NativeRendering
            }

            Text {
                id: badge
                anchors.left: icon.right
                anchors.leftMargin: -3
                anchors.top: icon.top
                anchors.topMargin: -2
                text: SystemdFailed.failedCount
                font.pixelSize: 8
                font.weight: Font.Bold
                color: Colors.foregroundRed
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignTop
                renderType: Text.NativeRendering
            }
        }
    }
}