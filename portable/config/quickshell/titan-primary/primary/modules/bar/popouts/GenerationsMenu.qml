import QtQuick
import QtQuick.Layouts
import "../../../services"

Rectangle {
  id: root
  
  property bool hasOwnBackground: true
  property var wrapper: null
  
  implicitWidth: 400
  implicitHeight: 500
  
  color: PopoutConfig.backgroundColor
  radius: PopoutConfig.cornerRadius
  border.width: PopoutConfig.borderWidth
  border.color: PopoutConfig.borderColor
  
  Component.onCompleted: Generations.refresh()
  
  ColumnLayout {
    id: content
    anchors.fill: parent
    anchors.margins: 16
    spacing: 8
    
    Text {
      text: "System Generations"
      font.pixelSize: 16
      font.weight: Font.Bold
      color: PopoutConfig.textColor
      Layout.fillWidth: true
    }
    
    Rectangle {
      Layout.fillWidth: true
      height: 1
      color: PopoutConfig.borderColor
      opacity: 0.3
    }
    
    ListView {
      id: listView
      Layout.fillWidth: true
      Layout.fillHeight: true
      clip: true
      spacing: 4
      
      model: Generations.generations
      
      delegate: Rectangle {
        required property var modelData
        required property int index
        
        width: listView.width
        height: 60
        color: mouseArea.containsMouse ? "#313244" : "transparent"
        radius: 8
        
        RowLayout {
          anchors.fill: parent
          anchors.margins: 12
          spacing: 12
          
          ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            
            RowLayout {
              spacing: 8
              
              Text {
                text: "#" + modelData.number
                font.pixelSize: 14
                font.weight: Font.Bold
                color: modelData.current ? PopoutConfig.successColor : PopoutConfig.textColor
              }
              
              Text {
                visible: modelData.current
                text: "(current)"
                font.pixelSize: 12
                color: PopoutConfig.successColor
                opacity: Colors.opacity.background1
              }
            }
            
            Text {
              text: modelData.date
              font.pixelSize: 11
              color: PopoutConfig.textColor
              opacity: 0.6
            }
            
            Text {
              text: modelData.summary
              font.pixelSize: 12
              color: PopoutConfig.textColor
              opacity: 0.8
            }
          }
          
          Text {
            visible: !modelData.current
            text: "chevron_right"
            font.family: "Material Symbols Outlined"
            font.pixelSize: 20
            color: PopoutConfig.textColor
            opacity: mouseArea.containsMouse ? Colors.opacity.foreground1 : Colors.opacity.background0
          }
        }
        
        MouseArea {
          id: mouseArea
          anchors.fill: parent
          hoverEnabled: true
          enabled: !modelData.current
          onClicked: {
            Generations.selectedGeneration = modelData.number
            if (root.wrapper) {
              root.wrapper.openPopout("generation-details", root.wrapper.currentX, root.wrapper.currentBottom, root.wrapper.currentWidgetWidth)
            }
          }
        }
      }
    }
    
    Text {
      visible: Generations.loading
      text: "Loading generations..."
      font.pixelSize: 13
      color: PopoutConfig.textColor
      opacity: 0.6
      Layout.alignment: Qt.AlignHCenter
    }
    
    Text {
      visible: Generations.error !== ""
      text: Generations.error
      font.pixelSize: 13
      color: PopoutConfig.errorColor
      Layout.alignment: Qt.AlignHCenter
    }
  }
}
