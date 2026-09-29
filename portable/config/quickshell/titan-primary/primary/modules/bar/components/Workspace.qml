import "../../../widgets"
import "../../../utils"
import "../../../services"
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property var workspace
    required property string monitorName

    readonly property bool isWorkspace: true
    readonly property real size: indicator.width
    readonly property int ws: workspace.id
    readonly property bool isOccupied: workspace.lastIpcObject.windows > 0
    readonly property bool isActive: Hyprland.focusedWorkspace?.id === ws

    Layout.preferredWidth: size
    Layout.preferredHeight: indicator.height

    // Organize windows into groups while keeping the source object model stable.
    readonly property var windowLayout: {
        // Reading the tracker revision instantiates the singleton refresh listener.
        const refreshRevision = HyprlandWindowTracker.revision;
        const windows = Hyprland.toplevels.values.filter(c => c.workspace?.id === root.ws);
        const groups = {};
        const ungrouped = [];

        for (const window of windows) {
            const grouped = window.lastIpcObject.grouped || [];

            if (grouped.length > 1) {
                // Never sort Hyprland's array in place.
                const groupKey = grouped.slice().sort().join(",");
                if (!groups[groupKey]) {
                    groups[groupKey] = [];
                }
                groups[groupKey].push(window);
            } else {
                ungrouped.push(window);
            }
        }

        const positions = {};
        const groupBorders = [];
        let currentX = 0;
        let contentWidth = 0;

        for (const [groupKey, groupWindows] of Object.entries(groups)) {
            const groupStartX = currentX;

            for (const window of groupWindows) {
                positions[window.address] = { x: currentX, groupKey: groupKey };
                contentWidth = currentX + 17;
                currentX += 19;
            }

            const groupWidth = groupWindows.length * 17 + (groupWindows.length - 1) * 2;
            groupBorders.push({
                x: groupStartX - 4,
                y: -2,
                width: groupWidth + 8,
                height: Colors.pillHeight - 4,
                groupKey: groupKey
            });
            currentX += 12;
        }

        for (const window of ungrouped) {
            positions[window.address] = { x: currentX, groupKey: "" };
            contentWidth = currentX + 17;
            currentX += 19;
        }

        return {
            positions: positions,
            borders: groupBorders,
            width: contentWidth
        };
    }

    Rectangle {
        id: indicator

        width: Math.max(20, windowIcons.width + 10)
        height: Colors.pillHeight
        radius: Colors.pillHeight / 2

        color: root.isActive ? Colors.bg1 : Colors.bg4
        border.color: Colors.secondary
        border.width: 1

        // Show workspace number when no windows
        Text {
            anchors.centerIn: parent
            text: root.ws
            visible: !root.isOccupied
            color: Colors.primary
            font.family: "IosevkaTerm NFM"
            font.weight: Font.Bold
            font.pixelSize: 12
        }

        Item {
            id: windowIcons
            anchors.centerIn: parent
            width: Math.max(1, root.windowLayout.width)
            height: Colors.pillHeight - 9
            visible: root.isOccupied

            // Create group borders first (behind icons)
            Repeater {
                id: groupBorders
                model: root.windowLayout.borders

                Rectangle {
                    required property var modelData

                    x: modelData.x
                    y: modelData.y
                    width: modelData.width
                    height: modelData.height
                    radius: 9
                    color: "transparent"
                    border.width: 2
                    border.color: Colors.primary



                    Behavior on x {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on width {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            // Binding directly to the object model preserves existing delegates on insert/remove.
            Repeater {
                model: Hyprland.toplevels

                Item {
                    id: windowIcon

                    required property var modelData
                    readonly property var layoutData: root.windowLayout.positions[modelData.address]
                    readonly property string className: modelData.lastIpcObject.class || ""

                    x: layoutData ? Math.round(layoutData.x) : 0
                    y: 0
                    width: Math.round(Colors.pillHeight - 9)
                    height: Math.round(Colors.pillHeight - 9)
                    visible: layoutData !== undefined

                    Item {
                        anchors.centerIn: parent
                        width: 17
                        height: 17

                        Image {
                            id: iconImage
                            anchors.fill: parent
                            source: windowIcon.visible ? Icons.getIconSource(windowIcon.className) : ""
                            visible: status === Image.Ready
                            fillMode: Image.PreserveAspectFit
                            smooth: false
                            antialiasing: false
                            mipmap: false
                            sourceSize.width: width * (typeof Screen !== 'undefined' && Screen.devicePixelRatio ? Screen.devicePixelRatio : 1)
                            sourceSize.height: height * (typeof Screen !== 'undefined' && Screen.devicePixelRatio ? Screen.devicePixelRatio : 1)
                            cache: true
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: windowIcon.className ? windowIcon.className.charAt(0).toUpperCase() : "?"
                        visible: windowIcon.visible && iconImage.status !== Image.Ready
                        color: Colors.primary
                        font.family: "IosevkaTerm NFM"
                        font.weight: Font.Bold
                        font.pixelSize: 10
                    }
                }
            }
        }



        Behavior on color {
            ColorAnimation {
                duration: 400
                easing.type: Easing.OutCubic
            }
        }

        Behavior on width {
            NumberAnimation {
                duration: 50
                easing.type: Easing.OutCubic
            }
        }
    }

    Behavior on Layout.preferredWidth {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

    Behavior on Layout.preferredHeight {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }
}
