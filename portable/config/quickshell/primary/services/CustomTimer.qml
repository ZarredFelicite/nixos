pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string displayText: "0"
    property string state: "standby"
    property string tooltipText: "No timer set"
    property bool hasTimer: state !== "standby"
    property int secondsRemaining: 0
    property int pausedSecondsRemaining: 0
    property int originalSeconds: 0
    property date expiresAt: new Date(0)
    property string timerAction: ""

    property string stopwatchState: "standby"
    property int stopwatchElapsedMs: 0
    property int stopwatchBaseMs: 0
    property double stopwatchStartedAtMs: 0
    readonly property bool hasStopwatch: stopwatchState !== "standby"
    readonly property string activeState: hasTimer ? state : stopwatchState

    readonly property string statusIcon: {
        switch (activeState) {
            case "running": return "󱫡"
            case "paused": return "󱫟"
            case "standby":
            default: return "󱎫"
        }
    }

    readonly property string stopwatchDisplayText: {
        var totalSeconds = Math.floor(stopwatchElapsedMs / 1000)
        var minutes = Math.floor(totalSeconds / 60)
        var seconds = totalSeconds % 60
        return minutes + ":" + (seconds < 10 ? "0" : "") + seconds
    }

    readonly property string formattedText: hasTimer
        ? `${statusIcon} ${displayText}`
        : hasStopwatch ? `${statusIcon} ${stopwatchDisplayText}` : ""

    property int refCount: 0

    property Process notificationProc: Process {
        running: false
    }

    function sendNotification(summary, body, urgency) {
        notificationProc.running = false
        notificationProc.command = ["notify-send", "-u", urgency || "normal", summary, body || ""]
        notificationProc.running = true
    }

    function newTimer(minutes, action) {
        var mins = parseInt(minutes)
        if (isNaN(mins) || mins <= 0) return
        newTimerSeconds(mins * 60, action)
    }

    function newTimerSeconds(seconds, action) {
        var totalSeconds = parseInt(seconds)
        if (isNaN(totalSeconds) || totalSeconds <= 0) return

        root.state = "running"
        root.secondsRemaining = totalSeconds
        root.originalSeconds = totalSeconds
        root.timerAction = action || "notify-send -u critical 'Timer expired.'"
        root.pausedSecondsRemaining = 0
        root.expiresAt = new Date(Date.now() + totalSeconds * 1000)
        updateDisplay()

        var d = root.expiresAt
        function pad2(n){ return (n<10?"0":"") + n }
        sendNotification("Timer Started", `Timer expires at ${pad2(d.getHours())}:${pad2(d.getMinutes())}`, "low")
    }

    function cancelTimer() {
        root.state = "standby"
        root.secondsRemaining = 0
        root.pausedSecondsRemaining = 0
        root.originalSeconds = 0
        root.expiresAt = new Date(0)
        root.timerAction = ""
        root.displayText = "0"
        root.tooltipText = root.hasStopwatch
            ? (root.stopwatchState === "running" ? "Stopwatch running" : "Stopwatch paused")
            : "No timer set"
    }

    function startStopwatch() {
        root.stopwatchElapsedMs = 0
        root.stopwatchBaseMs = 0
        root.stopwatchStartedAtMs = Date.now()
        root.stopwatchState = "running"
        if (!root.hasTimer) root.tooltipText = "Stopwatch running"
    }

    function toggleStopwatch() {
        if (root.stopwatchState === "standby") {
            startStopwatch()
        } else if (root.stopwatchState === "running") {
            root.stopwatchElapsedMs = root.stopwatchBaseMs
                + Math.max(0, Date.now() - root.stopwatchStartedAtMs)
            root.stopwatchBaseMs = root.stopwatchElapsedMs
            root.stopwatchState = "paused"
            if (!root.hasTimer) root.tooltipText = "Stopwatch paused"
        } else {
            root.stopwatchBaseMs = root.stopwatchElapsedMs
            root.stopwatchStartedAtMs = Date.now()
            root.stopwatchState = "running"
            if (!root.hasTimer) root.tooltipText = "Stopwatch running"
        }
    }

    function resetStopwatch() {
        root.stopwatchState = "standby"
        root.stopwatchElapsedMs = 0
        root.stopwatchBaseMs = 0
        root.stopwatchStartedAtMs = 0
        if (!root.hasTimer) root.tooltipText = "No timer set"
    }

    function togglePause() {
        if (!root.hasTimer) return

        if (root.state === "running") {
            root.state = "paused"
            root.pausedSecondsRemaining = root.secondsRemaining
            root.tooltipText = "Timer paused"
            sendNotification("Timer Paused", "", "low")
        } else if (root.state === "paused") {
            root.state = "running"
            root.secondsRemaining = root.pausedSecondsRemaining
            root.pausedSecondsRemaining = 0
            var d = new Date(Date.now() + root.secondsRemaining * 1000)
            function pad2(n){ return (n<10?"0":"") + n }
            root.tooltipText = `Timer expires at ${pad2(d.getHours())}:${pad2(d.getMinutes())}`
            sendNotification("Timer Resumed", root.tooltipText, "low")
        }
        updateDisplay()
    }

    function increaseTimer(seconds) {
        var delta = parseInt(seconds)
        if (isNaN(delta)) return

        if (!root.hasTimer && delta > 0) {
            newTimer(Math.ceil(delta / 60), "notify-send -u critical 'Timer expired.'; pw-play /home/zarred/audio/notifications/soft-4.mp3")
            return
        }

        if (root.state === "paused") {
            root.pausedSecondsRemaining = Math.max(0, root.pausedSecondsRemaining + delta)
            root.originalSeconds = Math.max(root.originalSeconds, root.pausedSecondsRemaining)
            if (root.pausedSecondsRemaining === 0) {
                cancelTimer()
            }
        } else if (root.state === "running") {
            root.secondsRemaining = Math.max(0, root.secondsRemaining + delta)
            root.originalSeconds = Math.max(root.originalSeconds, root.secondsRemaining)
            if (root.secondsRemaining === 0) {
                cancelTimer()
            } else {
                root.expiresAt = new Date(Date.now() + root.secondsRemaining * 1000)
                var d = root.expiresAt
                function pad2(n){ return (n<10?"0":"") + n }
                root.tooltipText = `Timer expires at ${pad2(d.getHours())}:${pad2(d.getMinutes())}`
            }
        }
        updateDisplay()
    }

    function updateDisplay() {
        var seconds = root.state === "paused" ? root.pausedSecondsRemaining : root.secondsRemaining
        var mins = Math.max(0, Math.ceil(seconds / 60))
        root.displayText = String(mins)
    }

    property Process actionProc: Process {
        running: false
    }

    function executeAction() {
        if (!root.timerAction) return
        actionProc.running = false
        actionProc.command = ["sh", "-c", root.timerAction]
        actionProc.running = true
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.refCount > 0 && root.state === "running" && root.secondsRemaining > 0
        onTriggered: {
            if (root.secondsRemaining > 0) {
                root.secondsRemaining = root.secondsRemaining - 1
                updateDisplay()

                if (root.secondsRemaining <= 0) {
                    executeAction()
                    cancelTimer()
                } else {
                    var d = new Date(Date.now() + root.secondsRemaining * 1000)
                    function pad2(n){ return (n<10?"0":"") + n }
                    root.tooltipText = `Timer expires at ${pad2(d.getHours())}:${pad2(d.getMinutes())}`
                }
            }
        }
    }

    Timer {
        interval: 100
        repeat: true
        running: root.refCount > 0 && root.stopwatchState === "running"
        onTriggered: {
            root.stopwatchElapsedMs = root.stopwatchBaseMs
                + Math.max(0, Date.now() - root.stopwatchStartedAtMs)
        }
    }
}
