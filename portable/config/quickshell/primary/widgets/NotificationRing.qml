import QtQuick
import Quickshell
import "../services"

// Notification icon showing active count overlaid inside the bell.
Item {
    id: root
    property var popouts: null

    // Make the icon as large as pill height allows (minus a small margin)
    readonly property int baseIconBox: Colors.pillHeight - 2
    readonly property real iconScale: 1.0   // normalize width to reduce side gap
    readonly property real countScale: 1.15  // slightly bigger than original (was 1.3 before)
    // Height constrained by pill height; width can expand to fit larger glyph
    width: baseIconBox
    height: baseIconBox

    readonly property int notifCount: Notifs.popups.length
    property string tooltip: notifCount > 0 ? (notifCount + (notifCount === 1 ? " notification" : " notifications")) : "No notifications"

    // Use external PNG icon instead of glyph; path provided by user.
    // Prefer user's pictures/icons/notifications.png; fall back to glyph if load fails.
    readonly property string iconPngPath: "file:///home/zarred/pictures/icons/notifications.png"

    // Base icon image.
    Image {
        id: bell
        anchors.centerIn: parent
        source: iconPngPath
        asynchronous: true
        fillMode: Image.PreserveAspectFit
        width: parent.width
        height: parent.height
        opacity: 1.0
        // Re-enable smoothing for bell to reduce jagged edges
        smooth: true
        antialiasing: true
        sourceSize.width: width * (typeof Screen !== 'undefined' && Screen.devicePixelRatio ? Screen.devicePixelRatio : 1)
        sourceSize.height: height * (typeof Screen !== 'undefined' && Screen.devicePixelRatio ? Screen.devicePixelRatio : 1)
        cache: true
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    }

    // Count overlay (centered). We draw AFTER the glyph so it appears on top.
    // This mirrors the waybar script which composites digits onto a base bell image.
    Text {
        id: countText
        visible: root.notifCount > 0
        text: root.notifCount > 999 ? "999" : root.notifCount
        anchors.centerIn: bell
        font.bold: true
        font.pixelSize: Math.round(root.height * 0.42 * root.countScale * 0.8)
        color: Colors.bg1   // dark backdrop text color for contrast stroke trick
        z: 2
    }
    // Foreground duplicate for outline effect (simple poor-man stroke)
    Text {
        visible: countText.visible
        text: countText.text
        anchors.centerIn: bell
        font.bold: true
        font.pixelSize: countText.font.pixelSize
        color: Colors.primary
        z: 3
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        onClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton) {
                if (root.popouts) {
                    if (root.popouts.currentName === "notifications" && root.popouts.hasCurrent) {
                        root.popouts.close()
                    } else {
                        var pos = root.popouts.mapFromItem(root, root.width / 2, root.height)
                        root.popouts.openPopout("notifications", pos.x, pos.y, root.width)
                    }
                }
            } else if (mouse.button === Qt.RightButton) {
                Notifs.clearAll()
            }
        }
        onEntered: {
            if (root.popouts) {
                var pos = root.popouts.mapFromItem(root, root.width / 2, root.height)
                root.popouts.openPopout("notifications", pos.x, pos.y, root.width)
            }
        }
        onExited: {
        }
    }
}
