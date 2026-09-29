import QtQuick
import "../services"

// Two-ring memory widget: outer = memory usage, inner = swap usage
Item {
  id: root
  property var popouts: null

  // Manage polling lifecycle
  Component.onCompleted: { Memory.refCount++ }
  Component.onDestruction: { Memory.refCount-- }

  readonly property int baseSize: Colors.ringSize
  width: baseSize
  height: baseSize

  // Appearance
  property color bgColor: Colors.primaryTransparent
  property real ringThickness: Math.max(1, Colors.ringThickness * 0.9)
  property real ringGap: 1

  // Values (0..1)
  property real memValue: Memory.memPercent
  property real swapValue: Memory.swapPercent

  // CPU-like color ramp for usage percent
  function usageColor(pct01) {
    // thresholds at 50, 70, 100 mirroring CPU temp coloring
    const levels = [0.5, 0.7, 1.0]
    const cols = [Colors.tempLevel1, Colors.tempLevel2, Colors.tempLevel3]
    const base = Colors.baseTempColor
    const p = Math.max(0, Math.min(1, pct01))
    function hexToRgb(col) {
      if (typeof col === 'string') {
        const h = col.replace('#','');
        return [parseInt(h.substring(0,2),16), parseInt(h.substring(2,4),16), parseInt(h.substring(4,6),16)]
      }
      if (col && typeof col.r !== 'undefined') {
        const to255 = v => v <= 1 ? Math.round(v * 255) : Math.round(v)
        return [to255(col.r), to255(col.g), to255(col.b)]
      }
      return [255,255,255]
    }
    function rgbToHex(r,g,b){
      return "#" + ((1<<24) + (Math.round(r)<<16) + (Math.round(g)<<8) + Math.round(b)).toString(16).slice(1)
    }
    let startLvl = 0.0, endLvl = levels[0]
    let startCol = base, endCol = cols[0]
    if (p >= levels[2]) return cols[2]
    else if (p >= levels[1]) { startLvl = levels[1]; endLvl = levels[2]; startCol = cols[1]; endCol = cols[2] }
    else if (p >= levels[0]) { startLvl = levels[0]; endLvl = levels[1]; startCol = cols[0]; endCol = cols[1] }
    const frac = endLvl - startLvl > 0 ? (p - startLvl) / (endLvl - startLvl) : 0
    const sc = hexToRgb(startCol); const ec = hexToRgb(endCol)
    const r = sc[0] + (ec[0] - sc[0]) * frac
    const g = sc[1] + (ec[1] - sc[1]) * frac
    const b = sc[2] + (ec[2] - sc[2]) * frac
    return rgbToHex(r,g,b)
  }

  Canvas {
    id: canvas
    anchors.fill: parent
    onPaint: {
      const ctx = getContext("2d")
      ctx.clearRect(0, 0, width, height)
      const cx = width / 2
      const cy = height / 2
      const maxR = Math.min(width, height) / 2
      const thick = root.ringThickness
      const gap = root.ringGap
      // outer = memory, inner = swap
      const rMem = maxR - thick/2
      const rSwap = rMem - (thick + gap)
      ctx.lineCap = "round"

      function drawRing(radius, value, fg) {
        ctx.lineWidth = thick
        // background
        ctx.beginPath(); ctx.strokeStyle = root.bgColor
        ctx.arc(cx, cy, radius, -Math.PI/2, 1.5*Math.PI, false)
        ctx.stroke()
        if (value > 0) {
          ctx.beginPath(); ctx.strokeStyle = fg
          ctx.arc(cx, cy, radius, -Math.PI/2, -Math.PI/2 + value * 2*Math.PI, false)
          ctx.stroke()
        }
      }

      drawRing(rMem, root.memValue, usageColor(root.memValue))
      drawRing(rSwap, root.swapValue, usageColor(root.swapValue))
    }
    Connections { 
      target: root
      function onMemValueChanged(){ canvas.requestPaint() } 
      function onSwapValueChanged(){ canvas.requestPaint() } 
      function onBgColorChanged(){ canvas.requestPaint() } 
    }
    Connections { target: Memory; function onMemPercentChanged(){ canvas.requestPaint() } function onSwapPercentChanged(){ canvas.requestPaint() } }
  }

  // Memory label in center
  Text {
    id: memoryLabel
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.horizontalCenterOffset: parent.width * 0.02
    anchors.verticalCenter: parent.verticalCenter
    anchors.verticalCenterOffset: parent.height * 0.02
    text: "M"
    color: usageColor(Math.max(memValue, swapValue))
    font.pixelSize: Math.round(parent.height * 0.39)
    font.bold: true
  }

  Behavior on memValue { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
  Behavior on swapValue { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

  // Tooltip hover (optional placeholder; may later add a popout)
  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.NoButton
    onEntered: {
      if (root.popouts) {
        var pos = root.popouts.mapFromItem(root, root.width / 2, root.height)
        root.popouts.openPopout("tooltip-memory", pos.x, pos.y, root.width)
      }
    }
    onExited: {
      if (root.popouts && root.popouts.currentName === "tooltip-memory") {
        root.popouts.scheduleClose()
      }
    }
  }
}
