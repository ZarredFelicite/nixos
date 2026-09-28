import QtQuick
import Quickshell
import "../services"

PopupWindow {
    id: tooltipWindow
    
    property string text: ""
    property Item target: null
    property bool tooltipVisible: false

    // Styling values copied from Network/Bluetooth popouts
    readonly property int minWidth: 200
    readonly property int maxWidth: 420
    readonly property int hPadding: 16
    readonly property int vPadding: 10
    readonly property real cornerRadius: Colors.pillHeight / 2

    visible: tooltipVisible && text !== ""

    implicitWidth: Math.max(minWidth, Math.min(maxWidth, tooltipText.implicitWidth + hPadding * 2))
    implicitHeight: tooltipText.paintedHeight + vPadding * 2

    color: "transparent"

    Rectangle {
        anchors.fill: parent
        color: Colors.bg1
        border.color: Colors.secondary
        border.width: 1
        radius: cornerRadius
        // clip children to rounded shape
        clip: true

        // Text content centered with wrapping and padding
        Text {
            id: tooltipText
            text: tooltipWindow.text
            color: "#cdd6f4"
            font.pixelSize: 13
            font.weight: Font.Medium
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            anchors.top: parent.top
            anchors.topMargin: vPadding - 2
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.max(0, parent.width - hPadding * 2)
            opacity: 1.0
        }
    }

    // Timer to retry positioning shortly after creation (handles races where wrapper geometry isn't ready)
    Timer {
        id: posTimer
        interval: 80
        running: false
        repeat: false
        onTriggered: tooltipWindow.updatePosition()
    }

    function debugLog() {
        // Lightweight guard to avoid flooding
        if (!debug || typeof console === 'undefined') return
    }

    function updatePosition() {
        if (!target) return

        // Try a few strategies to find the window the target belongs to.
        var win = null

        if (target.QsWindow && target.QsWindow.window) win = target.QsWindow.window
        else if (target.Window && target.Window.window) win = target.Window.window
        else {
            // Walk up parent chain looking for an ancestor with QsWindow
            var p = target
            while (p) {
                if (p.QsWindow && p.QsWindow.window) { win = p.QsWindow.window; break }
                if (p.Window && p.Window.window) { win = p.Window.window; break }
                p = p.parent
            }
        }

        if (!win) return

        // Set anchor to the discovered window
        anchor.window = win

        // Primary approach: map target position into window content coordinates
        var targetPos = null
        try {
            if (win.itemPosition) targetPos = win.itemPosition(target)
        } catch(e) { targetPos = null }

        if (!targetPos) {
            // Fallback: map from target to window.contentItem
            try {
                targetPos = win.contentItem.mapFromItem(target, 0, 0)
            } catch(e) { targetPos = { x: 0, y: 0 } }
        }

        // Center horizontally relative to target
        var desiredX = targetPos.x + (target.width / 2) - (tooltipWindow.implicitWidth / 2)
        var clampedX = Math.max(4, Math.min(win.width - tooltipWindow.implicitWidth - 4, desiredX))

        anchor.rect.x = clampedX

        // Position below target with spacing; keep the tooltip close to the bar
        anchor.rect.y = targetPos.y + target.height + Math.round(vPadding * 0.5)

        // Set anchor rect size to 0 (point anchor)
        anchor.rect.width = 0
        anchor.rect.height = 0
    }

    onTooltipVisibleChanged: {
        if (tooltipVisible) {
            // Update immediately and schedule a retry shortly after to handle timing races
            updatePosition()
            posTimer.start()
        }
    }

    onTargetChanged: {
        if (tooltipVisible) {
            updatePosition()
            posTimer.start()
        }
    }
}
