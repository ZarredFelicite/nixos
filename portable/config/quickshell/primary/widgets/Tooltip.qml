import QtQuick
import "../services"

Rectangle {
  id: tooltip
  
  property string text: ""
  property bool tooltipVisible: false
  property Item target: null
  
  width: Math.max(200, tooltipText.implicitWidth + 16)
  height: tooltipText.implicitHeight + 12
  
  color: "#1e1e2e"  // Dark background
  border.color: "#cdd6f4"  // Light border
  border.width: 2
  radius: 8
  
  opacity: tooltipVisible ? 1.0 : 0.0
  visible: tooltipVisible
  
  Behavior on opacity {
    NumberAnimation { duration: 150 }
  }
  
  Text {
    id: tooltipText
    anchors.centerIn: parent
    text: tooltip.text
    color: "#cdd6f4"  // Light text
    font.pixelSize: 13
    font.weight: Font.Medium
    wrapMode: Text.WordWrap
    horizontalAlignment: Text.AlignHCenter
  }
  
  // Position tooltip below the target, centered horizontally
  function updatePosition() {
    if (target && tooltip.parent) {
      var targetPos = target.mapToItem(tooltip.parent, 0, 0)
      
      // Center horizontally relative to target
      tooltip.x = targetPos.x + (target.width - tooltip.width) / 2
      
      // Position below target with more spacing (52px below)
      tooltip.y = targetPos.y + target.height + 52
      
      // Keep tooltip within horizontal bounds
      if (tooltip.parent.width) {
        tooltip.x = Math.max(8, Math.min(tooltip.x, tooltip.parent.width - tooltip.width - 8))
      }
    }
  }
  
  onTooltipVisibleChanged: {
    if (tooltipVisible) {
      updatePosition()
    }
  }
  
  onTargetChanged: {
    if (tooltipVisible) {
      updatePosition()
    }
  }
}