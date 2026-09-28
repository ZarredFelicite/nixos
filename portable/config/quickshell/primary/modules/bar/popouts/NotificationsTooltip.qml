import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import "../../../services"

ClippingRectangle {
  id: root

  required property Item wrapper
  property bool hasOwnBackground: true
  readonly property color softBorder: Qt.rgba(147/255, 143/255, 153/255, 0.58)

  readonly property int maxListHeight: 520
  readonly property int listHeight: Math.min(maxListHeight, listView.contentHeight)

  implicitWidth: 430
  implicitHeight: 24 + header.implicitHeight + 10 + (emptyState.visible ? 40 : listHeight)

  color: PopoutConfig.backgroundColor
  border.width: PopoutConfig.borderWidth
  border.color: PopoutConfig.borderColor
  radius: PopoutConfig.cornerRadius
  contentInsideBorder: true

  layer.enabled: true
  layer.smooth: false

  Column {
    anchors.fill: parent
    anchors.margins: 12
    spacing: 10

    Row {
      id: header
      width: parent.width
      spacing: 8

      Text {
        text: "Notifications"
        color: PopoutConfig.textColor
        font.pixelSize: 15
        font.weight: Font.DemiBold
        renderType: Text.NativeRendering
      }

      Text {
        text: Notifs.list.length > 0 ? `(${Notifs.list.length})` : ""
        color: Colors.outline
        font.pixelSize: 12
        renderType: Text.NativeRendering
      }

      Item {
        width: parent.width - clearButton.width - 130
        height: 1
      }

      Rectangle {
        id: clearButton
        width: clearLabel.implicitWidth + 16
        height: 24
        radius: 12
        color: Colors.bg3
        border.width: 1
        border.color: Colors.outline
        visible: Notifs.list.length > 0

        Text {
          id: clearLabel
          anchors.centerIn: parent
          text: "Clear all"
          color: PopoutConfig.textColor
          font.pixelSize: 11
          renderType: Text.NativeRendering
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: Notifs.clearAll()
        }
      }
    }

    Text {
      id: emptyState
      visible: Notifs.list.length === 0
      width: parent.width
      horizontalAlignment: Text.AlignHCenter
      text: "No active notifications"
      color: Colors.outline
      font.pixelSize: 12
      renderType: Text.NativeRendering
    }

    ListView {
      id: listView
      visible: Notifs.list.length > 0
      width: parent.width
      height: root.listHeight
      clip: true
      spacing: 8

      model: ScriptModel {
        values: [...Notifs.list].reverse()
      }

      delegate: Rectangle {
        id: card

        required property var modelData
        property bool expanded: false
        property int startY: 0
        readonly property bool hasLongContent: ((modelData.summary ? modelData.summary.length : 0)
                                              + (modelData.body ? modelData.body.length : 0)) > 120
                                               || (modelData.body && modelData.body.indexOf("\n") !== -1)

        width: listView.width
        radius: 11
        color: card.modelData.urgency === NotificationUrgency.Critical ? "#40212a" : Colors.bg2
        border.width: 1
        border.color: card.modelData.urgency === NotificationUrgency.Critical ? Colors.foregroundRed : root.softBorder
        implicitHeight: cardInner.implicitHeight + 14

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
            card.modelData.timer.stop();
            card.startY = mouse.y;
            if (mouse.button === Qt.MiddleButton)
              Notifs.dismissNotif(card.modelData);
          }

          onReleased: function() {
            if (!containsMouse)
              card.modelData.timer.start();

            if (Math.abs(card.x) < card.width * 0.30) {
              card.x = 0;
            } else {
              Notifs.dismissNotif(card.modelData);
            }
          }

          onPositionChanged: function(mouse) {
            if (pressed) {
              const diffY = mouse.y - card.startY;
              if (Math.abs(diffY) > 20)
                card.expanded = diffY > 0;
            }
          }

          onEntered: card.modelData.timer.stop()
          onExited: {
            if (!pressed)
              card.modelData.timer.start();
          }

          onClicked: function(mouse) {
            mouse.accepted = false;
          }
        }

        Column {
          id: cardInner
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.margins: 10
          spacing: 6

          Row {
            width: parent.width
            spacing: 8

            Text {
              text: card.modelData.appName && card.modelData.appName.length > 0 ? card.modelData.appName : "App"
              color: Colors.primary
              font.pixelSize: 12
              font.weight: Font.DemiBold
              elide: Text.ElideRight
              width: parent.width - timeLabel.implicitWidth - controls.implicitWidth - 24
              renderType: Text.NativeRendering
            }

            Text {
              id: timeLabel
              text: card.modelData.timeStr
              color: Colors.outline
              font.pixelSize: 11
              renderType: Text.NativeRendering
            }

            Row {
              id: controls
              spacing: 4

              Rectangle {
                width: 18
                height: 18
                radius: 9
                color: Colors.bg3

                Text {
                  anchors.centerIn: parent
                  text: card.expanded ? "-" : "+"
                  color: PopoutConfig.textColor
                  font.pixelSize: 12
                  renderType: Text.NativeRendering
                }

                visible: card.hasLongContent

                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: card.expanded = !card.expanded
                }
              }

              Rectangle {
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
                  onClicked: Notifs.dismissNotif(card.modelData)
                }
              }
            }
          }

          Text {
            text: card.modelData.summary
            color: PopoutConfig.textColor
            font.pixelSize: 13
            font.weight: Font.Medium
            wrapMode: Text.WordWrap
            width: parent.width
            visible: text.length > 0
            maximumLineCount: (card.expanded || !card.hasLongContent) ? 6 : 1
            elide: Text.ElideRight
            renderType: Text.NativeRendering
          }

          Text {
            text: card.modelData.body
            color: Colors.surfaceText
            font.pixelSize: 12
            wrapMode: Text.WordWrap
            width: parent.width
            visible: (card.expanded || !card.hasLongContent) && text.length > 0
            textFormat: Text.MarkdownText
            renderType: Text.NativeRendering
            onLinkActivated: function(link) {
              Quickshell.execDetached(["app2unit", "-O", "--", link]);
              Notifs.dismissNotif(card.modelData);
            }
          }

          Row {
            spacing: 6
            visible: (card.expanded || !card.hasLongContent) && card.modelData.actions && card.modelData.actions.length > 0

            Repeater {
              model: card.modelData.actions || []

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
                    parent.modelData.invoke();
                    Notifs.dismissNotif(card.modelData);
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
