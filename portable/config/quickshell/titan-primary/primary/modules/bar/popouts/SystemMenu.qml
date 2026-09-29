import QtQuick
import QtQuick.Layouts

Rectangle {
  id: root
  
  property bool hasOwnBackground: true
  
  implicitWidth: menuLayout.implicitWidth + 16
  implicitHeight: menuLayout.implicitHeight + 16
  
  color: PopoutConfig.backgroundColor
  radius: PopoutConfig.cornerRadius
  border.width: PopoutConfig.borderWidth
  border.color: PopoutConfig.borderColor
  
  ColumnLayout {
    id: menuLayout
    anchors.centerIn: parent
    spacing: 4
    
    // Quit Button
    Rectangle {
      Layout.preferredWidth: 120
      Layout.preferredHeight: 32
      color: quitMouse.containsMouse ? "#313244" : "transparent"
      radius: 6
      
      RowLayout {
        anchors.centerIn: parent
        spacing: 8
        
        Text {
          text: "logout"
          font.family: "Material Symbols Outlined"
          font.pixelSize: 16
          color: "#f38ba8"
        }
        
        Text {
          text: "Quit"
          color: PopoutConfig.textColor
          font.pixelSize: 14
        }
      }
      
      MouseArea {
        id: quitMouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
          var proc = Qt.createQmlObject('import Quickshell.Io; Process { }', root)
          proc.command = ["hyprctl", "dispatch", "exit"]
          proc.onExited.connect(function() {
            proc.destroy()
          })
          proc.running = true
          BarPopouts.hidePopout()
        }
      }
    }
    
    // Lock Button
    Rectangle {
      Layout.preferredWidth: 120
      Layout.preferredHeight: 32
      color: lockMouse.containsMouse ? "#313244" : "transparent"
      radius: 6
      
      RowLayout {
        anchors.centerIn: parent
        spacing: 8
        
        Text {
          text: "lock"
          font.family: "Material Symbols Outlined"
          font.pixelSize: 16
          color: "#fab387"
        }
        
        Text {
          text: "Lock"
          color: PopoutConfig.textColor
          font.pixelSize: 14
        }
      }
      
      MouseArea {
        id: lockMouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
          var proc = Qt.createQmlObject('import Quickshell.Io; Process { }', root)
          proc.command = ["loginctl", "lock-session"]
          proc.onExited.connect(function() {
            proc.destroy()
          })
          proc.running = true
          BarPopouts.hidePopout()
        }
      }
    }
    
    // Reboot Button
    Rectangle {
      Layout.preferredWidth: 120
      Layout.preferredHeight: 32
      color: rebootMouse.containsMouse ? "#313244" : "transparent"
      radius: 6
      
      RowLayout {
        anchors.centerIn: parent
        spacing: 8
        
        Text {
          text: "refresh"
          font.family: "Material Symbols Outlined"
          font.pixelSize: 16
          color: "#a6e3a1"
        }
        
        Text {
          text: "Reboot"
          color: PopoutConfig.textColor
          font.pixelSize: 14
        }
      }
      
      MouseArea {
        id: rebootMouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
          var proc = Qt.createQmlObject('import Quickshell.Io; Process { }', root)
          proc.command = ["reboot"]
          proc.onExited.connect(function() {
            proc.destroy()
          })
          proc.running = true
          BarPopouts.hidePopout()
        }
      }
    }
    
    // Power Button
    Rectangle {
      Layout.preferredWidth: 120
      Layout.preferredHeight: 32
      color: powerMouse.containsMouse ? "#313244" : "transparent"
      radius: 6
      
      RowLayout {
        anchors.centerIn: parent
        spacing: 8
        
        Text {
          text: "power_settings_new"
          font.family: "Material Symbols Outlined"
          font.pixelSize: 16
          color: "#f38ba8"
        }
        
        Text {
          text: "Shutdown"
          color: PopoutConfig.textColor
          font.pixelSize: 14
        }
      }
      
      MouseArea {
        id: powerMouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
          var proc = Qt.createQmlObject('import Quickshell.Io; Process { }', root)
          proc.command = ["shutdown", "now"]
          proc.onExited.connect(function() {
            proc.destroy()
          })
          proc.running = true
          BarPopouts.hidePopout()
        }
      }
    }
  }
}
