pragma ComponentBehavior: Bound

import "modules"
import "services" as Services
import "utils" as Utils
import Quickshell
import QtQuick

ShellRoot {
    id: root
    // Kick off icon override indexing as early as possible
    QtObject {
        Component.onCompleted: Utils.Icons.initOverrides()
    }

    QtObject {
        Component.onCompleted: Services.MemoryWatchdog.start()
        Component.onDestruction: Services.MemoryWatchdog.stop()
    }

    Bar {}
}
