pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../../../services"

Item {
  id: root

  readonly property int revision: Notifs.messengerRevision
  readonly property var conversations: [revision, Notifs.messengerConversations()][1]
  readonly property int maxVisibleHeight: 300
  readonly property int maxVisibleMessagesPerConversation: 20
  readonly property color softBorder: Qt.rgba(147/255, 143/255, 153/255, 0.34)

  visible: conversations.length > 0
  implicitHeight: visible ? header.implicitHeight + 8 + historyList.height : 0

  Row {
    id: header
    width: parent.width
    height: 24
    spacing: 8

    Text {
      text: "Messenger history"
      color: PopoutConfig.textColor
      font.pixelSize: 13
      font.weight: Font.DemiBold
      renderType: Text.NativeRendering
    }

    Text {
      text: `(${root.conversations.length})`
      color: Colors.outline
      font.pixelSize: 11
      anchors.verticalCenter: parent.verticalCenter
      renderType: Text.NativeRendering
    }
  }

  ListView {
    id: historyList
    anchors.top: header.bottom
    anchors.topMargin: 8
    width: parent.width
    height: Math.min(root.maxVisibleHeight, contentHeight)
    clip: true
    spacing: 6
    model: ScriptModel { values: root.conversations }

    delegate: Column {
      id: conversationBlock

      required property var modelData
      width: historyList.width
      spacing: 5
      property bool expanded: false
      property int visibleCount: 4
      readonly property var messages: conversationBlock.modelData.messages || []
      readonly property var visibleMessages: messages.slice(0, Math.min(
        conversationBlock.visibleCount, root.maxVisibleMessagesPerConversation))

      Rectangle {
        id: conversationCard
        width: parent.width
        radius: 11
        color: conversationMouse.containsMouse ? Colors.bg3 : Colors.bg2
        border.width: 1
        border.color: root.softBorder
        implicitHeight: cardContent.implicitHeight + 18

        Column {
          id: cardContent
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.margins: 9
          spacing: 6

          Row {
            width: parent.width
            spacing: 8

            Item {
              width: parent.width - clearButton.width - expandButton.width - 16
              height: 22

              Text {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: conversationBlock.modelData.label
                color: Colors.primary
                font.pixelSize: 12
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                renderType: Text.NativeRendering
              }

              MouseArea {
                id: conversationMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: conversationBlock.expanded = !conversationBlock.expanded
              }
            }

            Rectangle {
              id: expandButton
              width: 22
              height: 22
              radius: 11
              color: expandMouse.containsMouse ? Colors.bg3 : "transparent"
              border.width: 1
              border.color: root.softBorder

              Text {
                anchors.centerIn: parent
                text: conversationBlock.expanded ? "−" : "+"
                color: PopoutConfig.textColor
                font.pixelSize: 13
                renderType: Text.NativeRendering
              }

              MouseArea {
                id: expandMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: conversationBlock.expanded = !conversationBlock.expanded
              }
            }

            Rectangle {
              id: clearButton
              width: 42
              height: 22
              radius: 11
              color: clearMouse.containsMouse ? Colors.bg3 : "transparent"
              border.width: 1
              border.color: root.softBorder

              Text {
                anchors.centerIn: parent
                text: "Clear"
                color: Colors.outline
                font.pixelSize: 10
                font.weight: Font.Medium
                renderType: Text.NativeRendering
              }

              MouseArea {
                id: clearMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Notifs.clearMessengerConversation(conversationBlock.modelData.key)
              }
            }
          }

          Text {
            width: parent.width
            visible: !conversationBlock.expanded
            text: conversationBlock.messages.length > 0
              ? conversationBlock.messages[0].body : ""
            color: Colors.surfaceText
            font.pixelSize: 11
            wrapMode: Text.WordWrap
            maximumLineCount: conversationBlock.expanded ? 2 : 1
            elide: Text.ElideRight
            renderType: Text.NativeRendering
          }

          Column {
            width: parent.width
            spacing: 5
            visible: conversationBlock.expanded

            Repeater {
              model: conversationBlock.visibleMessages

              Rectangle {
                required property var modelData
                width: conversationBlock.width - 18
                radius: 8
                color: Colors.bg1
                implicitHeight: messageContent.implicitHeight + 12

                Column {
                  id: messageContent
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.top: parent.top
                  anchors.margins: 6
                  spacing: 2

                  Row {
                    width: parent.width
                    spacing: 6

                    Text {
                      text: parent.parent.parent.modelData.sender
                      color: Colors.outline
                      font.pixelSize: 10
                      elide: Text.ElideRight
                      width: parent.width - messageTime.implicitWidth - 6
                      renderType: Text.NativeRendering
                    }

                    Text {
                      id: messageTime
                      text: Qt.formatDateTime(new Date(parent.parent.parent.modelData.time), "MMM d, h:mm AP")
                      color: Colors.outline
                      font.pixelSize: 9
                      renderType: Text.NativeRendering
                    }
                  }

                  Text {
                    id: messageText
                    width: parent.width
                    text: parent.parent.modelData.body
                    color: Colors.surfaceText
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                    renderType: Text.NativeRendering
                  }
                }
              }
            }

            Rectangle {
              width: parent.width
              height: 22
              radius: 11
              visible: conversationBlock.messages.length > conversationBlock.visibleMessages.length
              color: olderMouse.containsMouse ? Colors.bg3 : "transparent"
              border.width: 1
              border.color: root.softBorder

              Text {
                anchors.centerIn: parent
                text: `Show ${Math.min(conversationBlock.messages.length,
                  root.maxVisibleMessagesPerConversation) - conversationBlock.visibleMessages.length} older`
                color: Colors.outline
                font.pixelSize: 10
                renderType: Text.NativeRendering
              }

              MouseArea {
                id: olderMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: conversationBlock.visibleCount = Math.min(
                  root.maxVisibleMessagesPerConversation,
                  conversationBlock.visibleCount + 4)
              }
            }
          }
        }
      }
    }
  }
}
