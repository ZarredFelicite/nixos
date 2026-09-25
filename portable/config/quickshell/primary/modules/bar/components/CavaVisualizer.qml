import "../../../services"
import "../../../widgets"
import QtQuick

Item {
    id: root

    property bool enabledWidget: true
    property int barCount: 20
    property int barWidth: 3
    property int barSpacing: 1
    property int maxHeight: 24
    property color barColor: Colors.primary
    property var popouts: null  // Injected from parent

    implicitWidth: (barWidth + barSpacing) * barCount * 2 - barSpacing
    implicitHeight: maxHeight

    Component.onCompleted: {
        Cava.bars = barCount;
        if (enabledWidget)
            Cava.refCount++;
    }

    Component.onDestruction: {
        if (enabledWidget && Cava.refCount > 0)
            Cava.refCount--;
    }

    onEnabledWidgetChanged: {
        if (enabledWidget) {
            Cava.bars = barCount;
            Cava.refCount++;
        } else if (Cava.refCount > 0) {
            Cava.refCount--;
        }
    }
    
    // Hover trigger for music player menu
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        
        onEntered: {
            if (root.popouts) {
                var pos = root.popouts.mapFromItem(root, root.width / 2, root.height)
                root.popouts.openPopout(
                    "music-player",
                    pos.x,
                    pos.y,
                    450  // menu width
                )
            }
        }
        
        onExited: {
            // Menu stays open (no auto-close)
        }
    }

    // Left side (mirrored)
    Repeater {
        model: root.barCount

        Rectangle {
            x: (root.barCount - 1 - index) * (root.barWidth + root.barSpacing)
            anchors.bottom: parent.bottom
            width: root.barWidth
            height: Math.max(1, (Cava.values[index] || 0) * root.maxHeight / 100)
            color: root.barColor
            radius: 1

            Behavior on height {
                NumberAnimation {
                    duration: 50
                    easing.type: Easing.OutQuad
                }
            }
        }
    }

    // Right side (original)
    Repeater {
        model: root.barCount

        Rectangle {
            x: (root.barCount + index) * (root.barWidth + root.barSpacing)
            anchors.bottom: parent.bottom
            width: root.barWidth
            height: Math.max(1, (Cava.values[index] || 0) * root.maxHeight / 100)
            color: root.barColor
            radius: 1

            Behavior on height {
                NumberAnimation {
                    duration: 50
                    easing.type: Easing.OutQuad
                }
            }
        }
    }
}
