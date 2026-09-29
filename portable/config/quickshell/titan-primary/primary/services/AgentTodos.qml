pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
    id: root

    property var sessionSummaries: []
    property string tooltipText: "No OpenCode todos found"
    property bool loading: false
    property string error: ""
    property date lastUpdated: new Date(0)

    readonly property string storageRoot: "/home/zarred/.local/share/opencode/storage"
    readonly property string partDirectory: storageRoot + "/part"

    property string _buffer: ""
    property int refCount: 0
    readonly property bool lowPowerMode: Quickshell.env("QUICKSHELL_LOW_POWER_MODE") === "1"
    readonly property int fallbackPollIntervalMs: lowPowerMode ? 300000 : 30000

    property Timer refreshTimer: Timer {
        interval: root.fallbackPollIntervalMs
        repeat: true
        running: root.refCount > 0
        onTriggered: root.refresh()
    }

    property Timer debounceTimer: Timer {
        interval: 500
        repeat: false
        onTriggered: root.refresh()
    }

    property Process watcher: Process {
        command: ["inotifywait", "-m", "-r", "-e", "close_write", "--format", "%w%f", root.partDirectory]
        stdout: SplitParser {
            onRead: function(line) {
                // Ignore output, just restart debounce timer
                debounceTimer.restart()
            }
        }
        // Discard stderr to prevent accumulation
        stderr: SplitParser {
            onRead: function(line) {
                // Discard stderr output to prevent memory accumulation
            }
        }
        running: root.refCount > 0
    }

    property Process scanProcess: Process {
        id: scanProc
        running: false
        stdout: SplitParser {
            onRead: function(chunk) {
                root._buffer += chunk
            }
        }
        onExited: function(code) {
            root._handleScanComplete(code)
        }
    }

    onRefCountChanged: {
        if (refCount > 0) {
            refresh()
        }
    }

    function refresh() {
        if (loading) return
        loading = true
        error = ""
        _buffer = ""
        scanProcess.running = false
        var script = _buildScannerScript()
        scanProcess.command = ["python3", "-c", script]
        scanProcess.environment = ["PYTHONUNBUFFERED=1","PYTHONDONTWRITEBYTECODE=1"]
        scanProcess.running = true
    }

    function _buildScannerScript() {
        var quotedPartDir = JSON.stringify(partDirectory)
        return [
            "import json, os, time",
            "p_dir = " + quotedPartDir,
            "c_path = '/tmp/opencode_todo_cache.json'",
            "now = time.time()",
            "cutoff = now - 3600",
            "cache = {}",
            "try:",
            "    with open(c_path, 'r') as f: cache = json.load(f)",
            "except: pass",
            "res, new_c = {}, {}",
            "if os.path.exists(p_dir):",
            "    for r, d, files in os.walk(p_dir):",
            "        for f in files:",
            "            if not f.startswith('prt_') or not f.endswith('.json'): continue",
            "            p = os.path.join(r, f)",
            "            try:",
            "                mt = os.path.getmtime(p)",
            "                if mt < cutoff: continue",
            "                ent = cache.get(p)",
            "                if ent and ent['mt'] == mt:",
            "                    d = ent['d']",
            "                else:",
            "                    with open(p, 'r') as fh: raw = json.load(fh)",
            "                    if raw.get('tool') != 'todowrite': d = None",
            "                    else:",
            "                        st = raw.get('state', {})",
            "                        tds = (st.get('metadata') or {}).get('todos') or (st.get('input') or {}).get('todos') or []",
            "                        d = {",
            "                            'sid': raw.get('sessionID', 'unknown'),",
            "                            'mid': raw.get('messageID'),",
            "                            'ts': int(st.get('time', {}).get('end') or st.get('time', {}).get('start') or 0),",
            "                            'tds': [{",
            "                                'id': t.get('id') or t.get('content') or '',",
            "                                'content': t.get('content') or '',",
            "                                'status': (t.get('status') or 'pending').strip().lower(),",
            "                                'priority': (t.get('priority') or '').lower()",
            "                            } for t in tds]",
            "                        }",
            "                if d:",
            "                    new_c[p] = {'mt': mt, 'd': d}",
            "                    sid = d['sid']",
            "                    if sid not in res or d['ts'] >= res[sid]['ts']:",
            "                        res[sid] = d",
            "            except: continue",
            "try:",
            "    with open(c_path, 'w') as f: json.dump(new_c, f)",
            "except: pass",
            "out = []",
            "for sid, info in res.items():",
            "    tsks = info['tds']",
            "    task_preview = tsks[:24]",
            "    out.append({",
            "        'sessionID': sid, 'messageID': info['mid'], 'timestamp': info['ts'],",
            "        'total': len(tsks),",
            "        'completed': sum(1 for t in tsks if t['status'] == 'completed'),",
            "        'in_progress': sum(1 for t in tsks if t['status'] == 'in_progress'),",
            "        'pending': sum(1 for t in tsks if t['status'] not in ('completed', 'in_progress')),",
            "        'tasks': task_preview",
            "    })",
            "out.sort(key=lambda x: x['timestamp'], reverse=True)",
            "print(json.dumps(out[:3]))"
        ].join("\n")
    }

    function _handleScanComplete(code) {
        var output = (_buffer || "").trim()
        _buffer = ""
        loading = false
        if (!output) {
            if (code !== 0) {
                error = "OpenCode todo scan failed (" + code + ")"
            }
            sessionSummaries = []
            tooltipText = "No OpenCode todos found"
            return
        }
        try {
            var parsed = JSON.parse(output)
            sessionSummaries = parsed
            tooltipText = _buildTooltip(parsed)
            lastUpdated = new Date()
        } catch (e) {
            error = "Failed to parse todo data: " + e
            sessionSummaries = []
            tooltipText = "OpenCode todos unavailable"
        }
    }

    function _buildTooltip(entries) {
        if (!entries || entries.length === 0) {
            return "No OpenCode todos found"
        }
        var lines = ["Opencode agent sessions: " + entries.length]
        for (var i = 0; i < entries.length; i++) {
            var sess = entries[i]
            var label = sess.sessionID ? sess.sessionID.slice(0, 8) : ("Session " + (i + 1))
            var totals = (sess.completed || 0) + "/" + (sess.total || 0) + " complete"
            lines.push(label + " • " + totals + ", " + (sess.in_progress || 0) + " in progress")
            var tasks = sess.tasks || []
            var previewCount = Math.min(tasks.length, 3)
            for (var j = 0; j < previewCount; j++) {
                var task = tasks[j]
                var status = (task.status || "pending")
                var prefix = status === "completed" ? "✓" : (status === "in_progress" ? "…" : "•")
                lines.push("  " + prefix + " " + task.content)
            }
            if (tasks.length > previewCount) {
                lines.push("  … +" + (tasks.length - previewCount) + " more")
            }
        }
        return lines.join("\n")
    }
}
