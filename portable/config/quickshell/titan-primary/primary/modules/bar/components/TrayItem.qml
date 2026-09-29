pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

MouseArea {
    id: root

    required property SystemTrayItem modelData
    property int itemIndex: 0
    property var popouts: null

    objectName: "TrayItem_" + modelData.title.replace(/\s+/g, "_")

    acceptedButtons: Qt.LeftButton | Qt.RightButton
    implicitWidth: 16
    implicitHeight: 16

    hoverEnabled: true

    property bool hovered: false

    onEntered: {
        hovered = true;
        // Cancel any pending close timer when mouse enters tray item
        if (popouts && popouts.closeTimer) {
            popouts.closeTimer.stop();
        }
        if (modelData.hasMenu && popouts) {
            // Find the index of this item in the SystemTray.items
            let itemIndex = -1;
            const items = [...SystemTray.items.values];
            for (let i = 0; i < items.length; i++) {
                if (items[i] === modelData) {
                    itemIndex = i;
                    break;
                }
            }
            if (itemIndex >= 0) {
                try {
                    const ptBottom = root.mapToItem(popouts, root.width / 2, root.height);
                    popouts.openPopout(`traymenu${itemIndex}`, ptBottom.x, ptBottom.y);
                } catch (e) {
                    popouts.openPopout(`traymenu${itemIndex}`);
                }
            }
        }
    }
    onExited: {
        hovered = false;
        // Start close timer when mouse leaves tray item
        if (popouts && popouts.hasCurrent) {
            popouts.scheduleClose();
        }
    }
    onClicked: event => {
        if (event.button === Qt.LeftButton) {
            if (typeof modelData.activate === "function") {
                modelData.activate();
            }
        } else if (event.button === Qt.RightButton) {
            if (modelData.hasMenu && popouts) {
                // Find the index of this item in the SystemTray.items
                let itemIndex = -1;
                const items = [...SystemTray.items.values];
                for (let i = 0; i < items.length; i++) {
                    if (items[i] === modelData) {
                        itemIndex = i;
                        break;
                    }
                }
                if (itemIndex >= 0) {
                    try {
                        const bottomPt = root.mapToItem(popouts, root.width / 2, root.height);
                        popouts.openPopout(`traymenu${itemIndex}`, bottomPt.x, bottomPt.y);
                    } catch (e) {
                        popouts.openPopout(`traymenu${itemIndex}`);
                    }
                }
            } else if (typeof modelData.secondaryActivate === "function") {
                modelData.secondaryActivate();
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: hovered ? Qt.rgba(255, 255, 255, 0.1) : "transparent"
        radius: 6
        z: -1
        
        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }

    Image {
        id: icon

        source: {
            let icon = root.modelData.icon;
            if (icon.includes("?path=")) {
                const [name, path] = icon.split("?path=");
                icon = `file://${path}/${name.slice(name.lastIndexOf("/") + 1)}`;
            }
            return icon;
        }
        asynchronous: true
        anchors.fill: parent
        fillMode: Image.PreserveAspectFit
        // Allow smoothing for tray icons to mitigate aliasing on diagonal/curved shapes
        smooth: true
        antialiasing: true
        sourceSize.width: width * (typeof Screen !== 'undefined' && Screen.devicePixelRatio ? Screen.devicePixelRatio : 1)
        sourceSize.height: height * (typeof Screen !== 'undefined' && Screen.devicePixelRatio ? Screen.devicePixelRatio : 1)
        cache: true
    }
}