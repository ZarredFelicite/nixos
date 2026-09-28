pragma Singleton

import QtQuick
import "."

// Compatibility facade for older callers. ChartData is the sole FileView reader
// and owns the producer-backed IBKR snapshot.
QtObject {
    id: root

    readonly property bool checking: ChartData.checking
    readonly property bool ready: ChartData.ready
    readonly property bool stale: ChartData.stale
    readonly property string status: ChartData.status
    readonly property string error: ChartData.error
    readonly property date lastUpdated: ChartData.lastUpdated
    readonly property var tokens: ChartData.tickerItems
    readonly property var chartData: ChartData.dataMap
    readonly property var portfolioSummary: ChartData.portfolioSummary

    readonly property real summaryValueChange: _number(portfolioSummary.unrealised_pnl)
    readonly property real summaryPercentChange: _number(portfolioSummary.percent_change)
    readonly property real summaryTotalValue: _number(portfolioSummary.total_value)
    readonly property real summaryTotalInvested: _number(portfolioSummary.total_invested)
    readonly property real summaryDayValueChange: _number(portfolioSummary.day_value_change)
    readonly property real summaryDayPercentChange: _number(portfolioSummary.day_percent_change)

    // Kept only for source compatibility. Consumers should increment ChartData.refCount.
    property int refCount: 0

    function _number(value) {
        var number = Number(value)
        return isFinite(number) ? number : 0
    }

    function refresh() {
        ChartData.refresh()
    }
}
