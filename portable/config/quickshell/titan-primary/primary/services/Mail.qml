pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
  id: root

  property string lastMail: ""
  property bool hasNewMail: false

  readonly property var process: Process {
    id: mailProcess
    command: ["/home/zarred/scripts/waybar/last_mail.sh"]
    running: false

    stdout: SplitParser {
      onRead: function(data) {
        const output = data.trim()
        root.lastMail = output
        root.hasNewMail = output.length > 0
      }
    }

    onExited: function(exitCode) {
      if (exitCode !== 0) {
        root.lastMail = ""
        root.hasNewMail = false
      }
    }
  }

  readonly property var timer: Timer {
    interval: 60000 // 60 seconds, same as waybar config
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  function refresh() {
    mailProcess.running = false
    mailProcess.running = true
  }

  Component.onCompleted: {
    refresh()
  }
}