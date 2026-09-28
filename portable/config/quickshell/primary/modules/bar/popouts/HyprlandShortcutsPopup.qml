import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Widgets
import "../../../services"
import "./"

ClippingRectangle {
  id: root

  required property Item wrapper
  property bool expanded: wrapper && wrapper.hasCurrent && wrapper.currentName === "shortcuts"
  property bool hasOwnBackground: true
  property var shortcuts: []
  property var bindingsByKey: ({})
  property var otherBindings: []
  property string outputBuffer: ""
  property bool loading: false
  property string errorText: ""
  readonly property var programPages: [
    "Hyprland", "Kitty", "Pqiv", "MPV", "Aerc", "Neomutt",
    "Newsboat", "Tmux", "Zsh", "FZF", "Yazi"
  ]
  property int programIndex: 0
  property string programQuery: ""
  readonly property string currentProgram: root.programPages[root.programIndex]
  // Scale the visual keyboard to use the monitor width instead of leaving empty side space.
  readonly property real keyUnit: Math.max(100, Math.min(195, (wrapper.width - 120) / 17))
  readonly property real keyGap: Math.max(10, Math.min(20, keyUnit / 9))
  readonly property real keyHeight: Math.max(100, Math.min(136, (wrapper.height - 360) / 6))
  readonly property real keyboardHeight: keyHeight * 6 + keyGap * 5 + 24

  readonly property var keyboardRows: [
    [
      { label: "Esc", code: "Escape", width: 1 },
      { label: "F1", code: "F1", width: 0.9 }, { label: "F2", code: "F2", width: 0.9 },
      { label: "F3", code: "F3", width: 0.9 }, { label: "F4", code: "F4", width: 0.9 },
      { label: "F5", code: "F5", width: 0.9 }, { label: "F6", code: "F6", width: 0.9 },
      { label: "F7", code: "F7", width: 0.9 }, { label: "F8", code: "F8", width: 0.9 },
      { label: "F9", code: "F9", width: 0.9 }, { label: "F10", code: "F10", width: 0.9 },
      { label: "F11", code: "F11", width: 0.9 }, { label: "F12", code: "F12", width: 0.9 },
      { label: "PrtSc", code: "Print", width: 1 }, { label: "Del", code: "Delete", width: 1 }
    ],
    [
      { label: "`", code: "Grave", width: 1 }, { label: "1", code: "1", width: 1 },
      { label: "2", code: "2", width: 1 }, { label: "3", code: "3", width: 1 },
      { label: "4", code: "4", width: 1 }, { label: "5", code: "5", width: 1 },
      { label: "6", code: "6", width: 1 }, { label: "7", code: "7", width: 1 },
      { label: "8", code: "8", width: 1 }, { label: "9", code: "9", width: 1 },
      { label: "0", code: "0", width: 1 }, { label: "-", code: "Minus", width: 1 },
      { label: "=", code: "Equal", width: 1 }, { label: "Backspace", code: "Backspace", width: 2 }
    ],
    [
      { label: "Tab", code: "Tab", width: 1.5 }, { label: "Q", code: "Q", width: 1 },
      { label: "W", code: "W", width: 1 }, { label: "F", code: "F", width: 1 },
      { label: "P", code: "P", width: 1 }, { label: "B", code: "B", width: 1 },
      { label: "J", code: "J", width: 1 }, { label: "L", code: "L", width: 1 },
      { label: "U", code: "U", width: 1 }, { label: "Y", code: "Y", width: 1 },
      { label: ";", code: "Semicolon", width: 1 }, { label: "[", code: "BracketLeft", width: 1 },
      { label: "]", code: "BracketRight", width: 1 }, { label: "\\", code: "Backslash", width: 1.5 }
    ],
    [
      { label: "Caps", code: "CapsLock", width: 1.8 }, { label: "A", code: "A", width: 1 },
      { label: "R", code: "R", width: 1 }, { label: "S", code: "S", width: 1 },
      { label: "T", code: "T", width: 1 }, { label: "G", code: "G", width: 1 },
      { label: "M", code: "M", width: 1 }, { label: "N", code: "N", width: 1 },
      { label: "E", code: "E", width: 1 }, { label: "I", code: "I", width: 1 },
      { label: "O", code: "O", width: 1 }, { label: "'", code: "Apostrophe", width: 1 },
      { label: "Enter", code: "Enter", width: 2.2 }
    ],
    [
      { label: "⇧", code: "Shift", width: 2.3 }, { label: "Z", code: "Z", width: 1 },
      { label: "X", code: "X", width: 1 }, { label: "C", code: "C", width: 1 },
      { label: "D", code: "D", width: 1 }, { label: "V", code: "V", width: 1 },
      { label: "K", code: "K", width: 1 }, { label: "H", code: "H", width: 1 },
      { label: ",", code: "Comma", width: 1 }, { label: ".", code: "Period", width: 1 },
      { label: "/", code: "Slash", width: 1 }, { label: "⇧", code: "ShiftRight", width: 2.8 }
    ],
    [
      { label: "⌃", code: "Control", width: 1.3 }, { label: "⊞", code: "Super", width: 1.5 },
      { label: "⌥", code: "Alt", width: 1.3 }, { label: "Space", code: "Space", width: 6 },
      { label: "⌥", code: "AltRight", width: 1.3 }, { label: "⊞", code: "SuperRight", width: 1.5 },
      { label: "Menu", code: "Menu", width: 1.3 }, { label: "⌃", code: "ControlRight", width: 1.3 }
    ]
  ]

  implicitWidth: expanded ? wrapper.width : 0
  implicitHeight: expanded ? wrapper.height : 0

  layer.enabled: true
  layer.smooth: false
  color: Qt.rgba(20 / 255, 18 / 255, 28 / 255, 0.97)
  border.width: 0
  border.color: "transparent"
  radius: 0
  contentInsideBorder: true
  clip: true
  focus: expanded
  activeFocusOnTab: true

  Behavior on implicitHeight {
    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
  }

  function normalizeKey(key) {
    const value = key.trim()
    const aliases = {
      "Return": "Enter",
      "return": "Enter",
      "escape": "Escape",
      "ESC": "Escape",
      "?": "Slash",
      "Print_Screen": "Print",
      "PrintScreen": "Print",
      "Page_Up": "Prior",
      "Page_Down": "Next"
    }
    return aliases[value] || value
  }

  function bindingsFor(key) {
    return root.bindingsByKey[key] || []
  }

  function modifierSymbols(modifiers) {
    return (modifiers || "")
      .replace(/SUPER/gi, "⊞")
      .replace(/CTRL/gi, "⌃")
      .replace(/SHIFT/gi, "⇧")
      .replace(/ALT/gi, "⌥")
      .replace(/\+/g, " ")
  }

  function bindingLine(binding) {
    const symbols = root.modifierSymbols(binding.modifiers)
    const prefix = binding.submap ? binding.combo : symbols
    return prefix ? `${prefix} · ${binding.description}` : binding.description
  }

  function listLine(binding) {
    return `${binding.combo || binding.key} · ${binding.description}`
  }

  function isKeyboardKey(key) {
    for (const row of root.keyboardRows) {
      for (const item of row) {
        if (item.code === key)
          return true
      }
    }
    return false
  }

  function modifiersForMask(mask) {
    const modifiers = []
    if (mask & 64) modifiers.push("SUPER")
    if (mask & 4) modifiers.push("CTRL")
    if (mask & 1) modifiers.push("SHIFT")
    if (mask & 8) modifiers.push("ALT")
    return modifiers.join("+")
  }

  function friendlyDescription(dispatcher, arg, submap, key) {
    const value = (arg || "").trim()
    if (dispatcher === "submap")
      return `Enter ${value || submap || "submap"} submap`
    if (dispatcher === "movefocus")
      return `Focus ${({ l: "left", r: "right", u: "up", d: "down" })[value] || value}`
    if (dispatcher === "swapwindow")
      return `Swap window ${value}`
    if (dispatcher === "movewindoworgroup")
      return `Move window ${value}`
    if (dispatcher === "workspace")
      return `Workspace ${value}`
    if (dispatcher === "movetoworkspace")
      return `Move to workspace ${value}`
    if (dispatcher === "fullscreenstate")
      return "Toggle fullscreen"
    if (dispatcher === "resizeactive")
      return "Resize active window"
    if (dispatcher === "exec") {
      if (value.includes("toggle_special.sh"))
        return `Toggle ${value.split("toggle_special.sh")[1].trim()} workspace`
      if (value.includes("hide_window.sh")) {
        const target = value.split("hide_window.sh")[1].trim().split(/\s+/)[0]
        return `Toggle ${target || "window"}`
      }
      if (value.includes("quickshell ipc"))
        return "Show shortcut overlay"
      if (value.includes("hover-lens"))
        return "Run Hover Lens"
      if (value.includes("hyprpin"))
        return "Pin active window"
      if (value.includes("hyprfull"))
        return "Toggle full layout"
      if (value.includes("hyprwindow"))
        return "Open window picker"
      if (value.includes("hypr_focusfloat"))
        return "Focus floating window"
      if (value.includes("hypr_opacity"))
        return "Adjust window opacity"
      if (value.includes("hyprzoom"))
        return value.includes("decrease") ? "Zoom out" : "Zoom in"
      if (value.includes("move_widget_cursor"))
        return value.endsWith(" l") ? "Move widget left" : "Move widget right"
      if (value.includes("screencapture/screenshot"))
        return "Take screenshot"
      if (value.includes("stt/stt"))
        return value.includes("--type") ? "Type speech" : "Record speech"
      if (value.includes("media-select")) {
        if (value.endsWith("previous")) return "Previous track"
        if (value.endsWith("next")) return "Next track"
        if (value.includes("position -5")) return "Seek back 5 seconds"
        if (value.includes("position +5")) return "Seek forward 5 seconds"
        return "Play / pause"
      }
      if (value.includes("volume.sh"))
        return value.endsWith("-") ? "Volume down" : "Volume up"
      if (value.includes("brightness.sh"))
        return value.includes("--decrease") ? "Brightness down" : "Brightness up"
      if (value.includes("swaync-client"))
        return value.includes("hide-latest") ? "Hide latest notification" : "Close notification"
      if (value.includes("vicinae toggle"))
        return "Toggle Vicinae launcher"
      if (value.includes("loginctl lock-session"))
        return "Lock session"
      if (value.includes("kitty"))
        return "Launch Kitty"
      if (value.includes("rofi"))
        return "Open calculator"
      if (value === "reset")
        return "Reset submap"
      if (value.endsWith(" firefox"))
        return "Launch Firefox"
      const command = value.split("/").pop().split(" ")[0]
      return command || "Run command"
    }
    if (dispatcher === "togglegroup") return "Toggle window group"
    if (dispatcher === "togglefloating") return "Toggle floating"
    if (dispatcher === "killactive") return "Close active window"
    if (dispatcher === "pseudo") return "Toggle pseudo-tiling"
    if (dispatcher === "centerwindow") return "Center window"
    if (dispatcher === "changegroupactive") return `Group window ${value}`
    if (dispatcher === "lockactivegroup") return "Lock window group"
    return `${dispatcher}${value ? ` · ${value}` : ""}`
  }

  function parseOutput(text) {
    const rawBindings = []
    const blocks = text.split(/\n\s*\n/)

    for (const block of blocks) {
      const fields = {}
      for (const rawLine of block.split(/\r?\n/)) {
        const line = rawLine.trim()
        const separator = line.indexOf(":")
        if (separator < 0)
          continue
        fields[line.slice(0, separator)] = line.slice(separator + 1).trim()
      }

      if (!fields.key || fields.key === "false")
        continue

      rawBindings.push({
        key: root.normalizeKey(fields.key),
        mask: parseInt(fields.modmask || "0") || 0,
        submap: fields.submap || "",
        dispatcher: fields.dispatcher || "bind",
        arg: fields.arg || ""
      })
    }

    // Resolve submap paths into a readable sequence, e.g. ⊞ I → E.
    const submapPrefixes = {}
    for (let pass = 0; pass < rawBindings.length; pass++) {
      for (const raw of rawBindings) {
        if (raw.dispatcher !== "submap" || !raw.arg)
          continue
        const symbols = root.modifierSymbols(root.modifiersForMask(raw.mask))
        const parent = raw.submap ? submapPrefixes[raw.submap] : ""
        const trigger = [symbols, raw.key].filter(part => part).join(" ")
        const prefix = parent ? `${parent} → ${raw.key}` : trigger
        if (!submapPrefixes[raw.arg] || parent)
          submapPrefixes[raw.arg] = prefix
      }
    }

    const parsed = []
    const grouped = {}
    for (const raw of rawBindings) {
      const symbols = root.modifierSymbols(root.modifiersForMask(raw.mask))
      const submapPrefix = raw.submap
        ? (submapPrefixes[raw.submap] || `[${raw.submap}]`)
        : ""
      const combo = raw.submap
        ? `${submapPrefix} → ${raw.key}`
        : [symbols, raw.key].filter(part => part).join(" ")
      const binding = {
        key: raw.key,
        combo: combo,
        modifiers: root.modifiersForMask(raw.mask),
        submap: !!raw.submap,
        description: root.friendlyDescription(raw.dispatcher, raw.arg, raw.submap, raw.key),
        command: `${raw.dispatcher}${raw.arg ? ` ${raw.arg}` : ""}`
      }
      parsed.push(binding)
      if (!grouped[raw.key]) grouped[raw.key] = []
      grouped[raw.key].push(binding)
    }

    shortcuts = parsed
    bindingsByKey = grouped
    otherBindings = parsed.filter(binding => !root.isKeyboardKey(binding.key))
  }

  function parseProgramCombo(combo) {
    return combo
      .replace(/ctrl/gi, "⌃")
      .replace(/shift/gi, "⇧")
      .replace(/alt/gi, "⌥")
      .replace(/super/gi, "⊞")
      .replace(/\+/g, " ")
  }

  function programKey(combo) {
    const first = combo.split(/\s+or\s+|\/|,/)[0].trim()
    const parts = first.split("+")
    const key = parts[parts.length - 1].trim().toUpperCase()
    const aliases = {
      "ESC": "Escape", "ENTER": "Enter", "SPACE": "Space", "TAB": "Tab",
      "LEFT": "Left", "RIGHT": "Right", "UP": "Up", "DOWN": "Down",
      "PRINT": "Print"
    }
    if (aliases[key]) return aliases[key]
    return key.length === 1 ? key : ""
  }

  function parseProgramOutput(text) {
    const parsed = []
    const grouped = {}
    const clean = text.replace(/\u001b\[[0-?]*[ -\/]*[@-~]/g, "")
    for (const rawLine of clean.split(/\r?\n/)) {
      const line = rawLine.trim()
      if (!line.startsWith("- ")) continue
      const parts = line.slice(2).split(" - ")
      if (parts.length < 2) continue
      const rawCombo = parts.shift().trim()
      const action = parts.shift().trim()
      const description = parts.join(" - ").trim() || action
      const key = root.programKey(rawCombo)
      const modifiers = rawCombo.split("+").slice(0, -1).join("+")
      const binding = {
        key: key,
        combo: root.parseProgramCombo(rawCombo),
        modifiers: modifiers,
        submap: false,
        description: description,
        command: action
      }
      parsed.push(binding)
      if (key) {
        if (!grouped[key]) grouped[key] = []
        grouped[key].push(binding)
      }
    }
    shortcuts = parsed
    bindingsByKey = grouped
    otherBindings = parsed.filter(binding => !root.isKeyboardKey(binding.key))
  }

  function switchProgram(delta) {
    programQuery = ""
    programIndex = (programIndex + delta + programPages.length) % programPages.length
    refresh()
  }

  function searchPrograms(event) {
    if (!event.text || !/^[a-z0-9]$/i.test(event.text))
      return false

    let query = (root.programQuery + event.text).toLowerCase()
    let index = root.programPages.findIndex(program => program.toLowerCase().startsWith(query))
    if (index < 0) {
      query = event.text.toLowerCase()
      index = root.programPages.findIndex(program => program.toLowerCase().startsWith(query))
    }
    if (index < 0)
      return false

    root.programQuery = query
    programSearchTimer.restart()
    if (index !== root.programIndex) {
      root.programIndex = index
      root.refresh()
    }
    return true
  }

  function refresh() {
    if (shortcutProcess.running)
      shortcutProcess.running = false
    outputBuffer = ""
    errorText = ""
    loading = true
    shortcutProcess.command = root.currentProgram === "Hyprland"
      ? ["hyprctl", "binds"]
      : ["/home/zarred/scripts/keyboard/shortcuts", "preview", root.currentProgram]
    shortcutProcess.running = true
  }

  onExpandedChanged: {
    if (expanded) {
      refresh()
      forceActiveFocus()
    }
  }

  Keys.onEscapePressed: {
    if (root.wrapper)
      root.wrapper.close()
  }

  Keys.onLeftPressed: {
    root.switchProgram(-1)
    event.accepted = true
  }

  Keys.onRightPressed: {
    root.switchProgram(1)
    event.accepted = true
  }

  Keys.onPressed: {
    if (root.searchPrograms(event))
      event.accepted = true
  }

  Timer {
    id: programSearchTimer
    interval: 900
    repeat: false
    onTriggered: root.programQuery = ""
  }

  Process {
    id: shortcutProcess
    running: false
    command: []

    stdout: SplitParser {
      onRead: function(data) {
        root.outputBuffer += data.toString() + "\n"
      }
    }

    stderr: SplitParser {
      onRead: function(_) {}
    }

    onExited: function(code) {
      root.loading = false
      if (code === 0) {
        if (root.currentProgram === "Hyprland")
          root.parseOutput(root.outputBuffer)
        else
          root.parseProgramOutput(root.outputBuffer)
      } else {
        root.errorText = `Could not read ${root.currentProgram} bindings`
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.NoButton
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: 30
    spacing: 18

    RowLayout {
      Layout.fillWidth: true
      spacing: 16

      Text {
        text: "‹"
        color: Colors.primary
        font.pixelSize: 40
        font.weight: Font.DemiBold
        renderType: Text.NativeRendering
      }

      Text {
        text: "keyboard"
        color: Colors.primary
        font.family: "Material Symbols Outlined"
        font.pixelSize: 38
        renderType: Text.NativeRendering
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        Text {
          text: `${root.currentProgram} shortcuts`
          color: PopoutConfig.textColor
          font.pixelSize: 26
          font.weight: Font.DemiBold
          renderType: Text.NativeRendering
        }

        Text {
          text: root.currentProgram === "Hyprland"
            ? "Colemak-DH layout · live bindings · ⊞ + ? to toggle"
            : "Program reference · ←/→ switch programs · ⊞ + ? to toggle"
          color: PopoutConfig.textColor
          opacity: 0.6
          font.pixelSize: 14
          renderType: Text.NativeRendering
        }
      }

      Text {
        text: root.loading
          ? "Loading…"
          : `${root.programIndex + 1}/${root.programPages.length} · ${root.shortcuts.length} bindings`
        color: Colors.primary
        opacity: 0.85
        font.pixelSize: 15
        renderType: Text.NativeRendering
      }

      Text {
        visible: root.programQuery.length > 0
        text: `“${root.programQuery}”`
        color: Colors.primary
        opacity: 0.9
        font.pixelSize: 16
        font.weight: Font.DemiBold
        renderType: Text.NativeRendering
      }

      Text {
        text: "›"
        color: Colors.primary
        font.pixelSize: 40
        font.weight: Font.DemiBold
        renderType: Text.NativeRendering
      }
    }

    Rectangle {
      Layout.fillWidth: true
      height: 1
      color: PopoutConfig.innerBorderColor
    }

    Item {
      id: keyboard
      Layout.fillWidth: true
      Layout.preferredHeight: root.keyboardHeight
      Layout.minimumHeight: root.keyboardHeight

      Column {
        anchors.centerIn: parent
        width: parent.width
        spacing: root.keyGap

        Repeater {
          model: root.keyboardRows

          delegate: Item {
            required property var modelData
            width: parent.width
            height: root.keyHeight

            Row {
              anchors.horizontalCenter: parent.horizontalCenter
              spacing: root.keyGap

              Repeater {
                model: modelData

                delegate: Rectangle {
                  required property var modelData
                  width: modelData.width * root.keyUnit + (modelData.width - 1) * root.keyGap
                  height: root.keyHeight
                  radius: 12
                  clip: true
                  property var entries: root.bindingsFor(modelData.code)
                  color: entries.length > 0
                    ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.24)
                    : Qt.rgba(255, 255, 255, 0.07)
                  border.width: entries.length > 0 ? 2 : 1
                  border.color: entries.length > 0
                    ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.82)
                    : Qt.rgba(255, 255, 255, 0.12)

                  Column {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 4

                    Text {
                      width: parent.width
                      text: modelData.label
                      color: entries.length > 0 ? Colors.primary : PopoutConfig.textColor
                      opacity: entries.length > 0 ? 1 : 0.70
                      font.pixelSize: modelData.label.length > 5 ? 18 : 28
                      font.weight: entries.length > 0 ? Font.DemiBold : Font.Normal
                      horizontalAlignment: Text.AlignHCenter
                      elide: Text.ElideRight
                      renderType: Text.NativeRendering
                    }

                    Repeater {
                      model: entries

                      delegate: Text {
                        required property var modelData
                        width: parent.width
                        text: root.bindingLine(modelData)
                        color: PopoutConfig.textColor
                        opacity: 0.98
                        font.pixelSize: 15
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        renderType: Text.NativeRendering
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

    Rectangle {
      Layout.fillWidth: true
      Layout.fillHeight: true
      Layout.minimumHeight: 180
      radius: 16
      color: Qt.rgba(0, 0, 0, 0.18)

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 10

        RowLayout {
          Layout.fillWidth: true
          Text {
            text: "All bindings"
            color: Colors.primary
            font.pixelSize: 20
            font.weight: Font.DemiBold
            renderType: Text.NativeRendering
          }
          Item { Layout.fillWidth: true }
          Text {
            text: `${root.shortcuts.length} active bindings · scroll to browse`
            color: PopoutConfig.textColor
            opacity: 0.55
            font.pixelSize: 13
            renderType: Text.NativeRendering
          }
        }

        GridView {
          id: allBindings
          Layout.fillWidth: true
          Layout.fillHeight: true
          clip: true
          cellWidth: width / 3
          cellHeight: 58
          model: root.shortcuts
          boundsBehavior: Flickable.StopAtBounds
          ScrollBar.vertical: ScrollBar {
            policy: allBindings.contentHeight > allBindings.height
              ? ScrollBar.AsNeeded
              : ScrollBar.AlwaysOff
          }

          delegate: Rectangle {
            required property var modelData
            width: allBindings.cellWidth - 10
            height: allBindings.cellHeight - 8
            radius: 10
            color: Qt.rgba(255, 255, 255, 0.07)

            Text {
              anchors.fill: parent
              anchors.margins: 12
              text: root.listLine(modelData)
              color: PopoutConfig.textColor
              font.pixelSize: 14
              font.weight: Font.DemiBold
              verticalAlignment: Text.AlignVCenter
              elide: Text.ElideRight
              renderType: Text.NativeRendering
            }
          }
        }
      }
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: 10
      Text {
        text: "Highlighted keys have bindings · Colemak-DH"
        color: PopoutConfig.textColor
        opacity: 0.5
        font.pixelSize: 12
        renderType: Text.NativeRendering
      }
      Item { Layout.fillWidth: true }
      Text {
        text: "ESC closes"
        color: PopoutConfig.textColor
        opacity: 0.5
        font.pixelSize: 12
        renderType: Text.NativeRendering
      }
    }

    Text {
      Layout.alignment: Qt.AlignHCenter
      visible: root.loading || !!root.errorText
      text: root.errorText || "Reading active Hyprland bindings…"
      color: root.errorText ? PopoutConfig.errorColor : PopoutConfig.textColor
      opacity: 0.7
      font.pixelSize: 12
      renderType: Text.NativeRendering
    }
  }
}
