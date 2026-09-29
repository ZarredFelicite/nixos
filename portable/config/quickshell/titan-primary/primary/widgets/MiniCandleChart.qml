import QtQuick
import "../services"

Canvas {
    id: root

    property var bars: []
    property bool positive: true

    width: 34
    height: parent ? parent.height : 20

    onBarsChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    Component.onCompleted: requestPaint()

    function usable(bar) {
        return bar && bar.synthetic !== true
            && isFinite(Number(bar.open))
            && isFinite(Number(bar.high))
            && isFinite(Number(bar.low))
            && isFinite(Number(bar.close))
    }

    onPaint: {
        var context = getContext("2d")
        context.clearRect(0, 0, width, height)

        var topPad = 2
        var chartHeight = Math.max(1, height - topPad * 2)
        context.fillStyle = "rgba(196, 167, 231, 0.05)"
        context.fillRect(0.5, topPad + 0.5, width - 1, chartHeight - 1)
        context.strokeStyle = "rgba(110, 106, 134, 0.3)"
        context.lineWidth = 1
        context.strokeRect(0.5, topPad + 0.5, width - 1, chartHeight - 1)

        var source = bars && typeof bars.length === "number" ? bars : []
        var start = Math.max(0, source.length - 8)
        var minimum = Infinity
        var maximum = -Infinity
        var validCount = 0
        for (var i = start; i < source.length; i++) {
            if (!usable(source[i]))
                continue
            minimum = Math.min(minimum, Number(source[i].low))
            maximum = Math.max(maximum, Number(source[i].high))
            validCount++
        }

        if (validCount === 0) {
            context.fillStyle = "rgba(144, 140, 170, 0.6)"
            context.fillRect(width / 2 - 1, height / 2 - 1, 3, 3)
            return
        }

        var range = Math.max(1e-9, maximum - minimum)
        var slotWidth = width / Math.max(8, source.length - start)
        function priceY(price) {
            return topPad + (1 - (Number(price) - minimum) / range) * chartHeight
        }

        for (var index = start; index < source.length; index++) {
            var bar = source[index]
            var x = (index - start + 0.5) * slotWidth
            if (!usable(bar)) {
                if (bar && bar.synthetic === true) {
                    context.fillStyle = "rgba(144, 140, 170, 0.35)"
                    context.fillRect(x, height / 2 - 1, 1, 3)
                }
                continue
            }

            var color = Number(bar.close) >= Number(bar.open) ? "#9ccfd8" : "#eb6f92"
            var highY = priceY(bar.high)
            var lowY = priceY(bar.low)
            var openY = priceY(bar.open)
            var closeY = priceY(bar.close)
            context.strokeStyle = color
            context.lineWidth = 1
            context.beginPath()
            context.moveTo(x, highY)
            context.lineTo(x, lowY)
            context.stroke()
            context.strokeRect(x - 1.5, Math.min(openY, closeY), 3,
                Math.max(1, Math.abs(closeY - openY)))
        }
    }
}
