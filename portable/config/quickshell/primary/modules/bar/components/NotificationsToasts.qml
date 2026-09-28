import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import "../../../services"
import "../popouts"

Item {
    id: root

    readonly property color softBorder: Qt.rgba(147/255, 143/255, 153/255, 0.58)

    implicitWidth: 444
    implicitHeight: Math.min((QsWindow.window?.screen?.height ?? 0) - 72, listView.contentHeight)
    visible: listView.count > 0

    ClippingRectangle {
        anchors.fill: parent
        color: "transparent"
        radius: 12

        ListView {
            id: listView

            anchors.fill: parent
            clip: true
            spacing: 8
            cacheBuffer: QsWindow.window?.screen?.height ?? 0

            model: ScriptModel {
                values: [...Notifs.popups].reverse()
            }

            delegate: Item {
                id: wrapper

                required property Notifs.Notif modelData
                required property int index
                property int idx: index

                onIndexChanged: {
                    if (index !== -1)
                        idx = index
                }

                readonly property bool hasNotif: modelData !== null && modelData !== undefined

                implicitWidth: card.implicitWidth
                implicitHeight: hasNotif ? card.implicitHeight + (idx === 0 ? 0 : 8) : 0

                ListView.onRemove: removeAnim.start()

                SequentialAnimation {
                    id: removeAnim

                    PropertyAction { target: wrapper; property: "ListView.delayRemove"; value: true }
                    PropertyAction { target: wrapper; property: "enabled"; value: false }
                    PropertyAction { target: wrapper; property: "implicitHeight"; value: 0 }
                    NumberAnimation {
                        target: card
                        property: "x"
                        to: card.x >= 0 ? card.width * 2 : -card.width * 2
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                    PropertyAction { target: wrapper; property: "ListView.delayRemove"; value: false }
                }

                Rectangle {
                    id: card

                    anchors.top: parent.top
                    anchors.topMargin: wrapper.idx === 0 ? 0 : 8

                    width: root.implicitWidth
                    radius: 11
                    visible: wrapper.hasNotif
                    color: wrapper.hasNotif && wrapper.modelData.urgency === NotificationUrgency.Critical ? "#40212a" : Colors.bg2
                    border.width: 1
                    border.color: wrapper.hasNotif && wrapper.modelData.urgency === NotificationUrgency.Critical ? Colors.foregroundRed : root.softBorder
                    implicitHeight: cardInner.implicitHeight + 22

                    property int startY: 0

                    RetainableLock {
                        object: wrapper.hasNotif ? wrapper.modelData.notification : null
                        locked: wrapper.hasNotif
                    }

                    Behavior on x {
                        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        preventStealing: true
                        propagateComposedEvents: true
                        drag.target: card
                        drag.axis: Drag.XAxis

                        onPressed: function(mouse) {
                            if (!wrapper.hasNotif) return
                            wrapper.modelData.timer.stop()
                            card.startY = mouse.y
                            if (mouse.button === Qt.MiddleButton)
                                Notifs.dismissNotif(wrapper.modelData)
                        }

                        onReleased: function() {
                            if (!wrapper.hasNotif) return
                            if (!containsMouse)
                                wrapper.modelData.timer.start()

                            if (Math.abs(card.x) < card.width * 0.30)
                                card.x = 0
                            else
                                Notifs.dismissNotif(wrapper.modelData)
                        }

                        onEntered: if (wrapper.hasNotif) wrapper.modelData.timer.stop()
                        onExited: {
                            if (wrapper.hasNotif && !pressed)
                                wrapper.modelData.timer.start()
                        }

                        onClicked: function(mouse) {
                            mouse.accepted = false
                        }
                    }

                    Column {
                        id: cardInner
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 12
                        spacing: 6

                        Row {
                            width: parent.width
                            spacing: 8

                            Text {
                                text: wrapper.hasNotif && wrapper.modelData.appName && wrapper.modelData.appName.length > 0 ? wrapper.modelData.appName : "App"
                                color: Colors.primary
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                                width: parent.width - timeLabel.implicitWidth - closeBtn.width - 20
                                renderType: Text.NativeRendering
                            }

                            Text {
                                id: timeLabel
                                text: wrapper.hasNotif ? wrapper.modelData.timeStr : ""
                                color: Colors.outline
                                font.pixelSize: 11
                                renderType: Text.NativeRendering
                            }

                            Rectangle {
                                id: closeBtn
                                width: 18
                                height: 18
                                radius: 9
                                color: Colors.bg3

                                Text {
                                    anchors.centerIn: parent
                                    text: "x"
                                    color: PopoutConfig.textColor
                                    font.pixelSize: 11
                                    renderType: Text.NativeRendering
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: if (wrapper.hasNotif) Notifs.dismissNotif(wrapper.modelData)
                                }
                            }
                        }

                        Text {
                            text: wrapper.hasNotif ? wrapper.modelData.summary : ""
                            color: PopoutConfig.textColor
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            wrapMode: Text.WordWrap
                            width: parent.width
                            visible: text.length > 0
                            renderType: Text.NativeRendering
                        }

                        Text {
                            text: wrapper.hasNotif ? wrapper.modelData.body : ""
                            color: Colors.surfaceText
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                            width: parent.width
                            visible: text.length > 0
                            textFormat: Text.MarkdownText
                            renderType: Text.NativeRendering
                            onLinkActivated: function(link) {
                                Quickshell.execDetached(["app2unit", "-O", "--", link])
                                if (wrapper.hasNotif) Notifs.dismissNotif(wrapper.modelData)
                            }
                        }

                        Row {
                            spacing: 6
                            visible: wrapper.hasNotif && wrapper.modelData.actions && wrapper.modelData.actions.length > 0

                            Repeater {
                                model: wrapper.hasNotif ? (wrapper.modelData.actions || []) : []

                                Rectangle {
                                    required property var modelData

                                    height: 24
                                    width: Math.min(130, Math.max(56, actionLabel.implicitWidth + 16))
                                    radius: 12
                                    color: Colors.bg3
                                    border.width: 1
                                    border.color: root.softBorder

                                    Text {
                                        id: actionLabel
                                        anchors.centerIn: parent
                                        width: parent.width - 10
                                        horizontalAlignment: Text.AlignHCenter
                                        text: parent.modelData.text
                                        color: PopoutConfig.textColor
                                        font.pixelSize: 11
                                        elide: Text.ElideRight
                                        renderType: Text.NativeRendering
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            parent.modelData.invoke()
                                            if (wrapper.hasNotif) Notifs.dismissNotif(wrapper.modelData)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            move: Transition {
                NumberAnimation {
                    property: "y"
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }

            displaced: Transition {
                NumberAnimation {
                    property: "y"
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}
