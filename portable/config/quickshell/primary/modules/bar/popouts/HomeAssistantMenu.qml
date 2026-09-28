import QtQuick
import QtQuick.Layouts
import "../../../services"

Rectangle {
    id: root

    property bool hasOwnBackground: true
    property var wrapper: null
    property real selectedHue: HomeAssistant.beamHue
    property real selectedSaturation: HomeAssistant.beamSaturation
    property real selectedBrightness: HomeAssistant.beamBrightnessPct
    readonly property color selectedColor: Qt.hsla(selectedHue / 360,
                                                    selectedSaturation / 100, 0.5, 1)

    implicitWidth: 260
    implicitHeight: menuLayout.implicitHeight + 28
    color: PopoutConfig.backgroundColor
    radius: PopoutConfig.cornerRadius
    border.width: PopoutConfig.borderWidth
    border.color: PopoutConfig.borderColor
    layer.enabled: true
    layer.smooth: false

    function stateText(state) {
        if (state === "on") return "On"
        if (state === "off") return "Off"
        if (state === "unknown") return "Unknown"
        return "Unavailable"
    }

    function stateColor(state) {
        if (state === "on") return PopoutConfig.successColor
        if (state === "off") return PopoutConfig.textColor
        return PopoutConfig.warningColor
    }

    function hueHex(hue) {
        var h = ((hue % 360) + 360) % 360 / 60
        var x = 1 - Math.abs(h % 2 - 1)
        var r = 0
        var g = 0
        var b = 0
        if (h < 1) { r = 1; g = x }
        else if (h < 2) { r = x; g = 1 }
        else if (h < 3) { g = 1; b = x }
        else if (h < 4) { g = x; b = 1 }
        else if (h < 5) { r = x; b = 1 }
        else { r = 1; b = x }
        function channel(value) { return Math.round(value * 255).toString(16).padStart(2, "0") }
        return "#" + channel(r) + channel(g) + channel(b)
    }

    function setHsAt(x, y) {
        selectedSaturation = Math.max(0, Math.min(100, x / Math.max(1, hsSelector.width) * 100))
        selectedHue = Math.max(0, Math.min(360, y / Math.max(1, hsSelector.height) * 360))
    }

    function setBrightnessAt(x) {
        selectedBrightness = Math.max(0, Math.min(100,
                                                      x / Math.max(1, brightnessSlider.width) * 100))
    }

    component LightRow: Rectangle {
        required property string label
        required property string entityId
        required property string lightState

        Layout.fillWidth: true
        Layout.preferredHeight: 38
        radius: 8
        color: rowMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 8
            spacing: 8

            Text {
                text: "lightbulb"
                font.family: "Material Symbols Outlined"
                font.pixelSize: 17
                color: root.stateColor(lightState)
                renderType: Text.NativeRendering
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: label
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: PopoutConfig.textColor
                    renderType: Text.NativeRendering
                }

                Text {
                    text: root.stateText(lightState)
                    font.pixelSize: 10
                    color: root.stateColor(lightState)
                    opacity: lightState === "off" ? 0.55 : 0.9
                    renderType: Text.NativeRendering
                }
            }

            Rectangle {
                width: 28
                height: 16
                radius: height / 2
                color: lightState === "on" ? PopoutConfig.successColor
                                            : Qt.rgba(1, 1, 1, 0.12)
                opacity: rowMouse.enabled ? 1 : 0.4

                Rectangle {
                    width: 12
                    height: 12
                    radius: width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    x: lightState === "on" ? parent.width - width - 2 : 2
                    color: lightState === "on" ? PopoutConfig.backgroundColor
                                                : PopoutConfig.textColor
                }
            }
        }

        MouseArea {
            id: rowMouse
            anchors.fill: parent
            enabled: HomeAssistant.configured && !HomeAssistant.actionBusy
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: HomeAssistant.toggle(entityId)
        }
    }

    ColumnLayout {
        id: menuLayout
        anchors.fill: parent
        anchors.margins: 14
        spacing: 7

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "lightbulb"
                font.family: "Material Symbols Outlined"
                font.pixelSize: 20
                color: HomeAssistant.beamState === "on" ? PopoutConfig.successColor
                                                         : PopoutConfig.textColor
                renderType: Text.NativeRendering
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    text: "Beam"
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    color: PopoutConfig.textColor
                    renderType: Text.NativeRendering
                }

                Text {
                    text: !HomeAssistant.configured ? "Config unavailable"
                          : (HomeAssistant.loading ? "Connecting…"
                             : (HomeAssistant.available ? "Connected" : "Unavailable"))
                    font.pixelSize: 10
                    color: HomeAssistant.available ? PopoutConfig.successColor
                                                     : PopoutConfig.textColor
                    opacity: HomeAssistant.available ? 0.85 : 0.6
                    renderType: Text.NativeRendering
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 42
            radius: 8
            color: masterMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(1, 1, 1, 0.035)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.07)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: "All Beam lights"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: PopoutConfig.textColor
                    renderType: Text.NativeRendering
                }

                Text {
                    text: root.stateText(HomeAssistant.beamState)
                    font.pixelSize: 10
                    color: root.stateColor(HomeAssistant.beamState)
                    opacity: 0.85
                    renderType: Text.NativeRendering
                }

                Rectangle {
                    width: 32
                    height: 18
                    radius: height / 2
                    color: HomeAssistant.beamState === "on" ? PopoutConfig.successColor
                                                             : Qt.rgba(1, 1, 1, 0.12)
                    opacity: masterMouse.enabled ? 1 : 0.4

                    Rectangle {
                        width: 14
                        height: 14
                        radius: width / 2
                        anchors.verticalCenter: parent.verticalCenter
                        x: HomeAssistant.beamState === "on" ? parent.width - width - 2 : 2
                        color: HomeAssistant.beamState === "on" ? PopoutConfig.backgroundColor
                                                                 : PopoutConfig.textColor
                    }
                }
            }

            MouseArea {
                id: masterMouse
                anchors.fill: parent
                enabled: HomeAssistant.configured && !HomeAssistant.actionBusy
                hoverEnabled: true
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: HomeAssistant.toggle("light.beam")
            }
        }

        Text {
            Layout.fillWidth: true
            text: "Color and brightness"
            font.pixelSize: 11
            font.weight: Font.DemiBold
            color: PopoutConfig.textColor
            opacity: 0.75
            renderType: Text.NativeRendering
        }

        Rectangle {
            id: hsSelector
            Layout.fillWidth: true
            Layout.preferredHeight: 108
            radius: 8
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.1)
            clip: true

            Canvas {
                id: hsCanvas
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d")
                    for (var y = 0; y < height; y++) {
                        var hue = y / Math.max(1, height - 1) * 360
                        var gradient = ctx.createLinearGradient(0, 0, width, 0)
                        gradient.addColorStop(0, "#ffffff")
                        gradient.addColorStop(1, root.hueHex(hue))
                        ctx.fillStyle = gradient
                        ctx.fillRect(0, y, width, 1)
                    }
                }
            }

            Rectangle {
                width: 14
                height: width
                radius: width / 2
                x: Math.max(1, Math.min(parent.width - width - 1,
                                         root.selectedSaturation / 100 * parent.width - width / 2))
                y: Math.max(1, Math.min(parent.height - height - 1,
                                         root.selectedHue / 360 * parent.height - height / 2))
                color: "transparent"
                border.width: 2
                border.color: "white"
            }

            MouseArea {
                anchors.fill: parent
                onPressed: function(mouse) { root.setHsAt(mouse.x, mouse.y) }
                onPositionChanged: function(mouse) {
                    if (pressed) root.setHsAt(mouse.x, mouse.y)
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "Brightness"
                font.pixelSize: 10
                color: PopoutConfig.textColor
                opacity: 0.65
                renderType: Text.NativeRendering
            }

            Rectangle {
                id: brightnessSlider
                Layout.fillWidth: true
                Layout.preferredHeight: 16
                radius: height / 2
                color: "#191724"
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.1)

                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "#191724" }
                    GradientStop { position: 1; color: root.selectedColor }
                }

                Rectangle {
                    width: 12
                    height: width
                    radius: width / 2
                    x: Math.max(1, Math.min(parent.width - width - 1,
                                             root.selectedBrightness / 100 * parent.width - width / 2))
                    anchors.verticalCenter: parent.verticalCenter
                    color: "transparent"
                    border.width: 2
                    border.color: "white"
                }

                MouseArea {
                    anchors.fill: parent
                    onPressed: function(mouse) { root.setBrightnessAt(mouse.x) }
                    onPositionChanged: function(mouse) {
                        if (pressed) root.setBrightnessAt(mouse.x)
                    }
                }
            }

            Text {
                text: Math.round(root.selectedBrightness) + "%"
                font.pixelSize: 10
                color: PopoutConfig.textColor
                width: 32
                horizontalAlignment: Text.AlignRight
                renderType: Text.NativeRendering
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 7

            Text {
                Layout.fillWidth: true
                text: "Drag to choose"
                font.pixelSize: 10
                color: PopoutConfig.textColor
                opacity: 0.55
                renderType: Text.NativeRendering
            }

            Rectangle {
                Layout.preferredWidth: 68
                Layout.preferredHeight: 28
                radius: 7
                color: applyMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08)
                                                : Qt.rgba(Colors.foregroundCyan.r,
                                                          Colors.foregroundCyan.g,
                                                          Colors.foregroundCyan.b, 0.12)
                border.width: 1
                border.color: Qt.rgba(Colors.foregroundCyan.r, Colors.foregroundCyan.g,
                                      Colors.foregroundCyan.b, 0.35)

                Text {
                    anchors.centerIn: parent
                    text: HomeAssistant.actionBusy ? "Working…" : "Apply"
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    color: Colors.foregroundCyan
                    opacity: applyMouse.enabled ? 0.95 : 0.4
                    renderType: Text.NativeRendering
                }

                MouseArea {
                    id: applyMouse
                    anchors.fill: parent
                    enabled: HomeAssistant.configured && !HomeAssistant.actionBusy
                    hoverEnabled: true
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: HomeAssistant.applyBeamColor(root.selectedHue,
                                                            root.selectedSaturation,
                                                            root.selectedBrightness)
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: "Presets: click to apply · right-click to save current color"
            font.pixelSize: 9
            color: PopoutConfig.textColor
            opacity: 0.55
            wrapMode: Text.WordWrap
            renderType: Text.NativeRendering
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: 5
                delegate: Rectangle {
                    required property int index
                    readonly property var preset: HomeAssistant.presetAt(index)
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    radius: 7
                    color: preset
                           ? Qt.hsla(preset.hue / 360, preset.saturation / 100,
                                     Math.max(0.03, 0.5 * preset.brightness / 100), 1)
                           : Qt.rgba(1, 1, 1, 0.04)
                    border.width: 1
                    border.color: preset ? Qt.rgba(1, 1, 1, 0.35)
                                         : Qt.rgba(1, 1, 1, 0.1)

                    Text {
                        anchors.centerIn: parent
                        text: index + 1
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        color: preset ? "#191724" : PopoutConfig.textColor
                        opacity: preset ? 0.85 : 0.55
                        renderType: Text.NativeRendering
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: function(mouse) {
                            if (mouse.button === Qt.LeftButton) {
                                if (preset) {
                                    root.selectedHue = preset.hue
                                    root.selectedSaturation = preset.saturation
                                    root.selectedBrightness = preset.brightness
                                    HomeAssistant.applyPreset(index)
                                }
                            } else if (mouse.button === Qt.RightButton) {
                                HomeAssistant.savePreset(index, root.selectedHue,
                                                         root.selectedSaturation,
                                                         root.selectedBrightness)
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: PopoutConfig.borderColor
            opacity: 0.35
        }

        LightRow {
            label: "Beam 1"
            entityId: "light.beam_1"
            lightState: HomeAssistant.beam1State
        }

        LightRow {
            label: "Beam 2"
            entityId: "light.beam_2"
            lightState: HomeAssistant.beam2State
        }

        Text {
            visible: HomeAssistant.error !== ""
            Layout.fillWidth: true
            text: HomeAssistant.error
            font.pixelSize: 10
            color: PopoutConfig.errorColor
            elide: Text.ElideRight
            renderType: Text.NativeRendering
        }
    }
}
