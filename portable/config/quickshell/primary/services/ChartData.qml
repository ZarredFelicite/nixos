pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Sole reader for the producer-owned IBKR market snapshot.
// The producer publishes one atomically replaced JSON file; this service publishes
// a validated snapshot and retains the last good one when a refresh fails.
QtObject {
    id: root

    readonly property string contractSchema: "ibkr.quickshell.market"
    readonly property int contractSchemaVersion: 1

    property int intervalMs: 30 * 1000
    property int maxBars: 200
    property int staleAfterMs: 30 * 60 * 1000
    property int refCount: 0

    property bool checking: false
    property bool ready: false
    property bool stale: false
    property string status: "loading"
    property string error: ""
    property string source: ""
    property string generatedAt: ""
    property date lastUpdated: new Date(0)
    property date lastSuccessAt: new Date(0)

    property var snapshot: null
    property var symbols: []
    property var symbolMap: ({})
    property var tickerItems: []
    property var portfolioSummary: ({})

    // Compatibility view for older consumers. New code should use symbols/symbolMap.
    property var dataMap: ({})

    readonly property string contractPath: resolveContractPath()

    property FileView contractFile: FileView {
        path: root.contractPath
        preload: root.refCount > 0
        watchChanges: root.refCount > 0
        printErrors: false

        onLoaded: root._handleText(text())
        onLoadFailed: function(_) { root._handleFailure("market contract could not be loaded") }
        onFileChanged: {
            if (root.refCount > 0)
                reload()
        }
    }

    property Timer pollTimer: Timer {
        interval: root.intervalMs
        repeat: true
        running: root.refCount > 0
        onTriggered: root.refresh()
    }

    onRefCountChanged: {
        pollTimer.running = refCount > 0
        if (refCount > 0)
            refresh()
    }

    Component.onCompleted: refresh()

    function resolveContractPath() {
        var explicitPath = String(Quickshell.env("IBKR_QUICKSHELL_MARKET_FILE") || "").trim()
        if (explicitPath !== "")
            return explicitPath

        var stateDir = String(Quickshell.env("XDG_STATE_HOME") || "").trim()
        if (stateDir === "") {
            var home = String(Quickshell.env("HOME") || "").trim()
            stateDir = home !== "" ? home + "/.local/state" : "/tmp"
        }
        return stateDir + "/ibkr/quickshell-market.json"
    }

    function refresh() {
        if (checking)
            return

        checking = true
        error = ""
        status = ready ? (stale ? "stale" : "refreshing") : "loading"
        contractFile.reload()
    }

    function _handleText(text) {
        var candidate
        try {
            candidate = JSON.parse(String(text || ""))
        } catch (e) {
            _handleFailure("invalid market contract JSON")
            return
        }

        var normalized
        try {
            normalized = _normalizeSnapshot(candidate)
        } catch (e) {
            _handleFailure(String(e))
            return
        }

        symbols = normalized.symbols
        symbolMap = normalized.symbolMap
        tickerItems = normalized.tickerItems
        portfolioSummary = normalized.portfolioSummary
        dataMap = normalized.dataMap
        source = normalized.source
        generatedAt = normalized.generatedAt
        lastUpdated = new Date()
        lastSuccessAt = lastUpdated
        checking = false
        ready = true
        stale = _isStale(generatedAt) || normalized.sourceStale
        status = stale ? "stale" : normalized.status
        error = normalized.contractError
        // Publish last so Connections handlers see one complete normalized snapshot.
        snapshot = normalized.snapshot
    }

    function _handleFailure(message) {
        checking = false
        error = message
        if (ready) {
            stale = true
            status = "stale"
        } else {
            stale = false
            status = "error"
        }
    }

    function _isStale(value) {
        var timestamp = Date.parse(String(value || ""))
        if (!isFinite(timestamp))
            return true
        return Date.now() - timestamp > Math.max(1, staleAfterMs)
    }

    function _finite(value) {
        return typeof value === "number" && isFinite(value)
    }

    function _normalizeBar(raw) {
        if (!raw || typeof raw !== "object")
            return null

        var timestamp = raw.timestamp
        if (typeof timestamp !== "string" && typeof timestamp !== "number")
            return null
        if (!isFinite(typeof timestamp === "number" ? timestamp : Date.parse(timestamp)))
            return null

        var open = Number(raw.open)
        var high = Number(raw.high)
        var low = Number(raw.low)
        var close = Number(raw.close)
        var volume = raw.volume === undefined || raw.volume === null ? 0 : Number(raw.volume)

        if (!_finite(open) || !_finite(high) || !_finite(low) || !_finite(close))
            return null
        if (!_finite(volume) || volume < 0)
            return null
        if (low > high || high < Math.max(open, close) || low > Math.min(open, close))
            return null

        return {
            timestamp: String(timestamp),
            open: open,
            high: high,
            low: low,
            close: close,
            volume: volume,
            synthetic: raw.synthetic === true,
            synthetic_reason: raw.synthetic_reason === null
                || raw.synthetic_reason === undefined ? "" : String(raw.synthetic_reason),
            session_id: String(raw.session_id || ""),
            is_session_open: raw.is_session_open === true,
            is_hour_mark: raw.is_hour_mark === true
        }
    }

    function _normalizeSymbol(raw, objectKey) {
        if (!raw || typeof raw !== "object")
            throw "invalid symbol record"

        var symbol = String(objectKey || raw.requested_symbol || "").trim()
        if (symbol === "")
            throw "symbol record has no object key or requested_symbol"

        var rawBars = Array.isArray(raw.bars) ? raw.bars : []
        var bars = []
        var invalidBars = 0
        var previousTimestamp = -Infinity
        var seen = ({})
        var maxCount = Math.max(1, Number(root.maxBars) || 200)
        var firstBar = Math.max(0, rawBars.length - maxCount)

        for (var i = firstBar; i < rawBars.length; i++) {
            var bar = _normalizeBar(rawBars[i])
            if (!bar) {
                invalidBars++
                continue
            }

            var epoch = Date.parse(bar.timestamp)
            if (!isFinite(epoch) || epoch <= previousTimestamp || seen[bar.timestamp]) {
                invalidBars++
                continue
            }
            seen[bar.timestamp] = true
            previousTimestamp = epoch
            bars.push(bar)
        }

        var changePercent = raw.change_percent
        if (changePercent !== null && changePercent !== undefined) {
            changePercent = Number(changePercent)
            if (!_finite(changePercent))
                changePercent = null
        } else {
            changePercent = null
        }

        var recordStatus = String(raw.status || (bars.length > 0 ? "ok" : "empty"))
        if (bars.length === 0 && recordStatus === "ok")
            recordStatus = "empty"

        var marketTimezone = String(raw.market_timezone || "")
        var lastSourceBarAt = String(raw.last_source_bar_at || "")
        return {
            symbol: symbol,
            requested_symbol: String(raw.requested_symbol || symbol),
            resolved_symbol: String(raw.resolved_symbol || raw.requested_symbol || symbol),
            display_symbol: String(raw.display_symbol || symbol),
            kind: String(raw.kind || "market"),
            asset_class: String(raw.asset_class || "unknown"),
            currency: raw.currency === null || raw.currency === undefined
                ? "" : String(raw.currency),
            market_timezone: marketTimezone,
            // Compatibility aliases for existing QML consumers.
            timezone: marketTimezone,
            calendar: raw.calendar === null || raw.calendar === undefined
                ? "" : String(raw.calendar),
            session: raw.session && typeof raw.session === "object" ? raw.session : null,
            status: recordStatus,
            error: String(raw.error || ""),
            retrieved_at: String(raw.retrieved_at || ""),
            first_bar_at: String(raw.first_bar_at || ""),
            last_bar_at: String(raw.last_bar_at || ""),
            last_source_bar_at: lastSourceBarAt,
            last_real_bar_at: lastSourceBarAt,
            counts: raw.counts && typeof raw.counts === "object" ? raw.counts : ({}),
            freshness: raw.freshness && typeof raw.freshness === "object"
                ? raw.freshness : ({}),
            change_percent: changePercent,
            change_basis: String(raw.change_basis || ""),
            bars: bars,
            invalid_bar_count: invalidBars
        }
    }

    function _normalizeSnapshot(raw) {
        if (!raw || typeof raw !== "object")
            throw "market contract is not an object"
        if (raw.schema !== contractSchema)
            throw "unsupported market contract schema"
        if (Number(raw.schema_version) !== contractSchemaVersion)
            throw "unsupported market contract version"
        if (typeof raw.generated_at !== "string" || !isFinite(Date.parse(raw.generated_at)))
            throw "market contract has invalid generated_at"
        if (!raw.symbols || typeof raw.symbols !== "object" || Array.isArray(raw.symbols))
            throw "market contract has no symbols object"
        if (!Array.isArray(raw.ticker_items))
            throw "market contract has no ticker_items array"

        var normalizedSymbols = []
        var normalizedMap = ({})
        var normalizedDataMap = ({})
        var symbolKeys = Object.keys(raw.symbols)
        for (var i = 0; i < symbolKeys.length; i++) {
            var objectKey = String(symbolKeys[i] || "").trim()
            var record = _normalizeSymbol(raw.symbols[symbolKeys[i]], objectKey)
            if (normalizedMap[record.symbol])
                throw "duplicate symbol: " + record.symbol
            normalizedMap[record.symbol] = record
            normalizedSymbols.push(record)
            normalizedDataMap[record.symbol] = record.bars
        }

        var tickerItems = []
        for (var j = 0; j < raw.ticker_items.length; j++) {
            var item = raw.ticker_items[j]
            if (!item || typeof item !== "object")
                continue
            var instrumentId = String(item.instrument_id || item.symbol || "").trim()
            if (instrumentId === "")
                continue

            var itemPercent = item.change_percent
            if (itemPercent !== null && itemPercent !== undefined) {
                itemPercent = Number(itemPercent)
                if (!_finite(itemPercent))
                    itemPercent = null
            } else {
                itemPercent = null
            }

            tickerItems.push({
                instrument_id: instrumentId,
                symbol: instrumentId,
                display_symbol: String(item.display_symbol || instrumentId),
                kind: String(item.kind || "position"),
                status: String(item.status || "ok"),
                change_percent: itemPercent,
                change_basis: String(item.change_basis || ""),
                value_change: _finite(Number(item.value_change)) ? Number(item.value_change) : null
            })
        }

        var status = String(raw.status || "ok")
        if (status === "ok" && normalizedSymbols.length === 0)
            status = "empty"

        var sourceStale = tickerItems.length > 0
        var freshnessRecords = 0
        for (var k = 0; k < tickerItems.length; k++) {
            var tickerRecord = normalizedMap[tickerItems[k].symbol]
            if (!tickerRecord || !tickerRecord.freshness)
                continue
            freshnessRecords++
            if (tickerRecord.freshness.is_stale !== true) {
                sourceStale = false
                break
            }
        }
        if (freshnessRecords === 0)
            sourceStale = false

        return {
            snapshot: raw,
            symbols: normalizedSymbols,
            symbolMap: normalizedMap,
            dataMap: normalizedDataMap,
            tickerItems: tickerItems,
            portfolioSummary: raw.portfolio_summary && typeof raw.portfolio_summary === "object"
                ? raw.portfolio_summary : ({}),
            source: String(raw.source || ""),
            generatedAt: raw.generated_at,
            status: status,
            sourceStale: sourceStale,
            contractError: String(raw.error || "")
        }
    }
}
