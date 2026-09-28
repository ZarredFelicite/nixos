pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// AirPods battery service
// Reads three temp files updated externally every second:
//   /tmp/airpods_battery_left
//   /tmp/airpods_battery_case
//   /tmp/airpods_battery_right
// Each file expected to contain an image path or inline image data (Waybar used `cat` directly).
// Additionally attempts to parse a percentage from the filename or a trailing `_NN` pattern inside text.
// Exposes:
//  - leftPath / casePath / rightPath: string (raw file content trimmed)
//  - leftPercent / casePercent / rightPercent: int (-1 if unknown)
//  - tooltipText: combined percentages for tooltip
//  - lastUpdated: date of last successful poll
//  - error: last error string (non-fatal)
// Poll interval defaults to 1000 ms (matching original Waybar config).
QtObject {
    id: root

    // Raw content (likely image path)
    property string leftPath: ""
    property string casePath: ""
    property string rightPath: ""

    // Parsed percentages (-1 means unknown)
    property int leftPercent: -1
    property int casePercent: -1
    property int rightPercent: -1

    property string tooltipText: buildTooltip()

    property date lastUpdated: new Date(0)
    property string error: ""

    property int interval: 5000

    // Consumers increment refCount to enable polling (pattern used by other services)
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
        // Read all three files using a single shell process for efficiency
        // Use tr to replace newlines with a delimiter so each battery data is on one line
        var script = 'L="$(cat /tmp/airpods_battery_left 2>/dev/null | tr "\\n" "\\t")"; C="$(cat /tmp/airpods_battery_case 2>/dev/null | tr "\\n" "\\t")"; R="$(cat /tmp/airpods_battery_right 2>/dev/null | tr "\\n" "\\t")"; echo "__L__${L}"; echo "__C__${C}"; echo "__R__${R}"';
        var proc = Qt.createQmlObject('import Quickshell.Io; import QtQuick; Process { stdout: SplitParser { onRead: function(line){ root._handle(line) } } }', root)
        proc.command = ["sh", "-c", script]
        proc.onExited.connect(function(code) {
            if (code !== 0) root.error = "Process failed: " + code
            proc.destroy()
        })
        proc.running = true
    }

    function _handle(line) {
        line = (line||"").trim();
        if (!line) return;
        if (line.startsWith("__L__")) {
            var content = line.substring(5).trim().replace(/\t/g, '\n');
            var result = parseContent(content);
            leftPath = result.path;
            leftPercent = result.percent;
        } else if (line.startsWith("__C__")) {
            var content = line.substring(5).trim().replace(/\t/g, '\n');
            var result = parseContent(content);
            casePath = result.path;
            casePercent = result.percent;
        } else if (line.startsWith("__R__")) {
            var content = line.substring(5).trim().replace(/\t/g, '\n');
            var result = parseContent(content);
            rightPath = result.path;
            rightPercent = result.percent;
        }
        lastUpdated = new Date();
    }

    function parseContent(content) {
        if (!content) return { path: "", percent: -1 };
        
        var lines = content.split('\n');
        var path = lines[0] || "";
        var percent = -1;
        
        // If there's a second line, try to parse it as JSON
        if (lines.length > 1 && lines[1].trim()) {
            try {
                var jsonData = JSON.parse(lines[1]);
                if (jsonData && jsonData.charge) {
                    // Determine which battery this is based on the path
                    if (path.includes('left')) {
                        percent = jsonData.charge.left >= 0 ? jsonData.charge.left : -1;
                    } else if (path.includes('case')) {
                        percent = jsonData.charge.case >= 0 ? jsonData.charge.case : -1;
                    } else if (path.includes('right')) {
                        percent = jsonData.charge.right >= 0 ? jsonData.charge.right : -1;
                    }
                }
            } catch (e) {
                // JSON parsing failed, fall back to filename parsing
                percent = parsePercentFromPath(path);
            }
        } else {
            // Only one line or empty second line, parse from filename
            percent = parsePercentFromPath(path);
        }
        
        return { path: path, percent: percent };
    }

    function parsePercentFromPath(text) {
        if (!text) return -1;
        // Try number patterns like _85, -85, or 85 before extension
        var re = /(^|[^\d])(\d{1,3})(?=%|[^\d]|$)/g;
        var match; var candidate = -1;
        while ((match = re.exec(text)) !== null) {
            var val = parseInt(match[2]);
            if (!isNaN(val) && val >= 0 && val <= 100) candidate = val; // keep last valid
        }
        return candidate;
    }

    function buildTooltip() {
        var parts = [];
        parts.push("L: " + (leftPercent >= 0 ? (leftPercent + "%") : "?") );
        parts.push("Case: " + (casePercent >= 0 ? (casePercent + "%") : "?") );
        parts.push("R: " + (rightPercent >= 0 ? (rightPercent + "%") : "?"));
        return parts.join("  ");
    }

    // Recompute tooltip when any percent changes
    onLeftPercentChanged: tooltipText = buildTooltip()
    onCasePercentChanged: tooltipText = buildTooltip()
    onRightPercentChanged: tooltipText = buildTooltip()
}
