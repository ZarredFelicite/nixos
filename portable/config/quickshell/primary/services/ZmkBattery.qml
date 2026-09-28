pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// ZMK battery service
// Reads three temp files updated by battery_icons.sh every second:
//   /tmp/zmk_battery_left
//   /tmp/zmk_battery_central
//   /tmp/zmk_battery_right
// File format produced by battery_icons.sh:
//   First line: path to generated icon PNG whose filename encodes part + percent + charging flag (e.g. /.../left_85_1.png)
//   Remaining lines: JSON of the aggregated /tmp/zmk_battery file, including fields:
//     charge: { left: <int>, right: <int>, central: <int> }
//     charging_left: <bool>, charging_right: <bool>, charging_central: <bool>
// Exposes per-part:
//   * leftPath/centralPath/rightPath (icon path)
//   * leftPercent/centralPercent/rightPercent (int -1 unknown)
//   * leftCharging/centralCharging/rightCharging (bool)
// Also builds a tooltip string.
QtObject {
    id: root

    // Icon paths
    property string leftPath: ""
    property string centralPath: ""
    property string rightPath: ""

    // Parsed charge values (-1 unknown)
    property int leftPercent: -1
    property int centralPercent: -1
    property int rightPercent: -1

    // Charging flags
    property bool leftCharging: false
    property bool centralCharging: false
    property bool rightCharging: false

    property bool connected: leftPercent >= 0 || centralPercent >= 0 || rightPercent >= 0

    property string tooltipText: buildTooltip()

    property date lastUpdated: new Date(0)
    property string error: ""

    // Polling interval (ms)
    property int interval: 5000

    // Reference counting for consumers
    property int refCount: 0

    property Timer pollTimer: Timer {
        interval: root.interval
        repeat: true
        running: root.refCount > 0
        onTriggered: root.refresh()
    }

    onRefCountChanged: {
        pollTimer.running = (root.refCount > 0)
        if (root.refCount > 0) refresh()
    }

    function refresh() {
        // Batch read all three part files. We need to guard against missing files.
        var script = '' +
            'for p in left central right; do ' +
            '  echo "__PART__${p}"; ' +
            '  if [ -f /tmp/zmk_battery_${p} ]; then ' +
            '    # Split first line (icon path) and JSON remainder\n' +
            '    ICON_LINE=$(head -n1 /tmp/zmk_battery_${p} 2>/dev/null); ' +
            '    echo "__ICON__${p} ${ICON_LINE}"; ' +
            '    tail -n +2 /tmp/zmk_battery_${p} 2>/dev/null | sed "s/^/__JSON__${p} /"; ' +
            '  fi; ' +
            'done';
        var proc = Qt.createQmlObject('import Quickshell.Io; import QtQuick; Process { stdout: SplitParser { onRead: function(line){ root._handle(line) } } }', root)
        proc.command = ["sh", "-c", script]
        proc.onExited.connect(function() {
            proc.destroy()
        })
        proc.running = true
    }

    // Temporary holders for JSON lines per part
    property var _jsonBuf: ({ left: [], central: [], right: [] })

    function _handle(rawLine) {
        var line = (rawLine || "").trim();
        if (!line) return;
        if (line.startsWith("__ICON__")) {
            // __ICON__<part> <path>
            var seg = line.substring(8); // after __ICON__
            var spaceIdx = seg.indexOf(' ');
            if (spaceIdx === -1) return;
            var part = seg.substring(0, spaceIdx);
            var path = seg.substring(spaceIdx + 1).trim();
            if (part === 'left') { leftPath = path; leftPercent = parsePercent(path); }
            else if (part === 'central') { centralPath = path; centralPercent = parsePercent(path); }
            else if (part === 'right') { rightPath = path; rightPercent = parsePercent(path); }
        } else if (line.startsWith("__JSON__")) {
            // Accumulate JSON lines per part then parse.
            var seg2 = line.substring(8); // after __JSON__
            var spaceIdx2 = seg2.indexOf(' ');
            if (spaceIdx2 === -1) return;
            var part2 = seg2.substring(0, spaceIdx2);
            var jsonFragment = seg2.substring(spaceIdx2 + 1);
            if (_jsonBuf[part2]) _jsonBuf[part2].push(jsonFragment);
            // We attempt parse when we see a complete JSON object line (heuristic: line ends with })
            if (jsonFragment.endsWith('}')) {
                tryParseJson(part2);
            }
        }
        lastUpdated = new Date();
    }

    function tryParseJson(part) {
        var arr = _jsonBuf[part];
        if (!arr || arr.length === 0) return;
        var text = arr.join('\n');
        // Reset buffer for part
        _jsonBuf[part] = [];
        try {
            var obj = JSON.parse(text);
            if (obj.charge) {
                if (typeof obj.charge.left === 'number') leftPercent = obj.charge.left;
                if (typeof obj.charge.central === 'number') centralPercent = obj.charge.central;
                if (typeof obj.charge.right === 'number') rightPercent = obj.charge.right;
            }
            if (typeof obj.charging_left === 'boolean') leftCharging = obj.charging_left;
            if (typeof obj.charging_central === 'boolean') centralCharging = obj.charging_central;
            if (typeof obj.charging_right === 'boolean') rightCharging = obj.charging_right;
        } catch (e) {
            error = 'JSON parse error: ' + e;
        }
    }

    function parsePercent(text) {
        if (!text) return -1;
        // Prefer pattern _NN_ (percent in filename) before .png
        var re = /[_-](\d{1,3})(?:_|\.|$)/g;
        var match; var candidate = -1;
        while ((match = re.exec(text)) !== null) {
            var val = parseInt(match[1]);
            if (!isNaN(val) && val >= 0 && val <= 100) candidate = val;
        }
        return candidate;
    }

    function buildTooltip() {
        function format(partName, pct, charging) {
            var base = (pct >= 0 ? pct + '%' : '?');
            if (charging) base += ' ⚡';
            return partName + ': ' + base;
        }
        return [
            format('L', leftPercent, leftCharging),
            format('C', centralPercent, centralCharging),
            format('R', rightPercent, rightCharging)
        ].join('  ');
    }

    onLeftPercentChanged: tooltipText = buildTooltip()
    onCentralPercentChanged: tooltipText = buildTooltip()
    onRightPercentChanged: tooltipText = buildTooltip()
    onLeftChargingChanged: tooltipText = buildTooltip()
    onCentralChargingChanged: tooltipText = buildTooltip()
    onRightChargingChanged: tooltipText = buildTooltip()
}
