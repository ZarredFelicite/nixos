pragma ComponentBehavior: Bound

import "../../widgets"
import "../../services"
import "components"
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property string monitorName

    readonly property list<Workspace> workspaces: layout.children.filter(c => c.isWorkspace).sort((w1, w2) => w1.ws - w2.ws)
    readonly property var occupied: Hyprland.workspaces.values.reduce((acc, curr) => {
        acc[curr.id] = curr.lastIpcObject.windows > 0;
        return acc;
    }, {})
    readonly property int groupOffset: Math.floor((Hyprland.focusedWorkspace?.id - 1) / 10) * 10

    implicitWidth: container.implicitWidth
    implicitHeight: container.implicitHeight

    Rectangle {
        id: container

        anchors.centerIn: parent
        radius: 15
        color: Colors.secondary  // secondary color workspaces background

        implicitWidth: layout.implicitWidth + 2
        implicitHeight: layout.implicitHeight + 2

        RowLayout {
            id: layout

            anchors.centerIn: parent
            spacing: 2

            Repeater {
                // Filter workspaces by monitor like ignis
                model: Hyprland.workspaces.values.filter(ws =>
                    ws.monitor?.name === root.monitorName &&
                    !ws.name.startsWith("special:")
                )

                Workspace {
                    required property var modelData

                    workspace: modelData
                    monitorName: root.monitorName
                }
            }


        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true

        onPressed: event => {
            const ws = layout.childAt(event.x - container.x + layout.x, event.y - container.y + layout.y).index + root.groupOffset + 1;
            if ((Hyprland.focusedWorkspace?.id ?? 1) !== ws)
                Hyprland.dispatch(`workspace ${ws}`);
        }

        onWheel: event => {
            const activeWs = Hyprland.activeToplevel?.workspace?.name;
            if (activeWs?.startsWith("special:"))
                Hyprland.dispatch(`togglespecialworkspace ${activeWs.slice(8)}`);
            else if (event.angleDelta.y < 0 || (Hyprland.focusedWorkspace?.id ?? 1) > 1)
                Hyprland.dispatch(`workspace r${event.angleDelta.y > 0 ? "-" : "+"}1`);
        }
    }
}
