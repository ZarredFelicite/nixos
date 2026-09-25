import QtQuick
import "../services"

Rectangle {
  id: root

  property var popouts: null
  property real expectedMinX: 0  // Set by parent - minimum x position before considered "pushed off"
  property bool isPushedOff: false  // True when logo is pushed too far left

  implicitWidth: Colors.pillHeight
  implicitHeight: Colors.pillHeight
  color: mouseArea.containsMouse ? "#313244" : "transparent"
  radius: Colors.pillHeight / 2

  // Monitor x position and update isPushedOff state
  onXChanged: {
    if (expectedMinX > 0) {
      isPushedOff = x < expectedMinX
    }
  }

  Behavior on color {
    ColorAnimation { duration: 150 }
  }

  Image {
    anchors.centerIn: parent
    source: "/home/zarred/pictures/icons/hyprnix.png"
    width: parent.width
    height: parent.height
    fillMode: Image.PreserveAspectFit
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    onClicked: {
      if (root.popouts) {
        // Toggle system menu via popouts
        if (root.popouts.hasCurrent && root.popouts.currentName === "systemMenu") {
          root.popouts.close()
        } else {
          try {
            var pos = root.popouts.mapFromItem(root, root.width / 2, root.height)
            root.popouts.openPopout("systemMenu", pos.x, pos.y, root.width)
          } catch (e) {
            root.popouts.openPopout("systemMenu")
          }
        }
      }
    }
  }
}
