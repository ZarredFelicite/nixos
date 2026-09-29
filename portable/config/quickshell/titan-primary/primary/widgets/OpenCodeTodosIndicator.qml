import QtQuick
import QtQuick
import "../services"

Item {
    id: root

    property var popouts: null

    Component.onCompleted: {
        AgentTodos.refCount++
    }

    Component.onDestruction: {
        if (AgentTodos.refCount > 0)
            AgentTodos.refCount--
    }

    readonly property bool hasSessions: AgentTodos.sessionSummaries.length > 0

    implicitHeight: Colors.pillHeight
    implicitWidth: Math.max(ringsRow.implicitWidth, Colors.ringSize)

    width: hasSessions ? implicitWidth : 0
    opacity: hasSessions ? 1 : 0

    Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    function openTooltip() {
        if (!popouts) return
        var pos = popouts.mapFromItem(root, root.width / 2, root.height)
        popouts.openPopout("tooltip-agent-todos", pos.x, pos.y, root.width)
    }

    function statusColor(status) {
        var normalized = (status || "").toString().toLowerCase()
        if (normalized === "completed") return Colors.success
        if (normalized === "in_progress") return Colors.foregroundCyan
        return Colors.todoDateNoDue
    }

    function buildPalette(tasks) {
        var palette = []
        if (!tasks || tasks.length === 0) {
            palette.push({ color: Colors.todoDateNoDue })
            return palette
        }
        for (var i = 0; i < tasks.length; i++) {
            palette.push({ color: statusColor(tasks[i].status) })
        }
        return palette
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        propagateComposedEvents: true
        onEntered: root.openTooltip()
        onClicked: function(mouse) {
            root.openTooltip()
            mouse.accepted = false
        }
        onExited: {
            if (root.popouts && root.popouts.currentName === "tooltip-agent-todos") {
                root.popouts.scheduleClose()
            }
        }
    }

    Row {
        id: ringsRow
        anchors.centerIn: parent
        spacing: 4

        Repeater {
            id: sessionRepeater
            model: Math.min(AgentTodos.sessionSummaries.length, 3)

            delegate: Item {
                id: sessionItem
                readonly property var session: AgentTodos.sessionSummaries[index]
                readonly property var palette: root.buildPalette(session ? session.tasks : [])

                width: Colors.ringSize
                height: Colors.ringSize

                SegmentedRing {
                    anchors.centerIn: parent
                    width: Colors.ringSize
                    height: Colors.ringSize
                    segmentCount: Math.max(sessionItem.palette.length, 1)
                    segmentPalette: sessionItem.palette
                    lineWidth: Colors.ringThickness * 1.9
                    backgroundColor: Colors.todoDateNoDue
                    gapAngle: 0.79
                    maxGapRadians: (Math.PI / (2.5 / 0.75)) * 0.75
                    enableGapCap: true
                }

                Text {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -3
                    text: "\udb81\udea9"
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: Colors.ringSize * 1.16
                    color: Colors.foregroundCyan
                    opacity: 0.95
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }
}
