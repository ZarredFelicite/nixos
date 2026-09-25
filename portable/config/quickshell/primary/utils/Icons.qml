pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import Qt.labs.folderlistmodel

QtObject {
    id: root

    // Enable to print candidate search strings and matches
    property bool debug: false

    // Directory containing per-app icon overrides (png/svg)
    readonly property string overrideDir: "/home/zarred/pictures/icons"
    // Lightweight pre-tinted SVGs used directly by high-churn window delegates.
    readonly property var bundledWindowIcons: ({
        "kitty": Qt.resolvedUrl("../assets/window-icons/kitty.svg"),
        "mpv": Qt.resolvedUrl("../assets/window-icons/mpv.svg")
    })
    // Map of base name -> absolute file path (prefer svg over png)
    property var _overrideIndex: ({})
    property bool _overrideBuilt: false
    readonly property url overrideDirUrl: "file:///" + overrideDir.replace(/^\//, "")

    // Synchronous folder listing to index overrides early (may not work in all envs)
    property FolderListModel overridesModel: FolderListModel {
        id: flm
        folder: root.overrideDirUrl
        nameFilters: ["*.svg", "*.png"]
        showDirs: false
        showDotAndDotDot: false
        onCountChanged: { if (!root._overrideBuilt) root._buildIndex() }
        onStatusChanged: { if (!root._overrideBuilt) root._buildIndex() }
        Component.onCompleted: {
            if (root.debug) console.log(`[Icons] overrides model folder=${folder} status=${status} count=${count}`)
            if (!root._overrideBuilt) root._buildIndex()
        }
    }

    // Fallback indexer using a shell ls to ensure we can index early
    signal overridesReady()
    property Process overrideIndexProc: Process {
        id: indexProc
        running: false
        stdout: SplitParser { onRead: function(line) { root._addOverridePath(line) } }
        onExited: function(code, status) {
            root._overrideBuilt = true;
            if (root.debug) console.log(`[Icons] process index built with ${Object.keys(root._overrideIndex).length} keys (code=${code})`)
            root.overridesReady();
        }
    }

    function initOverrides() {
        root._overrideIndex = {};
        root._overrideBuilt = false;
        // Prefer svg first so later pngs don't overwrite
        overrideIndexProc.command = ["sh", "-lc", "ls -1 '" + root.overrideDir + "'/*.svg '" + root.overrideDir + "'/*.png 2>/dev/null || true"]
        overrideIndexProc.running = true;
    }

    function _addOverridePath(path) {
        if (!path) return;
        var p = String(path).trim();
        if (p.length === 0) return;
        var lower = p.toLowerCase();
        var slash = lower.lastIndexOf("/");
        var dot = lower.lastIndexOf(".");
        if (slash < 0 || dot < 0 || dot <= slash) return;
        var base = lower.substring(slash + 1, dot); // filename without extension
        var ext = lower.substring(dot + 1);
        // Prefer svg when both exist
        var existing = root._overrideIndex[base];
        if (!existing || (ext === "svg" && existing.toLowerCase().lastIndexOf('.svg') !== existing.length - 4)) {
            root._overrideIndex[base] = p;
            if (root.debug) console.log(`[Icons] indexed override: ${base} -> ${p}`)
        }
    }

    function _buildIndex() {
        if (overridesModel.status !== 2 /* FolderListModel.Ready */) {
            if (root.debug) console.log(`[Icons] overrides model not ready (status=${overridesModel.status}), deferring index build; folder=${overridesModel.folder}`)
            return;
        }
        root._overrideIndex = {};
        for (var i = 0; i < overridesModel.count; i++) {
            var entry = overridesModel.get(i);
            if (!entry) continue;
            var p = entry.filePath || entry.fileURL || entry.fileUrl || entry.fileName; // try common roles
            // If only fileName is present, construct full path
            if (p && p.indexOf('/') < 0 && entry.fileName) {
                p = root.overrideDir + "/" + entry.fileName;
            }
            _addOverridePath(p);
        }
        root._overrideBuilt = true;
        if (root.debug) console.log(`[Icons] override index built with ${overridesModel.count} files`)
    }

    function _canon(name) {
        if (!name) return "";
        return String(name).toLowerCase();
    }

    function _lookupOverride(className, iconName) {
        var set = {};
        var list = [];
        function addKey(k) { if (!set[k]) { set[k] = true; list.push(k) } }
        function push(n) {
            var s = root._canon(n);
            if (!s) return;
            addKey(s);
            addKey(s.replace(/[\._]/g, "-"));
            addKey(s.replace(/[^a-z0-9]/g, ""));
            var dash = s.split("-")[0];
            if (dash) addKey(dash);
        }
        push(className);
        push(iconName);
        if (root.debug) console.log(`[Icons] override candidates for class="${className}" icon="${iconName}": ${list.join(", ")}`)
        for (var i = 0; i < list.length; i++) {
            var key = list[i];
            var path = root._overrideIndex[key];
            if (path && path.length > 0) return path;
        }
        return "";
    }

    // Public: get override path by a single name (e.g., player name)
    function getOverrideFor(name) {
        if (!name) return "";
        if (!root._overrideBuilt) {
            // Attempt to build if possible; if still not ready, init process indexer
            _buildIndex();
            if (!root._overrideBuilt) initOverrides();
        }
        var key = root._canon(name);
        // Try variants similar to _lookupOverride
        var variants = [key, key.replace(/[\._]/g, "-"), key.replace(/[^a-z0-9]/g, ""), key.split("-")[0]];
        for (var i = 0; i < variants.length; i++) {
            var v = variants[i];
            if (!v) continue;
            var p = root._overrideIndex[v];
            if (p && p.length > 0) return p;
        }
        return "";
    }

    // Manually refresh the overrides index (e.g., after adding files)
    function refreshOverrides() {
        root._overrideBuilt = false;
        // Nudge model to refresh, then rebuild index
        overridesModel.folder = root.overrideDirUrl
        _buildIndex();
    }

    function getCustomWindowIcon(className: string): string {
        const entry = DesktopEntries.heuristicLookup(className);
        const icon = entry?.icon;
        if (icon && icon.indexOf("/") === 0) {
            return icon;
        }
        const themePath = Quickshell.iconPath(icon, "application-x-executable");
        return themePath;
    }

    // Return a QML Image source that prefers theme provider for crisp/scalable icons
    function getIconSource(className: string): string {
        const entry = DesktopEntries.heuristicLookup(className);
        const icon = entry?.icon;
        const bundledIcon = bundledWindowIcons[_canon(className)] || bundledWindowIcons[_canon(icon)];
        if (bundledIcon) {
            return bundledIcon;
        }
        // Repo-level override: prefer files in overrideDir
        const overridePath = _lookupOverride(className, icon);
        if (overridePath && overridePath.length > 0) {
            if (root.debug) console.log(`[Icons] matched override: class="${className}" icon="${icon}" -> ${overridePath}`)
            return overridePath;
        }
        if (icon && icon.indexOf("/") === 0) {
            return icon; // absolute path
        }
        if (icon && icon && icon.length > 0) {
            const path = Quickshell.iconPath(icon, "application-x-executable");
            if (path && path.length > 0) {
                if (root.debug) console.log(`[Icons] theme path: class="${className}" icon="${icon}" -> ${path}`)
                return path;
            }
            // Fallback to theme provider if no resolved path
            if (root.debug) console.log(`[Icons] theme provider: class="${className}" icon="${icon}" -> image://theme/${icon}`)
            return `image://theme/${icon}`;
        }
        return "";
    }


}
