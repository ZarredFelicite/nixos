import QtQuick
import "../services"

Rectangle {
    id: root

    property var popouts: null

    readonly property bool anyOn: HomeAssistant.beamState === "on"
                                  || HomeAssistant.beam1State === "on"
                                  || HomeAssistant.beam2State === "on"
    readonly property color statusColor: !HomeAssistant.configured || HomeAssistant.error !== ""
                                         ? Colors.foregroundRed
                                         : (HomeAssistant.beamState === "on"
                                            ? Colors.success
                                            : (root.anyOn ? Colors.todoPriorityMedium
                                                          : Colors.primary))

    implicitWidth: Colors.ringSize
    implicitHeight: Colors.pillHeight
    color: "transparent"

    Text {
        anchors.centerIn: parent
        text: "lightbulb"
        font.family: "Material Symbols Outlined"
        font.pixelSize: 18
        color: root.statusColor
        opacity: HomeAssistant.beamState === "off" ? 0.55 : 0.9
        renderType: Text.NativeRendering
    }

    Rectangle {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 2
        anchors.bottomMargin: 4
        width: 5
        height: width
        radius: width / 2
        color: root.statusColor
        visible: HomeAssistant.configured
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        onEntered: {
            if (root.popouts) {
                var pos = root.popouts.mapFromItem(root, root.width / 2, root.height)
                root.popouts.openPopout("home-assistant", pos.x, pos.y, root.width)
            }
        }
        onClicked: HomeAssistant.toggle("light.beam")
        onExited: {
            // The Home Assistant popout is an interactive menu and closes via focus grab.
        }
    }
}
