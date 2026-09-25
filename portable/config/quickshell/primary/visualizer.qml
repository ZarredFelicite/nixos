//@ pragma UseQApplication
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick
import "modules"
import "services"

ShellRoot {
    PanelWindow {
        id: rootWindow
        
        // Fullscreen overlay
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        color: "transparent"
        mask: Region {} // Click-through
        
        // Wayland Layer Shell configuration
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "visualizer-overlay"
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        BrainGraph {
            id: graph
            anchors.centerIn: parent
            
            // Force Line Mode for Audio Visualizer
            mode: 1 
            
            // Large scale for standalone visualization
            configScale: 6.0 
            
            width: 600
            height: 600
        }
    }
}
