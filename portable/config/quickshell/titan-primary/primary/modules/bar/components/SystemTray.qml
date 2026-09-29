import QtQuick 2.15
import QtQuick.Layouts 1.15
import Quickshell
import Quickshell.Services.SystemTray
import "../../../services"
import "../../../widgets"

Item {
    id: trayRoot
    property bool hovered: false
    property var popouts: null  // Will be set by parent
    
    // Use implicit size based on content, not fixed widths
    implicitWidth: trayIcons.implicitWidth + 16  // 8px padding on each side
    implicitHeight: Colors.pillHeight  // Fixed height - no expansion



    Pill {
        id: trayBg
        anchors.fill: parent
        // implicitHeight: Colors.pillHeight (already set in Pill)
    }

    // Removed conflicting MouseArea - individual TrayItems handle their own hover

    RowLayout {
        id: trayIcons
        anchors.centerIn: parent
        spacing: 4
        
        Repeater {
            model: SystemTray.items
            delegate: TrayItem {
                // For now, just use a simple approach - right-click shows menu
                popouts: trayRoot.popouts
                itemIndex: 0  // Will be improved later
            }
        }
    }
}
