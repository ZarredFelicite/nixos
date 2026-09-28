import QtQuick
import QtQuick.Layouts 1.15
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import "../../../services"
import "../../../widgets"

Pill {
    id: root

    property var popouts: null
    property Notifs.Notif notif: Notifs.inlineNotifications.length > 0
        ? Notifs.inlineNotifications[Notifs.inlineNotifications.length - 1]
        : null

    readonly property string summaryText: notif ? Notifs.compactText(notif.summary) : ""
    readonly property string bodyText: notif ? Notifs.compactText(notif.body) : ""
    readonly property string displayText: {
        if (summaryText && bodyText)
            return `${summaryText} — ${bodyText}`
        return summaryText || bodyText
    }
    readonly property bool isCritical: notif && notif.urgency === NotificationUrgency.Critical
    readonly property color lightBg: isCritical ? "#f6c177" : Qt.rgba(196 / 255, 167 / 255, 231 / 255, 1.0)
    readonly property color lightBgInner: lightBg
    readonly property color lightBorder: lightBg
    readonly property color titleColor: "#16141d"
    readonly property color bodyColor: "#1d1926"
    readonly property color chipColor: Qt.rgba(196 / 255, 167 / 255, 231 / 255, 0.20)
    readonly property color chipBorder: Qt.rgba(196 / 255, 167 / 255, 231 / 255, 0.36)

    implicitHeight: Colors.pillHeight
    implicitWidth: visible ? Math.min(340, Math.max(110, label.implicitWidth + 20)) : 0
    Layout.preferredWidth: implicitWidth
    Layout.maximumWidth: implicitWidth
    Layout.alignment: Qt.AlignVCenter
    visible: !!notif && notif.popup && displayText.length > 0
    color: lightBg
    border.color: lightBorder
    border.width: 1

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: parent.cornerRadius - 1
        color: lightBgInner
        border.width: 0
        z: -1
    }

    RetainableLock {
        object: root.notif ? root.notif.notification : null
        locked: root.visible
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 6

        Text {
            id: label
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            text: root.displayText
            color: root.summaryText && root.bodyText ? root.bodyColor : root.titleColor
            font.pixelSize: 14
            font.weight: Font.Bold
            elide: Text.ElideRight
            wrapMode: Text.NoWrap
            maximumLineCount: 1
            renderType: Text.NativeRendering
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        hoverEnabled: true
        propagateComposedEvents: true
        onEntered: if (root.notif && !root.notif.persistent) root.notif.timer.stop()
        onExited: if (root.notif && !root.notif.persistent) root.notif.timer.start()
        onClicked: function(mouse) {
            if (!root.notif)
                return

            if (mouse.button === Qt.LeftButton && root.popouts) {
                const pos = root.popouts.mapFromItem(root, root.width / 2, root.height)
                root.popouts.openPopout("notifications", pos.x, pos.y, root.width)
            } else if (mouse.button === Qt.MiddleButton || mouse.button === Qt.RightButton) {
                root.notif.notification.dismiss()
            }
        }
    }
}
