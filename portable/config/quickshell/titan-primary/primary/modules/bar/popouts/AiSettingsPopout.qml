import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import "../.."
import "../../../services"

ClippingRectangle {
  id: root

  required property Item wrapper

  property bool expanded: wrapper && wrapper.hasCurrent && wrapper.currentName === "ai-settings"
  property bool hasOwnBackground: true

  property string gemmaState: "unknown"
  property string visionState: "unknown"
  property string sttWatcherState: "unknown"
  property bool ttsEnabled: true
  property string ttsProvider: "speechify"
  property real ttsSpeed: 1.0
  property string message: ""
  property bool actionBusy: serviceActionProc.running || ttsSettingProc.running
  property var providerModel: [
    "speechify", "kokoro", "supertonic", "kittentts", "soprano",
    "google", "elevenlabs", "inworld", "vibevoice", "chatterbox",
    "pocket-tts", "s2cpp"
  ]

  readonly property color mutedText: "#aaa4b5"
  readonly property color rowColor: Qt.rgba(40 / 255, 38 / 255, 54 / 255, 0.72)
  readonly property color rowHoverColor: Qt.rgba(49 / 255, 46 / 255, 66 / 255, 0.82)
  readonly property color dividerColor: Qt.rgba(196 / 255, 167 / 255, 231 / 255, 0.18)

  implicitWidth: 540
  implicitHeight: expanded ? contentColumn.implicitHeight + 28 : 0
  opacity: expanded ? Colors.opacity.foreground1 : 0

  color: PopoutConfig.backgroundColor
  border.width: PopoutConfig.borderWidth
  border.color: PopoutConfig.borderColor
  radius: PopoutConfig.cornerRadius
  contentInsideBorder: false

  layer.enabled: true
  layer.smooth: false

  Behavior on implicitHeight {
    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
  }
  Behavior on opacity {
    NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
  }

  function isActive(state) {
    return state === "active" || state === "activating"
  }

  function stateLabel(state) {
    if (state === "active") return "Running"
    if (state === "activating") return "Starting"
    if (state === "deactivating") return "Stopping"
    if (state === "failed") return "Failed"
    if (state === "inactive") return "Off"
    return "Checking"
  }

  function stateColor(state) {
    if (state === "failed") return PopoutConfig.errorColor
    return isActive(state) ? PopoutConfig.successColor : mutedText
  }

  function refresh() {
    if (!gemmaStatusProc.running) gemmaStatusProc.running = true
    if (!visionStatusProc.running) visionStatusProc.running = true
    if (!sttWatcherStatusProc.running) sttWatcherStatusProc.running = true
    if (!ttsDefaultsProc.running) ttsDefaultsProc.running = true
  }

  function toggleService(serviceName, currentlyActive) {
    if (actionBusy) return
    serviceActionProc.targetService = serviceName
    serviceActionProc.targetAction = currentlyActive ? "stop" : "start"
    serviceActionProc.command = [
      "systemctl", "--user", serviceActionProc.targetAction, serviceName
    ]
    message = (currentlyActive ? "Stopping " : "Starting ") + serviceName
    serviceActionProc.running = true
  }

  function restartService(serviceName) {
    if (actionBusy) return
    serviceActionProc.targetService = serviceName
    serviceActionProc.targetAction = "restart"
    serviceActionProc.command = ["systemctl", "--user", "restart", serviceName]
    message = "Restarting " + serviceName
    serviceActionProc.running = true
  }

  function shellQuote(value) {
    return "'" + String(value).replace(/'/g, "'\\''") + "'"
  }

  function writeTtsSetting(field, value) {
    if (actionBusy) return
    if (field === "provider" && providerModel.indexOf(value) < 0) return
    if (field === "speed" && (Number(value) < 0.5 || Number(value) > 2.0)) return
    if (field !== "provider" && field !== "enabled" && field !== "speed") return

    var path = "/home/zarred/scripts/tts/defaults.json"
    var filter = field === "provider"
      ? ".provider = $value"
      : (field === "speed"
          ? ".speed = ($value | tonumber)"
          : ".enabled = ($value == \"true\")")
    var script = "set -eu; "
      + "path=" + shellQuote(path) + "; "
      + "tmp=$(mktemp \"${path}.XXXXXX\"); "
      + "trap 'rm -f \"$tmp\"' EXIT; "
      + "jq --arg value " + shellQuote(String(value)) + " " + shellQuote(filter)
      + " \"$path\" > \"$tmp\"; "
      + "chmod --reference=\"$path\" \"$tmp\"; "
      + "mv \"$tmp\" \"$path\"; trap - EXIT"

    ttsSettingProc.settingName = field
    ttsSettingProc.command = ["sh", "-c", script]
    message = field === "provider" ? "Saving default TTS provider"
      : (field === "speed" ? "Saving default TTS speed" : "Saving TTS state")
    ttsSettingProc.running = true
  }

  function setTtsSpeed(speed) {
    var nextSpeed = Math.round(Math.max(0.5, Math.min(2.0, speed)) * 10) / 10
    writeTtsSetting("speed", nextSpeed.toFixed(1))
  }

  onExpandedChanged: {
    if (expanded) refresh()
  }

  Timer {
    interval: 5000
    repeat: true
    running: root.expanded
    onTriggered: root.refresh()
  }

  Timer {
    id: refreshTimer
    interval: 450
    repeat: false
    onTriggered: root.refresh()
  }

  Process {
    id: gemmaStatusProc
    command: ["systemctl", "--user", "is-active", "gemma4-e4b-server.service"]
    stdout: SplitParser {
      onRead: function(data) {
        var state = data.toString().trim()
        if (state) root.gemmaState = state
      }
    }
    stderr: SplitParser { onRead: function(_) {} }
  }

  Process {
    id: visionStatusProc
    command: ["systemctl", "--user", "is-active", "computer-vision.service"]
    stdout: SplitParser {
      onRead: function(data) {
        var state = data.toString().trim()
        if (state) root.visionState = state
      }
    }
    stderr: SplitParser { onRead: function(_) {} }
  }

  Process {
    id: sttWatcherStatusProc
    command: ["systemctl", "--user", "is-active", "audio-summary-obsidian.service"]
    stdout: SplitParser {
      onRead: function(data) {
        var state = data.toString().trim()
        if (state) root.sttWatcherState = state
      }
    }
    stderr: SplitParser { onRead: function(_) {} }
  }

  Process {
    id: serviceActionProc
    property string targetService: ""
    property string targetAction: ""
    stderr: SplitParser { onRead: function(_) {} }
    onExited: function(code) {
      root.message = code === 0
        ? targetService + " " + targetAction + " complete"
        : "Could not " + targetAction + " " + targetService
      refreshTimer.restart()
    }
  }

  Process {
    id: ttsDefaultsProc
    command: [
      "jq", "-r", "[.enabled, .provider, (.speed // 1.0)] | @tsv",
      "/home/zarred/scripts/tts/defaults.json"
    ]
    stdout: SplitParser {
      onRead: function(data) {
        var parts = data.toString().trim().split("\t")
        if (parts.length < 3) return
        root.ttsEnabled = parts[0] === "true"
        root.ttsProvider = parts[1]
        var speed = Number(parts[2])
        root.ttsSpeed = isNaN(speed) ? 1.0 : speed
      }
    }
    stderr: SplitParser { onRead: function(_) {} }
  }

  Process {
    id: ttsSettingProc
    property string settingName: ""
    stdout: SplitParser { onRead: function(_) {} }
    stderr: SplitParser { onRead: function(_) {} }
    onExited: function(code) {
      root.message = code === 0
        ? (settingName === "provider" ? "Default TTS provider saved"
          : (settingName === "speed" ? "Default TTS speed saved" : "TTS state saved"))
        : "Could not save TTS setting"
      refreshTimer.restart()
    }
  }

  component SettingsToggle: Item {
    id: toggle

    property bool checked: false
    signal toggled(bool nextChecked)

    implicitWidth: 42
    implicitHeight: 23
    opacity: enabled ? 1 : 0.45

    Rectangle {
      anchors.fill: parent
      radius: height / 2
      color: toggle.checked ? PopoutConfig.successColor : "#494354"
      border.width: 1
      border.color: toggle.checked ? PopoutConfig.successColor : "#625b6c"
      Behavior on color { ColorAnimation { duration: 140 } }
    }

    Rectangle {
      width: 17
      height: 17
      radius: 9
      y: 3
      x: toggle.checked ? toggle.width - width - 3 : 3
      color: toggle.checked ? "#14241a" : "#c1bac9"
      Behavior on x {
        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
      }
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: toggle.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
      onClicked: if (toggle.enabled) toggle.toggled(!toggle.checked)
    }
  }

  component IconButton: Rectangle {
    id: button

    property string icon: "refresh"
    signal clicked()

    implicitWidth: 30
    implicitHeight: 30
    radius: 8
    color: mouse.containsMouse ? root.rowHoverColor : "transparent"
    border.width: 1
    border.color: mouse.containsMouse ? Colors.primary : root.dividerColor
    opacity: enabled ? 1 : 0.4

    Text {
      anchors.centerIn: parent
      text: button.icon
      color: PopoutConfig.textColor
      font.family: "Material Symbols Outlined"
      font.pixelSize: 15
      renderType: Text.NativeRendering
    }

    MouseArea {
      id: mouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: button.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
      onClicked: if (button.enabled) button.clicked()
    }
  }

  component ServiceRow: Rectangle {
    id: serviceRow

    required property string title
    required property string description
    required property string serviceName
    required property string serviceState
    property string icon: "memory"
    property color iconColor: Colors.primary

    Layout.fillWidth: true
    Layout.preferredHeight: 70
    radius: PopoutConfig.innerRadius
    color: root.rowColor
    border.width: 1
    border.color: root.dividerColor

    RowLayout {
      anchors.fill: parent
      anchors.margins: 12
      spacing: 11

      Rectangle {
        width: 34
        height: 34
        radius: 9
        color: Qt.rgba(serviceRow.iconColor.r, serviceRow.iconColor.g,
                       serviceRow.iconColor.b, 0.12)

        Text {
          anchors.centerIn: parent
          text: serviceRow.icon
          color: serviceRow.iconColor
          font.family: "Material Symbols Outlined"
          font.pixelSize: 18
          renderType: Text.NativeRendering
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 1

        Text {
          text: serviceRow.title
          color: PopoutConfig.textColor
          font.pixelSize: 13
          font.weight: Font.DemiBold
          renderType: Text.NativeRendering
        }
        Text {
          text: serviceRow.description
          color: root.mutedText
          font.pixelSize: 10
          renderType: Text.NativeRendering
        }
        Text {
          text: root.stateLabel(serviceRow.serviceState)
          color: root.stateColor(serviceRow.serviceState)
          font.pixelSize: 9
          font.weight: Font.Bold
          font.letterSpacing: 0.7
          renderType: Text.NativeRendering
        }
      }

      IconButton {
        enabled: !root.actionBusy
        onClicked: root.restartService(serviceRow.serviceName)
      }

      SettingsToggle {
        checked: root.isActive(serviceRow.serviceState)
        enabled: !root.actionBusy && serviceRow.serviceState !== "unknown"
        onToggled: function(_) {
          root.toggleService(serviceRow.serviceName, checked)
        }
      }
    }
  }

  ColumnLayout {
    id: contentColumn
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: 14
    spacing: 10

    RowLayout {
      Layout.fillWidth: true
      spacing: 9

      BrainGraph {
        Layout.preferredWidth: 28
        Layout.preferredHeight: 28
        configScale: 0.5
        graphVisible: true
        shadowVisible: false
        graphColor: Colors.primary
        paused: !root.expanded
      }

      ColumnLayout {
        spacing: 0
        Text {
          text: "AI settings"
          color: PopoutConfig.textColor
          font.pixelSize: 14
          font.weight: Font.Bold
          renderType: Text.NativeRendering
        }
        Text {
          text: "Local services and speech defaults"
          color: root.mutedText
          font.pixelSize: 10
          renderType: Text.NativeRendering
        }
      }

      Item { Layout.fillWidth: true }

      Text {
        text: "settings"
        color: Colors.primary
        font.family: "Material Symbols Outlined"
        font.pixelSize: 18
        renderType: Text.NativeRendering
      }
    }

    Text {
      text: "SERVICES"
      color: root.mutedText
      font.pixelSize: 9
      font.weight: Font.Bold
      font.letterSpacing: 1.2
      renderType: Text.NativeRendering
    }

    ServiceRow {
      title: "Gemma 4 E4B"
      description: "Local language model · CUDA0 · :8083"
      serviceName: "gemma4-e4b-server.service"
      serviceState: root.gemmaState
      icon: "memory"
      iconColor: Colors.primary
    }

    ServiceRow {
      title: "Computer vision"
      description: "Inference and camera pipeline · :8154"
      serviceName: "computer-vision.service"
      serviceState: root.visionState
      icon: "visibility"
      iconColor: "#9ccfd8"
    }

    Text {
      text: "SPEECH DEFAULTS"
      color: root.mutedText
      font.pixelSize: 9
      font.weight: Font.Bold
      font.letterSpacing: 1.2
      renderType: Text.NativeRendering
    }

    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: 58
      radius: PopoutConfig.innerRadius
      color: root.rowColor
      border.width: 1
      border.color: root.dividerColor

      RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        Rectangle {
          width: 32
          height: 32
          radius: 9
          color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.12)
          Text {
            anchors.centerIn: parent
            text: "volume_up"
            color: Colors.primary
            font.family: "Material Symbols Outlined"
            font.pixelSize: 17
            renderType: Text.NativeRendering
          }
        }

        ColumnLayout {
          Layout.preferredWidth: 92
          spacing: 0
          Text {
            text: "TTS defaults"
            color: PopoutConfig.textColor
            font.pixelSize: 12
            font.weight: Font.DemiBold
            renderType: Text.NativeRendering
          }
          Text {
            text: root.ttsEnabled ? "Enabled" : "Disabled"
            color: root.ttsEnabled ? PopoutConfig.successColor : root.mutedText
            font.pixelSize: 9
            renderType: Text.NativeRendering
          }
        }

        Controls.ComboBox {
          id: providerCombo

          Layout.preferredWidth: 122
          Layout.preferredHeight: 30
          model: root.providerModel
          currentIndex: Math.max(0, root.providerModel.indexOf(root.ttsProvider))
          enabled: !root.actionBusy

          onActivated: function(index) {
            var provider = root.providerModel[index]
            if (provider && provider !== root.ttsProvider)
              root.writeTtsSetting("provider", provider)
          }

          contentItem: Text {
            leftPadding: 9
            rightPadding: 24
            text: providerCombo.displayText
            color: PopoutConfig.textColor
            font.pixelSize: 10
            font.weight: Font.DemiBold
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            renderType: Text.NativeRendering
          }

          indicator: Text {
            x: providerCombo.width - width - 8
            y: (providerCombo.height - height) / 2
            text: providerCombo.popup.visible ? "expand_less" : "expand_more"
            color: Colors.primary
            font.family: "Material Symbols Outlined"
            font.pixelSize: 16
            renderType: Text.NativeRendering
          }

          background: Rectangle {
            radius: 7
            color: providerCombo.hovered || providerCombo.popup.visible
              ? root.rowHoverColor : Qt.rgba(23 / 255, 20 / 255, 31 / 255, 0.72)
            border.width: 1
            border.color: providerCombo.popup.visible ? Colors.primary : root.dividerColor
          }

          delegate: Controls.ItemDelegate {
            id: providerDelegate
            required property int index
            required property string modelData

            width: providerCombo.width
            height: 28
            highlighted: providerCombo.highlightedIndex === index

            contentItem: Text {
              text: providerDelegate.modelData
              color: providerDelegate.highlighted ? PopoutConfig.textColor : root.mutedText
              font.pixelSize: 10
              font.weight: providerDelegate.highlighted ? Font.DemiBold : Font.Normal
              verticalAlignment: Text.AlignVCenter
              renderType: Text.NativeRendering
            }
            background: Rectangle {
              color: providerDelegate.highlighted
                ? Qt.rgba(196 / 255, 167 / 255, 231 / 255, 0.18) : "transparent"
              radius: 5
            }
          }

          popup: Controls.Popup {
            y: providerCombo.height + 4
            width: providerCombo.width
            implicitHeight: Math.min(contentItem.implicitHeight + 8, 240)
            padding: 4

            contentItem: ListView {
              clip: true
              implicitHeight: contentHeight
              model: providerCombo.popup.visible ? providerCombo.delegateModel : null
              currentIndex: providerCombo.highlightedIndex
              Controls.ScrollIndicator.vertical: Controls.ScrollIndicator {}
            }
            background: Rectangle {
              color: "#1f1d2e"
              radius: 8
              border.width: 1
              border.color: Colors.primary
            }
          }
        }

        IconButton {
          icon: "remove"
          enabled: !root.actionBusy && root.ttsSpeed > 0.5
          onClicked: root.setTtsSpeed(root.ttsSpeed - 0.1)
        }
        Text {
          Layout.preferredWidth: 31
          horizontalAlignment: Text.AlignHCenter
          text: root.ttsSpeed.toFixed(1) + "×"
          color: Colors.primary
          font.pixelSize: 10
          font.weight: Font.Bold
          renderType: Text.NativeRendering
        }
        IconButton {
          icon: "add"
          enabled: !root.actionBusy && root.ttsSpeed < 2.0
          onClicked: root.setTtsSpeed(root.ttsSpeed + 0.1)
        }

        SettingsToggle {
          checked: root.ttsEnabled
          enabled: !root.actionBusy
          onToggled: function(nextChecked) {
            root.writeTtsSetting("enabled", nextChecked ? "true" : "false")
          }
        }
      }
    }

    ServiceRow {
      title: "STT recording watcher"
      description: "Process new recordings into Obsidian notes"
      serviceName: "audio-summary-obsidian.service"
      serviceState: root.sttWatcherState
      icon: "mic"
      iconColor: "#ebbcba"
    }

    RowLayout {
      Layout.fillWidth: true
      Layout.preferredHeight: 18
      spacing: 7

      Rectangle {
        width: 6
        height: 6
        radius: 3
        color: root.actionBusy ? PopoutConfig.warningColor : PopoutConfig.successColor
      }
      Text {
        text: root.message || "Settings ready"
        color: root.mutedText
        font.pixelSize: 9
        elide: Text.ElideRight
        Layout.fillWidth: true
        renderType: Text.NativeRendering
      }
    }
  }
}
