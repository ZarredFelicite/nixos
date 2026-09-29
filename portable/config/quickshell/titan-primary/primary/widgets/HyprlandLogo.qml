import QtQuick

Rectangle {
  id: root

  implicitWidth: 32
  implicitHeight: 32
  color: "transparent"
  radius: 16

  Image {
    anchors.centerIn: parent
    source: "/home/zarred/pictures/icons/hyprland.png"
    width: 24
    height: 24
    fillMode: Image.PreserveAspectFit
    smooth: false
    antialiasing: false
    sourceSize.width: width * (typeof Screen !== 'undefined' && Screen.devicePixelRatio ? Screen.devicePixelRatio : 1)
    sourceSize.height: height * (typeof Screen !== 'undefined' && Screen.devicePixelRatio ? Screen.devicePixelRatio : 1)
  }
}
