import QtQuick
import QtQuick.Layouts
import "../services"

// 3D Printer status indicator - shows print progress or idle state
Rectangle {
  id: root
  objectName: "Printer3DIndicator"

  property var popouts: null
  property bool isLockedOpen: false

  implicitWidth: row.implicitWidth + 6
  implicitHeight: Colors.pillHeight
  radius: height / 2
  color: "transparent"
  opacity: indicatorMouse.containsMouse ? 1.0 : 0.85
  Behavior on opacity { NumberAnimation { duration: 150 } }

  RowLayout {
    id: row
    anchors.centerIn: parent
    spacing: 6

    ProgressRing {
      Layout.preferredWidth: Colors.ringSize
      Layout.preferredHeight: Colors.ringSize
      Layout.alignment: Qt.AlignVCenter
      sweepAngle: 360
      value: Math.max(0, Printer3D.percentage / 100.0)
      foregroundColor: {
        if (Printer3D.errorCode !== 0) return Colors.foregroundRed;
        if (Printer3D.state === "FINISH") return Colors.success;
        if (Printer3D.state === "IDLE" || Printer3D.percentage === 0) return Colors.outline;
        return Colors.primary;
      }
      backgroundColor: Qt.rgba(1, 1, 1, 0.1)
      thickness: Colors.ringThickness

      Text {
        anchors.centerIn: parent
        text: "\udb81\udc2b"
        font.family: "Material Symbols Outlined"
        font.pixelSize: 24
        color: {
          if (!Printer3D.connected) return Colors.outline;
          if (Printer3D.errorCode !== 0) return Colors.foregroundRed;
          return Colors.primary;
        }
      }
    }
  }

  MouseArea {
    id: indicatorMouse
    anchors.fill: parent
    hoverEnabled: true
    onEntered: {
      // Only auto-open on hover if not locked open
      if (!root.isLockedOpen && root.popouts) {
        var pos = root.popouts.mapFromItem(root, root.width / 2, root.height)
        root.popouts.openPopout("printer3d-menu", pos.x, pos.y, root.width)
      }
    }
    onExited: {
      if (!root.isLockedOpen && root.popouts && root.popouts.currentName !== "printer3d-menu" && root.popouts.closeTimer) {
        root.popouts.closeTimer.start()
      }
    }
    onClicked: {
      // Toggle locked state on click
      root.isLockedOpen = !root.isLockedOpen
      if (root.popouts) {
        var pos = root.popouts.mapFromItem(root, root.width / 2, root.height)
        root.popouts.openPopout("printer3d-menu", pos.x, pos.y, root.width)
        
        if (root.isLockedOpen && root.popouts.closeTimer) {
          // Stop the close timer if locking open
          root.popouts.closeTimer.stop()
        } else if (!root.isLockedOpen && root.popouts.closeTimer) {
          // Start the close timer if unlocking
          root.popouts.closeTimer.start()
        }
      }
    }
  }

  // Listen for when popout closes to reset locked state
  Connections {
    target: root.popouts
    function onHasCurrentChanged() {
      if (!root.popouts.hasCurrent && root.popouts.currentName === "printer3d-menu") {
        root.isLockedOpen = false
      }
    }
  }
}
