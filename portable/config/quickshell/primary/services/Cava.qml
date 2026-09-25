pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
    id: root

    property list<int> values: Array(20)  // 20 bars by default
    property int bars: 20
    property int refCount
    property bool enabled: true

    onRefCountChanged: {
        var shouldRun = root.enabled && root.refCount > 0
        if (cavaProc.running !== shouldRun)
            cavaProc.running = shouldRun
    }

    onBarsChanged: {
        root.values = Array(bars);
        if (root.enabled && root.refCount > 0) {
            cavaProc.running = false;
            cavaProc.running = true;
        }
    }

    property Process cavaProc: Process {
        id: cavaProc

        running: root.enabled && root.refCount > 0
        command: ["sh", "-c", `printf '[general]\nframerate=15\nbars=${root.bars}\nsleep_timer=3\n[output]\nchannels=mono\nmethod=raw\nraw_target=/dev/stdout\ndata_format=ascii\nascii_max_range=100' | cava -p /dev/stdin`]
        stdout: SplitParser {
            onRead: data => {
                if (!root.refCount)
                    return

                var nextValues = data.slice(0, -1).split(";").map(v => parseInt(v, 10))
                if (nextValues.length === root.bars)
                    root.values = nextValues
            }
        }
        stderr: SplitParser {
            onRead: function(_) {
                // Discard stderr output to prevent long-running buffer growth
            }
        }
    }
}
