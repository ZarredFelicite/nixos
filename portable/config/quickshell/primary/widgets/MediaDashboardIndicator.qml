import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../services"

// Compact entry for the independently installed media dashboard.
Pill {
    id: root
    objectName: "MediaDashboardIndicator"

    readonly property string configDir: {
        const override = String(Quickshell.env("SANKARA_MEDIA_CONFIG") || "")
        if (override.length > 0)
            return override
        const xdg = String(Quickshell.env("XDG_CONFIG_HOME") || "")
        const home = String(Quickshell.env("HOME") || "")
        return (xdg.length > 0 ? xdg : home + "/.config") + "/quickshell/media-dashboard"
    }
    readonly property string launcher: configDir + "/scripts/launch-dashboard"
    signal activated()

    implicitWidth: content.implicitWidth + 12
    implicitHeight: Colors.pillHeight
    Layout.preferredWidth: implicitWidth

    RowLayout {
        id: content
        anchors.centerIn: parent
        spacing: 6

        Text {
            text: "󰐊"
            color: Colors.primary
            font.family: "Symbols Nerd Font"
            font.pixelSize: 15
            renderType: Text.NativeRendering
        }
        Text {
            text: "Media"
            color: Colors.surfaceText
            font.pixelSize: 11
            renderType: Text.NativeRendering
        }
    }

    Process {
        id: launcherProcess
        running: false
        command: [root.launcher]
        stdout: SplitParser { onRead: function(_) {} }
        stderr: SplitParser { onRead: function(_) {} }
    }

    MouseArea {
        id: mouse
        z: 1
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
            root.activated()
            if (!launcherProcess.running)
                launcherProcess.running = true
        }
    }
}
