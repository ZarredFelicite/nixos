import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services"

// Simple computer status indicator showing online/offline state
Pill {
    id: root
    property var popouts: null

    // Size to fit the indicator icons
    implicitWidth: rowLayout.implicitWidth + 12
    implicitHeight: Colors.pillHeight

    // Activate monitoring when visible
    Component.onCompleted: ComputerStatus.refCount++
    Component.onDestruction: ComputerStatus.refCount--

    // Only show when at least one computer is configured
    visible: ComputerStatus.computers.length > 0

    RowLayout {
        id: rowLayout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: 6
        spacing: 4

        // Nano indicator (laptop - fa-laptop)
        Text {
            id: nanoIcon
            text: "\uf109"
            font.pixelSize: Math.round(Colors.pillHeight * 0.9)
            font.family: "IosevkaTerm NFM"
            color: Colors.primary
            opacity: ComputerStatus.nanoOnline ? 1.0 : 0.4

            Behavior on opacity {
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }
        }

        // Sankara indicator (server - fa-server)
        Text {
            id: sankaraIcon
            text: "\uf233"
            font.pixelSize: Math.round(Colors.pillHeight * 0.9)
            font.family: "IosevkaTerm NFM"
            color: Colors.primary
            opacity: ComputerStatus.sankaraOnline ? 1.0 : 0.4

            Behavior on opacity {
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }
        }
    }

    // Tooltip on hover
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton

        onEntered: {
            if (root.popouts) {
                var pos = root.popouts.mapFromItem(root, root.width / 2, root.height)
                root.popouts.openPopout("computer-status", pos.x, pos.y, root.width)
            }
        }

        onExited: {
            if (root.popouts && root.popouts.currentName === "computer-status") {
                root.popouts.scheduleClose()
            }
        }
    }
}
