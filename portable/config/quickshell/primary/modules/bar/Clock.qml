import QtQuick
import "../../widgets"
import "../../services"

Pill {
    id: clockContainer
    // Allow external popouts to be passed in (for timer tooltip)
    property var popouts: null
    // Asymmetric side padding inside the pill
    property int leftPadding: 4
    property int rightPadding: 7

    Component.onCompleted: GoogleCalendar.refCount++
    Component.onDestruction: GoogleCalendar.refCount--

    // Size to fit contents plus asymmetric side padding
    implicitWidth: contentRow.implicitWidth + leftPadding + rightPadding

    // Use standardized styling from widgets/Pill.qml
    // Hover and color behavior are provided by Pill

    Row {
        id: contentRow
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: (rightPadding - leftPadding) / 2
        spacing: 4
        // Timer ring to the left of the clock, centered to align with others
        Item {
            id: timerRingWrapper
            width: Colors.ringSize
            height: Colors.pillHeight
            anchors.verticalCenter: parent.verticalCenter
            TimerRing {
                id: timerRing
                width: Colors.ringSize
                height: Colors.ringSize
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                popouts: clockContainer.popouts
            }
        }

        // Group clock text and calendar with tighter spacing between them
        Row {
            id: timeGroup
            spacing: 3  // 3px gap between time and calendar
            anchors.verticalCenter: parent.verticalCenter

            // Time text
            Text {
                id: timeText
                anchors.verticalCenter: parent.verticalCenter
                // Inline JS formatter to ensure 12-hour format without AM/PM
                text: (function(){ var d=new Date(); var h=d.getHours()%12; if(h===0) h=12; var m=d.getMinutes(); return h + ":" + (m<10?"0"+m:m); })()
                color: Colors.primary  // primary color clock text
                font.family: "IosevkaTerm NFM"
                font.weight: Font.Bold
                font.pixelSize: Colors.clockFontSize

                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    onTriggered: {
                        var d=new Date(); var h=d.getHours()%12; if(h===0) h=12; var m=d.getMinutes(); timeText.text = h + ":" + (m<10?"0"+m:m);
                    }
                }
            }

            // Calendar icon with day number overlay (right of the clock)
            Item {
                id: calendarIcon
                objectName: "CalendarIcon"
                // Keep visual size the same, but tighten width to glyph
                width: Math.ceil(calendarBg.implicitWidth) + 2
                height: Colors.clockIconSize
                anchors.verticalCenter: parent.verticalCenter

                // Calendar icon background (using Nerd Font icon)
                Text {
                    id: calendarBg
                    anchors.centerIn: parent
                    text: "󰃮"
                    font.pixelSize: Colors.clockIconSize * 0.8
                    color: calendarMouse.containsMouse
                           || (clockContainer.popouts
                               && clockContainer.popouts.currentName === "calendar-agenda")
                        ? Colors.todoDateDue
                        : Colors.primary
                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                // Day number overlay
                Text {
                    id: dayNumber
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: 2  // Slight downward offset
                    text: Qt.formatDateTime(new Date(), "d")
                    color: calendarBg.color
                    font.family: "IosevkaTerm NFM"
                    font.weight: Font.Bold
                    font.pixelSize: Colors.dayNumberFontSize

                    Timer {
                        interval: 60000  // Update every minute (day doesn't change often)
                        running: true
                        repeat: true
                        onTriggered: dayNumber.text = Qt.formatDateTime(new Date(), "d")
                    }
                }

                MouseArea {
                    id: calendarMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    function openAgenda() {
                        if (!clockContainer.popouts) return
                        var pos = clockContainer.popouts.mapFromItem(
                            calendarIcon, calendarIcon.width / 2, calendarIcon.height)
                        clockContainer.popouts.openPopout(
                            "calendar-agenda", pos.x, pos.y, calendarIcon.width)
                    }

                    onEntered: openAgenda()
                    onClicked: {
                        if (!clockContainer.popouts) return
                        if (clockContainer.popouts.hasCurrent
                                && clockContainer.popouts.currentName === "calendar-agenda") {
                            clockContainer.popouts.close()
                            return
                        }
                        openAgenda()
                        GoogleCalendar.refresh(true)
                    }
                }
            }
        }
    }

    Behavior on color {
        ColorAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }
}
