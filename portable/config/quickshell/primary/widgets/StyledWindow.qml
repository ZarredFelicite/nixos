import Quickshell
import Quickshell.Wayland

PanelWindow {
    required property string name

    WlrLayershell.namespace: "primary-" + name
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    color: "transparent"
}
