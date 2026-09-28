import QtQuick
import QtQuick.Controls
import Quickshell.Widgets
import Quickshell.Io
import "../../../services"
import "./"

ClippingRectangle {
    id: root
    required property Item wrapper

    property bool expanded: wrapper && wrapper.hasCurrent && wrapper.currentName === "brightness"
    property bool hasOwnBackground: true

    readonly property int hPadding: 16
    readonly property int vPadding: 14
    readonly property int contentWidth: 300
    readonly property int maxListHeight: 220

    implicitWidth: expanded ? contentWidth + hPadding * 2 : 0
    implicitHeight: expanded ? mainColumn.implicitHeight + vPadding * 2 : 0

    layer.enabled: true
    layer.smooth: false

    color: PopoutConfig.backgroundColor
    border.width: PopoutConfig.borderWidth
    border.color: PopoutConfig.borderColor
    radius: PopoutConfig.cornerRadius
    contentInsideBorder: false

    Behavior on implicitHeight { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

    // Controllers and freshness
    property var controllers: []
    property date lastUpdated: new Date(0)
    property string error: ""
    property bool refreshing: false
    property int _tick: 0

    Timer {
        interval: 30000
        running: root.expanded
        repeat: true
        triggeredOnStart: true
        onTriggered: root._tick++
    }

    onExpandedChanged: { if (expanded) refresh() }

    function refresh() {
        if (refreshing) return
        refreshing = true
        controllers = []
        error = ""
        enumProc.running = false
        enumProc.running = true
    }

    Process {
        id: enumProc
        running: false
        command: ["/run/current-system/sw/bin/brillo", "-e", "-G"]
        stdout: SplitParser {
            onRead: function (line) {
                var txt = (line || "").trim()
                if (!txt) return
                var parts = txt.split(/\s+/)
                if (parts.length < 2) return
                var name = parts[0]
                var val = parseFloat(parts[1])
                var arr = root.controllers.slice(0)
                var found = false
                for (var i = 0; i < arr.length; i++) {
                    if (arr[i].name === name) {
                        arr[i].value = isNaN(val) ? -1 : val
                        found = true
                        break
                    }
                }
                if (!found) arr.push({ name: name, value: isNaN(val) ? -1 : val })
                root.controllers = arr
            }
        }
        onExited: function (code) {
            if (code !== 0) root.error = "brillo exited " + code
            root.lastUpdated = new Date()
            root.refreshing = false
        }
    }

    function avgBrightness() {
        if (controllers.length === 0) return -1
        var sum = 0
        var n = 0
        for (var i = 0; i < controllers.length; i++) {
            if (isFinite(controllers[i].value) && controllers[i].value >= 0) {
                sum += controllers[i].value
                n++
            }
        }
        return n > 0 ? Math.round(sum / n) : -1
    }

    function brightnessAccent(p) {
        if (p < 0) return Colors.todoDateNoDue
        if (p >= 70) return Colors.todoDateDue
        if (p >= 30) return Colors.todoPriorityLow
        return Colors.todoPriorityMedium
    }

    function statusBadge() {
        if (root.refreshing) return "Reading"
        if (root.error.length > 0) return "Error"
        var p = root.avgBrightness()
        if (p < 0) return "Unknown"
        if (p >= 70) return "Bright"
        if (p >= 30) return "Balanced"
        return "Dim"
    }

    function statusAccent() {
        if (root.refreshing) return Colors.todoDateDue
        if (root.error.length > 0) return Colors.foregroundRed
        return root.brightnessAccent(root.avgBrightness())
    }

    function freshness() {
        if (root.refreshing) return "reading…"
        if (!root.lastUpdated || root.lastUpdated.getTime() === 0) return ""
        var s = Math.max(0, Math.floor((Date.now() - root.lastUpdated.getTime()) / 1000))
        if (s < 60) return "just now"
        var m = Math.floor(s / 60)
        if (m < 60) return m + "m ago"
        var h = Math.floor(m / 60)
        if (h < 24) return h + "h ago"
        return Math.floor(h / 24) + "d ago"
    }

    function controllerSymbol(name) {
        var n = (name || "").toLowerCase()
        if (n.indexOf("ddcci") >= 0) return "tv"
        if (n.indexOf("intel_backlight") >= 0 || n.indexOf("amdgpu") >= 0 || n.indexOf("backlight") >= 0) return "laptop_mac"
        if (n.indexOf("kbd") >= 0 || n.indexOf("keyboard") >= 0) return "keyboard"
        return "monitor"
    }

    function controllerValue(name) {
        // Keep bindings reactive while preserving the controller objects during a drag.
        var tick = _tick
        for (var i = 0; i < controllers.length; i++) {
            if (controllers[i].name === name) return Number(controllers[i].value)
        }
        return -1
    }

    function setControllerValue(name, value) {
        var bounded = Math.max(0, Math.min(100, Math.round(value)))
        for (var i = 0; i < controllers.length; i++) {
            if (controllers[i].name === name) {
                controllers[i].value = bounded
                _tick++
                return bounded
            }
        }
        return -1
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onEntered: if (root.wrapper && root.wrapper.closeTimer) root.wrapper.closeTimer.stop()
        onExited: if (root.wrapper && root.wrapper.closeTimer) root.wrapper.closeTimer.start()
    }

    Column {
        id: mainColumn
        width: root.contentWidth
        spacing: 10
        anchors.top: parent.top
        anchors.topMargin: root.vPadding
        anchors.horizontalCenter: parent.horizontalCenter
        opacity: root.expanded ? Colors.opacity.foreground1 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }

        // ── Header ──
        Item {
            width: parent.width
            height: 22

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Brightness"
                    color: PopoutConfig.textColor
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    renderType: Text.NativeRendering
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: badgeText.implicitWidth + 12
                    height: 16
                    radius: 8
                    color: Qt.rgba(root.statusAccent().r, root.statusAccent().g, root.statusAccent().b, 0.16)

                    Text {
                        id: badgeText
                        anchors.centerIn: parent
                        text: root.statusBadge().toUpperCase()
                        color: root.statusAccent()
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        renderType: Text.NativeRendering
                    }
                }
            }

            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 8
                height: 8
                radius: 4
                color: root.statusAccent()
                opacity: 0.85
                SequentialAnimation on opacity {
                    running: root.refreshing
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.30; duration: 600; easing.type: Easing.InOutQuad }
                    NumberAnimation { to: 0.85; duration: 600; easing.type: Easing.InOutQuad }
                }
            }
        }

        // ── Error banner ──
        Rectangle {
            visible: root.error.length > 0
            width: parent.width
            height: 28
            radius: 8
            color: Qt.rgba(Colors.foregroundRed.r, Colors.foregroundRed.g, Colors.foregroundRed.b, 0.12)
            border.width: 1
            border.color: Qt.rgba(Colors.foregroundRed.r, Colors.foregroundRed.g, Colors.foregroundRed.b, 0.32)

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: root.error
                color: Colors.foregroundRed
                font.pixelSize: 11
                opacity: 0.85
                elide: Text.ElideRight
                width: parent.width - 20
                renderType: Text.NativeRendering
            }
        }

        // ── Section header ──
        Item {
            visible: root.controllers.length > 0
            width: parent.width
            height: 14

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "DISPLAYS"
                color: Colors.primary
                opacity: 0.85
                font.pixelSize: 10
                font.weight: Font.Bold
                renderType: Text.NativeRendering
            }
            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: root.controllers.length === 1 ? "1 device" : root.controllers.length + " devices"
                color: PopoutConfig.textColor
                opacity: 0.45
                font.pixelSize: 10
                renderType: Text.NativeRendering
            }
        }

        // ── Empty / loading state ──
        Item {
            visible: root.controllers.length === 0 && root.error.length === 0
            width: parent.width
            height: 36

            Row {
                anchors.centerIn: parent
                spacing: 6

                Text {
                    id: spinnerIcon
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.refreshing ? "sync" : "tv_off"
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 14
                    color: root.refreshing ? Colors.primary : PopoutConfig.textColor
                    opacity: 0.65
                    RotationAnimation on rotation {
                        running: root.refreshing
                        loops: Animation.Infinite
                        from: 0; to: 360
                        duration: 900
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.refreshing ? "Reading controllers…" : "No display controllers found"
                    color: PopoutConfig.textColor
                    opacity: 0.65
                    font.pixelSize: 12
                    renderType: Text.NativeRendering
                }
            }
        }

        // ── Controller cards ──
        ScrollView {
            id: ctrlScroll
            visible: root.controllers.length > 0
            width: parent.width
            implicitHeight: Math.min(ctrlColumn.implicitHeight, root.maxListHeight)
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            Column {
                id: ctrlColumn
                width: ctrlScroll.availableWidth
                spacing: 6

                Repeater {
                    model: root.controllers
                    delegate: Rectangle {
                        id: ctrlItem
                        required property var modelData
                        readonly property real currentValue: root.controllerValue(modelData.name)
                        readonly property bool valid: isFinite(currentValue) && currentValue >= 0
                        readonly property int pct: valid ? Math.round(currentValue) : 0
                        readonly property color accent: valid ? root.brightnessAccent(pct) : Colors.todoDateNoDue
                        property int pendingPct: -1
                        property int sentPct: -1

                        Timer {
                            id: writeTimer
                            interval: 120
                            repeat: false
                            onTriggered: {
                                if (ctrlItem.pendingPct < 0 || setProc.running) return
                                ctrlItem.sentPct = ctrlItem.pendingPct
                                setProc.command = [
                                    "/run/current-system/sw/bin/brillo", "-S", String(ctrlItem.sentPct),
                                    "-q", "-s", ctrlItem.modelData.name, "-u", "100000"
                                ]
                                setProc.running = true
                            }
                        }

                        Process {
                            id: setProc
                            running: false
                            onExited: function (code) {
                                if (code !== 0) root.error = "Unable to set " + ctrlItem.modelData.name
                                if (ctrlItem.pendingPct === ctrlItem.sentPct) {
                                    ctrlItem.pendingPct = -1
                                } else {
                                    writeTimer.restart()
                                }
                            }
                        }

                        function setFromMouse(x) {
                            if (!ctrlItem.valid) return
                            ctrlItem.pendingPct = root.setControllerValue(
                                ctrlItem.modelData.name, x / width * 100)
                            writeTimer.restart()
                        }

                        width: ctrlColumn.width
                        height: 50
                        radius: 10
                        color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.06)
                        border.width: 1
                        border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.18)

                        Item {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            anchors.topMargin: 8
                            anchors.bottomMargin: 8

                            Item {
                                id: ctrlTop
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                height: 16

                                Row {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 8

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: root.controllerSymbol(ctrlItem.modelData.name)
                                        font.family: "Material Symbols Outlined"
                                        font.pixelSize: 14
                                        color: Colors.primary
                                        opacity: 0.9
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: ctrlItem.modelData.name || "—"
                                        color: PopoutConfig.textColor
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                        renderType: Text.NativeRendering
                                    }
                                }

                                Text {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: ctrlItem.valid ? (ctrlItem.pct + "%") : "—"
                                    color: ctrlItem.accent
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    renderType: Text.NativeRendering
                                }
                            }

                            Rectangle {
                                id: brightnessTrack
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: ctrlTop.bottom
                                anchors.topMargin: 6
                                height: 5
                                radius: 2.5
                                color: Qt.rgba(1, 1, 1, 0.07)

                                Rectangle {
                                    width: parent.width * Math.max(0, Math.min(1, ctrlItem.pct / 100))
                                    height: parent.height
                                    radius: parent.radius
                                    color: ctrlItem.accent
                                    visible: ctrlItem.valid
                                    Behavior on width { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                                }
                            }

                            MouseArea {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: brightnessTrack.top
                                anchors.bottom: parent.bottom
                                anchors.topMargin: -8
                                hoverEnabled: true
                                enabled: ctrlItem.valid
                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onPressed: function(mouse) { ctrlItem.setFromMouse(mouse.x) }
                                onPositionChanged: function(mouse) {
                                    if (pressed) ctrlItem.setFromMouse(mouse.x)
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── Footer ──
        Rectangle {
            width: parent.width
            height: 24
            radius: 8
            color: footerHover.containsMouse && !root.refreshing ? Qt.rgba(1, 1, 1, 0.05) : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                text: { var _ = root._tick; return "Updated " + root.freshness() }
                visible: root.lastUpdated && root.lastUpdated.getTime() > 0
                color: PopoutConfig.textColor
                opacity: 0.45
                font.pixelSize: 11
                renderType: Text.NativeRendering
            }
            Text {
                anchors.right: parent.right
                anchors.rightMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                text: root.refreshing ? "Reading…" : "Click to refresh"
                color: root.refreshing ? Colors.todoDateDue : PopoutConfig.textColor
                opacity: root.refreshing ? 0.85 : 0.55
                font.pixelSize: 11
                font.weight: root.refreshing ? Font.DemiBold : Font.Medium
                renderType: Text.NativeRendering
            }

            MouseArea {
                id: footerHover
                anchors.fill: parent
                hoverEnabled: true
                enabled: !root.refreshing
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root.refresh()
            }
        }
    }
}
