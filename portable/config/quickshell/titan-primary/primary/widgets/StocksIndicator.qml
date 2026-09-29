import QtQuick
import Quickshell
import "../services"

Item {
    id: root

    property var popouts: null
    property bool enabledWidget: true
    property real maxWidth: 400
    property var displayItems: []
    property bool _registered: false

    implicitHeight: Colors.pillHeight
    implicitWidth: Math.min(300, maxWidth)

    property real marqueePhase: 0
    readonly property real setGap: 4
    readonly property real repeatDistance: firstSet.width + setGap

    function formatPercent(value) {
        if (value === null || value === undefined || !isFinite(Number(value)))
            return "—"
        var number = Number(value)
        return (number >= 0 ? "+" : "") + number.toFixed(1) + "%"
    }

    function registerData() {
        if (_registered || !enabledWidget)
            return
        _registered = true
        ChartData.refCount++
    }

    function unregisterData() {
        if (!_registered)
            return
        _registered = false
        if (ChartData.refCount > 0)
            ChartData.refCount--
    }

    Component.onCompleted: {
        registerData()
        updateSegments()
    }

    Component.onDestruction: unregisterData()

    onEnabledWidgetChanged: {
        if (enabledWidget) {
            registerData()
            updateSegments()
        } else {
            unregisterData()
            displayItems = []
            captureMarqueePhase()
            scheduleMarquee()
        }
    }

    function captureMarqueePhase() {
        var distance = repeatDistance
        if (distance <= 0 || !isFinite(distance))
            return
        var offset = ((-slidingContent.x % distance) + distance) % distance
        marqueePhase = offset / distance
    }

    function scheduleMarquee() {
        marqueeTimer.restart()
    }

    function updateSegments() {
        captureMarqueePhase()

        var next = []
        var items = ChartData.tickerItems || []
        var symbolMap = ChartData.symbolMap || {}
        for (var i = 0; i < items.length; i++) {
            var item = items[i]
            if (!item || !item.symbol)
                continue
            var instrument = symbolMap[item.symbol] || null
            next.push({
                symbol: item.symbol,
                display_symbol: item.display_symbol || item.symbol,
                change_percent: item.change_percent,
                change_basis: item.change_basis || "",
                status: item.status || (instrument ? instrument.status : "empty"),
                is_positive: item.change_percent !== null && Number(item.change_percent) >= 0,
                bars: instrument ? (instrument.bars || []) : []
            })
        }
        displayItems = next
        scheduleMarquee()
    }

    Connections {
        target: ChartData
        enabled: root.enabledWidget
        function onSnapshotChanged() { root.updateSegments() }
    }

    MouseArea {
        id: mainMouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        onClicked: {
            if (root.popouts) {
                var pos = root.popouts.mapFromItem(root, root.width / 2, root.height)
                root.popouts.openPopout("tooltip-stocks", pos.x, pos.y, root.width)
            }
        }
    }

    Item {
        id: scrollContainer
        anchors.fill: parent
        clip: true

        Item {
            id: slidingContent
            height: parent.height
            width: firstSet.width + root.setGap + secondSet.width
            layer.enabled: true
            layer.smooth: false

            Row {
                id: firstSet
                width: implicitWidth
                height: parent.height
                spacing: 8
                Repeater {
                    model: root.displayItems
                    delegate: tickerDelegate
                }
            }

            Row {
                id: secondSet
                width: implicitWidth
                height: parent.height
                spacing: 8
                x: firstSet.width + root.setGap
                Repeater {
                    model: root.displayItems
                    delegate: tickerDelegate
                }
            }
        }

        Timer {
            id: marqueeTimer
            interval: 0
            repeat: false
            onTriggered: {
                scrollAnimation.stop()
                var distance = root.repeatDistance
                if (!root.visible || root.displayItems.length === 0 || distance <= 0 || !isFinite(distance)) {
                    slidingContent.x = 0
                    return
                }

                var start = -Math.max(0, Math.min(1, root.marqueePhase)) * distance
                slidingContent.x = start
                scrollAnimation.from = start
                scrollAnimation.to = start - distance
                scrollAnimation.duration = Math.max(1000, Math.round(distance * 24))
                scrollAnimation.start()
            }
        }

        NumberAnimation {
            id: scrollAnimation
            target: slidingContent
            property: "x"
            loops: Animation.Infinite
            paused: mainMouseArea.containsMouse
        }
    }

    onVisibleChanged: {
        if (visible)
            scheduleMarquee()
        else
            scrollAnimation.stop()
    }

    Component {
        id: tickerDelegate
        Item {
            required property var modelData
            width: innerRow.implicitWidth
            height: root.implicitHeight

            Row {
                id: innerRow
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                spacing: 2

                Text {
                    text: modelData.display_symbol
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    color: Colors.primary
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    text: root.formatPercent(modelData.change_percent)
                    font.pixelSize: 14
                    color: modelData.change_percent === null
                        ? Colors.secondary
                        : (modelData.is_positive ? "#9ccfd8" : Colors.foregroundRed)
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                }

                MiniCandleChart {
                    bars: modelData.bars || []
                    positive: modelData.is_positive
                }
            }
        }
    }
}
