import QtQuick
import Quickshell.Io
import Quickshell.Widgets
import "../../../services"
import "./"

ClippingRectangle {
  id: root
  required property Item wrapper
  property bool expanded: wrapper && wrapper.hasCurrent && wrapper.currentName === "tooltip-codex-usage"
  property bool hasOwnBackground: true
  property bool dashboardReferenced: false

  readonly property int hPadding: 16
  readonly property int vPadding: 14
  readonly property int contentWidth: 460
  readonly property int maxArchivedReplyHeight: 180

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

  // Ticker drives live "resets in …" countdown and "Xm ago" footer.
  property int _tick: 0
  Timer {
    interval: 30000
    running: root.expanded
    repeat: true
    triggeredOnStart: true
    onTriggered: root._tick++
  }

  Process {
    id: openDashboardProcess
    command: ["xdg-open", PiDashboardStatus.publicUrl]
  }

  function sessionRows(liveRows, archivedRows) {
    var archiveBySession = {}
    var seen = {}
    var rows = []
    var live = Array.isArray(liveRows) ? liveRows : []
    var archived = Array.isArray(archivedRows) ? archivedRows : []

    for (var i = 0; i < archived.length; i++)
      archiveBySession[archived[i].sessionId] = archived[i]

    for (var j = 0; j < live.length; j++) {
      var session = live[j]
      var reply = archiveBySession[session.id]
      seen[session.id] = true
      rows.push({
        id: session.id,
        name: session.name,
        status: session.status,
        model: session.model,
        tool: session.tool,
        archivedText: reply ? reply.text : "",
      })
    }

    // Completed sessions normally leave the dashboard's short working-session
    // list, so retain a compact local row for their dismissed final reply.
    for (var k = archived.length - 1; k >= 0; k--) {
      var item = archived[k]
      if (seen[item.sessionId])
        continue
      rows.push({
        id: item.sessionId,
        name: item.sessionName,
        status: "completed",
        model: "complete",
        tool: "",
        archivedText: item.text,
      })
    }
    return rows
  }

  onExpandedChanged: {
    if (expanded && !dashboardReferenced) {
      PiDashboardStatus.refCount++
      dashboardReferenced = true
    } else if (!expanded && dashboardReferenced) {
      PiDashboardStatus.refCount = Math.max(0, PiDashboardStatus.refCount - 1)
      dashboardReferenced = false
    }
  }

  Component.onDestruction: {
    if (dashboardReferenced)
      PiDashboardStatus.refCount = Math.max(0, PiDashboardStatus.refCount - 1)
  }

  function windowLabel(bucket) {
    if (!bucket) return "—"
    var minutes = Number(bucket.limit_window_minutes || 0)
    if (minutes <= 0) return "Window"
    if (minutes >= 1440) return Math.round(minutes / 1440) + "d window"
    if (minutes >= 60) return Math.round(minutes / 60) + "h window"
    return Math.round(minutes) + "m window"
  }

  function shortReset(bucket) {
    if (!bucket) return ""
    var seconds = Number(bucket.reset_after_seconds || 0)
    if (seconds <= 0) return "soon"
    if (seconds < 60) return "<1m"
    var hours = Math.floor(seconds / 3600)
    var mins = Math.floor((seconds % 3600) / 60)
    if (hours >= 24) {
      var days = Math.floor(hours / 24)
      return days + "d " + (hours % 24) + "h"
    }
    if (hours > 0) return hours + "h " + mins + "m"
    return mins + "m"
  }

  // Pace-aware accent: warn when burn rate outruns the window's linear pace.
  function paceColor(bucket) {
    if (!bucket) return Colors.todoDateNoDue
    var used = Number(bucket.used_percent || 0)
    var remaining = Number(bucket.remaining_percent || 0)
    if (remaining <= 5) return Colors.foregroundRed
    var windowSec = Number(bucket.limit_window_seconds || 0)
    var resetSec = Number(bucket.reset_after_seconds || 0)
    if (windowSec <= 0) {
      if (remaining <= 15) return Colors.foregroundRed
      if (remaining <= 35) return Colors.todoPriorityMedium
      return Colors.foregroundCyan
    }
    var elapsed = Math.max(0, windowSec - resetSec)
    var pace = (elapsed / windowSec) * 100
    var lead = used - pace
    if (lead >= 25 || remaining <= 10) return Colors.foregroundRed
    if (lead >= 10 || remaining <= 25) return Colors.todoPriorityMedium
    return Colors.foregroundCyan
  }

  function freshness() {
    if (CodexUsage.loading) return "refreshing…"
    if (!CodexUsage.lastUpdated) return ""
    var seconds = Math.max(0, Math.floor((Date.now() - CodexUsage.lastUpdated) / 1000))
    if (seconds < 60) return "just now"
    var mins = Math.floor(seconds / 60)
    if (mins < 60) return mins + "m ago"
    var hours = Math.floor(mins / 60)
    if (hours < 24) return hours + "h ago"
    return Math.floor(hours / 24) + "d ago"
  }

  function creditsLabel() {
    var c = CodexUsage.credits
    if (!c) return "Credits —"
    if (c.unlimited) return "Credits unlimited"
    return "Credits " + (c.balance !== undefined && c.balance !== null ? c.balance : "—")
  }

  function durationLabel(milliseconds) {
    var seconds = Math.round(Number(milliseconds || 0) / 1000)
    if (seconds < 60) return seconds + "s"
    if (seconds % 60 === 0) return (seconds / 60) + "m"
    return Math.floor(seconds / 60) + "m " + (seconds % 60) + "s"
  }

  component SettingsToggle: Item {
    id: toggle
    property bool checked: false
    signal toggled(bool nextChecked)

    implicitWidth: 36
    implicitHeight: 20
    opacity: enabled ? 1 : 0.4

    Rectangle {
      anchors.fill: parent
      radius: height / 2
      color: toggle.checked ? PopoutConfig.successColor : "#494354"
      border.width: 1
      border.color: toggle.checked ? PopoutConfig.successColor : "#625b6c"
      Behavior on color { ColorAnimation { duration: 140 } }
    }

    Rectangle {
      width: 14
      height: 14
      radius: 7
      y: 3
      x: toggle.checked ? toggle.width - width - 3 : 3
      color: toggle.checked ? "#14241a" : "#c1bac9"
      Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: toggle.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
      onClicked: if (toggle.enabled) toggle.toggled(!toggle.checked)
    }
  }

  component NotifyToggle: Rectangle {
    id: notifyToggle
    required property string label
    required property string settingKey
    required property bool settingValue

    width: (root.contentWidth - 8) / 2
    height: 32
    radius: 8
    color: Qt.rgba(1, 1, 1, 0.035)
    border.width: 1
    border.color: Qt.rgba(1, 1, 1, 0.065)

    Text {
      anchors.left: parent.left
      anchors.leftMargin: 9
      anchors.verticalCenter: parent.verticalCenter
      text: notifyToggle.label
      color: PopoutConfig.textColor
      opacity: PiNotify.enabled ? 0.82 : 0.4
      font.pixelSize: 11
      font.weight: Font.Medium
      renderType: Text.NativeRendering
    }

    SettingsToggle {
      anchors.right: parent.right
      anchors.rightMargin: 7
      anchors.verticalCenter: parent.verticalCenter
      checked: notifyToggle.settingValue
      enabled: PiNotify.enabled && !PiNotify.saving
      onToggled: function(value) { PiNotify.setSetting(notifyToggle.settingKey, value) }
    }
  }

  component StepButton: Rectangle {
    id: stepButton
    property string symbol: "add"
    signal clicked()

    width: 24
    height: 24
    radius: 7
    color: stepMouse.containsMouse ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.16) : "transparent"
    border.width: 1
    border.color: stepMouse.containsMouse ? Colors.primary : Qt.rgba(1, 1, 1, 0.09)
    opacity: enabled ? 1 : 0.35

    Text {
      anchors.centerIn: parent
      text: stepButton.symbol
      color: PopoutConfig.textColor
      font.family: "Material Symbols Outlined"
      font.pixelSize: 14
      renderType: Text.NativeRendering
    }
    MouseArea {
      id: stepMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: stepButton.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
      onClicked: if (stepButton.enabled) stepButton.clicked()
    }
  }

  component SessionStat: Rectangle {
    id: sessionStat
    required property string label
    required property int value
    property color accent: Colors.primary
    property bool clickable: false
    signal clicked()

    width: (root.contentWidth - 16) / 3
    height: 38
    radius: 9
    color: Qt.rgba(1, 1, 1, 0.035)
    border.width: 1
    border.color: Qt.rgba(sessionStat.accent.r, sessionStat.accent.g, sessionStat.accent.b, 0.18)

    Column {
      anchors.centerIn: parent
      spacing: 1
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: sessionStat.value
        color: sessionStat.accent
        font.pixelSize: 13
        font.weight: Font.Bold
        renderType: Text.NativeRendering
      }
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: sessionStat.label
        color: PopoutConfig.textColor
        opacity: 0.5
        font.pixelSize: 9
        renderType: Text.NativeRendering
      }
    }

    MouseArea {
      anchors.fill: parent
      enabled: sessionStat.clickable
      hoverEnabled: sessionStat.clickable
      cursorShape: Qt.PointingHandCursor
      onClicked: sessionStat.clicked()
    }
  }

  component AbortValueRow: Item {
    id: abortRow
    required property string label
    required property string settingKey
    required property int value
    required property int step
    required property int minimum
    required property int maximum
    property bool durationValue: false

    width: root.contentWidth
    height: 26

    Text {
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      text: abortRow.label
      color: PopoutConfig.textColor
      opacity: PiAbortGuard.enabled ? 0.7 : 0.35
      font.pixelSize: 11
      renderType: Text.NativeRendering
    }
    Row {
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      spacing: 6
      StepButton {
        symbol: "remove"
        enabled: PiAbortGuard.enabled && !PiAbortGuard.saving && abortRow.value > abortRow.minimum
        onClicked: PiAbortGuard.setSetting(abortRow.settingKey, Math.max(abortRow.minimum, abortRow.value - abortRow.step))
      }
      Text {
        width: 54
        anchors.verticalCenter: parent.verticalCenter
        horizontalAlignment: Text.AlignHCenter
        text: abortRow.durationValue ? root.durationLabel(abortRow.value) : abortRow.value + "×"
        color: Colors.primary
        font.pixelSize: 10
        font.weight: Font.DemiBold
        renderType: Text.NativeRendering
      }
      StepButton {
        symbol: "add"
        enabled: PiAbortGuard.enabled && !PiAbortGuard.saving && abortRow.value < abortRow.maximum
        onClicked: PiAbortGuard.setSetting(abortRow.settingKey, Math.min(abortRow.maximum, abortRow.value + abortRow.step))
      }
    }
  }

  component TimingRow: Item {
    id: timingRow
    required property string label
    required property string settingKey
    required property int valueMs
    required property int stepMs

    width: root.contentWidth
    height: 26

    Text {
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      text: timingRow.label
      color: PopoutConfig.textColor
      opacity: PiNotify.enabled ? 0.7 : 0.35
      font.pixelSize: 11
      renderType: Text.NativeRendering
    }
    Row {
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      spacing: 6
      StepButton {
        symbol: "remove"
        enabled: PiNotify.enabled && !PiNotify.saving && timingRow.valueMs >= timingRow.stepMs
        onClicked: PiNotify.setSetting(timingRow.settingKey, Math.max(0, timingRow.valueMs - timingRow.stepMs))
      }
      Text {
        width: 54
        anchors.verticalCenter: parent.verticalCenter
        horizontalAlignment: Text.AlignHCenter
        text: root.durationLabel(timingRow.valueMs)
        color: Colors.primary
        font.pixelSize: 10
        font.weight: Font.DemiBold
        renderType: Text.NativeRendering
      }
      StepButton {
        symbol: "add"
        enabled: PiNotify.enabled && !PiNotify.saving
        onClicked: PiNotify.setSetting(timingRow.settingKey, timingRow.valueMs + timingRow.stepMs)
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    propagateComposedEvents: true
    onEntered: if (root.wrapper && root.wrapper.closeTimer) root.wrapper.closeTimer.stop()
    onClicked: function(mouse) { mouse.accepted = false }
    onExited: if (root.wrapper) root.wrapper.scheduleClose()
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

    // ── General coding-agent header ──
    Item {
      width: parent.width
      height: 22

      Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: "Coding agents"
        color: PopoutConfig.textColor
        font.pixelSize: 14
        font.weight: Font.Bold
        renderType: Text.NativeRendering
      }

      Rectangle {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: notifyState.implicitWidth + 12
        height: 18
        radius: 9
        color: PiNotify.enabled
               ? Qt.rgba(PopoutConfig.successColor.r, PopoutConfig.successColor.g, PopoutConfig.successColor.b, 0.14)
               : Qt.rgba(1, 1, 1, 0.06)
        Text {
          id: notifyState
          anchors.centerIn: parent
          text: PiNotify.saving ? "SAVING" : (PiNotify.enabled ? "NOTIFY ON" : "NOTIFY OFF")
          color: PiNotify.enabled ? PopoutConfig.successColor : PopoutConfig.textColor
          opacity: PiNotify.enabled ? 1 : 0.55
          font.pixelSize: 9
          font.weight: Font.DemiBold
          renderType: Text.NativeRendering
        }
      }
    }

    // ── Codex usage section ──
    Item {
      width: parent.width
      height: 18

      Row {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 7
        Rectangle {
          width: 7
          height: 7
          radius: 4
          anchors.verticalCenter: parent.verticalCenter
          color: CodexUsage.loading
                ? Colors.todoPriorityMedium
                : (CodexUsage.available ? Colors.success : Colors.foregroundRed)
          SequentialAnimation on opacity {
            running: CodexUsage.loading
            loops: Animation.Infinite
            NumberAnimation { to: 0.30; duration: 600; easing.type: Easing.InOutQuad }
            NumberAnimation { to: 0.85; duration: 600; easing.type: Easing.InOutQuad }
          }
        }
        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: "Codex usage"
          color: PopoutConfig.textColor
          opacity: 0.72
          font.pixelSize: 11
          font.weight: Font.DemiBold
          renderType: Text.NativeRendering
        }
      }

      Rectangle {
        visible: CodexUsage.planType.length > 0
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: planText.implicitWidth + 10
        height: 16
        radius: 8
        color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.16)
        Text {
          id: planText
          anchors.centerIn: parent
          text: CodexUsage.planType.toUpperCase()
          color: Colors.primary
          font.pixelSize: 9
          font.weight: Font.DemiBold
          renderType: Text.NativeRendering
        }
      }
    }

    // ── Error state ──
    Text {
      visible: !CodexUsage.available && !CodexUsage.loading
      width: parent.width
      text: CodexUsage.error.length > 0 ? CodexUsage.error : "Codex usage unavailable"
      color: Colors.foregroundRed
      opacity: 0.9
      font.pixelSize: 12
      wrapMode: Text.WordWrap
      renderType: Text.NativeRendering
    }

    // ── Window rows ──
    Repeater {
      model: [CodexUsage.primary, CodexUsage.secondary]
      delegate: Item {
        required property var modelData
        readonly property var bucket: modelData
        readonly property color accent: root.paceColor(bucket)
        readonly property real used: bucket ? Number(bucket.used_percent || 0) : 0

        width: mainColumn.width
        height: bucket ? 44 : 0
        visible: bucket !== null && bucket !== undefined

        Column {
          anchors.fill: parent
          spacing: 5

          Item {
            width: parent.width
            height: 16

            Text {
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
              text: root.windowLabel(bucket)
              color: PopoutConfig.textColor
              opacity: 0.78
              font.pixelSize: 12
              font.weight: Font.Medium
              renderType: Text.NativeRendering
            }

            Text {
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              // Re-read _tick so the countdown ticks live without a refetch.
              text: { var _ = root._tick; return "resets " + root.shortReset(bucket) }
              color: accent
              font.pixelSize: 12
              font.weight: Font.DemiBold
              renderType: Text.NativeRendering
            }
          }

          Rectangle {
            width: parent.width
            height: 6
            radius: 3
            color: Qt.rgba(1, 1, 1, 0.07)

            Rectangle {
              width: parent.width * Math.max(0, Math.min(1, used / 100))
              height: parent.height
              radius: parent.radius
              color: accent
              Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            }
          }

          Text {
            text: Math.round(used) + "% used"
            color: PopoutConfig.textColor
            opacity: 0.5
            font.pixelSize: 10
            renderType: Text.NativeRendering
          }
        }
      }
    }

    // ── Footer: credits · freshness ──
    Item {
      width: parent.width
      height: 14
      visible: CodexUsage.available

      Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: root.creditsLabel()
        color: PopoutConfig.textColor
        opacity: 0.55
        font.pixelSize: 11
        renderType: Text.NativeRendering
      }

      Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: { var _ = root._tick; return root.freshness() }
        color: PopoutConfig.textColor
        opacity: 0.45
        font.pixelSize: 11
        renderType: Text.NativeRendering
      }
    }

    Rectangle {
      width: parent.width
      height: 1
      color: Qt.rgba(1, 1, 1, 0.075)
    }

    // ── Live Pi Dashboard status ──
    Item {
      width: parent.width
      height: 25

      Column {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1
        Text {
          text: "Pi sessions"
          color: PopoutConfig.textColor
          font.pixelSize: 12
          font.weight: Font.DemiBold
          renderType: Text.NativeRendering
        }
        Text {
          text: PiDashboardStatus.available
                ? PiDashboardStatus.connected + " connected · " + PiDashboardStatus.totalSessions + " total"
                : (PiDashboardStatus.loading ? "Checking dashboard…" : "Dashboard unavailable")
          color: PopoutConfig.textColor
          opacity: 0.45
          font.pixelSize: 9
          renderType: Text.NativeRendering
        }
      }

      Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: "open_in_new"
        color: Colors.primary
        font.family: "Material Symbols Outlined"
        font.pixelSize: 16
        renderType: Text.NativeRendering
      }
      MouseArea {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 30
        height: 26
        cursorShape: Qt.PointingHandCursor
        onClicked: openDashboardProcess.running = true
      }
    }

    Row {
      spacing: 8
      SessionStat { label: "Working"; value: PiDashboardStatus.working; accent: Colors.todoPriorityMedium }
      SessionStat {
        label: "Needs you"
        value: PiDashboardStatus.needsAttention
        accent: Colors.primary
        clickable: PiDashboardQuestions.hasItems
        onClicked: {
          var pos = root.wrapper.mapFromItem(sessionStat, sessionStat.width / 2, sessionStat.height)
          root.wrapper.openPopout("pi-dashboard-questions", pos.x, pos.y, sessionStat.width)
        }
      }
      SessionStat { label: "Idle"; value: PiDashboardStatus.idle; accent: PopoutConfig.successColor }
    }

    Item {
      width: parent.width
      height: 25

      Column {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1
        Text {
          text: "Inline final replies"
          color: PopoutConfig.textColor
          font.pixelSize: 12
          font.weight: Font.DemiBold
          renderType: Text.NativeRendering
        }
        Text {
          text: "Show completed agent-message pills in the bar"
          color: PopoutConfig.textColor
          opacity: 0.45
          font.pixelSize: 9
          renderType: Text.NativeRendering
        }
      }

      SettingsToggle {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        checked: PiNotify.showFinalMessagePills
        enabled: PiNotify.ready && !PiNotify.saving
        onToggled: function(value) { PiNotify.setSetting("showFinalMessagePills", value) }
      }
    }

    Item {
      width: parent.width
      height: 25

      Column {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1
        Text {
          text: "Dashboard question listener"
          color: PopoutConfig.textColor
          font.pixelSize: 12
          font.weight: Font.DemiBold
          renderType: Text.NativeRendering
        }
        Text {
          text: "Monitor Pi Dashboard prompts and completed replies"
          color: PopoutConfig.textColor
          opacity: 0.45
          font.pixelSize: 9
          renderType: Text.NativeRendering
        }
      }

      SettingsToggle {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        checked: PiNotify.dashboardQuestionsListenerEnabled
        enabled: PiNotify.ready && !PiNotify.saving
        onToggled: function(value) { PiNotify.setSetting("dashboardQuestionsListenerEnabled", value) }
      }
    }

    Repeater {
      model: root.sessionRows(PiDashboardStatus.sessions, PiDashboardQuestions.archivedFinalMessages)
      delegate: Rectangle {
        id: sessionCard
        required property var modelData
        readonly property string archivedText: modelData.archivedText || ""

        width: mainColumn.width
        height: sessionHeader.height + (archivedText.length > 0 ? archiveColumn.implicitHeight + 13 : 0)
        radius: 8
        color: Qt.rgba(1, 1, 1, archivedText.length > 0 ? 0.045 : 0.03)
        border.width: archivedText.length > 0 ? 1 : 0
        border.color: Qt.rgba(156 / 255, 207 / 255, 216 / 255, 0.16)

        Item {
          id: sessionHeader
          width: parent.width
          height: Math.max(35, sessionName.implicitHeight + 8)

          Rectangle {
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            width: 7
            height: 7
            radius: 4
            color: modelData.status === "needs-you"
              ? Colors.primary
              : modelData.status === "completed" ? PopoutConfig.successColor : Colors.todoPriorityMedium
          }
          Text {
            id: sessionName
            anchors.left: parent.left
            anchors.leftMargin: 23
            anchors.right: sessionModel.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: modelData.name
            color: PopoutConfig.textColor
            opacity: 0.78
            leftPadding: 2
            rightPadding: 2
            topPadding: 4
            bottomPadding: 4
            wrapMode: Text.WordWrap
            font.pixelSize: 16
            font.weight: Font.Bold
            renderType: Text.NativeRendering
          }
          Text {
            id: sessionModel
            anchors.right: parent.right
            anchors.rightMargin: 9
            anchors.verticalCenter: parent.verticalCenter
            text: modelData.tool || modelData.model
            color: modelData.status === "needs-you"
              ? Colors.primary
              : modelData.status === "completed" ? PopoutConfig.successColor : Colors.todoPriorityMedium
            font.pixelSize: 9
            font.weight: Font.DemiBold
            renderType: Text.NativeRendering
          }
        }

        Column {
          id: archiveColumn
          visible: sessionCard.archivedText.length > 0
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: sessionHeader.bottom
          anchors.leftMargin: 10
          anchors.rightMargin: 10
          spacing: 3

          Text {
            text: "LAST REPLY"
            color: "#9ccfd8"
            opacity: 0.72
            font.pixelSize: 9
            font.weight: Font.DemiBold
            renderType: Text.NativeRendering
          }
          Flickable {
            id: archiveFlickable
            width: parent.width
            height: Math.min(root.maxArchivedReplyHeight, archiveReply.implicitHeight)
            implicitHeight: height
            contentWidth: width
            contentHeight: archiveReply.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Text {
              id: archiveReply
              width: archiveFlickable.width
              text: sessionCard.archivedText
              color: PopoutConfig.textColor
              opacity: 0.86
              font.pixelSize: 18
              lineHeight: 1.2
              wrapMode: Text.WordWrap
              textFormat: Text.MarkdownText
              renderType: Text.NativeRendering
            }
          }
        }
      }
    }

    Text {
      visible: PiDashboardStatus.error.length > 0
      width: parent.width
      text: PiDashboardStatus.error
      color: Colors.foregroundRed
      font.pixelSize: 10
      wrapMode: Text.WordWrap
      renderType: Text.NativeRendering
    }

    Rectangle {
      width: parent.width
      height: 1
      color: Qt.rgba(1, 1, 1, 0.075)
    }

    // ── Pi notify controls ──
    Item {
      width: parent.width
      height: 24

      Column {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1
        Text {
          text: "Pi notifications"
          color: PopoutConfig.textColor
          font.pixelSize: 12
          font.weight: Font.DemiBold
          renderType: Text.NativeRendering
        }
        Text {
          text: "Completion alerts for coding-agent sessions"
          color: PopoutConfig.textColor
          opacity: 0.45
          font.pixelSize: 9
          renderType: Text.NativeRendering
        }
      }

      SettingsToggle {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        checked: PiNotify.enabled
        enabled: PiNotify.ready && !PiNotify.saving
        onToggled: function(value) { PiNotify.setSetting("enabled", value) }
      }
    }

    Row {
      spacing: 8
      NotifyToggle { label: "Desktop"; settingKey: "desktop"; settingValue: PiNotify.desktop }
      NotifyToggle { label: "Sound"; settingKey: "sound"; settingValue: PiNotify.sound }
    }
    Row {
      spacing: 8
      NotifyToggle { label: "Spoken alert"; settingKey: "tts"; settingValue: PiNotify.tts }
      NotifyToggle { label: "Visual alert"; settingKey: "visualAlert"; settingValue: PiNotify.visualAlert }
    }

    Column {
      width: parent.width
      spacing: 2
      TimingRow {
        label: "Minimum task duration"
        settingKey: "minDurationMs"
        valueMs: PiNotify.minDurationMs
        stepMs: 1000
      }
      TimingRow {
        label: "Visual alert after"
        settingKey: "visualAlertAfterMs"
        valueMs: PiNotify.visualAlertAfterMs
        stepMs: 15000
      }
      TimingRow {
        label: "Spoken alert after"
        settingKey: "ttsAfterMs"
        valueMs: PiNotify.ttsAfterMs
        stepMs: 60000
      }
    }

    Text {
      visible: PiNotify.error.length > 0
      width: parent.width
      text: PiNotify.error
      color: Colors.foregroundRed
      font.pixelSize: 10
      wrapMode: Text.WordWrap
      renderType: Text.NativeRendering
    }

    Rectangle {
      width: parent.width
      height: 1
      color: Qt.rgba(1, 1, 1, 0.075)
    }

    // ── Pi abort-guard controls ──
    Item {
      width: parent.width
      height: 25

      Column {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1
        Text {
          text: "Abort guard"
          color: PopoutConfig.textColor
          font.pixelSize: 12
          font.weight: Font.DemiBold
          renderType: Text.NativeRendering
        }
        Text {
          text: "Stop and retry stalled model streams"
          color: PopoutConfig.textColor
          opacity: 0.45
          font.pixelSize: 9
          renderType: Text.NativeRendering
        }
      }

      SettingsToggle {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        checked: PiAbortGuard.enabled
        enabled: PiAbortGuard.ready && !PiAbortGuard.saving
        onToggled: function(value) { PiAbortGuard.setSetting("enabled", value) }
      }
    }

    Column {
      width: parent.width
      spacing: 2
      AbortValueRow {
        label: "Model stall timeout"
        settingKey: "modelStallMs"
        value: PiAbortGuard.modelStallMs
        step: 15000
        minimum: 5000
        maximum: 3600000
        durationValue: true
      }
      AbortValueRow {
        label: "Automatic retries"
        settingKey: "maxModelRetries"
        value: PiAbortGuard.maxModelRetries
        step: 1
        minimum: 0
        maximum: 10
      }
    }

    Text {
      visible: PiAbortGuard.error.length > 0
      width: parent.width
      text: PiAbortGuard.error
      color: Colors.foregroundRed
      font.pixelSize: 10
      wrapMode: Text.WordWrap
      renderType: Text.NativeRendering
    }
  }
}
