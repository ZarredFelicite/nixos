import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import "../../../services"
import "./"

ClippingRectangle {
  id: root

  required property Item wrapper
  property bool hasOwnBackground: true
  property bool expanded: wrapper && wrapper.hasCurrent && wrapper.currentName === "calendar-agenda"
  property int _tick: 0
  property string _todayKey: Qt.formatDateTime(new Date(), "yyyy-MM-dd")

  readonly property int contentWidth: 352
  readonly property int hPadding: 16
  readonly property int populatedBodyHeight: Math.min(330, Math.max(110,
    GoogleCalendar.events.length * 58 + root.dayCount() * 32))
  readonly property int bodyHeight: GoogleCalendar.events.length > 0 ? populatedBodyHeight : 138

  implicitWidth: expanded ? contentWidth + hPadding * 2 : 0
  implicitHeight: expanded ? header.height + bodyHeight + footer.height + 2 : 0

  layer.enabled: true
  layer.smooth: false
  color: PopoutConfig.backgroundColor
  border.width: PopoutConfig.borderWidth
  border.color: PopoutConfig.borderColor
  radius: PopoutConfig.cornerRadius
  contentInsideBorder: false

  Behavior on implicitHeight { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

  Timer {
    interval: 60000
    repeat: true
    running: root.expanded
    triggeredOnStart: true
    onTriggered: {
      root._tick++
      var nextKey = Qt.formatDateTime(new Date(), "yyyy-MM-dd")
      if (nextKey !== root._todayKey) {
        root._todayKey = nextKey
        GoogleCalendar.refresh(false)
      }
    }
  }

  function dayCount() {
    var seen = {}
    var count = 0
    for (var i = 0; i < GoogleCalendar.events.length; i++) {
      var key = GoogleCalendar.events[i].dayKey
      if (!seen[key]) {
        seen[key] = true
        count++
      }
    }
    return count
  }

  function eventIsNow(eventData) {
    root._tick
    if (!eventData || eventData.allDay || eventData.endMs <= 0) return false
    var now = Date.now()
    return eventData.startMs <= now && now < eventData.endMs
  }

  component TextButton: Rectangle {
    id: button
    property string label: ""
    property color accent: Colors.primary
    signal triggered

    implicitWidth: buttonText.implicitWidth + 16
    implicitHeight: 24
    radius: 12
    color: buttonMouse.containsMouse
      ? Qt.rgba(accent.r, accent.g, accent.b, 0.22)
      : Qt.rgba(accent.r, accent.g, accent.b, 0.10)
    border.width: 1
    border.color: Qt.rgba(accent.r, accent.g, accent.b, 0.28)

    Behavior on color { ColorAnimation { duration: 120 } }

    Text {
      id: buttonText
      anchors.centerIn: parent
      text: button.label
      color: button.accent
      font.pixelSize: 10
      font.weight: Font.DemiBold
      renderType: Text.NativeRendering
    }

    MouseArea {
      id: buttonMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: button.triggered()
    }
  }

  Item {
    id: header
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: 58

    Column {
      anchors.left: parent.left
      anchors.leftMargin: root.hPadding
      anchors.verticalCenter: parent.verticalCenter
      spacing: 2

      Text {
        text: "Agenda"
        color: PopoutConfig.textColor
        font.pixelSize: 15
        font.weight: Font.Bold
        renderType: Text.NativeRendering
      }

      Text {
        text: {
          root._tick
          return Qt.formatDateTime(new Date(), "dddd, d MMMM")
        }
        color: Colors.todoDateNoDue
        font.pixelSize: 10
        renderType: Text.NativeRendering
      }
    }

    Row {
      anchors.right: parent.right
      anchors.rightMargin: root.hPadding
      anchors.verticalCenter: parent.verticalCenter
      spacing: 8

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: GoogleCalendar.checking ? "Refreshing…" : "Next 7 days"
        color: Colors.todoDateNoDue
        font.pixelSize: 9
        renderType: Text.NativeRendering
      }

      TextButton {
        label: "↻"
        accent: Colors.todoDateDue
        onTriggered: GoogleCalendar.refresh(true)
      }
    }
  }

  Rectangle {
    anchors.top: header.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    height: 1
    color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.14)
  }

  Item {
    id: body
    anchors.top: header.bottom
    anchors.topMargin: 1
    anchors.left: parent.left
    anchors.right: parent.right
    height: root.bodyHeight

    ListView {
      id: eventList
      anchors.fill: parent
      anchors.leftMargin: root.hPadding
      anchors.rightMargin: root.hPadding
      visible: GoogleCalendar.events.length > 0
      clip: true
      model: GoogleCalendar.events
      boundsBehavior: Flickable.StopAtBounds
      spacing: 0
      section.property: "dayLabel"
      section.criteria: ViewSection.FullString
      section.labelPositioning: ViewSection.InlineLabels

      ScrollBar.vertical: ScrollBar {
        policy: eventList.contentHeight > eventList.height
          ? ScrollBar.AsNeeded
          : ScrollBar.AlwaysOff
      }

      section.delegate: Item {
        required property string section
        width: eventList.width
        height: 32

        Text {
          anchors.left: parent.left
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 7
          text: parent.section
          color: Colors.todoDateDue
          font.pixelSize: 10
          font.weight: Font.Bold
          font.capitalization: Font.AllUppercase
          renderType: Text.NativeRendering
        }

        Rectangle {
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          height: 1
          color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.12)
        }
      }

      delegate: Item {
        id: eventRow
        required property var modelData
        width: eventList.width
        height: modelData.location ? 62 : 52

        Rectangle {
          anchors.fill: parent
          anchors.topMargin: 3
          anchors.bottomMargin: 3
          radius: 8
          color: root.eventIsNow(eventRow.modelData)
            ? Qt.rgba(Colors.todoDateDue.r, Colors.todoDateDue.g, Colors.todoDateDue.b, 0.10)
            : "transparent"
        }

        Text {
          id: eventTime
          anchors.left: parent.left
          anchors.top: parent.top
          anchors.topMargin: 11
          width: 92
          text: eventRow.modelData.timeLabel
          color: root.eventIsNow(eventRow.modelData) ? Colors.todoDateDue : Colors.todoDateNoDue
          font.pixelSize: 10
          font.weight: root.eventIsNow(eventRow.modelData) ? Font.Bold : Font.Medium
          renderType: Text.NativeRendering
        }

        Column {
          anchors.left: eventTime.right
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.topMargin: 9
          spacing: 3

          Text {
            width: parent.width
            text: eventRow.modelData.title
            color: PopoutConfig.textColor
            font.pixelSize: 12
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            renderType: Text.NativeRendering
          }

          Text {
            width: parent.width
            visible: eventRow.modelData.location.length > 0
            text: eventRow.modelData.location
            color: Colors.todoDateNoDue
            font.pixelSize: 9
            elide: Text.ElideRight
            renderType: Text.NativeRendering
          }
        }
      }
    }

    Column {
      anchors.centerIn: parent
      width: parent.width - root.hPadding * 2
      spacing: 8
      visible: GoogleCalendar.events.length === 0

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: GoogleCalendar.checking
          ? "󰑐"
          : GoogleCalendar.error
            ? "󰅚"
            : !GoogleCalendar.connected
              ? "󰸗"
              : "󰃭"
        color: GoogleCalendar.error ? PopoutConfig.errorColor : Colors.todoDateDue
        font.pixelSize: 25
        renderType: Text.NativeRendering
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: GoogleCalendar.checking
          ? "Loading your agenda…"
          : GoogleCalendar.error
            ? GoogleCalendar.error
            : !GoogleCalendar.connected
              ? "Google Calendar isn’t connected"
              : "Nothing scheduled for the next 7 days"
        color: PopoutConfig.textColor
        font.pixelSize: 12
        font.weight: Font.DemiBold
        horizontalAlignment: Text.AlignHCenter
        renderType: Text.NativeRendering
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        visible: !GoogleCalendar.checking && !GoogleCalendar.error && !GoogleCalendar.connected
        text: "Connect it from TaskNotes calendar settings"
        color: Colors.todoDateNoDue
        font.pixelSize: 9
        horizontalAlignment: Text.AlignHCenter
        renderType: Text.NativeRendering
      }
    }
  }

  Rectangle {
    anchors.top: body.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    height: 1
    color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.12)
  }

  Item {
    id: footer
    anchors.top: body.bottom
    anchors.topMargin: 1
    anchors.left: parent.left
    anchors.right: parent.right
    height: 38

    Text {
      anchors.left: parent.left
      anchors.leftMargin: root.hPadding
      anchors.verticalCenter: parent.verticalCenter
      text: GoogleCalendar.connected ? "Google Calendar" : "TaskNotes"
      color: Colors.todoDateNoDue
      font.pixelSize: 9
      renderType: Text.NativeRendering
    }

    TextButton {
      anchors.right: parent.right
      anchors.rightMargin: root.hPadding
      anchors.verticalCenter: parent.verticalCenter
      label: "Open Calendar"
      accent: Colors.todoDateDue
      onTriggered: Qt.openUrlExternally("https://calendar.google.com/calendar/u/0/r/agenda")
    }
  }
}
