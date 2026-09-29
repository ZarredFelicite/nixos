import QtQuick
import "../services"

// Timer ring: full ring at 60 minutes; shows remaining minutes inside.
// When inactive (standby), shows the timer icon instead of a number.
Item {
  id: root
  property var popouts: null
  // Ensure the timer service updates while this widget is shown
  Component.onCompleted: CustomTimer.refCount++
  Component.onDestruction: CustomTimer.refCount--

  // Sizing consistent with other ring widgets
  readonly property int ringSize: Colors.ringSize
  readonly property real ringThickness: Colors.ringThickness
  width: ringSize
  height: ringSize

  // Prefer the countdown when both tools are active; otherwise show stopwatch progress.
  readonly property bool showingStopwatch: !CustomTimer.hasTimer && CustomTimer.hasStopwatch
  readonly property int minutesRemaining: Math.max(0, Math.ceil((CustomTimer.secondsRemaining || 0) / 60))
  readonly property int stopwatchSecond: Math.floor(CustomTimer.stopwatchElapsedMs / 1000) % 60
  readonly property bool active: CustomTimer.hasTimer || CustomTimer.hasStopwatch
  // Countdown: full ring at 60 minutes. Stopwatch: one revolution per minute.
  readonly property real value: showingStopwatch
    ? (CustomTimer.stopwatchElapsedMs % 60000) / 60000.0
    : CustomTimer.hasTimer
      ? Math.max(0, Math.min(1, (CustomTimer.secondsRemaining || 0) / 3600.0))
      : 0

  // Ring drawing using ProgressRing (full 360deg sweep)
  ProgressRing {
    id: ring
    anchors.fill: parent
    value: root.value
    foregroundColor: CustomTimer.activeState === "paused" ? (Colors.foregroundRed || "#f38ba8") : Colors.foregroundCyan
    backgroundColor: Colors.primaryTransparent
    thickness: root.ringThickness
    startAngle: -90
    sweepAngle: 360
  }

  // Center content: number when active, icon when inactive
  Text {
    id: centerText
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    anchors.horizontalCenterOffset: root.active ? 0 : -1
    text: root.showingStopwatch
      ? String(root.stopwatchSecond)
      : root.active ? String(root.minutesRemaining) : CustomTimer.statusIcon
    color: Colors.primary
    // Larger Nerd Font symbol when inactive; keep numbers compact when active
    font.pixelSize: root.active ? 12 : Math.round(root.ringSize * 0.9)
    font.bold: root.active
  }

  // Interactions match previous TimerIndicator
  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

    onEntered: {
      if (root.popouts) {
        var pos = root.popouts.mapFromItem(root, root.width / 2, root.height)
        root.popouts.openPopout("tooltip-timer", pos.x, pos.y, root.width)
      }
    }
    onExited: {
    }

    onClicked: function(mouse) {
      if (mouse.button === Qt.LeftButton) {
        if (CustomTimer.hasTimer) {
          CustomTimer.increaseTimer(15 * 60)
        } else {
          CustomTimer.newTimer(15, "notify-send -u critical 'Timer expired.'; pw-play /home/zarred/audio/notifications/soft-4.mp3")
        }
      } else if (mouse.button === Qt.RightButton) {
        if (CustomTimer.hasTimer) CustomTimer.togglePause()
        else CustomTimer.toggleStopwatch()
      } else if (mouse.button === Qt.MiddleButton) {
        if (CustomTimer.hasTimer) CustomTimer.cancelTimer()
        else CustomTimer.resetStopwatch()
      }
    }

    onWheel: function(wheel) {
      if (wheel.angleDelta.y > 0) {
        if (CustomTimer.hasTimer) {
          CustomTimer.increaseTimer(60)
        } else {
          CustomTimer.newTimer(1, "notify-send -u critical 'Timer expired.'; pw-play /home/zarred/audio/notifications/soft-4.mp3")
        }
      } else if (wheel.angleDelta.y < 0) {
        CustomTimer.increaseTimer(-60)
      }
      wheel.accepted = true
    }
  }
}
