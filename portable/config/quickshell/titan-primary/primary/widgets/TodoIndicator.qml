import QtQuick
import Quickshell
import Quickshell.Io
import "../services"

Item {
    id: root
    objectName: "TodoIndicator"
    property var popouts: null

    property int iconFontSize: 18
    property int textFontSize: 12

    implicitWidth: row.implicitWidth
    width: implicitWidth
    height: Colors.pillHeight

    property string tooltip: Todos.tooltipText

    property bool shouldPulse: Todos.overdueTasks > 0

    SequentialAnimation on opacity {
        running: shouldPulse
        loops: Animation.Infinite
        NumberAnimation { to: 0.6; duration: 1000; easing.type: Easing.InOutQuad }
        NumberAnimation { to: 1.0; duration: 1000; easing.type: Easing.InOutQuad }
    }

    function openInObsidian() {
        var uri = "obsidian://open?vault=home&file=todo.md"
        Qt.openUrlExternally(uri)
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onEntered: {
            if (root.popouts) {
                var pos = root.popouts.mapFromItem(root, root.width / 2, root.height)
                root.popouts.openPopout("tooltip-todos", pos.x, pos.y, root.width)
            }
        }
        onExited: {
        }
        onClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton) {
                root.openInObsidian()
            } else if (mouse.button === Qt.MiddleButton) {
                Todos.refresh()
            } else if (mouse.button === Qt.RightButton) {
                Todos.refresh()
            }
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 4
        property int maxCount: 99

        Text {
            id: highPrioCount
            visible: Todos.highPriorityTasks > 0
            text: Todos.highPriorityTasks > row.maxCount ? (row.maxCount + "+") : Todos.highPriorityTasks
            font.pixelSize: root.textFontSize
            color: Colors.todoPriorityHigh
            verticalAlignment: Text.AlignVCenter
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            id: icon
            text: "\ue69c"
            font.family: "monospace"
            font.pixelSize: 30
            color: {
                // Show red if API is not available
                if (!Todos.apiAvailable) return "#ff5555"
                if (Todos.overdueTasks > 0) return Colors.todoDateOverdue
                if (Todos.dueTodayTasks > 0) return Colors.todoPriorityMedium
                if (Todos.pendingTasks > 0) return Colors.primary
                return Colors.primaryTransparent
            }
            opacity: !Todos.apiAvailable || Todos.pendingTasks > 0 ? 1.0 : 0.5
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            anchors.verticalCenter: parent.verticalCenter
            width: implicitWidth
            height: implicitHeight
        }

        Text {
            id: dueCount
            visible: (Todos.dueTodayTasks + Todos.overdueTasks) > 0
            text: {
                var total = Todos.dueTodayTasks + Todos.overdueTasks
                return total > row.maxCount ? (row.maxCount + "+") : total
            }
            font.pixelSize: root.textFontSize
            color: Todos.overdueTasks > 0 ? Colors.todoDateOverdue : Colors.todoPriorityMedium
            verticalAlignment: Text.AlignVCenter
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Component.onCompleted: Todos.refresh()
}
