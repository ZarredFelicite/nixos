import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io
import "../../../services"

Rectangle {
  id: root
  
  property bool hasOwnBackground: true
  property var wrapper: null
  property int generation: Generations.selectedGeneration
  
  Process {
    id: switchProcess
    running: false
    command: []
    
    onExited: function(exitCode, exitStatus) {
      if (exitCode === 0) {
        console.log("Successfully switched to generation", root.generation)
        sendNotification("Generation Switch", "Successfully switched to generation " + root.generation, "emblem-default")
      } else {
        console.error("Failed to switch to generation", root.generation, "Exit code:", exitCode)
        sendNotification("Generation Switch Failed", "Failed to switch to generation " + root.generation, "dialog-error")
      }
    }
  }
  
  Process {
    id: bootProcess
    running: false
    command: []
    
    onExited: function(exitCode, exitStatus) {
      if (exitCode === 0) {
        console.log("Successfully set boot generation to", root.generation)
        sendNotification("Generation Boot", "Generation " + root.generation + " will be used on next boot", "emblem-default")
      } else {
        console.error("Failed to set boot generation to", root.generation, "Exit code:", exitCode)
        sendNotification("Generation Boot Failed", "Failed to set boot generation to " + root.generation, "dialog-error")
      }
    }
  }
  
  function sendNotification(summary, body, icon) {
    var notifyProc = Qt.createQmlObject('import Quickshell.Io; Process { }', root)
    notifyProc.command = ["notify-send", "-a", "Quickshell", "-i", icon, summary, body]
    notifyProc.onExited.connect(function() {
      notifyProc.destroy()
    })
    notifyProc.running = true
  }
  
  function switchToGeneration(gen) {
    switchProcess.command = ["pkexec", "sh", "-c", 
      "nix-env -p /nix/var/nix/profiles/system --switch-generation " + gen + " && " +
      "/nix/var/nix/profiles/system/bin/switch-to-configuration switch"]
    switchProcess.running = true
  }
  
  function bootToGeneration(gen) {
    bootProcess.command = ["pkexec", "sh", "-c",
      "nix-env -p /nix/var/nix/profiles/system --switch-generation " + gen + " && " +
      "/nix/var/nix/profiles/system/bin/switch-to-configuration boot"]
    bootProcess.running = true
  }
  
  implicitWidth: 600
  implicitHeight: Math.min(700, content.implicitHeight + 32)
  
  color: PopoutConfig.backgroundColor
  radius: PopoutConfig.cornerRadius
  border.width: PopoutConfig.borderWidth
  border.color: PopoutConfig.borderColor
  
  onGenerationChanged: {
    if (generation > 0) {
      GenerationDiff.loadGeneration(generation)
    }
  }
  
  ColumnLayout {
    id: content
    anchors.fill: parent
    anchors.margins: 16
    spacing: 12
    
    RowLayout {
      Layout.fillWidth: true
      
      Text {
        text: "arrow_back"
        font.family: "Material Symbols Outlined"
        font.pixelSize: 20
        color: PopoutConfig.textColor
        
        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            if (root.wrapper) {
              root.wrapper.openPopout("generations-menu", root.wrapper.currentX, root.wrapper.currentBottom, root.wrapper.currentWidgetWidth)
            }
          }
        }
      }
      
      Text {
        text: "Generation #" + root.generation
        font.pixelSize: 16
        font.weight: Font.Bold
        color: PopoutConfig.textColor
        Layout.fillWidth: true
      }
    }
    
    Rectangle {
      Layout.fillWidth: true
      height: 1
      color: PopoutConfig.borderColor
      opacity: 0.3
    }
    
    ScrollView {
      Layout.fillWidth: true
      Layout.fillHeight: true
      clip: true
      
      ColumnLayout {
        width: parent.width
        spacing: 16
        
        Text {
          visible: GenerationDiff.rebootRequired
          text: " Reboot required"
          font.pixelSize: 13
          color: PopoutConfig.warningColor
          Layout.fillWidth: true
        }
        
        ColumnLayout {
          visible: GenerationDiff.downgrades.length > 0
          Layout.fillWidth: true
          spacing: 8
          
          Text {
            text: "Downgrades (" + GenerationDiff.downgradeCount + ")"
            font.pixelSize: 14
            font.weight: Font.Bold
            color: PopoutConfig.errorColor
          }
          
          Repeater {
            model: GenerationDiff.downgrades
            delegate: Text {
              required property var modelData
              text: "  " + modelData.name + " " + modelData.from + " → " + modelData.to
              font.pixelSize: 12
              font.family: "monospace"
              color: PopoutConfig.textColor
              opacity: Colors.opacity.foreground0
              Layout.fillWidth: true
            }
          }
        }
        
        ColumnLayout {
          visible: GenerationDiff.upgrades.length > 0
          Layout.fillWidth: true
          spacing: 8
          
          Text {
            text: "Upgrades (" + GenerationDiff.upgradeCount + ")"
            font.pixelSize: 14
            font.weight: Font.Bold
            color: PopoutConfig.successColor
          }
          
          Repeater {
            model: GenerationDiff.upgrades
            delegate: Text {
              required property var modelData
              text: "  " + modelData.name + " " + modelData.from + " → " + modelData.to
              font.pixelSize: 12
              font.family: "monospace"
              color: PopoutConfig.textColor
              opacity: Colors.opacity.foreground0
              Layout.fillWidth: true
            }
          }
        }
        
        ColumnLayout {
          visible: GenerationDiff.additions.length > 0
          Layout.fillWidth: true
          spacing: 8
          
          Text {
            text: "Additions (" + GenerationDiff.additionCount + ")"
            font.pixelSize: 14
            font.weight: Font.Bold
            color: PopoutConfig.textColor
          }
          
          Repeater {
            model: GenerationDiff.additions
            delegate: Text {
              required property var modelData
              text: "  + " + modelData.name + " " + modelData.version
              font.pixelSize: 12
              font.family: "monospace"
              color: PopoutConfig.successColor
              opacity: Colors.opacity.foreground0
              Layout.fillWidth: true
            }
          }
        }
        
        ColumnLayout {
          visible: GenerationDiff.removals.length > 0
          Layout.fillWidth: true
          spacing: 8
          
          Text {
            text: "Removals (" + GenerationDiff.removalCount + ")"
            font.pixelSize: 14
            font.weight: Font.Bold
            color: PopoutConfig.textColor
          }
          
          Repeater {
            model: GenerationDiff.removals
            delegate: Text {
              required property var modelData
              text: "  - " + modelData.name + " " + modelData.version
              font.pixelSize: 12
              font.family: "monospace"
              color: PopoutConfig.errorColor
              opacity: Colors.opacity.foreground0
              Layout.fillWidth: true
            }
          }
        }
        
        Text {
          visible: GenerationDiff.loading
          text: "Loading changes..."
          font.pixelSize: 13
          color: PopoutConfig.textColor
          opacity: 0.6
          Layout.alignment: Qt.AlignHCenter
        }
        
        Text {
          visible: GenerationDiff.error !== ""
          text: GenerationDiff.error
          font.pixelSize: 13
          color: PopoutConfig.errorColor
          Layout.alignment: Qt.AlignHCenter
        }
      }
    }
    
    Rectangle {
      Layout.fillWidth: true
      height: 1
      color: PopoutConfig.borderColor
      opacity: 0.3
    }
    
    RowLayout {
      Layout.fillWidth: true
      spacing: 8
      
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 36
        color: switchMouse.containsMouse ? "#313244" : PopoutConfig.secondaryBackgroundColor
        radius: 8
        border.width: 1
        border.color: PopoutConfig.successColor
        
        Text {
          anchors.centerIn: parent
          text: "Switch"
          font.pixelSize: 14
          font.weight: Font.Medium
          color: PopoutConfig.successColor
        }
        
        MouseArea {
          id: switchMouse
          anchors.fill: parent
          hoverEnabled: true
          onClicked: {
            root.switchToGeneration(root.generation)
          }
        }
      }
      
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 36
        color: bootMouse.containsMouse ? "#313244" : PopoutConfig.secondaryBackgroundColor
        radius: 8
        border.width: 1
        border.color: PopoutConfig.textColor
        
        Text {
          anchors.centerIn: parent
          text: "Boot"
          font.pixelSize: 14
          font.weight: Font.Medium
          color: PopoutConfig.textColor
        }
        
        MouseArea {
          id: bootMouse
          anchors.fill: parent
          hoverEnabled: true
          onClicked: {
            root.bootToGeneration(root.generation)
          }
        }
      }
    }
  }
}
