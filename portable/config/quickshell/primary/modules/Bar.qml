pragma ComponentBehavior: Bound

import "../widgets"
import "bar"
import "bar/components"
import "bar/popouts" as BarPopouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts 1.15
import QtQuick.Dialogs
import "../services"
import ".." as Config

Variants {
    model: Quickshell.screens

    property string resolvedPrimaryMonitor: Config.Config.resolvePrimaryMonitor(Quickshell.screens)

    Scope {
        id: scope

        required property ShellScreen modelData
        
        readonly property bool isPrimaryMonitor: modelData.name === resolvedPrimaryMonitor
        readonly property string barType: isPrimaryMonitor ? "full" : "workspaces-only"
        readonly property bool disableStocksWidget: true
        readonly property bool aiVisualizerEnabled: Quickshell.env("QUICKSHELL_DISABLE_AI_VISUALIZER") !== "1"
        readonly property bool legacyAiVisualizerEnabled: Quickshell.env("QUICKSHELL_AI_VISUALIZER") === "legacy"
        property real brainFadeX: 0
        property real brainFadeY: 0
        property real brainFadeSize: 36
        property real brainFadeOpacity: 0
        property bool brainFadePositionValid: false
        property bool brainFadeReady: false
        
        // Debug function to write widget positions to JSON file
        function writeWidgetPositions(mainLayout) {
            if (!isPrimaryMonitor || !mainLayout) return
            
            let widgets = []
            
            // Recursively collect all visible widgets with non-zero width
            function collectAllWidgets(item, offsetX, offsetY) {
                if (!item) return
                
                let itemX = offsetX + item.x
                let itemY = offsetY + item.y
                
                // Add this item if it has a name and is visible
                if (item.objectName && item.width > 0 && item.height > 0) {
                    widgets.push({
                        name: item.objectName,
                        x: Math.round(itemX),
                        y: Math.round(itemY),
                        width: Math.round(item.width),
                        height: Math.round(item.height)
                    })
                }
                
                // Recursively check children
                if (item.children && item.children.length > 0) {
                    for (let i = 0; i < item.children.length; i++) {
                        collectAllWidgets(item.children[i], itemX, itemY)
                    }
                }
            }
            
            // Collect from all mainLayout children
            for (let i = 0; i < mainLayout.children.length; i++) {
                collectAllWidgets(mainLayout.children[i], 0, 0)
            }
            
            let jsonData = {
                monitor: modelData.name,
                timestamp: new Date().toISOString(),
                widgets: widgets
            }
            
            let filepath = "/tmp/quickshell-widget-positions.json"
            let jsonStr = JSON.stringify(jsonData, null, 2)
            
            // Use Process to write JSON file
            let proc = Qt.createQmlObject('import Quickshell.Io; Process { }', scope)
            proc.command = ["bash", "-c", "printf '%s' '" + jsonStr.replace(/'/g, "'\\''") + "' > '" + filepath + "'"]
            
            proc.onExited.connect(function() {
                console.log("[Bar Debug] Widget positions written to: " + filepath)
                proc.destroy()
            })
            
            proc.running = true
        }

        function findItemByObjectName(rootItem, name) {
            if (!rootItem || !name) return null
            if (rootItem.objectName === name) return rootItem

            if (rootItem.item && rootItem.item.objectName === name) return rootItem.item
            if (rootItem.contentItem && rootItem.contentItem.objectName === name) return rootItem.contentItem

            if (rootItem.children && rootItem.children.length > 0) {
                for (let i = 0; i < rootItem.children.length; i++) {
                    let found = findItemByObjectName(rootItem.children[i], name)
                    if (found) return found
                }
            }

            if (rootItem.item) {
                let foundItem = findItemByObjectName(rootItem.item, name)
                if (foundItem) return foundItem
            }

            if (rootItem.contentItem) {
                let foundContent = findItemByObjectName(rootItem.contentItem, name)
                if (foundContent) return foundContent
            }

            return null
        }

        function isMouseArea(item) {
            return item
                && typeof item.containsMouse === "boolean"
                && typeof item.pressed === "boolean"
        }

        function collectInteractiveWidgets(rootItem) {
            const candidates = []
            const visited = []

            function visit(item) {
                if (!item || visited.indexOf(item) >= 0)
                    return
                visited.push(item)

                if (item.children) {
                    for (const child of item.children) {
                        if (isMouseArea(child) && child.parent
                                && candidates.indexOf(child.parent) < 0) {
                            candidates.push(child.parent)
                        }
                        visit(child)
                    }
                }
                if (item.item && item.item !== item)
                    visit(item.item)
            }

            function contains(ancestor, descendant) {
                let current = descendant
                while (current) {
                    current = current.parent
                    if (current === ancestor)
                        return true
                }
                return false
            }

            visit(rootItem)

            // Keep only the leaf widget for each interactive branch. This prevents
            // a container row or pill wrapper from scaling along with its child widget.
            return candidates.filter(candidate => !candidates.some(other => other !== candidate
                && contains(candidate, other)))
        }

        function defaultAnchorForPopoutName(name) {
            switch (name) {
            case "audio-in": return "AudioInputRing"
            case "audio-out": return "AudioOutputRing"
            case "brightness": return "BrightnessRing"
            case "network": return "NetworkRings"
            case "networks-menu": return "NetworkRings"
            case "bluetooth": return "BluetoothRing"
            case "tooltip-news": return "NewsPill"
            case "tooltip-stocks": return "StocksPill"
            case "tooltip-players": return "MprisPill"
            case "tooltip-zmk": return "ZmkBatteryPill"
            case "tooltip-bluetooth-battery": return "AirpodsBatteryPill"
            case "tooltip-weather": return "WeatherPill"
            case "tooltip-updates": return "UpdatesIndicator"
            case "tooltip-todos": return "SystemRings_TodoIndicator"
            case "tooltip-agent-todos": return "AgentTodosPill"
            case "tooltip-systemd": return "SystemdFailedIndicator"
            case "tooltip-codex-usage": return "CodexUsageIndicator"
            case "pi-dashboard-questions": return "CodexUsageIndicator"
            case "calendar-agenda": return "CalendarIcon"
            case "tooltip-memory": return "MemoryRings"
            case "tooltip-battery": return "BatteryIndicator"
            case "tooltip-gpu-nvidia": return "NvidiaGPURing"
            case "tooltip-gpu-amd": return "AmdGPURing"
            case "tooltip-disk": return "DiskRing"
            case "restic-tooltip": return "ResticIndicator"
            case "tooltip-alphaess": return "AlphaESSFlow"
            case "tooltip-video-stream": return "VideoStreamIndicator"
            case "tooltip-mail": return "MailIndicator"
            case "tooltip-submap": return "HyprlandSubmapIndicator"
            case "tooltip-recording": return "RecordingIndicator"
            case "screen-recording-menu": return "RecordingIndicator"
            case "screen-recording": return "RecordingIndicator"
            case "printer3d-menu": return "Printer3DIndicator"
            case "music-player": return "MprisPill"
            case "computer-status": return "ComputerStatusIndicator"
            case "ai-settings": return "AIVisualizer"
            }

            return ""
        }
        
        // Timer to write widget positions after layout settles
        Timer {
            id: positionWriteTimer
            interval: 500
            repeat: false
            onTriggered: {
                if (barLoader.item && scope.isPrimaryMonitor) {
                    scope.writeWidgetPositions(barLoader.item)
                }
            }
        }

        IpcHandler {
            enabled: scope.isPrimaryMonitor
            target: "bar"

            function toggleNotifications(): void {
                if (popouts.hasCurrent && popouts.currentName === "notifications") {
                    popouts.close()
                } else {
                    popouts.openPopout("notifications")
                }
            }

            function toggleShortcuts(): void {
                if (popouts.hasCurrent && popouts.currentName === "shortcuts") {
                    popouts.close()
                } else {
                    popouts.openPopout("shortcuts")
                }
            }
        }

        Timer {
            id: debugPopoutTimer
            interval: Config.Config.debugPopoutDelayMs
            repeat: false
            onTriggered: {
                if (!scope.isPrimaryMonitor || !popouts || !barLoader.item) return
                if (!Config.Config.debugPopoutsEnabled || !Config.Config.debugPopoutName) return

                let anchorName = Config.Config.debugPopoutAnchorObjectName
                if (!anchorName) {
                    anchorName = scope.defaultAnchorForPopoutName(Config.Config.debugPopoutName)
                }
                let anchorItem = anchorName ? scope.findItemByObjectName(barLoader.item, anchorName) : null
                let centerX = undefined
                let bottomY = undefined
                let width = undefined

                if (anchorItem) {
                    let pos = popouts.mapFromItem(anchorItem, anchorItem.width / 2, anchorItem.height)
                    centerX = pos.x
                    bottomY = pos.y
                    width = anchorItem.width
                }

                console.log("[DebugPopout] open", Config.Config.debugPopoutName,
                            "anchor=", anchorName,
                            "found=", !!anchorItem,
                            "centerX=", centerX,
                            "bottomY=", bottomY,
                            "width=", width)
                popouts.openPopout(Config.Config.debugPopoutName, centerX, bottomY, width)
            }
        }

        property string finalMessageAutoSessionId: ""

        function openQuestionsView(anchorObjectName, finalSessionId) {
            if (!scope.isPrimaryMonitor || !barLoader.item || !PiDashboardQuestions.hasItems)
                return

            PiDashboardQuestions.focusedFinalSessionId = finalSessionId || ""
            var anchorName = anchorObjectName || "CodexUsageIndicator"
            var anchorItem = scope.findItemByObjectName(barLoader.item, anchorName)
            var centerX = undefined
            var bottomY = undefined
            var width = undefined
            if (anchorItem) {
                var pos = popouts.mapFromItem(anchorItem, anchorItem.width / 2, anchorItem.height)
                centerX = pos.x
                bottomY = pos.y
                width = anchorItem.width
            }
            popouts.openPopout("pi-dashboard-questions", centerX, bottomY, width)
        }

        Timer {
            id: questionAutoOpenTimer
            interval: 150
            repeat: false
            onTriggered: scope.openQuestionsView("CodexUsageIndicator")
        }

        Timer {
            id: finalMessageAutoOpenTimer
            interval: 150
            repeat: false
            onTriggered: {
                var sessionId = scope.finalMessageAutoSessionId
                scope.openQuestionsView("AgentMessagePill:" + sessionId, sessionId)
                finalMessageAutoCloseTimer.restart()
            }
        }

        Timer {
            id: finalMessageAutoCloseTimer
            interval: 5000
            repeat: false
            onTriggered: {
                if (popouts.hasCurrent
                        && popouts.currentName === "pi-dashboard-questions"
                        && !PiDashboardQuestions.hasQuestions
                        && !popouts.currentHovered)
                    popouts.close()
            }
        }

        Connections {
            target: PiDashboardQuestions
            function onNewQuestion() {
                finalMessageAutoCloseTimer.stop()
                questionAutoOpenTimer.restart()
            }
            function onNewFinalMessage(sessionId) {
                scope.finalMessageAutoSessionId = sessionId
                finalMessageAutoOpenTimer.restart()
            }
            function onHasQuestionsChanged() {
                if (PiDashboardQuestions.hasQuestions) {
                    finalMessageAutoCloseTimer.stop()
                    questionAutoOpenTimer.restart()
                }
            }
        }

        Connections {
            target: Config.Config
            function onDebugPopoutsEnabledChanged() {
                if (!scope.isPrimaryMonitor || !barLoader.item) return
                if (Config.Config.debugPopoutsEnabled && Config.Config.debugPopoutName) {
                    debugPopoutTimer.restart()
                }
            }
            function onDebugPopoutNameChanged() {
                if (!scope.isPrimaryMonitor || !barLoader.item) return
                if (Config.Config.debugPopoutsEnabled && Config.Config.debugPopoutName) {
                    debugPopoutTimer.restart()
                }
            }
            function onDebugPopoutDelayMsChanged() {
                if (!scope.isPrimaryMonitor || !barLoader.item) return
                if (Config.Config.debugPopoutsEnabled && Config.Config.debugPopoutName) {
                    debugPopoutTimer.restart()
                }
            }
        }
        
        Component.onCompleted: {
            positionWriteTimer.start()
            _avaWakeWasActive = TtsMonitor.isAvaWakeActive
        }

        // Exclusion strip reserving bar height (only for primary monitors)
        StyledWindow {
            screen: scope.modelData
            name: "bar-exclusion"
            // Only primary monitors reserve exclusive space
            anchors.top: scope.isPrimaryMonitor
            anchors.left: scope.isPrimaryMonitor
            anchors.right: scope.isPrimaryMonitor
            implicitHeight: scope.isPrimaryMonitor ? 36 : 0
            exclusiveZone: scope.isPrimaryMonitor ? 36 : 0
            visible: scope.isPrimaryMonitor
            mask: Region {}
        }

        // Separate BrainGraph fade layer so Hyprland blur alpha can be tuned without
        // affecting popouts/menus in the main primary-bar namespace.
        StyledWindow {
            screen: scope.modelData
            name: "brain-fade"
            anchors.top: scope.isPrimaryMonitor
            anchors.left: scope.isPrimaryMonitor
            anchors.right: scope.isPrimaryMonitor
            implicitHeight: Math.max(36, scope.brainFadeSize)
            visible: scope.aiVisualizerEnabled && scope.legacyAiVisualizerEnabled && scope.isPrimaryMonitor && scope.brainFadeOpacity > 0 && scope.brainFadePositionValid && scope.brainFadeReady
            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            mask: Region {}

            BrainGraph {
                x: scope.brainFadeX
                y: scope.brainFadeY
                width: scope.brainFadeSize
                height: scope.brainFadeSize
                configScale: 1.0
                graphVisible: false
                shadowVisible: true
                opacity: scope.brainFadeOpacity
                paused: true
            }
        }

        // Fullscreen AI Visualizer Overlay
        // Auto-open behavior: only for "ava" wake flow (agent+deliver),
        // not plain transcribe mode.
        // Keep it open through the whole turn (record -> generate/tools -> TTS)
        // and close shortly after everything goes idle.
        property bool _avaWakeWasActive: false
        property bool _fullscreenAutoOpened: false

        function _shouldKeepFullscreenOpen() {
            return TtsMonitor.isAvaWakeActive
                || Ember.isGenerating
                || TtsMonitor.isTtsActive
        }

        function _scheduleFullscreenAutoCloseIfIdle() {
            if (!_fullscreenAutoOpened) return
            if (_shouldKeepFullscreenOpen()) {
                fullscreenAutoCloseTimer.stop()
                return
            }
            fullscreenAutoCloseTimer.restart()
        }

        Connections {
            target: TtsMonitor

            function onIsAvaWakeActiveChanged() {
                if (scope.aiVisualizerEnabled && TtsMonitor.isAvaWakeActive && !_avaWakeWasActive) {
                    fullscreenOverlay.visible = true
                    _fullscreenAutoOpened = true
                    fullscreenAutoCloseTimer.stop()
                }
                _avaWakeWasActive = TtsMonitor.isAvaWakeActive
                _scheduleFullscreenAutoCloseIfIdle()
            }

            function onIsTtsActiveChanged() {
                if (_fullscreenAutoOpened && TtsMonitor.isTtsActive)
                    fullscreenAutoCloseTimer.stop()
                _scheduleFullscreenAutoCloseIfIdle()
            }
        }

        Connections {
            target: Ember

            function onIsGeneratingChanged() {
                if (_fullscreenAutoOpened && Ember.isGenerating)
                    fullscreenAutoCloseTimer.stop()
                _scheduleFullscreenAutoCloseIfIdle()
            }
        }

        Timer {
            id: fullscreenAutoCloseTimer
            interval: 7000
            repeat: false
            onTriggered: {
                if (_fullscreenAutoOpened && !_shouldKeepFullscreenOpen()) {
                    fullscreenOverlay.visible = false
                    _fullscreenAutoOpened = false
                }
            }
        }

        StyledWindow {
            id: fullscreenOverlay
            screen: scope.modelData
            name: "ai-visualizer-fullscreen"
            visible: false

            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            // Match old fullscreen visualizer feel: no full-screen blackout,
            // let BrainGraph's own radial shadow provide center fade.
            color: "transparent"

            // Key handling surface (Esc closes fullscreen)
            Item {
                anchors.fill: parent
                focus: fullscreenOverlay.visible
                Keys.onEscapePressed: {
                    fullscreenOverlay.visible = false
                    _fullscreenAutoOpened = false
                    fullscreenAutoCloseTimer.stop()
                }
            }

            // Click background to close
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    fullscreenOverlay.visible = false
                    _fullscreenAutoOpened = false
                    fullscreenAutoCloseTimer.stop()
                }
            }

            BrailleActivityVisualizer {
                id: fullscreenBrailleActivityVisualizer
                anchors.centerIn: parent
                width: 600
                height: 200
                visualizerEnabled: scope.aiVisualizerEnabled && !scope.legacyAiVisualizerEnabled && fullscreenOverlay.visible
                manualMode: AiVisualizerPreview.mode
                audioActive: TtsMonitor.isTtsPlaying || TtsMonitor.isRecordingActive
                audioLevel: TtsMonitor.isRecordingActive
                    ? TtsMonitor.recordingLevel
                    : TtsMonitor.ttsLevel
                audioSource: TtsMonitor.isRecordingActive
                    ? "stt"
                    : ((TtsMonitor.isTtsPlaying || TtsMonitor.isTtsActive) ? "tts" : "none")
                gatewayUp: Ember.gatewayUp
                activityMode: TtsMonitor.isTtsPlaying
                    ? "generating"
                    : (TtsMonitor.isRecordingActive
                        ? "thinking"
                        : (Ember.isCompacting
                            ? "compacting"
                            : (Ember.isTextGenerating
                                ? "generating"
                                : (Ember.isThinkingOrToolActive ? "thinking" : "idle"))))
                visible: scope.aiVisualizerEnabled && !scope.legacyAiVisualizerEnabled && fullscreenOverlay.visible
            }

            BrainGraph {
                id: fullscreenBrainGraph
                anchors.centerIn: parent
                width: 600
                height: 600
                configScale: 8.0
                connectionDistanceMultiplier: 1.2
                connectionLineWidth: 3.0
                modulateConnectionLineWidth: true
                ringNodes: true
                maxConnectionCount: 240
                // Compensate motion for larger fullscreen graph size.
                // Boosted per request for faster fullscreen movement.
                speedScaleMultiplier: (configScale / 6.0) * 1.4
                visible: scope.aiVisualizerEnabled && scope.legacyAiVisualizerEnabled && fullscreenOverlay.visible
                paused: !scope.aiVisualizerEnabled || !scope.legacyAiVisualizerEnabled || !fullscreenOverlay.visible
                scale: fullscreenOverlay.visible ? 1 : 0.8
                Behavior on scale {
                    NumberAnimation { duration: 300; easing.type: Easing.OutBack }
                }

                // Sync state with bar visualizer - Ember drives AI activity.
                mode: TtsMonitor.isRecordingActive ? 2 : 0
                speedMode: (Ember.isThinkingOrToolActive || Ember.isCompacting) ? "high" : TtsMonitor.brainSpeedMode
                graphColor: !Ember.gatewayUp
                    ? "#6e6a86"
                    : ((Ember.isThinkingOrToolActive || Ember.isCompacting) ? "#B388FF" : "#c4a7e7")
                graphVisible: true

                // Prevent click from closing when clicking the visualizer itself
                MouseArea {
                    anchors.fill: parent
                    // Empty - just blocks propagation to parent
                }
            }

        }

        // Full-screen overlay window (masked) containing bar + popouts; only masked areas interactive
        StyledWindow {
            id: win

            screen: scope.modelData
            name: "bar"

            // Full coverage overlay
            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true
            implicitHeight: 36

            // Do not reserve space in layershell
            WlrLayershell.exclusionMode: ExclusionMode.Ignore

            // Define mask explicitly - only interactive areas receive input
            mask: Region {
                regions: scope.isPrimaryMonitor ? 
                    [barRegion, popoutRegion, notificationsRegion] :  // Primary: bar + popouts + notif toasts
                    [workspaceRegion]            // Secondary: only workspace area
                
                Region { 
                    id: barRegion
                    item: scope.isPrimaryMonitor ? barLoader.item : null
                }
                Region { 
                    id: popoutRegion
                    item: (scope.isPrimaryMonitor && popouts.hasCurrent) ? popouts.contentLoader : null
                }
                Region {
                    id: notificationsRegion
                    item: (scope.isPrimaryMonitor && notificationsToasts.visible) ? notificationsToasts : null
                }
                Region { 
                    id: workspaceRegion
                    item: !scope.isPrimaryMonitor ? barLoader.item : null
                }
            }

            // Bar content - conditional based on monitor type
        Loader {
            id: barLoader
                // Primary monitors: full width at top
                anchors.left: scope.isPrimaryMonitor ? parent.left : undefined
                anchors.right: scope.isPrimaryMonitor ? parent.right : undefined
                anchors.top: scope.isPrimaryMonitor ? parent.top : undefined
                anchors.topMargin: scope.isPrimaryMonitor ? 2 : 0
                
                // Secondary monitors: centered horizontally at bottom
                anchors.horizontalCenter: !scope.isPrimaryMonitor ? parent.horizontalCenter : undefined
                anchors.bottom: !scope.isPrimaryMonitor ? parent.bottom : undefined
                anchors.bottomMargin: !scope.isPrimaryMonitor ? 4 : 0
                
            sourceComponent: scope.isPrimaryMonitor ? fullBarComponent : workspacesOnlyComponent
            onLoaded: {
                if (!scope.isPrimaryMonitor) return
                if (!Config.Config.debugPopoutsEnabled || !Config.Config.debugPopoutName) return
                debugPopoutTimer.restart()
            }
        }

            // Shared hover/click feedback for each top-level bar widget. The helper
            // observes the widget's existing MouseAreas without intercepting input.
            Item {
                id: widgetEffectsLayer
                anchors.fill: barLoader
                z: 5
                visible: !!barLoader.item

                Repeater {
                    model: barLoader.item
                        ? scope.collectInteractiveWidgets(barLoader.item)
                            .filter(widget => widget.width > 0 && widget.height > 0)
                        : []

                    BarWidgetEffects {
                        required property var modelData
                        target: modelData
                    }
                }
            }

            // Popouts wrapper - only active on primary monitors
            BarPopouts.Wrapper {
                id: popouts
                screen: scope.modelData
                anchors.fill: parent
                z: 10
                visible: scope.isPrimaryMonitor
            }

            NotificationsToasts {
                id: notificationsToasts
                anchors.top: parent.top
                anchors.topMargin: 42
                anchors.right: parent.right
                anchors.rightMargin: 12
                z: 12
                visible: scope.isPrimaryMonitor && implicitHeight > 0
            }
        }

        // Full bar component for primary monitor
        Component {
            id: fullBarComponent
            
            RowLayout {
                id: mainLayout
                spacing: 8

                // Calculate available space for responsive elements (excluding news, mail, and stocks pills to avoid circular dependency)
                property real availableWidth: width
                property real essentialWidth: workspaces.implicitWidth + cavaPill.implicitWidth +
                                              (mprisPill.visible ? mprisPill.implicitWidth : 0) +
                                              (notificationInlinePill.visible ? notificationInlinePill.implicitWidth : 0) +
                                              systemTray.implicitWidth + systemRings.implicitWidth +
                                              clock.implicitWidth + nixosLogo.implicitWidth + 8 * spacing
                property real remainingWidth: availableWidth - essentialWidth

                // Workspaces
                Workspaces {
                    id: workspaces
                    objectName: "Workspaces"
                    Layout.alignment: Qt.AlignVCenter
                    monitorName: win.screen.name
                }

                // Cava Visualizer (wrapped in pill)
                Pill {
                    id: cavaPill
                    objectName: "CavaPill"
                    implicitHeight: Colors.pillHeight
                    Layout.alignment: Qt.AlignVCenter
                    // Size to fit the visualizer plus left/right padding (6 + 6)
                    Layout.preferredWidth: (typeof cavaVisualizer !== 'undefined' ? cavaVisualizer.implicitWidth + 12 : 140)

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        anchors.rightMargin: 6
                        spacing: 6
                        Layout.alignment: Qt.AlignVCenter

                        CavaVisualizer {
                            id: cavaVisualizer
                            Layout.alignment: Qt.AlignVCenter
                            barCount: 15
                            barWidth: 2
                            maxHeight: Colors.pillHeight - 8
                            height: Colors.pillHeight - 8
                            Layout.preferredHeight: Colors.pillHeight - 8
                            popouts: popouts
                        }
                    }
                }

                // MPRIS (wrapped in pill)
                Pill {
                    id: mprisPill
                    objectName: "MprisPill"
                    Layout.alignment: Qt.AlignVCenter
                    implicitHeight: Colors.pillHeight
                    implicitWidth: mprisRow.implicitWidth + 12
                    Layout.preferredWidth: implicitWidth
                    visible: Mpris.hasActivePlayer

                    RowLayout {
                        id: mprisRow
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: 6
                        Layout.alignment: Qt.AlignVCenter
                        MprisIndicator { 
                            id: mprisIndicator
                            Layout.alignment: Qt.AlignVCenter
                            popouts: popouts
                            shouldShrink: spacer.tooSmall
                            screenWidth: scope.modelData.width
                        }
                    }
                }

                // Portable profile omits local news cache and financial data.

                NotificationInlinePill {
                    id: notificationInlinePill
                    objectName: "NotificationInlinePill"
                    Layout.alignment: Qt.AlignVCenter
                    popouts: popouts
                }

                // Spacer
                Item {
                    id: spacer
                    objectName: "Spacer"
                    Layout.fillWidth: true
                    // Signal when spacer gets too small (indicates overflow pressure)
                    property bool tooSmall: width < 100
                }

                // Keep one compact hover target for each completed agent reply.
                RowLayout {
                    id: agentMessagePills
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 6
                    visible: PiNotify.showFinalMessagePills

                    Repeater {
                        model: PiDashboardQuestions.finalMessages

                        delegate: Pill {
                            id: agentMessagePill
                            required property var modelData
                            objectName: "AgentMessagePill:" + modelData.sessionId
                            Layout.alignment: Qt.AlignVCenter
                            implicitHeight: Colors.pillHeight
                            implicitWidth: agentMessageRow.implicitWidth + 20

                            RowLayout {
                                id: agentMessageRow
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 6

                                Rectangle {
                                    Layout.alignment: Qt.AlignVCenter
                                    implicitWidth: 6
                                    implicitHeight: 6
                                    radius: 3
                                    color: "#c4a7e7"
                                }

                                Text {
                                    Layout.alignment: Qt.AlignVCenter
                                    text: agentMessagePill.modelData.sessionName
                                    color: "#e0def4"
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    renderType: Text.NativeRendering
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.MiddleButton
                                onEntered: {
                                    finalMessageAutoCloseTimer.stop()
                                    scope.openQuestionsView(
                                        agentMessagePill.objectName,
                                        agentMessagePill.modelData.sessionId
                                    )
                                    popouts.currentHovered = true
                                }
                                onExited: {
                                    popouts.currentHovered = false
                                    if (popouts.currentName === "pi-dashboard-questions")
                                        popouts.scheduleClose()
                                }
                                onClicked: function(mouse) {
                                    if (mouse.button !== Qt.MiddleButton)
                                        return
                                    PiDashboardQuestions.dismissFinalMessage(agentMessagePill.modelData.id)
                                    if (popouts.currentName === "pi-dashboard-questions")
                                        popouts.close()
                                }
                            }
                        }
                    }
                }

                // AI Visualizer
                Item {
                    id: aiVisualizer
                    objectName: "AIVisualizer"
                    Layout.alignment: Qt.AlignVCenter
                    visible: scope.aiVisualizerEnabled

                    // Give the braille slot room to breathe while retaining the
                    // old geometry when QUICKSHELL_AI_VISUALIZER=legacy.
                    property real visualWidth: scope.legacyAiVisualizerEnabled ? 36 : 56
                    property real visualHeight: 36
                    property real pillWidth: 54
                    property bool recordingActive: TtsMonitor.isRecordingActive
                    property bool ttsActive: TtsMonitor.isTtsActive
                    property bool ttsPlaying: TtsMonitor.isTtsPlaying
                    property real ttsLevel: TtsMonitor.ttsLevel
                    property bool ttsAudible: false
                    property bool audioVisualizerActive: recordingActive || ttsAudible
                    property bool textDotsActive: Ember.isTextGenerating && !audioVisualizerActive
                    property real audioLevel: recordingActive ? TtsMonitor.recordingLevel : ttsLevel
                    property real ttsAudibleThreshold: 0.006
                    property double lastTtsSignalMs: 0
                    property bool pillActive: audioVisualizerActive
                    property color accentColor: !Ember.gatewayUp
                        ? "#6e6a86"
                        : ((Ember.isThinkingOrToolActive || Ember.isCompacting) ? "#B388FF" : "#c4a7e7")
                    property var barHeights: [3, 3, 3, 3, 3, 3, 3, 3, 3, 3]
                    property string stateLogPath: "/tmp/quickshell-braingraph-state.log"
                    property var stateLogQueue: []
                    property string lastLoggedState: ""

                    function compactState() {
                        var mode = recordingActive ? "stt" : (ttsAudible ? "tts" : (textDotsActive ? "text" : Ember.activityPhase))
                        var speed = (Ember.isThinkingOrToolActive || Ember.isCompacting) ? "fast" : TtsMonitor.brainSpeedMode
                        var color = !Ember.gatewayUp ? "offline" : ((Ember.isThinkingOrToolActive || Ember.isCompacting) ? "bright-purple" : "purple")
                        return mode + " speed=" + speed + " color=" + color
                    }

                    function logStateChange(reason) {
                        if (!scope.legacyAiVisualizerEnabled || !scope.isPrimaryMonitor)
                            return
                        var state = compactState()
                        if (state === lastLoggedState)
                            return
                        lastLoggedState = state
                        stateLogQueue.push(new Date().toISOString() + " " + state)
                        flushStateLog()
                    }

                    function flushStateLog() {
                        if (stateLogProc.running || stateLogQueue.length === 0)
                            return
                        var line = stateLogQueue.shift()
                        var escapedLine = line.replace(/'/g, "'\\''")
                        var escapedPath = stateLogPath.replace(/'/g, "'\\''")
                        stateLogProc.command = [
                            "sh",
                            "-c",
                            "printf '%s\\n' '" + escapedLine + "' >> '" + escapedPath + "'"
                        ]
                        stateLogProc.running = false
                        stateLogProc.running = true
                    }

                    implicitWidth: scope.aiVisualizerEnabled
                        ? (scope.legacyAiVisualizerEnabled ? (pillActive ? pillWidth : visualWidth) : visualWidth)
                        : 0
                    implicitHeight: visualHeight
                    width: implicitWidth
                    height: visualHeight
                    clip: false
                    Layout.preferredWidth: scope.aiVisualizerEnabled ? implicitWidth : 0
                    Layout.minimumWidth: scope.aiVisualizerEnabled ? implicitWidth : 0
                    Layout.maximumWidth: scope.aiVisualizerEnabled ? implicitWidth : 0
                    Layout.preferredHeight: visualHeight
                    Layout.minimumHeight: visualHeight
                    Layout.maximumHeight: visualHeight

                    property int brainFadeSettleTicks: 0

                    function updateBrainFadePosition() {
                        if (!scope.legacyAiVisualizerEnabled)
                            return
                        if (!barLoader || !barLoader.item || width <= 0 || height <= 0) {
                            scope.brainFadePositionValid = false
                            return
                        }
                        var pos = mapToItem(barLoader.item, width / 2, height / 2)
                        scope.brainFadeSize = aiVisualizer.pillActive ? aiVisualizer.pillWidth + 10 : visualHeight
                        scope.brainFadeX = barLoader.x + pos.x - scope.brainFadeSize / 2
                        scope.brainFadeY = Math.max(0, barLoader.y + pos.y - scope.brainFadeSize / 2)
                        scope.brainFadePositionValid = true
                    }

                    function scheduleBrainFadeSettle() {
                        if (!scope.legacyAiVisualizerEnabled)
                            return
                        // Hide only during initial layout settle. After first placement, keep the
                        // fade visible and continuously correct position so STT expansion is instant.
                        if (!scope.brainFadeReady) {
                            scope.brainFadePositionValid = false
                        }
                        brainFadeSettleTicks = 12
                        brainFadeSettleTimer.restart()
                    }

                    Component.onCompleted: {
                        if (scope.legacyAiVisualizerEnabled) {
                            scheduleBrainFadeSettle()
                            updateTtsAudible()
                            logStateChange("completed")
                        }
                    }
                    onXChanged: scheduleBrainFadeSettle()
                    onYChanged: scheduleBrainFadeSettle()
                    onWidthChanged: scheduleBrainFadeSettle()
                    onHeightChanged: scheduleBrainFadeSettle()
                    onRecordingActiveChanged: if (scope.legacyAiVisualizerEnabled) logStateChange("recordingActive")
                    onTtsAudibleChanged: if (scope.legacyAiVisualizerEnabled) logStateChange("ttsAudible")
                    onAudioVisualizerActiveChanged: if (scope.legacyAiVisualizerEnabled) logStateChange("audioVisualizerActive")
                    onTextDotsActiveChanged: if (scope.legacyAiVisualizerEnabled) logStateChange("textDotsActive")
                    onAccentColorChanged: if (scope.legacyAiVisualizerEnabled) logStateChange("accentColor")
                    onPillActiveChanged: {
                        if (!scope.legacyAiVisualizerEnabled)
                            return
                        updateBrainFadePosition()
                        scheduleBrainFadeSettle()
                        logStateChange("pillActive")
                    }

                    Timer {
                        id: brainFadeSettleTimer
                        interval: 100
                        repeat: true
                        onTriggered: {
                            aiVisualizer.updateBrainFadePosition()
                            aiVisualizer.brainFadeSettleTicks--
                            if (aiVisualizer.brainFadeSettleTicks <= 0) {
                                scope.brainFadeReady = true
                                stop()
                            }
                        }
                    }

                    Timer {
                        interval: 500
                        repeat: true
                        running: scope.aiVisualizerEnabled && scope.legacyAiVisualizerEnabled && scope.isPrimaryMonitor
                        triggeredOnStart: false
                        onTriggered: aiVisualizer.updateBrainFadePosition()
                    }

                    Binding {
                        target: scope
                        property: "brainFadeOpacity"
                        value: scope.legacyAiVisualizerEnabled ? 1 : 0
                    }

                    Binding {
                        target: TtsMonitor
                        property: "keepTtsOutputMonitor"
                        value: scope.legacyAiVisualizerEnabled && aiVisualizer.ttsAudible
                    }

                    Behavior on Layout.preferredWidth {
                        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                    }

                    function scheduleTtsClose() {
                        if (!scope.legacyAiVisualizerEnabled)
                            return
                        if (ttsPlaying)
                            return
                        // TTS mode has display priority; close only after the TTS signal clears
                        // and output audio has been quiet for a short grace period.
                        ttsCloseTimer.start()
                    }

                    function updateTtsAudible() {
                        if (!scope.legacyAiVisualizerEnabled)
                            return
                        if (ttsPlaying) {
                            lastTtsSignalMs = Date.now()
                            ttsCloseTimer.stop()
                            ttsAudible = true
                        } else {
                            scheduleTtsClose()
                        }
                    }

                    onTtsPlayingChanged: {
                        if (!scope.legacyAiVisualizerEnabled)
                            return
                        updateTtsAudible()
                        logStateChange("ttsPlaying")
                    }

                    onTtsActiveChanged: if (scope.legacyAiVisualizerEnabled) logStateChange("ttsActive")

                    Connections {
                        target: Ember
                        function onIsGeneratingChanged() {
                            if (!scope.legacyAiVisualizerEnabled)
                                return
                            if (!Ember.isGenerating && aiVisualizer.ttsAudible && !aiVisualizer.ttsActive)
                                aiVisualizer.scheduleTtsClose()
                            else if (Ember.isGenerating && aiVisualizer.ttsAudible)
                                ttsCloseTimer.stop()
                            aiVisualizer.logStateChange("emberGenerating")
                        }
                        function onActivityPhaseChanged() {
                            if (scope.legacyAiVisualizerEnabled)
                                aiVisualizer.logStateChange("emberPhase")
                        }
                        function onGatewayUpChanged() {
                            if (scope.legacyAiVisualizerEnabled)
                                aiVisualizer.logStateChange("emberGatewayUp")
                        }
                    }

                    Connections {
                        target: TtsMonitor
                        function onBrainSpeedModeChanged() {
                            if (scope.legacyAiVisualizerEnabled)
                                aiVisualizer.logStateChange("brainSpeedMode")
                        }
                    }

                    Process {
                        id: stateLogProc
                        running: false
                        stderr: SplitParser { onRead: function(_) {} }
                        onExited: aiVisualizer.flushStateLog()
                    }

                    Timer {
                        id: ttsAudioStartTimer
                        interval: 80
                        repeat: true
                        running: scope.legacyAiVisualizerEnabled && aiVisualizer.ttsPlaying
                        onTriggered: {
                            if (aiVisualizer.ttsLevel > aiVisualizer.ttsAudibleThreshold) {
                                aiVisualizer.lastTtsSignalMs = Date.now()
                                aiVisualizer.ttsAudible = true
                            }
                        }
                    }

                    Timer {
                        id: ttsCloseTimer
                        interval: 250
                        repeat: true
                        onTriggered: {
                            if (aiVisualizer.ttsPlaying)
                                return
                            if (Date.now() - aiVisualizer.lastTtsSignalMs > 1500) {
                                aiVisualizer.ttsAudible = false
                                stop()
                            }
                        }
                    }

                    Timer {
                        interval: 160
                        repeat: true
                        running: scope.legacyAiVisualizerEnabled && aiVisualizer.audioVisualizerActive
                        onTriggered: {
                            var rawPeak = Math.max(0, (aiVisualizer.audioLevel - 0.012) * 5.5)
                            var peak = Math.min(1, Math.pow(rawPeak, 0.8))
                            var heightScale = aiVisualizer.recordingActive ? 12 : 18
                            var maxHeight = aiVisualizer.recordingActive ? 20 : 24
                            var next = []
                            for (var i = 0; i < 10; i++) {
                                var centerBias = 0.55 + Math.sin((i + 1) / 11 * Math.PI) * 0.45
                                var bandBias = 0.55 + ((i * 43) % 11) / 10
                                var randomBand = 0.28 + Math.random() * 1.15
                                var previous = aiVisualizer.barHeights[i] || 3
                                var target = 3 + peak * centerBias * bandBias * randomBand * heightScale
                                target = previous * 0.28 + target * 0.72
                                next.push(Math.min(maxHeight, target))
                            }
                            aiVisualizer.barHeights = next
                        }
                    }

                    BrailleActivityVisualizer {
                        id: brailleActivityVisualizer
                        anchors.centerIn: parent
                        width: parent.visualWidth
                        height: parent.visualHeight
                        visualizerEnabled: scope.aiVisualizerEnabled && !scope.legacyAiVisualizerEnabled
                        manualMode: AiVisualizerPreview.mode
                        audioActive: TtsMonitor.isTtsPlaying || TtsMonitor.isRecordingActive
                        audioLevel: TtsMonitor.isRecordingActive
                            ? TtsMonitor.recordingLevel
                            : TtsMonitor.ttsLevel
                        audioSource: TtsMonitor.isRecordingActive
                            ? "stt"
                            : ((TtsMonitor.isTtsPlaying || TtsMonitor.isTtsActive) ? "tts" : "none")
                        gatewayUp: Ember.gatewayUp
                        activityMode: TtsMonitor.isTtsPlaying
                            ? "generating"
                            : (TtsMonitor.isRecordingActive
                                ? "thinking"
                                : (Ember.isCompacting
                                    ? "compacting"
                                    : (Ember.isTextGenerating
                                        ? "generating"
                                        : (Ember.isThinkingOrToolActive ? "thinking" : "idle"))))
                        visible: scope.aiVisualizerEnabled && !scope.legacyAiVisualizerEnabled
                    }

                    BrainGraph {
                        id: aiBrainGraph
                        anchors.centerIn: parent
                        width: parent.visualWidth
                        height: parent.visualWidth
                        configScale: 1.0
                        connectionDistanceMultiplier: 1.2
                        connectionLineWidth: 0.45
                        nodeSizeMultiplier: 1.0
                        mode: 0
                        speedMode: (Ember.isThinkingOrToolActive || Ember.isCompacting) ? "high" : TtsMonitor.brainSpeedMode
                        graphColor: aiVisualizer.accentColor
                        visible: scope.aiVisualizerEnabled && scope.legacyAiVisualizerEnabled
                        paused: !scope.aiVisualizerEnabled || !scope.legacyAiVisualizerEnabled
                        graphVisible: true
                        shadowVisible: false
                        opacity: scope.legacyAiVisualizerEnabled && (aiVisualizer.pillActive || aiVisualizer.textDotsActive) ? 0 : 1
                        scale: (aiVisualizer.pillActive || aiVisualizer.textDotsActive) ? 0.58 : 1
                        clip: true

                        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                    }

                    Row {
                        id: textDots
                        anchors.centerIn: parent
                        spacing: 4
                        opacity: aiVisualizer.textDotsActive ? 1 : 0
                        visible: scope.legacyAiVisualizerEnabled && opacity > 0

                        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                        Repeater {
                            model: 3
                            Rectangle {
                                required property int index
                                width: 4
                                height: 4
                                radius: 2
                                color: aiVisualizer.accentColor
                                opacity: 0.35
                                scale: 0.85

                                SequentialAnimation on opacity {
                                    running: textDots.visible
                                    loops: Animation.Infinite
                                    PauseAnimation { duration: index * 140 }
                                    NumberAnimation { to: 1.0; duration: 220; easing.type: Easing.OutCubic }
                                    NumberAnimation { to: 0.35; duration: 360; easing.type: Easing.InOutSine }
                                    PauseAnimation { duration: (2 - index) * 140 }
                                }

                                SequentialAnimation on scale {
                                    running: textDots.visible
                                    loops: Animation.Infinite
                                    PauseAnimation { duration: index * 140 }
                                    NumberAnimation { to: 1.25; duration: 220; easing.type: Easing.OutCubic }
                                    NumberAnimation { to: 0.85; duration: 360; easing.type: Easing.InOutSine }
                                    PauseAnimation { duration: (2 - index) * 140 }
                                }
                            }
                        }
                    }

                    Rectangle {
                        id: recordingPill
                        anchors.centerIn: parent
                        width: aiVisualizer.pillActive ? aiVisualizer.pillWidth : aiVisualizer.visualWidth
                        height: aiVisualizer.pillActive ? Colors.pillHeight : aiVisualizer.visualWidth
                        radius: height / 2
                        color: "transparent"
                        border.color: "transparent"
                        border.width: 0
                        opacity: scope.legacyAiVisualizerEnabled && aiVisualizer.pillActive ? 1 : 0
                        scale: scope.legacyAiVisualizerEnabled && aiVisualizer.pillActive ? 1 : 0.75
                        clip: true

                        Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                        Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                        Row {
                            id: recordingBars
                            anchors.centerIn: parent
                            height: aiVisualizer.recordingActive ? 20 : 24
                            spacing: 2
                            opacity: scope.legacyAiVisualizerEnabled && aiVisualizer.audioVisualizerActive ? 1 : 0
                            visible: scope.legacyAiVisualizerEnabled && opacity > 0

                            Behavior on opacity { NumberAnimation { duration: 140 } }

                            Repeater {
                                model: 10
                                Rectangle {
                                    required property int index
                                    width: 2
                                    height: aiVisualizer.audioVisualizerActive
                                        ? (aiVisualizer.barHeights[index] || 3)
                                        : 3
                                    y: (recordingBars.height - height) / 2
                                    radius: 1
                                    color: aiVisualizer.recordingActive ? "#ebbcba" : aiVisualizer.accentColor

                                    Behavior on height {
                                        NumberAnimation { duration: 190; easing.type: Easing.InOutSine }
                                    }
                                }
                            }
                        }
                    }

                    // Click to open the anchored AI settings menu.
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (popouts.hasCurrent && popouts.currentName === "ai-settings") {
                                popouts.close()
                                return
                            }
                            var pos = popouts.mapFromItem(
                                aiVisualizer,
                                aiVisualizer.width / 2,
                                aiVisualizer.height
                            )
                            popouts.openPopout("ai-settings", pos.x, pos.y, aiVisualizer.width)
                        }
                    }
                }

                // Hyprland Submap Indicator (first in right section)
                HyprlandSubmapIndicator {
                    id: submapIndicator
                    objectName: "HyprlandSubmapIndicator"
                    Layout.alignment: Qt.AlignVCenter
                    popouts: popouts
                }

                // System Tray
                SystemTray {
                    id: systemTray
                    objectName: "SystemTray"
                    Layout.alignment: Qt.AlignVCenter
                    popouts: popouts
                }

                // System Rings (including brightness and new battery)
                SystemRings {
                    id: systemRings
                    objectName: "SystemRings"
                    Layout.alignment: Qt.AlignVCenter
                    popouts: popouts
                    // debug references removed (no longer needed)
                }

                // Clock (with embedded timer ring on left, calendar on right)
                Clock {
                    id: clock
                    objectName: "Clock"
                    Layout.alignment: Qt.AlignVCenter
                    popouts: popouts
                }

                // The workstation's NixOS logo PNG is not included on the USB.
                Pill {
                    id: nixosLogo
                    objectName: "SystemMenu"
                    implicitWidth: Colors.pillHeight
                    implicitHeight: Colors.pillHeight
                    Layout.alignment: Qt.AlignVCenter
                    Text {
                        anchors.centerIn: parent
                        text: "N"
                        font.bold: true
                        color: "#c4a7e7"
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (popouts.hasCurrent && popouts.currentName === "systemMenu")
                                popouts.close()
                            else {
                                let pos = popouts.mapFromItem(nixosLogo, nixosLogo.width / 2, nixosLogo.height)
                                popouts.openPopout("systemMenu", pos.x, pos.y, nixosLogo.width)
                            }
                        }
                    }
                }
            }
        }

        // Workspaces-only component for secondary monitors
        Component {
            id: workspacesOnlyComponent
            
            // Direct Workspaces widget without container - positioned by loader
            Workspaces {
                id: workspaces
                monitorName: win.screen.name
            }
        }
    }
}
