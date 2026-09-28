pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import "../../../services"

// Styled tray menu container similar to bluetooth popup (rounded, bordered, padded)
StackView {
    id: root

    // Indicates this menu draws its own styled background so outer popout background should be suppressed
    property bool hasOwnBackground: true

    required property Item popouts
    required property QsMenuHandle trayItem

    // Size directly from current item; internal padding handled within submenu columns
    implicitWidth: currentItem ? currentItem.implicitWidth : 0
    implicitHeight: currentItem ? currentItem.implicitHeight : 0

    function friendlyUsbText(text) {
        if (!text) return ""
        return text
            .replace(/Cambridge Silicon Radio, Ltd\s*/g, "")
            .replace(/Mpow HC5 Headset in charging mode - USB Hub/g, "Qudelix-5K USB DAC")
            .replace(/Mpow HC5 Headset in charging mode - HID \/ Mass Storage/g, "Qudelix-5K USB DAC")
            .replace(/Mpow HC5 Headset in charging mode/g, "Qudelix-5K USB DAC")
    }

    // Provide a background using unified PopoutConfig styling
    Rectangle {
        anchors.fill: parent
        color: PopoutConfig.backgroundColor
        radius: PopoutConfig.cornerRadius
        border.width: PopoutConfig.borderWidth
        border.color: PopoutConfig.borderColor
    }

    // Mouse area to detect hover on the actual menu
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true
        acceptedButtons: Qt.NoButton
        
        onEntered: {
            // Cancel any pending close timer when mouse enters menu
            if (root.popouts.closeTimer) {
                root.popouts.closeTimer.stop();
            }
        }
    }

    initialItem: SubMenu {
        handle: root.trayItem
    }

    // Instant transitions - no animations
    pushEnter: null
    pushExit: null
    popEnter: null
    popExit: null

    component SubMenu: Column {
        id: menu

        required property QsMenuHandle handle
        property bool isSubMenu: false

        padding: 16
        spacing: 2
        width: 200

        Component.onCompleted: {
        }

        // Back button for submenus
        Rectangle {
            visible: menu.isSubMenu
            width: parent.width - parent.padding * 2
            height: 28
            color: backMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.1) : "transparent"
            radius: 4

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "‹"
                    color: PopoutConfig.textColor
                    font.pixelSize: 14
                    font.bold: true
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Back"
                    color: PopoutConfig.textColor
                    font.pixelSize: 12
                    font.bold: true
                }
            }

            MouseArea {
                id: backMouse
                anchors.fill: parent
                hoverEnabled: true

                onClicked: {
                    root.pop();
                }
            }
        }

        // Spacer between back button and menu items
        Item {
            visible: menu.isSubMenu
            width: parent.width
            height: 20  // Even bigger gap - 20px
        }

        QsMenuOpener {
            id: menuOpener
            menu: menu.handle
        }

        Repeater {
            model: menuOpener.children

            Rectangle {
                id: item

                required property QsMenuEntry modelData

                width: parent.width - parent.padding * 2
                height: modelData.isSeparator ? 1 : Colors.pillHeight
                color: modelData.isSeparator ? Qt.rgba(255, 255, 255, 0.2) : (itemMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.1) : "transparent")
                radius: 4

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8
                    visible: !item.modelData.isSeparator

                    // Icon (if available)
                    Loader {
                        anchors.verticalCenter: parent.verticalCenter
                        active: item.modelData.icon !== ""
                        sourceComponent: Image {
                            source: item.modelData.icon
                            width: Math.max(12, Colors.pillHeight - 10)
                            height: Math.max(12, Colors.pillHeight - 10)
                            fillMode: Image.PreserveAspectFit
                            // Slight smoothing helps small symbolic icons
                            smooth: true
                            antialiasing: true
                            sourceSize.width: width * (typeof Screen !== 'undefined' && Screen.devicePixelRatio ? Screen.devicePixelRatio : 1)
                            sourceSize.height: height * (typeof Screen !== 'undefined' && Screen.devicePixelRatio ? Screen.devicePixelRatio : 1)
                            cache: true
                        }
                    }

                    // Text
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.friendlyUsbText(item.modelData.text || "")
                        color: item.modelData.enabled ? PopoutConfig.textColor : Qt.rgba(255, 255, 255, 0.5)
                        font.pixelSize: 12
                    }
                }

                // Submenu indicator
                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: "›"
                    color: item.modelData.enabled ? "white" : Qt.rgba(255, 255, 255, 0.5)
                    font.pixelSize: 12
                    visible: item.modelData.hasChildren && !item.modelData.isSeparator
                }

                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !item.modelData.isSeparator

                    onClicked: {
                        const entry = item.modelData;
                        if (entry.hasChildren) {
                            // Push submenu onto stack immediately

                            root.push(subMenuComp, {
                                handle: entry,
                                isSubMenu: true
                            });
                        } else {
                            // Execute action and close menu
                            entry.triggered();
                            root.popouts.hasCurrent = false;
                        }
                    }
                }
            }
        }
    }

    Component {
        id: subMenuComp
        SubMenu {}
    }
}