import QtQuick
import Quickshell
import "../services"

// Enhanced updates indicator showing downgrade and upgrade counts around a package icon.
// Layout: [downgrades] icon [upgrades]; hide sides if zero. Tooltip shows details from Updates.tooltipText.
Item {
    id: root
    objectName: "UpdatesIndicator"
    property var popouts: null

    // Configurable icon sizing; default larger than other ring icons.
    // Note: To truly double beyond pill height would require increasing Colors.pillHeight globally.
    // Keep within pill height to avoid clipping by Pill's ClippingRectangle parent.
    property int iconFontSize: Colors.pillHeight + 6  // enlarged beyond pill height (now ~32px)

    // Allow dynamic width to fit counts; use full pill height for larger icon
    implicitWidth: row.implicitWidth
    width: implicitWidth
    // Allow extra height for oversized icon; parent pill may clip unless extraHeight adjusted externally
    height: Math.max(Colors.pillHeight, icon.implicitHeight)

    property string tooltip: Updates.finalTooltipText

    // Offset to vertically align small count numbers relative to large icon
    property int countYOffset: Math.round(iconFontSize * 0.30)

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onEntered: {
            if (root.popouts) {
                var pos = root.popouts.mapFromItem(root, root.width / 2, root.height)
                root.popouts.openPopout("tooltip-updates", pos.x, pos.y, root.width)
            }
        }
        onExited: {
        }
        onClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton) {
                if (root.popouts) {
                    var pos = root.popouts.mapFromItem(root, root.width / 2, root.height)
                    root.popouts.openPopout("generations-menu", pos.x, pos.y, root.width)
                }
            } else if (mouse.button === Qt.RightButton) {
                var p = Qt.createQmlObject('import Quickshell.Io; Process { }', root)
                p.command = ["sh", "-c", "rm -f $HOME/.cache/nix-update-state"]
                p.onExited.connect(function() {
                    p.destroy()
                })
                p.running = true
                Updates.refresh()
            } else if (mouse.button === Qt.MiddleButton) {
                Updates.refresh()
            }
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 2
        property int maxCount: 99

        Text { // Downgrades left
            id: downCount
            visible: Updates.downgradeCount > 0
            text: Updates.downgradeCount > row.maxCount ? (row.maxCount + "+") : Updates.downgradeCount
            font.pixelSize: 10
            color: Colors.foregroundRed || Colors.primary // fallback
            verticalAlignment: Text.AlignVCenter
            y: root.countYOffset
        }

        Text { // Package icon ( glyph)
            id: icon
            text: ""
            font.pixelSize: root.iconFontSize
             // Show grey if nixos-upgrade service failed, primary color otherwise based on hasChanges
             color: Updates.nixosUpgradeServiceFailed ? Colors.outline : (Updates.hasChanges ? Colors.primary : Colors.primaryTransparent)
             opacity: Updates.nixosUpgradeServiceFailed ? 1.0 : (Updates.hasChanges ? 1.0 : 0.5)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        Text { // Upgrades right
            id: upCount
            visible: Updates.upgradeCount > 0
            text: Updates.upgradeCount > row.maxCount ? (row.maxCount + "+") : Updates.upgradeCount
            font.pixelSize: 10
            color: Colors.foregroundCyan || Colors.primary
            verticalAlignment: Text.AlignVCenter
            y: root.countYOffset
        }
    }

    Component.onCompleted: Updates.refresh()
}
