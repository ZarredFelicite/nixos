import QtQuick
import Quickshell.Widgets
import "../../../services"
import "./"

ClippingRectangle {
    id: root
    required property Item wrapper
    property bool expanded: wrapper && wrapper.hasCurrent && wrapper.currentName === "tooltip-timer"
    property bool hasOwnBackground: true

    readonly property int hPadding: 16
    readonly property int vPadding: 14
    readonly property int contentWidth: 280

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

    // Live re-render so the digits and "expires in" stay accurate every second.
    property int _tick: 0
    Timer {
        interval: 1000
        running: root.expanded
        repeat: true
        triggeredOnStart: true
        onTriggered: root._tick++
    }

    readonly property int liveSeconds: CustomTimer.state === "paused"
        ? CustomTimer.pausedSecondsRemaining
        : CustomTimer.secondsRemaining

    readonly property real progress: CustomTimer.originalSeconds > 0
        ? Math.max(0, Math.min(1, (CustomTimer.originalSeconds - liveSeconds) / CustomTimer.originalSeconds))
        : 0

    function statusBadge() {
        if (CustomTimer.activeState === "running") return "Running"
        if (CustomTimer.activeState === "paused") return "Paused"
        return "Idle"
    }

    function statusAccent() {
        if (CustomTimer.activeState === "running") return Colors.todoDateDue
        if (CustomTimer.activeState === "paused") return Colors.todoPriorityMedium
        return Colors.todoDateNoDue
    }

    function stopwatchAccent() {
        if (CustomTimer.stopwatchState === "running") return Colors.todoDateDue
        if (CustomTimer.stopwatchState === "paused") return Colors.todoPriorityMedium
        return Colors.todoDateNoDue
    }

    function pad2(n) { return (n < 10 ? "0" : "") + n }

    function formatTime(secs) {
        var s = Math.max(0, secs | 0)
        var h = Math.floor(s / 3600)
        var m = Math.floor((s % 3600) / 60)
        var sec = s % 60
        if (h > 0) return h + ":" + pad2(m) + ":" + pad2(sec)
        return pad2(m) + ":" + pad2(sec)
    }

    function formatStopwatch(ms) {
        var safeMs = Math.max(0, Math.floor(ms || 0))
        var totalSeconds = Math.floor(safeMs / 1000)
        var hours = Math.floor(totalSeconds / 3600)
        var minutes = Math.floor((totalSeconds % 3600) / 60)
        var seconds = totalSeconds % 60
        var tenths = Math.floor((safeMs % 1000) / 100)
        if (hours > 0) return hours + ":" + pad2(minutes) + ":" + pad2(seconds) + "." + tenths
        return pad2(minutes) + ":" + pad2(seconds) + "." + tenths
    }

    function formatExpiresAt() {
        if (!CustomTimer.expiresAt || CustomTimer.expiresAt.getTime() === 0) return ""
        var d = CustomTimer.expiresAt
        return root.pad2(d.getHours()) + ":" + root.pad2(d.getMinutes())
    }

    function parseDuration(value) {
        var text = String(value || "").trim().toLowerCase()
        if (!text) return 0

        // A plain number means minutes.
        if (/^\d+$/.test(text)) return parseInt(text) * 60

        // Colon notation is MM:SS or HH:MM:SS.
        var colonParts = text.split(":")
        if (colonParts.length === 2 || colonParts.length === 3) {
            for (var i = 0; i < colonParts.length; i++) {
                if (!/^\d+$/.test(colonParts[i])) return 0
            }
            var seconds = parseInt(colonParts[colonParts.length - 1])
            var minutes = parseInt(colonParts[colonParts.length - 2])
            var hours = colonParts.length === 3 ? parseInt(colonParts[0]) : 0
            if (seconds > 59 || minutes > 59) return 0
            return hours * 3600 + minutes * 60 + seconds
        }

        // Unit notation accepts values such as "1h 30m" or "45s".
        var compact = text.replace(/\s+/g, "")
        var unitPattern = /(\d+)(h|m|s)/g
        var matchedText = ""
        var total = 0
        var match
        while ((match = unitPattern.exec(compact)) !== null) {
            matchedText += match[0]
            var amount = parseInt(match[1])
            total += match[2] === "h" ? amount * 3600 : match[2] === "m" ? amount * 60 : amount
        }
        return matchedText === compact ? total : 0
    }

    readonly property int enteredDurationSeconds: parseDuration(durationInput.text)

    function startEnteredTimer() {
        if (root.enteredDurationSeconds <= 0) return
        CustomTimer.newTimerSeconds(
            root.enteredDurationSeconds,
            "notify-send -u critical 'Timer expired.'; pw-play /home/zarred/audio/notifications/soft-4.mp3"
        )
        durationInput.text = ""
        durationInput.focus = false
    }

    component ActionBtn: Rectangle {
        property string label: ""
        property color accent: Colors.primary
        property bool danger: false
        property bool disabled: false
        signal triggered

        height: 24
        radius: 12
        width: btnText.implicitWidth + 18
        opacity: disabled ? 0.4 : 1.0
        color: actionMouse.containsMouse && !disabled
            ? Qt.rgba(accent.r, accent.g, accent.b, 0.30)
            : Qt.rgba(accent.r, accent.g, accent.b, 0.16)
        Behavior on color { ColorAnimation { duration: 120 } }
        border.width: 1
        border.color: Qt.rgba(accent.r, accent.g, accent.b, 0.36)

        Text {
            id: btnText
            anchors.centerIn: parent
            text: parent.label
            color: parent.accent
            font.pixelSize: 10
            font.weight: Font.Bold
            renderType: Text.NativeRendering
        }

        MouseArea {
            id: actionMouse
            anchors.fill: parent
            hoverEnabled: true
            enabled: !parent.disabled
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: parent.triggered()
        }
    }

    Column {
        id: mainColumn
        width: root.contentWidth
        spacing: 12
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
                    text: "Timer"
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
                    running: CustomTimer.activeState === "running"
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.30; duration: 600; easing.type: Easing.InOutQuad }
                    NumberAnimation { to: 0.85; duration: 600; easing.type: Easing.InOutQuad }
                }
            }
        }

        // ── Active timer card ──
        Rectangle {
            visible: CustomTimer.hasTimer
            width: parent.width
            height: timerCardCol.implicitHeight + 20
            radius: 10
            color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.06)
            border.width: 1
            border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.18)

            Column {
                id: timerCardCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                anchors.topMargin: 10
                spacing: 6

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: { var _ = root._tick; return root.formatTime(root.liveSeconds) }
                    color: root.statusAccent()
                    font.pixelSize: 30
                    font.weight: Font.Bold
                    font.family: "monospace"
                    renderType: Text.NativeRendering
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: CustomTimer.expiresAt && CustomTimer.expiresAt.getTime() > 0 && CustomTimer.state === "running"
                    text: { var _ = root._tick; return "expires at " + root.formatExpiresAt() }
                    color: PopoutConfig.textColor
                    opacity: 0.55
                    font.pixelSize: 11
                    renderType: Text.NativeRendering
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: CustomTimer.state === "paused"
                    text: "paused"
                    color: PopoutConfig.textColor
                    opacity: 0.55
                    font.pixelSize: 11
                    font.italic: true
                    renderType: Text.NativeRendering
                }

                // Progress bar (visible when we know the original duration)
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    visible: CustomTimer.originalSeconds > 0
                    height: 5
                    radius: 2.5
                    color: Qt.rgba(1, 1, 1, 0.07)

                    Rectangle {
                        width: parent.width * root.progress
                        height: parent.height
                        radius: parent.radius
                        color: root.statusAccent()
                        Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.Linear } }
                    }
                }
            }
        }

        // ── Idle state card ──
        Rectangle {
            visible: !CustomTimer.hasTimer
            width: parent.width
            height: 64
            radius: 10
            color: Qt.rgba(Colors.todoDateNoDue.r, Colors.todoDateNoDue.g, Colors.todoDateNoDue.b, 0.10)
            border.width: 1
            border.color: Qt.rgba(Colors.todoDateNoDue.r, Colors.todoDateNoDue.g, Colors.todoDateNoDue.b, 0.22)

            Column {
                anchors.centerIn: parent
                spacing: 4

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "hourglass_empty"
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 22
                    color: Colors.todoDateNoDue
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "No timer set"
                    color: PopoutConfig.textColor
                    opacity: 0.7
                    font.pixelSize: 12
                    renderType: Text.NativeRendering
                }
            }
        }

        // ── Stopwatch ──
        Item {
            width: parent.width
            height: 14

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "STOPWATCH"
                color: Colors.primary
                opacity: 0.85
                font.pixelSize: 10
                font.weight: Font.Bold
                renderType: Text.NativeRendering
            }
        }

        Rectangle {
            width: parent.width
            height: 52
            radius: 10
            color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.06)
            border.width: 1
            border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.18)

            Column {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Text {
                    text: root.formatStopwatch(CustomTimer.stopwatchElapsedMs)
                    color: CustomTimer.hasStopwatch ? root.stopwatchAccent() : PopoutConfig.textColor
                    opacity: CustomTimer.hasStopwatch ? 1 : 0.55
                    font.pixelSize: 20
                    font.weight: Font.Bold
                    font.family: "monospace"
                    renderType: Text.NativeRendering
                }

                Text {
                    text: CustomTimer.stopwatchState.toUpperCase()
                    color: PopoutConfig.textColor
                    opacity: 0.4
                    font.pixelSize: 8
                    font.weight: Font.DemiBold
                    renderType: Text.NativeRendering
                }
            }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                ActionBtn {
                    label: CustomTimer.stopwatchState === "running"
                        ? "PAUSE" : CustomTimer.stopwatchState === "paused" ? "RESUME" : "START"
                    accent: CustomTimer.stopwatchState === "running"
                        ? Colors.todoPriorityMedium : Colors.todoDateDue
                    width: 66
                    height: 26
                    onTriggered: CustomTimer.toggleStopwatch()
                }

                ActionBtn {
                    label: "RESET"
                    accent: Colors.foregroundRed
                    disabled: !CustomTimer.hasStopwatch
                    width: 60
                    height: 26
                    onTriggered: CustomTimer.resetStopwatch()
                }
            }
        }

        // ── Custom countdown ──
        Item {
            width: parent.width
            height: 14

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "SET COUNTDOWN"
                color: Colors.primary
                opacity: 0.85
                font.pixelSize: 10
                font.weight: Font.Bold
                renderType: Text.NativeRendering
            }
        }

        Row {
            width: parent.width
            height: 30
            spacing: 8

            Rectangle {
                width: 164
                height: parent.height
                radius: 8
                color: Qt.rgba(1, 1, 1, 0.05)
                border.width: 1
                border.color: durationInput.focus
                    ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.65)
                    : Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.20)

                TextInput {
                    id: durationInput
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    color: PopoutConfig.textColor
                    selectionColor: Colors.primary
                    selectedTextColor: PopoutConfig.backgroundColor
                    font.pixelSize: 11
                    verticalAlignment: TextInput.AlignVCenter
                    maximumLength: 20
                    clip: true
                    onAccepted: root.startEnteredTimer()

                    Text {
                        anchors.fill: parent
                        visible: !parent.text && !parent.focus
                        text: "25m · 1:30 · 1h 15m"
                        color: PopoutConfig.textColor
                        opacity: 0.35
                        font.pixelSize: 11
                        verticalAlignment: Text.AlignVCenter
                        renderType: Text.NativeRendering
                    }
                }
            }

            ActionBtn {
                label: CustomTimer.hasTimer ? "REPLACE" : "START"
                accent: Colors.todoDateDue
                disabled: root.enteredDurationSeconds <= 0
                width: parent.width - 172
                height: parent.height
                onTriggered: root.startEnteredTimer()
            }
        }

        // ── Quick add row ──
        Item {
            width: parent.width
            height: 14

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: CustomTimer.hasTimer ? "ADJUST" : "QUICK START"
                color: Colors.primary
                opacity: 0.85
                font.pixelSize: 10
                font.weight: Font.Bold
                renderType: Text.NativeRendering
            }
        }

        Row {
            width: parent.width
            spacing: 6

            ActionBtn {
                label: "+1m"
                accent: Colors.todoDateDue
                onTriggered: {
                    if (CustomTimer.hasTimer) CustomTimer.increaseTimer(60)
                    else CustomTimer.newTimer(1, "notify-send -u critical 'Timer expired.'; pw-play /home/zarred/audio/notifications/soft-4.mp3")
                }
            }
            ActionBtn {
                label: "+5m"
                accent: Colors.todoDateDue
                onTriggered: {
                    if (CustomTimer.hasTimer) CustomTimer.increaseTimer(5 * 60)
                    else CustomTimer.newTimer(5, "notify-send -u critical 'Timer expired.'; pw-play /home/zarred/audio/notifications/soft-4.mp3")
                }
            }
            ActionBtn {
                label: "+15m"
                accent: Colors.todoDateDue
                onTriggered: {
                    if (CustomTimer.hasTimer) CustomTimer.increaseTimer(15 * 60)
                    else CustomTimer.newTimer(15, "notify-send -u critical 'Timer expired.'; pw-play /home/zarred/audio/notifications/soft-4.mp3")
                }
            }
            ActionBtn {
                label: "−1m"
                accent: Colors.todoPriorityMedium
                disabled: !CustomTimer.hasTimer
                onTriggered: CustomTimer.increaseTimer(-60)
            }
            ActionBtn {
                label: "−5m"
                accent: Colors.todoPriorityMedium
                disabled: !CustomTimer.hasTimer
                onTriggered: CustomTimer.increaseTimer(-5 * 60)
            }
        }

        // ── Pause/Cancel row ──
        Row {
            visible: CustomTimer.hasTimer
            width: parent.width
            spacing: 6

            ActionBtn {
                label: CustomTimer.state === "paused" ? "RESUME" : "PAUSE"
                accent: CustomTimer.state === "paused" ? Colors.todoPriorityLow : Colors.todoPriorityMedium
                width: (parent.width - 6) / 2
                onTriggered: CustomTimer.togglePause()
            }
            ActionBtn {
                label: "CANCEL"
                accent: Colors.foregroundRed
                width: (parent.width - 6) / 2
                onTriggered: CustomTimer.cancelTimer()
            }
        }

        // ── Hints footer ──
        Text {
            width: parent.width
            text: CustomTimer.hasTimer
                ? "scroll ±1m · click +15m · right-click pauses timer"
                : CustomTimer.hasStopwatch
                    ? "right-click pause · middle-click reset · click starts a timer"
                    : "scroll to start a 1m timer · click for 15m"
            color: PopoutConfig.textColor
            opacity: 0.40
            font.pixelSize: 10
            horizontalAlignment: Text.AlignHCenter
            renderType: Text.NativeRendering
        }
    }
}
