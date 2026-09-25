pragma Singleton

import Quickshell
import Quickshell.Hyprland
import QtQuick

Singleton {
    id: root

    // Consumers read this to instantiate the singleton and react after a coalesced refresh.
    property int revision: 0

    function affectsWindowLayout(name) {
        return name.includes("group")
            || name.startsWith("openwindow")
            || name.startsWith("closewindow")
            || name.startsWith("movewindow");
    }

    Timer {
        id: refreshTimer
        interval: 75
        repeat: false
        onTriggered: {
            Hyprland.refreshToplevels();
            root.revision++;
        }
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (root.affectsWindowLayout(event.name)) {
                refreshTimer.restart();
            }
        }
    }

    Connections {
        target: Hyprland.toplevels

        function onValuesChanged() {
            root.revision++;
        }
    }
}
