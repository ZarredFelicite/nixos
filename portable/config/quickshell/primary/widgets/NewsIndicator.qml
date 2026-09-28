import QtQuick
import Quickshell
import "../services"

// News indicator pill content: shows summarized news text.
// - Activates News service polling via refCount.
// - Elides text if longer than available width.
// - Tooltip shows full multi-line headlines.
// - Left / Middle click triggers manual refresh (rate limited in service)
Item {
    id: root
    objectName: "NewsIndicator"
    property var popouts: null

    // Collapsed state - when true, shows icon instead of text
    property bool collapsed: false

    implicitHeight: Colors.pillHeight
    implicitWidth: collapsed ? iconItem.implicitWidth : textItem.implicitWidth

    // Activate polling
    Component.onCompleted: News.refCount++
    Component.onDestruction: News.refCount--

    property string tooltip: News.tooltipText

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onEntered: {
            if (root.popouts) {
                var pos = root.popouts.mapFromItem(root, root.width / 2, root.height)
                root.popouts.openPopout("tooltip-news", pos.x, pos.y, root.width)
            }
        }
        onExited: {
            // Empty - tooltip stays open via wrapper timer delay
        }
        onClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton) {
                // Tooltip is already open from onEntered, clicking closes it
                if (root.popouts && root.popouts.hasCurrent && root.popouts.currentName === "tooltip-news") {
                    root.popouts.close()
                }
            } else if (mouse.button === Qt.MiddleButton) {
                News.refresh(true)
            } else if (mouse.button === Qt.RightButton) {
                root.collapsed = !root.collapsed
            }
        }
    }

    // Container with clipping to enforce elide/inset
    Item {
        id: clipper
        anchors.fill: parent
        anchors.leftMargin: 0
        anchors.rightMargin: 0
        clip: true

        Text {
            id: textItem
            visible: !root.collapsed
            text: News.summaryText
            font.pixelSize: 14
            font.weight: Font.Medium
            color: News.error !== '' ? (Colors.foregroundRed || Colors.primary) : Colors.primary
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
            // show full text without eliding; allow implicitWidth so the pill expands to fit
            anchors.verticalCenter: parent.verticalCenter
            opacity: News.checking ? 0.7 : 1.0
            textFormat: Text.PlainText
        }

        Text {
            id: iconItem
            visible: root.collapsed
            text: "󱀄"
            font.pixelSize: 28
            font.weight: Font.Medium
            color: News.error !== '' ? (Colors.foregroundRed || Colors.surfaceText) : Colors.surfaceText
            horizontalAlignment: Text.AlignCenter
            verticalAlignment: Text.AlignVCenter
            anchors.verticalCenter: parent.verticalCenter
            opacity: News.checking ? 0.7 : 1.0
        }
    }
}
