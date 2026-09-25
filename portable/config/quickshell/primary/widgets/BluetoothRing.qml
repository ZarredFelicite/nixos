import QtQuick
import Quickshell
import "../services"

Item {
    id: root
    
    property var popouts: null  // Will be set by parent
    
    width: Colors.ringSize
    height: Colors.ringSize
    
    // Tooltip showing connected devices
    property string tooltip: Bluetooth.connectionCount > 0 ? 
        "Bluetooth (" + Bluetooth.connectionCount + " connected): " + Bluetooth.connectedDevices : 
        "Bluetooth: No devices connected"
    
    // Segmented ring background
    SegmentedRing {
        anchors.fill: parent
        segmentCount: 5
        filledSegments: Bluetooth.connectionCount
        segmentColor: Colors.foregroundCyan
        backgroundColor: Colors.primaryTransparent
        lineWidth: 2
    }
    
    // Bluetooth icon in center (crisp)
    Image {
        id: icon
        anchors.fill: parent
        source: "/home/zarred/pictures/icons/bluetooth.png"
        fillMode: Image.PreserveAspectFit
        smooth: false
        antialiasing: false
        sourceSize.width: width * (typeof Screen !== 'undefined' && Screen.devicePixelRatio ? Screen.devicePixelRatio : 1)
        sourceSize.height: height * (typeof Screen !== 'undefined' && Screen.devicePixelRatio ? Screen.devicePixelRatio : 1)
        cache: true
        
        // Tint icon based on connection status
        opacity: Bluetooth.connectionCount > 0 ? 1.0 : 0.5
    }

    // No color overlay; use icon opacity only
    
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        
        onClicked: function(mouse) {
            console.log("Bluetooth clicked!")
            if (mouse.button === Qt.LeftButton) {
                // Open bluetooth menu
                if (root.popouts) {
                    var pos = root.popouts.mapFromItem(root, root.width / 2, root.height)
                    root.popouts.openPopout("bluetooth-menu", pos.x, pos.y, root.width)
                }
            } else if (mouse.button === Qt.RightButton) {
                // Toggle bluetooth power
                Bluetooth.toggleBluetooth()
            }
        }
        
        onEntered: {
            console.log("Bluetooth hover entered")
            if (root.popouts) {
                var pos = root.popouts.mapFromItem(root, root.width / 2, root.height)
                root.popouts.openPopout("bluetooth", pos.x, pos.y, root.width)
            }
        }
        
        onExited: {
            console.log("Bluetooth hover exited")
            if (root.popouts && root.popouts.currentName === "bluetooth") {
                if (root.popouts.closeTimer) root.popouts.closeTimer.start()
            }
        }
    }
    
    // Tooltip handled by popout system
    
    Component.onCompleted: {
        console.log("BluetoothRing component completed!")
        Bluetooth.refCount++
    }
    
    Component.onDestruction: {
        Bluetooth.refCount--
    }
}
