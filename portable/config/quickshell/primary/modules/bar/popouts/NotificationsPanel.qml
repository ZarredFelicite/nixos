import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import "../../../services"

ClippingRectangle {
  id: root

  required property Item wrapper
  property bool hasOwnBackground: true
  readonly property color softBorder: Qt.rgba(147/255, 143/255, 153/255, 0.34)
  readonly property int panelHeight: Math.max(520, (wrapper ? wrapper.height : 760) - 52)
  readonly property int revision: Notifs.revision
  readonly property var sections: [revision, (Notifs.recencySections() || [])][1]
  property var selectedNotif: null
  property var rowItems: []

  implicitWidth: 540
  implicitHeight: panelHeight

  color: PopoutConfig.backgroundColor
  border.width: PopoutConfig.borderWidth
  border.color: PopoutConfig.borderColor
  radius: PopoutConfig.cornerRadius
  contentInsideBorder: true

  layer.enabled: true
  layer.smooth: false

  focus: true

  function flatNotifications(): var {
    const out = [];
    for (const section of (root.sections || [])) {
      for (const stack of (section.stacks || [])) {
        for (const notif of (stack.items || []))
          out.push(notif);
      }
    }
    return out;
  }

  function selectedIndex(): int {
    return flatNotifications().indexOf(root.selectedNotif);
  }

  function syncSelected(): void {
    const items = flatNotifications();
    if (items.length === 0) {
      root.selectedNotif = null;
      return;
    }

    if (items.indexOf(root.selectedNotif) < 0)
      root.selectedNotif = items[0];
  }

  function scrollToSelected(): void {
    if (!root.selectedNotif)
      return;

    for (let i = 0; i < root.sections.length; i++) {
      for (const stack of root.sections[i].stacks) {
        if (stack.items.indexOf(root.selectedNotif) >= 0) {
          senderList.positionViewAtIndex(i, ListView.Contain);
          return;
        }
      }
    }
  }

  function selectRelative(delta): void {
    const items = flatNotifications();
    if (items.length === 0)
      return;

    let idx = items.indexOf(root.selectedNotif);
    if (idx < 0)
      idx = 0;
    else
      idx = Math.max(0, Math.min(items.length - 1, idx + delta));

    root.selectedNotif = items[idx];
    scrollToSelected();
  }

  function dismissSelected(): void {
    if (root.selectedNotif)
      Notifs.dismissNotif(root.selectedNotif);
  }

  function clearSelectedSender(): void {
    if (root.selectedNotif)
      Notifs.clearSender(Notifs.senderKey(root.selectedNotif));
  }

  function toggleSelectedExpanded(): void {
    if (!root.selectedNotif)
      return;

    for (let i = 0; i < root.rowItems.length; i++) {
      const item = root.rowItems[i];
      if (item && item.modelData === root.selectedNotif) {
        item.expanded = !item.expanded;
        return;
      }
    }
  }

  function invokeSelectedAction(index): void {
    if (!root.selectedNotif || !root.selectedNotif.actions || root.selectedNotif.actions.length <= index)
      return;

    root.selectedNotif.actions[index].invoke();
    Notifs.dismissNotif(root.selectedNotif);
  }

  onRevisionChanged: syncSelected()
  Component.onCompleted: {
    syncSelected();
    forceActiveFocus();
  }

  Keys.onPressed: function(event) {
    if (event.key === Qt.Key_Escape) {
      root.wrapper.close();
      event.accepted = true;
    } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
      root.selectRelative(1);
      event.accepted = true;
    } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
      root.selectRelative(-1);
      event.accepted = true;
    } else if (event.key === Qt.Key_PageDown) {
      root.selectRelative(5);
      event.accepted = true;
    } else if (event.key === Qt.Key_PageUp) {
      root.selectRelative(-5);
      event.accepted = true;
    } else if (event.key === Qt.Key_Home) {
      const items = root.flatNotifications();
      if (items.length > 0) root.selectedNotif = items[0];
      root.scrollToSelected();
      event.accepted = true;
    } else if (event.key === Qt.Key_End) {
      const items = root.flatNotifications();
      if (items.length > 0) root.selectedNotif = items[items.length - 1];
      root.scrollToSelected();
      event.accepted = true;
    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
      root.toggleSelectedExpanded();
      event.accepted = true;
    } else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
      root.invokeSelectedAction(event.key - Qt.Key_1);
      event.accepted = true;
    } else if (event.key === Qt.Key_Delete || event.key === Qt.Key_Backspace) {
      if (event.modifiers & Qt.ShiftModifier)
        root.clearSelectedSender();
      else
        root.dismissSelected();
      event.accepted = true;
    } else if (event.key === Qt.Key_C && (event.modifiers & Qt.ControlModifier)) {
      Notifs.clearAll();
      event.accepted = true;
    }
  }

  Column {
    anchors.fill: parent
    anchors.margins: 16
    spacing: 14

    Row {
      id: header
      width: parent.width
      height: 34
      spacing: 10

      Column {
        width: parent.width - clearAllButton.width - 12
        spacing: 2

        Text {
          text: "Notifications"
          color: PopoutConfig.textColor
          font.pixelSize: 18
          font.weight: Font.DemiBold
          renderType: Text.NativeRendering
        }

        Text {
          text: Notifs.list.length > 0
            ? `${Notifs.list.length} saved • newest first • stacked by recurring type`
            : "Nothing saved"
          color: Colors.outline
          font.pixelSize: 11
          renderType: Text.NativeRendering
        }
      }

      Rectangle {
        id: clearAllButton
        width: 82
        height: 28
        radius: 14
        color: clearAllMouse.containsMouse ? Colors.bg3 : Colors.bg2
        border.width: 1
        border.color: root.softBorder
        visible: Notifs.list.length > 0

        Text {
          anchors.centerIn: parent
          text: "Clear all"
          color: PopoutConfig.textColor
          font.pixelSize: 11
          font.weight: Font.Medium
          renderType: Text.NativeRendering
        }

        MouseArea {
          id: clearAllMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: Notifs.clearAll()
        }
      }
    }

    Rectangle {
      width: parent.width
      height: 1
      color: root.softBorder
    }

    Item {
      id: body
      width: parent.width
      height: parent.height - header.height - 15 - 1

      Loader {
        id: messengerHistory
        width: parent.width
        height: item ? item.implicitHeight : 0
        source: "MessengerHistory.qml"
      }

      Column {
        anchors.centerIn: parent
        spacing: 8
        visible: Notifs.list.length === 0

        Text {
          width: body.width
          horizontalAlignment: Text.AlignHCenter
          text: "No notification history"
          color: PopoutConfig.textColor
          font.pixelSize: 14
          font.weight: Font.Medium
          renderType: Text.NativeRendering
        }

        Text {
          width: body.width
          horizontalAlignment: Text.AlignHCenter
          text: "New alerts will be saved here by recency."
          color: Colors.outline
          font.pixelSize: 12
          renderType: Text.NativeRendering
        }
      }

      ListView {
        id: senderList
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: messengerHistory.bottom
        anchors.topMargin: messengerHistory.item && messengerHistory.item.visible ? 12 : 0
        anchors.bottom: parent.bottom
        visible: Notifs.list.length > 0
        clip: true
        spacing: 16
        model: ScriptModel { values: root.sections }

        delegate: Column {
          id: section

          required property var modelData
          width: senderList.width
          spacing: 10

          Row {
            width: parent.width
            height: 24
            spacing: 8

            Rectangle {
              width: 5
              height: 18
              radius: 3
              color: Colors.primary
              anchors.verticalCenter: parent.verticalCenter
            }

            Text {
              text: section.modelData.label
              color: PopoutConfig.textColor
              font.pixelSize: 14
              font.weight: Font.DemiBold
              renderType: Text.NativeRendering
            }

            Text {
              text: `${section.modelData.count} notification${section.modelData.count === 1 ? "" : "s"} • ${section.modelData.stacks.length} stack${section.modelData.stacks.length === 1 ? "" : "s"}`
              color: Colors.outline
              font.pixelSize: 10
              anchors.verticalCenter: parent.verticalCenter
              renderType: Text.NativeRendering
            }
          }

          Column {
            width: parent.width
            spacing: 10

            Repeater {
              model: section.modelData.stacks

              Column {
                id: stackBlock

                required property var modelData
                property bool stackExpanded: false
                readonly property var visibleItems: stackExpanded
                  ? modelData.items
                  : modelData.items.slice(0, Math.min(3, modelData.items.length))

                width: section.width
                spacing: 6

                Row {
                  width: parent.width
                  height: stackBlock.modelData.count > 1 ? 25 : 0
                  visible: stackBlock.modelData.count > 1
                  spacing: 8

                  Text {
                    width: parent.width - clearStackButton.width - 16
                    text: `${stackBlock.modelData.label}  ·  ${stackBlock.modelData.count}`
                    color: Colors.primary
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    anchors.verticalCenter: parent.verticalCenter
                    renderType: Text.NativeRendering
                  }

                  Rectangle {
                    id: clearStackButton
                    width: 54
                    height: 22
                    radius: 11
                    color: clearStackMouse.containsMouse ? Colors.bg3 : "transparent"
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
                      id: clearStackMouse
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onClicked: Notifs.clearStack(stackBlock.modelData.items)
                    }
                  }
                }

                Column {
                  width: parent.width
                  spacing: stackBlock.modelData.count > 1 && !stackBlock.stackExpanded ? -5 : 6

                  Repeater {
                    model: stackBlock.visibleItems

                    Rectangle {
                      id: row

                      required property var modelData
                      required property int index
                      property bool expanded: false
                      readonly property bool inStack: stackBlock.modelData.count > 1
                      readonly property bool stackedPreview: inStack && !stackBlock.stackExpanded

                      x: stackedPreview ? index * 8 : 0
                      width: stackBlock.width - (stackedPreview ? index * 8 : 0)
                      implicitHeight: notificationContent.implicitHeight + 18
                      Component.onCompleted: root.rowItems = root.rowItems.concat([row])
                      Component.onDestruction: root.rowItems = root.rowItems.filter(function(item) { return item !== row })
                      radius: 12
                      opacity: stackedPreview ? Math.max(0.78, 1 - index * 0.08) : 1
                      z: 10 - index
                      color: root.selectedNotif === row.modelData
                        ? Qt.rgba(196/255, 167/255, 231/255, 0.13)
                        : (rowMouse.containsMouse ? Colors.bg3 : Colors.bg2)
                      border.width: root.selectedNotif === row.modelData ? 2 : 1
                      border.color: root.selectedNotif === row.modelData
                        ? Colors.primary
                        : (row.modelData.urgency === NotificationUrgency.Critical ? Colors.foregroundRed : root.softBorder)

                      MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        propagateComposedEvents: true
                        onClicked: function(mouse) {
                          root.selectedNotif = row.modelData;
                          root.forceActiveFocus();
                          if (mouse.button === Qt.MiddleButton) {
                            Notifs.dismissNotif(row.modelData);
                          } else if (row.stackedPreview && stackBlock.modelData.count > 1) {
                            stackBlock.stackExpanded = true;
                          } else {
                            row.expanded = !row.expanded;
                            mouse.accepted = false;
                          }
                        }
                      }

                      Column {
                        id: notificationContent
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 9
                        spacing: 6

                        Row {
                          width: parent.width
                          spacing: 8

                          Text {
                            width: parent.width - timeText.implicitWidth - closeButton.width - 18
                            text: row.inStack && row.modelData.body
                              ? Notifs.truncateText(row.modelData.body, 110)
                              : Notifs.truncateText(row.modelData.summary || "Notification", 120)
                            color: PopoutConfig.textColor
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                            renderType: Text.NativeRendering
                          }

                          Text {
                            id: timeText
                            text: row.modelData.timeStr
                            color: Colors.outline
                            font.pixelSize: 10
                            renderType: Text.NativeRendering
                          }

                          Rectangle {
                            id: closeButton
                            width: 18
                            height: 18
                            radius: 9
                            color: closeMouse.containsMouse ? Colors.bg2 : "transparent"

                            Text {
                              anchors.centerIn: parent
                              text: "×"
                              color: Colors.outline
                              font.pixelSize: 13
                              renderType: Text.NativeRendering
                            }

                            MouseArea {
                              id: closeMouse
                              anchors.fill: parent
                              hoverEnabled: true
                              cursorShape: Qt.PointingHandCursor
                              onClicked: Notifs.dismissNotif(row.modelData)
                            }
                          }
                        }

                        Text {
                          width: parent.width
                          text: Notifs.truncateText(row.modelData.body, row.expanded ? 900 : 260)
                          visible: text.length > 0 && (!row.inStack || row.expanded)
                          color: Colors.surfaceText
                          font.pixelSize: 12
                          lineHeight: 1.15
                          wrapMode: Text.WordWrap
                          maximumLineCount: row.expanded ? 10 : 2
                          elide: Text.ElideRight
                          textFormat: Text.MarkdownText
                          renderType: Text.NativeRendering
                          onLinkActivated: function(link) {
                            Quickshell.execDetached(["app2unit", "-O", "--", link]);
                            Notifs.dismissNotif(row.modelData);
                          }
                        }

                        Row {
                          spacing: 6
                          visible: row.modelData.actions && row.modelData.actions.length > 0

                          Repeater {
                            model: row.modelData.actions || []

                            Rectangle {
                              required property var modelData
                              required property int index

                              height: 24
                              width: Math.min(142, Math.max(64, actionText.implicitWidth + 18))
                              radius: 12
                              color: actionMouse.containsMouse ? Colors.bg3 : Colors.bg2
                              border.width: 1
                              border.color: root.softBorder

                              Text {
                                id: actionText
                                anchors.centerIn: parent
                                width: parent.width - 10
                                horizontalAlignment: Text.AlignHCenter
                                text: `${parent.index + 1} ${parent.modelData.text}`
                                color: PopoutConfig.textColor
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                renderType: Text.NativeRendering
                              }

                              MouseArea {
                                id: actionMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                  parent.modelData.invoke();
                                  Notifs.dismissNotif(row.modelData);
                                }
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }

                Rectangle {
                  width: parent.width
                  height: 24
                  radius: 12
                  visible: stackBlock.modelData.count > 3
                  color: stackToggleMouse.containsMouse ? Colors.bg3 : Colors.bg2
                  border.width: 1
                  border.color: root.softBorder

                  Text {
                    anchors.centerIn: parent
                    text: stackBlock.stackExpanded
                      ? "Collapse stack"
                      : `Show ${stackBlock.modelData.count - 3} older notification${stackBlock.modelData.count - 3 === 1 ? "" : "s"}`
                    color: Colors.outline
                    font.pixelSize: 10
                    font.weight: Font.Medium
                    renderType: Text.NativeRendering
                  }

                  MouseArea {
                    id: stackToggleMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: stackBlock.stackExpanded = !stackBlock.stackExpanded
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
