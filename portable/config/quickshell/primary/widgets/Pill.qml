import QtQuick 2.15
import QtQuick.Layouts 1.15
import Quickshell.Widgets
import "../services"

// Standard pill container supporting seamless merge with a popup below
ClippingRectangle {
    id: pill

    // External API -----------------------------------------------------------
    // When true, bottom corners are squared so a popup directly below can
    // attach with its top corners squared, forming a single continuous shape.
    property bool mergedBottom: false

    // Standardized pill dimensions and appearance
    // Allow dynamic extra height for overlap merging (e.g. when a popup overlaps the
    // bottom portion). Default 0 so existing pills unaffected.
    property int extraHeight: 0
    implicitHeight: Colors.pillHeight + extraHeight

    // Base color & border (shared with popouts for seamless join)
    color: Colors.bg1
    border.color: Colors.secondary
    border.width: 1

    // Per-corner radii (Qt 6+ via ClippingRectangle)
    readonly property real cornerRadius: implicitHeight / 2
    topLeftRadius: cornerRadius
    topRightRadius: cornerRadius
    bottomLeftRadius: mergedBottom ? 0 : cornerRadius
    bottomRightRadius: mergedBottom ? 0 : cornerRadius

    // Layout hints for RowLayout/Layouts usage
    Layout.preferredHeight: implicitHeight
    Layout.minimumHeight: implicitHeight

    // Remove hover highlight; keep mouse area if needed for future interactions
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        // No color changes on hover
    }

    Behavior on color {
        ColorAnimation { duration: 200; easing.type: Easing.OutCubic }
    }
}
