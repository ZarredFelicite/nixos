import QtQuick
import Quickshell
import "../../../services"

// Canonical detailed renderer for the producer-owned IBKR market snapshot.
Item {
    id: root
    required property Item wrapper

    readonly property int outerPadding: 12
    readonly property int rowSpacing: 10
    readonly property int rowHeight: 112
    readonly property int candleSpacing: 5
    readonly property int labelAreaWidth: 48
    readonly property int plotWidth: Math.min(PopoutConfig.stocksMaxWidth - outerPadding * 2, 780)
    readonly property int rowWidth: plotWidth

    property var visibleSymbols: {
        var out = []
        var items = ChartData.tickerItems || []
        var symbolMap = ChartData.symbolMap || {}
        for (var i = 0; i < items.length; i++) {
            var instrument = symbolMap[items[i].symbol]
            if (instrument)
                out.push(instrument)
        }
        return out
    }
    property bool hasOwnBackground: true

    implicitWidth: Math.max(360, plotWidth + outerPadding * 2)
    implicitHeight: visibleSymbols.length > 0
        ? Math.min(900, visibleSymbols.length * rowHeight
            + Math.max(0, visibleSymbols.length - 1) * rowSpacing + outerPadding * 2)
        : 150

    function usableBar(bar) {
        return bar && bar.synthetic !== true
            && isFinite(Number(bar.open))
            && isFinite(Number(bar.high))
            && isFinite(Number(bar.low))
            && isFinite(Number(bar.close))
    }

    function formatPrice(value) {
        if (value === null || value === undefined || !isFinite(Number(value)))
            return "—"
        var number = Number(value)
        var absolute = Math.abs(number)
        var precision = absolute >= 100 ? 0 : (absolute >= 10 ? 1 : 2)
        return number.toFixed(precision)
    }

    function formatPercent(value) {
        if (value === null || value === undefined || !isFinite(Number(value)))
            return "—"
        var number = Number(value)
        return (number >= 0 ? "+" : "") + number.toFixed(1) + "%"
    }

    Rectangle {
        anchors.fill: parent
        color: PopoutConfig.backgroundColor
        border.width: PopoutConfig.borderWidth
        border.color: PopoutConfig.borderColor
        radius: PopoutConfig.cornerRadius
        layer.enabled: true
        layer.smooth: false
        clip: true
    }

    Flickable {
        id: flickable
        anchors.fill: parent
        clip: true
        contentWidth: root.width
        contentHeight: root.visibleSymbols.length > 0
            ? chartColumn.height + root.outerPadding * 2 : root.height
        interactive: contentHeight > height

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            onExited: if (root.wrapper) root.wrapper.scheduleClose()
        }

        Column {
            id: chartColumn
            x: root.outerPadding
            y: root.outerPadding
            width: root.rowWidth
            spacing: root.rowSpacing

            Repeater {
                model: root.visibleSymbols
                delegate: Item {
                    id: rowRoot
                    required property var modelData
                    required property int index

                    width: root.rowWidth
                    height: root.rowHeight

                    property var instrument: modelData
                    property var allBars: instrument && instrument.bars
                        && typeof instrument.bars.length === "number" ? instrument.bars : []
                    property var visibleBars: {
                        var capacity = Math.max(1, Math.floor((root.plotWidth
                            - root.labelAreaWidth - 12) / root.candleSpacing))
                        return allBars.slice(Math.max(0, allBars.length - capacity))
                    }
                    property var realBars: {
                        var out = []
                        for (var i = 0; i < visibleBars.length; i++) {
                            if (root.usableBar(visibleBars[i]))
                                out.push(visibleBars[i])
                        }
                        return out
                    }
                    property bool hasBars: realBars.length > 0
                    property bool sourceStale: instrument && instrument.freshness
                        && instrument.freshness.is_stale === true
                    property real dataMin: {
                        if (!hasBars)
                            return 0
                        var value = Number(realBars[0].low)
                        for (var i = 1; i < realBars.length; i++)
                            value = Math.min(value, Number(realBars[i].low))
                        return value
                    }
                    property real dataMax: {
                        if (!hasBars)
                            return 1
                        var value = Number(realBars[0].high)
                        for (var i = 1; i < realBars.length; i++)
                            value = Math.max(value, Number(realBars[i].high))
                        return value
                    }
                    property real padding: {
                        var range = dataMax - dataMin
                        return range > 0 ? range * 0.15 : Math.max(Math.abs(dataMax) * 0.01, 0.0001)
                    }
                    property real minPrice: dataMin - padding
                    property real maxPrice: dataMax + padding
                    property real range: Math.max(1e-9, maxPrice - minPrice)
                    property var ticks: [minPrice, (minPrice + maxPrice) / 2, maxPrice]

                    function priceToY(value) {
                        return (1 - (Number(value) - minPrice) / range) * chartPlot.height
                    }

                    Rectangle {
                        id: chartBox
                        anchors.fill: parent
                        color: PopoutConfig.secondaryBackgroundColor
                        border.width: PopoutConfig.borderWidth
                        border.color: PopoutConfig.innerBorderColor
                        radius: PopoutConfig.innerRadius
                        clip: true

                        Text {
                            id: title
                            x: 8
                            y: 5
                            text: (rowRoot.instrument.display_symbol || rowRoot.instrument.symbol)
                                + "  " + root.formatPercent(rowRoot.instrument.change_percent)
                                + (rowRoot.sourceStale ? "  STALE" : "")
                            color: rowRoot.sourceStale ? PopoutConfig.warningColor : Colors.secondary
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            z: 3
                        }

                        Item {
                            id: chartPlot
                            anchors {
                                top: title.bottom
                                bottom: parent.bottom
                                left: parent.left
                                right: parent.right
                                leftMargin: 8
                                rightMargin: root.labelAreaWidth + 8
                                bottomMargin: 5
                            }

                            Repeater {
                                model: rowRoot.ticks
                                delegate: Rectangle {
                                    required property var modelData
                                    width: chartPlot.width
                                    height: 1
                                    y: Math.max(0, Math.min(chartPlot.height - 1,
                                        rowRoot.priceToY(modelData)))
                                    color: Colors.secondary
                                    opacity: 0.12
                                }
                            }

                            Repeater {
                                model: rowRoot.visibleBars
                                delegate: Rectangle {
                                    required property var modelData
                                    required property int index
                                    property var previousBar: index > 0
                                        ? rowRoot.visibleBars[index - 1] : null
                                    visible: modelData.is_session_open
                                        || modelData.is_hour_mark
                                        || (previousBar && modelData.session_id !== previousBar.session_id)
                                    width: modelData.is_session_open ? 2 : 1
                                    height: chartPlot.height
                                    x: index * root.candleSpacing + root.candleSpacing / 2
                                    color: modelData.is_session_open ? Colors.primary : Colors.secondary
                                    opacity: modelData.is_session_open ? 0.35 : 0.14
                                }
                            }

                            Repeater {
                                model: rowRoot.visibleBars
                                delegate: Item {
                                    required property var modelData
                                    required property int index
                                    property bool usable: root.usableBar(modelData)
                                    width: root.candleSpacing
                                    height: chartPlot.height
                                    x: index * root.candleSpacing

                                    Rectangle {
                                        visible: parent.usable
                                        width: 1
                                        x: (root.candleSpacing - width) / 2
                                        y: Math.min(rowRoot.priceToY(parent.modelData.high),
                                            rowRoot.priceToY(parent.modelData.low))
                                        height: Math.max(1, Math.abs(rowRoot.priceToY(parent.modelData.high)
                                            - rowRoot.priceToY(parent.modelData.low)))
                                        color: parent.modelData.close >= parent.modelData.open
                                            ? "#9ccfd8" : Colors.foregroundRed
                                        opacity: 0.65
                                    }

                                    Rectangle {
                                        visible: parent.usable
                                        width: root.candleSpacing - 1
                                        x: 0
                                        y: Math.min(rowRoot.priceToY(parent.modelData.open),
                                            rowRoot.priceToY(parent.modelData.close))
                                        height: Math.max(2, Math.abs(rowRoot.priceToY(parent.modelData.close)
                                            - rowRoot.priceToY(parent.modelData.open)))
                                        color: parent.modelData.close >= parent.modelData.open
                                            ? "#9ccfd8" : Colors.foregroundRed
                                        radius: 1
                                    }

                                    // Synthetic slots remain in the time grid but never draw a
                                    // directional candle or imply a real price movement.
                                    Rectangle {
                                        visible: !parent.usable && parent.modelData.synthetic === true
                                        width: 1
                                        height: 3
                                        anchors.centerIn: parent
                                        color: Colors.secondary
                                        opacity: 0.25
                                    }
                                }
                            }

                            Repeater {
                                model: rowRoot.ticks
                                delegate: Rectangle {
                                    required property var modelData
                                    width: 4
                                    height: 1
                                    x: chartPlot.width
                                    y: Math.max(0, Math.min(chartPlot.height - 1,
                                        rowRoot.priceToY(modelData)))
                                    color: Colors.secondary
                                    opacity: 0.2
                                }
                            }
                        }

                        Item {
                            id: labelColumn
                            width: root.labelAreaWidth
                            anchors.top: chartPlot.top
                            anchors.bottom: chartPlot.bottom
                            anchors.right: parent.right

                            Repeater {
                                model: rowRoot.ticks
                                delegate: Text {
                                    required property var modelData
                                    text: root.formatPrice(modelData)
                                    color: Colors.secondary
                                    font.pixelSize: 10
                                    x: 6
                                    y: Math.max(0, Math.min(labelColumn.height - height,
                                        rowRoot.priceToY(modelData) - height / 2))
                                }
                            }
                        }

                        Text {
                            anchors.centerIn: chartBox
                            visible: !rowRoot.hasBars
                            text: rowRoot.instrument.status === "error"
                                ? "Unavailable"
                                : (rowRoot.sourceStale || rowRoot.instrument.status === "stale"
                                    ? "Stale / no bars" : "No bars")
                            color: Colors.secondary
                            opacity: 0.7
                            font.pixelSize: 12
                        }
                    }
                }
            }
        }

        Text {
            anchors.centerIn: parent
            width: parent.width - root.outerPadding * 2
            horizontalAlignment: Text.AlignHCenter
            visible: !ChartData.ready || root.visibleSymbols.length === 0
            text: !ChartData.ready
                ? (ChartData.checking ? "Loading market data…"
                    : (ChartData.error || "Market data unavailable"))
                : (ChartData.error || "No market symbols")
            color: ChartData.error ? PopoutConfig.errorColor : Colors.secondary
            wrapMode: Text.WordWrap
        }

        Text {
            x: root.outerPadding
            y: 3
            visible: ChartData.ready && (ChartData.stale || ChartData.error.length > 0)
            text: ChartData.error.length > 0 ? "ERROR" : "STALE"
            color: ChartData.error.length > 0 ? PopoutConfig.errorColor : PopoutConfig.warningColor
            font.pixelSize: 10
            font.weight: Font.DemiBold
            z: 10
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        radius: PopoutConfig.cornerRadius
        border.width: PopoutConfig.borderWidth
        border.color: PopoutConfig.borderColor
        z: 100
    }
}
