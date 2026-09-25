pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
    id: root

    property var generations: []
    property bool loading: false
    property string error: ""
    property int selectedGeneration: -1
    property string _buffer: ""

    signal generationSelected(int generation)

    function refresh() {
        if (loading) return
        loading = true
        error = ""
        _buffer = ""
        var p = Qt.createQmlObject('import Quickshell.Io; import QtQuick; Process { \n  id: genProc; \n  stdout: SplitParser { onRead: function(data){ root._handleOutput(data) } } \n}', root)
        p.exited.connect(function() {
            root._parseBuffer()
            // CRITICAL: Destroy process to prevent memory leak
            p.destroy()
        })
        p.command = ["/home/zarred/.config/quickshell/primary/scripts/nix-generations"]
        p.running = true
    }

    function _handleOutput(data) {
        _buffer += data
    }

    function _parseBuffer() {
        var trimmed = _buffer.trim()
        if (!trimmed) {
            loading = false
            return
        }
        try {
            var parsed = JSON.parse(trimmed)
            if (Array.isArray(parsed)) {
                generations = parsed
            }
        } catch (e) {
            error = "Parse failed: " + e
        }
        loading = false
    }

    Component.onCompleted: refresh()
}
