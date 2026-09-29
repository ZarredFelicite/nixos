import QtQuick
import Quickshell.Widgets
import "../../../services"

// Generic tooltip popout that displays text content below widgets
ClippingRectangle {
    id: root

    required property Item wrapper
    property string tooltipText: ""
    property Item content: null

    // expanded when active tooltip popout
    property bool expanded: wrapper && wrapper.hasCurrent && wrapper.currentName.startsWith("tooltip-")

    // indicate this component draws its own background so outer popout background can be suppressed
    property bool hasOwnBackground: true

    // Sizing constraints
    readonly property int maxWidth: PopoutConfig.tooltipMaxWidth
    readonly property int hPadding: PopoutConfig.tooltipPadding
    readonly property int vPadding: PopoutConfig.tooltipVerticalPadding

    // Use actual widget width as minimum, maxWidth as maximum
    property int widgetWidth: wrapper && wrapper.currentWidgetWidth ? wrapper.currentWidgetWidth : 100

    // Calculate width to wrap content closely between widget width and maxWidth
    implicitWidth: {
        if (root.content) {
            var contentWidth = root.content.implicitWidth + hPadding * 2
            var minWidth = Math.max(widgetWidth, 100)
            return Math.max(minWidth, Math.min(maxWidth, contentWidth))
        } else {
            var textWidth = textItem.implicitWidth + hPadding * 2
            var minWidth = Math.max(widgetWidth, 100)
            return Math.max(minWidth, Math.min(maxWidth, textWidth))
        }
    }
    implicitHeight: expanded ? (root.content ? root.content.implicitHeight : textItem.paintedHeight) + vPadding * 2 : 0

    // Position directly below pill; wrapper handles absolute y (we are y=0 in its local coords)
    y: 0

    // Visual styling from unified PopoutConfig
    color: PopoutConfig.backgroundColor
    // Full border with rounded corners
    border.width: PopoutConfig.borderWidth
    border.color: PopoutConfig.borderColor
    radius: PopoutConfig.cornerRadius

    // Clip children to rounded shape
    contentInsideBorder: true

    // Hover area to keep popout open
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onExited: if (root.wrapper) root.wrapper.scheduleClose()
    }

    // Animated height
    Behavior on implicitHeight { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

    // Fade content in/out
    Behavior on opacity { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

    // Content area - either text or custom content
    Item {
        id: contentArea
        anchors.left: parent.left
        anchors.leftMargin: root.hPadding
        anchors.top: parent.top
        anchors.topMargin: root.vPadding - 2
        width: Math.max(0, root.width - root.hPadding * 2)
        height: root.content ? root.content.height : textItem.paintedHeight
        opacity: expanded ? Colors.opacity.foreground1 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }

        // Custom content
        // children: root.content ? [root.content] : []
        Component.onCompleted: {
            if (root.content) {
                root.content.parent = contentArea
                root.content.anchors.fill = contentArea
            }
        }

        // Fallback text content
        Text {
            id: textItem
            visible: !root.content
            text: root.tooltipText
            color: PopoutConfig.textColor
            font.pixelSize: PopoutConfig.tooltipTextSize
            font.weight: Font.Medium
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignLeft
            width: parent.width
        }
    }

    Component {
        id: textComponent
        Text {
            text: root.tooltipText
            color: PopoutConfig.textColor
            font.pixelSize: PopoutConfig.tooltipTextSize
            font.weight: Font.Medium
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignLeft
            width: contentLoader.width
        }
    }
}