import QtQuick
import Quickshell.Widgets
import "../../../services"

// Tooltip listing available media players; highlights active one
ClippingRectangle {
    id: root

    required property Item wrapper

    // indicate this component draws its own background so outer popout background can be suppressed
    property bool hasOwnBackground: true

    readonly property int hPadding: PopoutConfig.tooltipPadding
    readonly property int vPadding: PopoutConfig.tooltipVerticalPadding

    implicitWidth: Math.max(wrapper.currentWidgetWidth || 160, listContent.implicitWidth + hPadding * 2)
    implicitHeight: listContent.implicitHeight + vPadding * 2

    y: 0
    color: PopoutConfig.backgroundColor
    border.width: PopoutConfig.borderWidth
    border.color: PopoutConfig.borderColor
    radius: PopoutConfig.cornerRadius
    contentInsideBorder: false

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: if (root.wrapper && root.wrapper.closeTimer) root.wrapper.closeTimer.stop()
        onExited: if (root.wrapper && root.wrapper.closeTimer) root.wrapper.closeTimer.start()
    }

    Column {
        id: listContent
        spacing: 6
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: hPadding
        anchors.topMargin: vPadding

        Repeater {
            model: Playerctl.players
            delegate: Row {
                spacing: 8
                height: 22

                // Icon
                Image {
                    id: iconImg
                    width: 18
                    height: 18
                    anchors.verticalCenter: parent.verticalCenter
                    source: Playerctl.iconFor(modelData)
                    fillMode: Image.PreserveAspectFit
                    smooth: false
                    antialiasing: false
                    mipmap: false
                    sourceSize.width: width * (typeof Screen !== 'undefined' && Screen.devicePixelRatio ? Screen.devicePixelRatio : 1)
                    sourceSize.height: height * (typeof Screen !== 'undefined' && Screen.devicePixelRatio ? Screen.devicePixelRatio : 1)
                }
                // No tint overlay here; show theme icon as-is
                // Fallback letter
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: iconImg.status !== Image.Ready
                    text: (modelData || "?").charAt(0).toUpperCase()
                    color: modelData === Playerctl.activePlayer ? Colors.foregroundCyan : "#888"
                    font.pixelSize: 14
                    font.bold: true
                }
                // Name
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData
                    color: modelData === Playerctl.activePlayer ? Colors.foregroundCyan : PopoutConfig.textColor
                    font.pixelSize: PopoutConfig.tooltipTextSize
                    font.weight: Font.Medium
                }
            }
        }
    }
}
