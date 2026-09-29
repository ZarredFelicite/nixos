import QtQuick
import Quickshell
import "../services"

// Displays three images (left, central, right) for ZMK keyboard battery status.
// Tooltip shows parsed percentages and charging flags from ZmkBattery singleton.
Item {
    id: root
    property var popouts: null

    visible: ZmkBattery.connected

    implicitHeight: visible ? Colors.pillHeight : 0
    implicitWidth: visible ? row.implicitWidth : 0

    // Activate polling
    Component.onCompleted: ZmkBattery.refCount++
    Component.onDestruction: ZmkBattery.refCount--

    property string tooltip: ZmkBattery.tooltipText

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onEntered: {
            if (root.popouts) {
                var pos = root.popouts.mapFromItem(root, root.width / 2, root.height)
                root.popouts.openPopout("tooltip-zmk", pos.x, pos.y, root.width)
            }
        }
        onExited: {
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 2

        property int iconSize: Colors.ringSize
        readonly property real dpr: (typeof Screen !== 'undefined' && Screen.devicePixelRatio) ? Screen.devicePixelRatio : 1

        Image {
            id: leftImage
            source: ZmkBattery.leftPath
            width: row.iconSize
            height: row.iconSize
            fillMode: Image.PreserveAspectFit
            smooth: false
            antialiasing: false
            sourceSize.width: width * row.dpr
            sourceSize.height: height * row.dpr
            cache: true
            asynchronous: true
            visible: source !== '' && status === Image.Ready
        }
        Image {
            id: centralImage
            source: ZmkBattery.centralPath
            width: row.iconSize
            height: row.iconSize
            fillMode: Image.PreserveAspectFit
            smooth: false
            antialiasing: false
            sourceSize.width: width * row.dpr
            sourceSize.height: height * row.dpr
            cache: true
            asynchronous: true
            visible: source !== '' && status === Image.Ready
        }
        Image {
            id: rightImage
            source: ZmkBattery.rightPath
            width: row.iconSize
            height: row.iconSize
            fillMode: Image.PreserveAspectFit
            smooth: false
            antialiasing: false
            sourceSize.width: width * row.dpr
            sourceSize.height: height * row.dpr
            cache: true
            asynchronous: true
            visible: source !== '' && status === Image.Ready
        }

        // Fallback glyph when no icons are available
        Text {
            text: "" // keyboard glyph
            font.pixelSize: 14
            color: Colors.primary
            visible: !leftImage.visible && !centralImage.visible && !rightImage.visible
        }
    }
}
