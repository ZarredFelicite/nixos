pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../services"

Rectangle {
    id: root

    property bool hasOwnBackground: true
    property var wrapper: null
    property bool showingScreenSelect: false
    property string selectedAction: "" // "screenshot" or "record"
    property bool recordMicrophone: false

    implicitWidth: Math.max(menuLayout.implicitWidth + 24, screenSelectLayout.implicitWidth + 24, 320)
    implicitHeight: root.showingScreenSelect ? 
        (screenSelectLayout.implicitHeight + 24) : 
        (menuLayout.implicitHeight + 24)

    color: PopoutConfig.backgroundColor
    radius: PopoutConfig.cornerRadius
    border.width: PopoutConfig.borderWidth
    border.color: PopoutConfig.borderColor



    Connections {
        target: Recording
        function onScreenshotCompleted() {
            if (wrapper) wrapper.scheduleClose()
        }
        function onRecordingCompleted() {
            if (wrapper) wrapper.scheduleClose()
        }
    }

    ColumnLayout {
        id: menuLayout
        anchors.centerIn: parent
        spacing: 6
        width: root.width - 24
        visible: !root.showingScreenSelect

        // Section title
        Text {
            text: "Screenshot"
            color: PopoutConfig.textColor
            font.pixelSize: 12
            font.bold: true
            Layout.leftMargin: 8
            Layout.topMargin: 4
        }

        // Screenshot options - Full Screen
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            color: fsMouse.containsMouse ? "#313244" : "transparent"
            radius: 6
            
            Behavior on color { ColorAnimation { duration: 150 } }
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 12
                
                Text {
                    text: "screenshot"
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 20
                    color: PopoutConfig.textColor
                }
                
                Text {
                    text: "Full Screen"
                    color: PopoutConfig.textColor
                    font.pixelSize: 14
                    Layout.fillWidth: true
                }
            }
            
            MouseArea {
                id: fsMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    if (Recording.availableMonitors.length > 1) {
                        root.selectedAction = "screenshot-fullscreen"
                        root.showingScreenSelect = true
                    } else {
                        Recording.screenshotFullscreen()
                        if (wrapper) wrapper.scheduleClose()
                    }
                }
            }
        }

        // Screenshot options - Region
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            color: regionMouse.containsMouse ? "#313244" : "transparent"
            radius: 6
            
            Behavior on color { ColorAnimation { duration: 150 } }
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 12
                
                Text {
                    text: "crop_free"
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 20
                    color: PopoutConfig.textColor
                }
                
                Text {
                    text: "Region"
                    color: PopoutConfig.textColor
                    font.pixelSize: 14
                    Layout.fillWidth: true
                }
            }
            
            MouseArea {
                id: regionMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    Recording.screenshotRegion()
                }
            }
        }

        // Screenshot options - Window
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            color: windowMouse.containsMouse ? "#313244" : "transparent"
            radius: 6
            
            Behavior on color { ColorAnimation { duration: 150 } }
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 12
                
                Text {
                    text: "window"
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 20
                    color: PopoutConfig.textColor
                }
                
                Text {
                    text: "Window"
                    color: PopoutConfig.textColor
                    font.pixelSize: 14
                    Layout.fillWidth: true
                }
            }
            
            MouseArea {
                id: windowMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    Recording.screenshotWindow()
                }
            }
        }

        // Divider
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: PopoutConfig.borderColor
            Layout.topMargin: 6
            Layout.bottomMargin: 6
        }

        // Section title
        Text {
            text: "Record"
            color: PopoutConfig.textColor
            font.pixelSize: 12
            font.bold: true
            Layout.leftMargin: 8
        }

        // Recording options - Full Screen
        Rectangle {
            visible: !Recording.isRecording
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            color: recordFSMouse.containsMouse ? "#313244" : "transparent"
            radius: 6
            
            Behavior on color { ColorAnimation { duration: 150 } }
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 12
                
                Text {
                    text: "videocam"
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 20
                    color: PopoutConfig.textColor
                }
                
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    
                    Text {
                        text: "Full Screen"
                        color: PopoutConfig.textColor
                        font.pixelSize: 14
                    }
                    
                    Text {
                        text: "Record full screen"
                        color: "#9ca3af"
                        font.pixelSize: 11
                    }
                }
            }
            
            MouseArea {
                id: recordFSMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    if (Recording.availableMonitors.length > 1) {
                        root.selectedAction = "record-fullscreen"
                        root.showingScreenSelect = true
                    } else {
                        Recording.recordFullscreen(false)
                        if (wrapper) wrapper.scheduleClose()
                    }
                }
            }
        }

        // Recording options - Region
        Rectangle {
            visible: !Recording.isRecording
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            color: recordRegionMouse.containsMouse ? "#313244" : "transparent"
            radius: 6
            
            Behavior on color { ColorAnimation { duration: 150 } }
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 12
                
                Text {
                    text: "crop_free"
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 20
                    color: PopoutConfig.textColor
                }
                
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    
                    Text {
                        text: "Region"
                        color: PopoutConfig.textColor
                        font.pixelSize: 14
                    }
                    
                    Text {
                        text: "Select area to record"
                        color: "#9ca3af"
                        font.pixelSize: 11
                    }
                }
            }
            
            MouseArea {
                id: recordRegionMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    if (wrapper) wrapper.scheduleClose()
                    // Defer to ensure popout fully closes and compositor releases focus
                    regionRecordTimer.start()
                }
            }
            
            Timer {
                id: regionRecordTimer
                interval: 250
                repeat: false
                onTriggered: Recording.recordRegion(false)
            }
        }

        // Recording options - Window
        Rectangle {
            visible: !Recording.isRecording
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            color: recordWindowMouse.containsMouse ? "#313244" : "transparent"
            radius: 6
            
            Behavior on color { ColorAnimation { duration: 150 } }
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 12
                
                Text {
                    text: "window"
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 20
                    color: PopoutConfig.textColor
                }
                
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    
                    Text {
                        text: "Window"
                        color: PopoutConfig.textColor
                        font.pixelSize: 14
                    }
                    
                    Text {
                        text: "Record active window"
                        color: "#9ca3af"
                        font.pixelSize: 11
                    }
                }
            }
            
            MouseArea {
                id: recordWindowMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    Recording.recordWindow(false)
                    // Don't close - recording starts but continues in background
                }
            }
        }

        // Stop recording button (shown when recording)
        Rectangle {
            visible: Recording.isRecording
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            color: stopMouse.containsMouse ? "#eb6f92" : "transparent"
            radius: 6
            opacity: visible ? Colors.opacity.foreground1 : 0
            height: visible ? 48 : 0
            
            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 200 } }
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 12
                
                Text {
                    text: "stop_circle"
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 20
                    color: "#eb6f92"
                }
                
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    
                    Text {
                        text: "Stop Recording"
                        color: "#eb6f92"
                        font.pixelSize: 14
                        font.bold: true
                    }
                    
                    Text {
                        visible: Recording.recordingFilename !== ""
                        text: Recording.recordingFilename ? Recording.recordingFilename.split('/').pop() : ""
                        color: "#9ca3af"
                        font.pixelSize: 11
                    }
                }
            }
            
            MouseArea {
                id: stopMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    Recording.stopRecording()
                    if (wrapper) wrapper.scheduleClose()
                }
            }
        }
    }

    // Screen selection layout
    ColumnLayout {
        id: screenSelectLayout
        anchors.centerIn: parent
        spacing: 8
        width: root.width - 24
        visible: root.showingScreenSelect



        Text {
            text: "Select Screen"
            color: PopoutConfig.textColor
            font.pixelSize: 14
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        Repeater {
            id: monitorRepeater
            model: Recording.availableMonitors
            


            Rectangle {
                required property int index
                required property string modelData
                
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                color: screenMouse.containsMouse ? "#313244" : "transparent"
                radius: 6

                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: "Monitor " + (parent.index + 1) + ": " + parent.modelData
                    color: PopoutConfig.textColor
                    font.pixelSize: 14
                }

                MouseArea {
                    id: screenMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        const monitorName = parent.modelData
                        // Call the appropriate recording function with selected monitor
                        if (root.selectedAction === "record-fullscreen") {
                            Recording.recordFullscreenOnMonitor(monitorName, false)
                        } else if (root.selectedAction === "screenshot-fullscreen") {
                            Recording.screenshotFullscreenOnMonitor(monitorName)
                        }
                        if (wrapper) wrapper.scheduleClose()
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            color: backMouse.containsMouse ? "#313244" : "transparent"
            radius: 6

            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: "Back"
                color: PopoutConfig.textColor
                font.pixelSize: 14
            }

            MouseArea {
                id: backMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    root.showingScreenSelect = false
                    root.selectedAction = ""
                }
            }
        }
    }

    // Menu item component
    component MenuItem: Rectangle {
        id: item

        required property string icon
        required property string label
        property string subtitle: ""
        property bool isDestructive: false
        property bool shouldShow: true
        property var onItemClicked: null

        Layout.preferredHeight: subtitle ? 48 : 40
        color: mouseArea.containsMouse ? "#313244" : "transparent"
        radius: 6

        visible: item.shouldShow
        opacity: visible ? Colors.opacity.foreground1 : 0
        height: visible ? Layout.preferredHeight : 0

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 200 } }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 12

            // Icon
            Text {
                text: item.icon
                font.family: "Material Symbols Outlined"
                font.pixelSize: 20
                color: item.isDestructive ? "#eb6f92" : PopoutConfig.textColor
                Layout.alignment: Qt.AlignVCenter
            }

            // Labels
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    text: item.label
                    color: item.isDestructive ? "#eb6f92" : PopoutConfig.textColor
                    font.pixelSize: 14
                    font.bold: item.isDestructive
                }

                Text {
                    visible: item.subtitle !== ""
                    text: item.subtitle
                    color: "#9ca3af"
                    font.pixelSize: 11
                }
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            propagateComposedEvents: true

            onClicked: function(mouse) {
                if (item.onItemClicked) {
                    item.onItemClicked()
                }
                mouse.accepted = false
            }
        }
    }
}
