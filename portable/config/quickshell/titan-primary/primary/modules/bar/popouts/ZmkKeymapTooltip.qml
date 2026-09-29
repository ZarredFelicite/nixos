import QtQuick
import Quickshell.Widgets
import "../../../services"
import "./"

ClippingRectangle {
  id: root

  required property Item wrapper
  property bool expanded: wrapper && wrapper.hasCurrent && wrapper.currentName === "tooltip-zmk"
  property bool hasOwnBackground: true
  property int layerIndex: 0

  readonly property var layers: [
    { name: "Base", file: "DEF.png" },
    { name: "Navigation", file: "NAV.png" },
    { name: "Numbers", file: "NUM.png" },
    { name: "Mouse", file: "MSE.png" },
    { name: "Scroll", file: "SCR.png" },
    { name: "Gaming 1", file: "GM1.png" },
    { name: "Gaming 2", file: "GM2.png" }
  ]
  readonly property string imageRoot: "file:///home/zarred/.config/keyboard/zmk-workspace/draw/layers/"
  readonly property int hPadding: 18
  readonly property int vPadding: 14
  readonly property int contentWidth: 790
  readonly property int imageHeight: 336

  implicitWidth: expanded ? contentWidth + hPadding * 2 : 0
  implicitHeight: expanded ? header.height + imageHeight + vPadding * 2 + 16 : 0

  color: PopoutConfig.backgroundColor
  border.width: PopoutConfig.borderWidth
  border.color: PopoutConfig.borderColor
  radius: PopoutConfig.cornerRadius
  contentInsideBorder: true

  Behavior on implicitHeight {
    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
  }
  Behavior on opacity {
    NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
  }

  function changeLayer(offset) {
    layerIndex = (layerIndex + offset + layers.length) % layers.length
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.NoButton
    onExited: if (root.wrapper) root.wrapper.scheduleClose()
  }

  Item {
    id: header
    anchors.top: parent.top
    anchors.topMargin: root.vPadding
    anchors.left: parent.left
    anchors.leftMargin: root.hPadding
    anchors.right: parent.right
    anchors.rightMargin: root.hPadding
    height: 24

    Text {
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      text: "Zorne keymap"
      color: PopoutConfig.textColor
      font.pixelSize: 14
      font.weight: Font.DemiBold
    }

    Text {
      anchors.centerIn: parent
      text: root.layers[root.layerIndex].name
      color: Colors.primary
      font.pixelSize: 13
      font.weight: Font.DemiBold
    }

    Text {
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      text: ZmkBattery.tooltipText
      color: PopoutConfig.textColor
      opacity: 0.62
      font.pixelSize: 11
    }
  }

  Item {
    id: imageRow
    anchors.top: header.bottom
    anchors.topMargin: 8
    anchors.left: parent.left
    anchors.leftMargin: root.hPadding
    anchors.right: parent.right
    anchors.rightMargin: root.hPadding
    height: root.imageHeight

    component LayerButton: Rectangle {
      required property string symbol
      required property int direction

      width: 42
      height: 86
      anchors.verticalCenter: parent.verticalCenter
      radius: 12
      color: buttonArea.pressed
          ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.20)
          : Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.09)
      border.width: 1
      border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.28)

      Text {
        anchors.centerIn: parent
        text: symbol
        color: Colors.primary
        font.family: "Material Symbols Outlined"
        font.pixelSize: 28
      }

      MouseArea {
        id: buttonArea
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.changeLayer(direction)
      }
    }

    LayerButton {
      anchors.left: parent.left
      symbol: "chevron_left"
      direction: -1
    }

    Image {
      id: layerImage
      anchors.left: parent.left
      anchors.leftMargin: 50
      anchors.right: parent.right
      anchors.rightMargin: 50
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      source: root.imageRoot + root.layers[root.layerIndex].file
      fillMode: Image.PreserveAspectFit
      asynchronous: true
      cache: false
      smooth: true
      mipmap: true

      Behavior on opacity {
        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
      }
    }

    LayerButton {
      anchors.right: parent.right
      symbol: "chevron_right"
      direction: 1
    }
  }

  Row {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 9
    spacing: 6

    Repeater {
      model: root.layers.length
      Rectangle {
        required property int index
        width: index === root.layerIndex ? 18 : 6
        height: 6
        radius: 3
        color: index === root.layerIndex ? Colors.primary : PopoutConfig.textColor
        opacity: index === root.layerIndex ? 0.9 : 0.25
        Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
      }
    }
  }
}
