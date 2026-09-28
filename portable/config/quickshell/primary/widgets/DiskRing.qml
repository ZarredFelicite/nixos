import QtQuick
import Quickshell
import "../services"

// Single ring showing main disk usage percent from Disk service.
// Hover opens tooltip via popouts (consumer sets popouts & tooltipName).
Item {
  id: root
  property var popouts: null
  property string tooltipName: "tooltip-disk"
  width: Colors.ringSize
  height: Colors.ringSize

  // Expose usage percent (0-100); convert to 0..1 for ring
  property int percent: Disk.mainPercent
  property real value: Math.max(0, Math.min(1, percent / 100))

  // Color scaling similar to memory usage: green->yellow->red
  function usageColor(p) {
    // Reuse temperature gradient colors: baseTempColor -> tempLevel1 -> tempLevel2 -> tempLevel3
    if (!isFinite(p) || p < 0) p = 0
    if (p > 100) p = 100
    const pct01 = p / 100.0
    const levels = [0.5, 0.7, 1.0]
    const cols = [Colors.tempLevel1, Colors.tempLevel2, Colors.tempLevel3]
    const base = Colors.baseTempColor
    function hexToRgb(col) {
      if (typeof col === 'string') {
        const h = col.replace('#','')
        return [parseInt(h.substring(0,2),16), parseInt(h.substring(2,4),16), parseInt(h.substring(4,6),16)]
      }
      if (col && typeof col.r !== 'undefined') {
        const to255 = v => v <= 1 ? Math.round(v * 255) : Math.round(v)
        return [to255(col.r), to255(col.g), to255(col.b)]
      }
      return [255,255,255]
    }
    function rgbToHex(r,g,b){ return "#" + ((1<<24) + (Math.round(r)<<16) + (Math.round(g)<<8) + Math.round(b)).toString(16).slice(1) }
    let startLvl = 0.0, endLvl = levels[0]
    let startCol = base, endCol = cols[0]
    if (pct01 >= levels[2]) return cols[2]
    else if (pct01 >= levels[1]) { startLvl = levels[1]; endLvl = levels[2]; startCol = cols[1]; endCol = cols[2] }
    else if (pct01 >= levels[0]) { startLvl = levels[0]; endLvl = levels[1]; startCol = cols[0]; endCol = cols[1] }
    const frac = endLvl - startLvl > 0 ? (pct01 - startLvl) / (endLvl - startLvl) : 0
    const sc = hexToRgb(startCol); const ec = hexToRgb(endCol)
    const r = sc[0] + (ec[0] - sc[0]) * frac
    const g = sc[1] + (ec[1] - sc[1]) * frac
    const b = sc[2] + (ec[2] - sc[2]) * frac
    return rgbToHex(r,g,b)
  }

  readonly property color ringColor: usageColor(percent)
  property real ringThickness: Colors.ringThickness

  Canvas {
    id: canvas
    anchors.fill: parent
    onPaint: {
      const ctx = getContext("2d")
      ctx.clearRect(0,0,width,height)
      const cx = width/2
      const cy = height/2
      const r = Math.min(width,height)/2 - ringThickness/2

      ctx.lineCap = "round"
      ctx.lineWidth = ringThickness
      // Background
      ctx.beginPath()
      ctx.strokeStyle = Colors.primaryTransparent
      ctx.arc(cx, cy, r, 0, 2*Math.PI, false)
      ctx.stroke()

      // Foreground arc
      const angle = value * 2*Math.PI
      ctx.beginPath()
      ctx.strokeStyle = ringColor
      ctx.arc(cx, cy, r, -Math.PI/2, -Math.PI/2 + angle, false)
      ctx.stroke()
    }
  }
  Connections { target: root; function onValueChanged(){ canvas.requestPaint() } }
  Connections { target: Disk; function onMainPercentChanged(){ canvas.requestPaint() } }

  // Center label D
  Text {
    anchors.centerIn: parent
    text: "D"
    color: ringColor
    font.pixelSize: Math.round(parent.height * 0.42)
    font.bold: true
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onEntered: {
      if (root.popouts) {
        const pos = root.popouts.mapFromItem(root, root.width/2, root.height)
        root.popouts.openPopout(root.tooltipName, pos.x, pos.y, root.width)
      }
    }
    onExited: { if (root.popouts) root.popouts.scheduleClose() }
    onClicked: function(mouse) {
      if (root.popouts) {
        const pos = root.popouts.mapFromItem(root, root.width/2, root.height)
        root.popouts.openPopout(root.tooltipName, pos.x, pos.y, root.width)
      }
    }
  }
}
