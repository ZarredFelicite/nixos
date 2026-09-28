pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../../services"
import "../../.." as Config

Item {
    id: root

    required property ShellScreen screen

    property string currentName
    property real currentCenter
    property real currentX
    // Bottom coordinate (in wrapper space) of the source element (tray item) for vertical positioning
    property real currentBottom
    property bool hasCurrent
    property bool currentHovered: false
    property alias closeTimer: closeTimer
    readonly property bool debugKeepOpen: Config.Config.debugPopoutsEnabled && Config.Config.debugPopoutKeepOpen && root.currentName === Config.Config.debugPopoutName
    // Questions require interaction and stay pinned. Final-message previews are
    // transient so they can auto-close and later reopen from their bar pill.
    readonly property bool pinned: root.currentName === "pi-dashboard-questions"
                                   && PiDashboardQuestions.hasQuestions

    // Use popupContainer dimensions (height animates via openProgress for unfold effect)
    readonly property real nonAnimWidth: popupContainer.width
    readonly property real nonAnimHeight: popupContainer.height

    // width of the source pill (SystemRings) to optionally lock popout width
    property real sourcePillWidth: 0
    // geometry of the source pill in wrapper coordinates
    property real sourcePillLeft: 0
    property real sourcePillBottom: 0
    // Overlap no longer used (kept for backward compatibility but fixed at 0)
    property real sourcePillOverlap: 0

    // width of individual widget for tooltip sizing (separate from pill width)
    property real currentWidgetWidth: 0

    // Gap below source elements (bluetooth pill and tray items)
    property int trayPopoutGap: 10

    visible: width > 0 && height > 0
    clip: true

    implicitWidth: nonAnimWidth
    implicitHeight: nonAnimHeight

    function close(): void {
        hasCurrent = false;
        currentHovered = false;
        currentName = "";
        if (popupContainer) popupContainer.openProgress = 0; // animate close
    }

    function openPopout(name, centerX, bottomY, widgetWidth) {
        var switching = hasCurrent && currentName && currentName !== name;

        if (switching) currentHovered = false;
        if (closeTimer.running) closeTimer.stop();
        currentName = name;
        if (centerX !== undefined) currentX = centerX;
        if (bottomY !== undefined) currentBottom = bottomY;
        if (widgetWidth !== undefined) currentWidgetWidth = widgetWidth;
        hasCurrent = true;
        if (popupContainer) {
            if (switching && typeof popupContainer.restartOpen === 'function') {
                popupContainer.restartOpen();
            } else if (!switching) {
                // Fresh open: ensure we start from 0 then animate to 1
                popupContainer.openProgress = 0;
                Qt.callLater(function(){ popupContainer.openProgress = 1; });
            }
        }
    }

    function scheduleClose() {
        if (debugKeepOpen || pinned) return;
        if (closeTimer) closeTimer.start();
    }

    Keys.onEscapePressed: if (!pinned) close()

    Timer {
        id: closeTimer
        interval: 2500  // Extended delay to prevent premature popup dismissal
        onTriggered: {
            if (root.debugKeepOpen || root.pinned) return;
            root.hasCurrent = false;
        }
    }

    HyprlandFocusGrab {
        // Automatically opened/hovered previews must not steal keyboard or pointer
        // focus from the active app. Interactive agent questions are pinned separately.
        active: root.hasCurrent
                && !root.debugKeepOpen
                && !root.pinned
                && root.currentName !== "tooltip-video-stream"
                && root.currentName !== "pi-dashboard-questions"
        windows: [QsWindow.window]
        onCleared: {
            if (root.debugKeepOpen || root.pinned) return;
            root.close();
        }
    }

    // Expose loader for geometry (used by bar mask Region)
    property alias contentLoader: content
    property alias contentItem: content.item
    property real contentX: content.x
    property real contentY: content.y
    property real contentWidth: content.implicitWidth
    property real contentHeight: content.implicitHeight

    // Container to manage unfold animation (height grows from 0 to full)
    Item {
        id: popupContainer
        // Manually managed open progress so we can retrigger animation when switching widgets
        property real openProgress: 0
        function restartOpen() {
            // Stop current animation and restart from 0
            // Disable behavior temporarily to force immediate reset
            openProgressBehavior.enabled = false;
            openProgress = 0;
            openProgressBehavior.enabled = true;
            Qt.callLater(function(){ 
                openProgress = 1; 
            });
        }
        Component.onCompleted: openProgress = 0
        // Animate openProgress for unfolding height
        Behavior on openProgress { 
            id: openProgressBehavior
            NumberAnimation { duration: PopoutConfig.openDuration; easing.type: PopoutConfig.openEasing } 
        }

        // Derive implicit size from content loader
        implicitWidth: content.implicitWidth
        implicitHeight: (content.implicitHeight * openProgress)

        // Position logic (full target size for coordinates); only vertical unfolding
        property bool shouldBeActive: root.hasCurrent

        // Unified horizontal positioning: center on widget's x coordinate
        x: root.currentName === "shortcuts"
              ? 0
              : root.currentName === "notifications"
                  ? Math.max(8, parent.width - implicitWidth - 8)
                  : (root.currentX !== undefined && root.currentX !== null)
                      ? Math.max(8, Math.min(parent.width - implicitWidth - 8, root.currentX - implicitWidth / 2))
                      : Math.max(8, parent.width - implicitWidth - 8)

        // Unified positioning: all widgets now pass coordinates, use currentBottom for source position
        property real sourceBottom: (root.currentBottom !== undefined && root.currentBottom !== null)
              ? root.currentBottom
              : (root.currentCenter !== undefined && root.currentCenter !== null)
                  ? root.currentCenter + (root.currentWidgetWidth > 0 ? root.currentWidgetWidth / 2 : 12)  // fallback estimate
                  : parent.height / 2
        
        property real targetY: root.currentName === "shortcuts"
              ? 0
              : root.currentName === "notifications"
                  ? 44
                  : Math.max(8, Math.min(parent.height - content.implicitHeight - 8, sourceBottom + root.trayPopoutGap))

        // Centered reference popups unfold in place; bar popouts slide from their source widget.
        y: root.currentName === "shortcuts"
              ? targetY
              : sourceBottom + (targetY - sourceBottom) * openProgress

        opacity: shouldBeActive ? Colors.opacity.foreground1 : 0
        Behavior on opacity { NumberAnimation { duration: popupContainer.shouldBeActive ? PopoutConfig.opacityInDuration : PopoutConfig.opacityOutDuration; easing.type: popupContainer.shouldBeActive ? PopoutConfig.openEasing : PopoutConfig.closeEasing; } }

        // Removed scale overshoot animation; only vertical unfold effect remains

        // Child loader (full size); we clip its visible portion via a mask rectangle
        Loader {
            id: content
            active: popupContainer.shouldBeActive || popupContainer.openProgress > 0
            asynchronous: false
            sourceComponent: Content { wrapper: root }
        }

        // Clipping rectangle to reveal content progressively
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            clip: true
            border.width: 0
            // Use content item as child so it's clipped; reparenting
            Component.onCompleted: { content.parent = this }
        }
    }




}
