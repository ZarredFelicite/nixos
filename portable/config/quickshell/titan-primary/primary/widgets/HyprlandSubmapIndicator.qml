import QtQuick
import Quickshell
import "../services"

// Hyprland submap indicator showing current submap name in a pill
// Matches waybar hyprland/submap functionality
Pill {
    id: root
    property var popouts: null

    implicitWidth: textItem.implicitWidth + 16  // Add padding like other pills

    // Only show when there's an active submap
    visible: HyprlandSubmap.hasSubmap
    width: visible ? implicitWidth : 0
    opacity: visible ? 1 : 0

    Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    // Activate monitoring
    Component.onCompleted: HyprlandSubmap.refCount++
    Component.onDestruction: HyprlandSubmap.refCount--

    property string tooltip: HyprlandSubmap.tooltipText

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        
        onEntered: {
            if (root.popouts && HyprlandSubmap.hasSubmap) {
                var pos = root.popouts.mapFromItem(root, root.width / 2, root.height)
                root.popouts.openPopout("tooltip-submap", pos.x, pos.y, root.width)
            }
        }
        
        onExited: {
        }
    }

    Text {
        id: textItem
        text: HyprlandSubmap.displayText
        font.pixelSize: 14
        font.weight: Font.Medium
        color: Colors.foregroundYellow || Colors.primary  // Yellow color for submap (like waybar)
        anchors.centerIn: parent
    }
}