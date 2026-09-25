import QtQuick
import Quickshell
import "../services"

Pill {
  id: root
  objectName: "MailIndicator"

  property var popouts: null

  // Let the parent control visibility based on space + mail availability
  width: visible ? implicitWidth : 0
  opacity: visible ? 1 : 0



  Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
  Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

  Text {
    anchors.centerIn: parent
    text: Mail.lastMail
    color: "#ffffff"
    font.pixelSize: 14
    font.weight: Font.Medium
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    
    onEntered: {
      if (root.popouts && Mail.lastMail.length > 0) {
        var pos = root.popouts.mapFromItem(root, root.width / 2, root.height)
        root.popouts.openPopout("tooltip-mail", pos.x, pos.y, root.width)
      }
    }
    
    onExited: {
    }
  }
}