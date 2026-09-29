import QtQuick
import Quickshell.Io
import "../services"

Item {
    id: root
    objectName: "CodexUsageIndicator"
    property var popouts: null

    readonly property int baseSize: Colors.ringSize
    property real ringThickness: Math.max(1, Colors.ringThickness * 1.05)
    property real splitGapRadians: Math.PI / 18

    implicitWidth: baseSize
    implicitHeight: baseSize
    width: implicitWidth
    height: implicitHeight

    Component.onCompleted: CodexUsage.refCount++
    Component.onDestruction: {
        if (CodexUsage.refCount > 0)
            CodexUsage.refCount--
    }

    readonly property real primaryRemaining: CodexUsage.primary ? Number(CodexUsage.primary.remaining_percent || 0) : -1
    readonly property real secondaryRemaining: CodexUsage.secondary ? Number(CodexUsage.secondary.remaining_percent || 0) : -1
    property real primaryValue: primaryRemaining < 0 ? 0 : Math.max(0, Math.min(1, primaryRemaining / 100))
    property real secondaryValue: secondaryRemaining < 0 ? 0 : Math.max(0, Math.min(1, secondaryRemaining / 100))

    function usageColor(remaining) {
        if (remaining < 0) return Colors.todoDateNoDue
        if (remaining <= 15) return Colors.foregroundRed
        if (remaining <= 35) return Colors.todoPriorityMedium
        return Colors.foregroundCyan
    }

    function openDashboard() {
        dashboardProc.running = false
        dashboardProc.command = ["xdg-open", "https://chatgpt.com/codex/settings/usage"]
        dashboardProc.running = true
    }

    Process {
        id: dashboardProc
        running: false
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        onPaint: {
            const ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            const cx = width / 2
            const cy = height / 2
            const radius = Math.min(width, height) / 2 - root.ringThickness / 2
            const halfSpan = Math.PI - root.splitGapRadians
            ctx.lineWidth = root.ringThickness
            ctx.lineCap = "round"

            function drawArc(startAngle, endAngle, color) {
                ctx.beginPath()
                ctx.strokeStyle = color
                ctx.arc(cx, cy, radius, startAngle, endAngle, false)
                ctx.stroke()
            }

            const leftStart = Math.PI / 2 + root.splitGapRadians / 2
            const leftEnd = 3 * Math.PI / 2 - root.splitGapRadians / 2
            const rightStart = -Math.PI / 2 + root.splitGapRadians / 2
            const rightEnd = Math.PI / 2 - root.splitGapRadians / 2

            drawArc(leftStart, leftEnd, Colors.primaryTransparent)
            drawArc(rightStart, rightEnd, Colors.primaryTransparent)

            if (root.primaryValue > 0) {
                drawArc(leftEnd - (halfSpan * root.primaryValue), leftEnd, root.usageColor(root.primaryRemaining))
            }
            if (root.secondaryValue > 0) {
                drawArc(rightStart, rightStart + (halfSpan * root.secondaryValue), root.usageColor(root.secondaryRemaining))
            }
        }

        Connections {
            target: root
            function onPrimaryValueChanged() { canvas.requestPaint() }
            function onSecondaryValueChanged() { canvas.requestPaint() }
            function onPrimaryRemainingChanged() { canvas.requestPaint() }
            function onSecondaryRemainingChanged() { canvas.requestPaint() }
        }
    }

    Image {
        anchors.centerIn: parent
        width: Math.round(root.baseSize * 0.7)
        height: width
        source: "../assets/openai.svg"
        sourceSize.width: 160
        sourceSize.height: 160
        fillMode: Image.PreserveAspectFit
        smooth: false
        mipmap: false
        opacity: CodexUsage.available ? (CodexUsage.loading ? 0.72 : 0.96) : 0.45
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onEntered: {
            if (root.popouts) {
                var pos = root.popouts.mapFromItem(root, root.width / 2, root.height)
                root.popouts.openPopout("tooltip-codex-usage", pos.x, pos.y, 350)
            }
        }
        onExited: {
            if (root.popouts && root.popouts.currentName === "tooltip-codex-usage") {
                root.popouts.scheduleClose()
            }
        }
        onClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton) {
                CodexUsage.refresh(true)
            } else if (mouse.button === Qt.MiddleButton) {
                root.openDashboard()
            }
        }
    }

    Behavior on primaryValue { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    Behavior on secondaryValue { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
}
