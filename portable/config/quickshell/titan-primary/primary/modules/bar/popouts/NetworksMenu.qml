import QtQuick
import QtQuick.Layouts
import "../../../services"

Rectangle {
  id: root
  
  property bool hasOwnBackground: true
  property var wrapper: null

  readonly property bool isWired: Network.iface.startsWith("en") || Network.iface.startsWith("eth")
  readonly property bool is24Ghz: !isWired && Network.frequencyMhz > 0 && Network.frequencyMhz < 4900
  readonly property color bandColor: is24Ghz ? Colors.todoPriorityMedium : Colors.foregroundCyan

  function formatRate(value) {
    if (value >= 100) return value.toFixed(0)
    if (value >= 10) return value.toFixed(1)
    return value.toFixed(2)
  }

  component ConnectionMeter: Item {
    required property string icon
    required property string label
    required property string valueText
    required property real value
    required property color accent

    implicitHeight: 18

    Text {
      id: meterIcon
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      text: parent.icon
      font.family: "Material Symbols Outlined"
      font.pixelSize: 13
      color: parent.accent
      renderType: Text.NativeRendering
    }

    Text {
      anchors.left: meterIcon.right
      anchors.leftMargin: 6
      anchors.verticalCenter: parent.verticalCenter
      width: 48
      text: parent.label
      font.pixelSize: 10
      color: PopoutConfig.textColor
      opacity: 0.55
      renderType: Text.NativeRendering
    }

    Rectangle {
      anchors.left: parent.left
      anchors.leftMargin: 72
      anchors.right: meterValue.left
      anchors.rightMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      height: 3
      radius: 2
      color: Qt.rgba(1, 1, 1, 0.08)

      Rectangle {
        width: parent.width * Math.max(0, Math.min(1, value))
        height: parent.height
        radius: parent.radius
        color: accent
        Behavior on width { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
      }
    }

    Text {
      id: meterValue
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      width: 86
      horizontalAlignment: Text.AlignRight
      text: parent.valueText
      font.pixelSize: 11
      font.weight: Font.DemiBold
      color: PopoutConfig.textColor
      renderType: Text.NativeRendering
    }
  }
  
  implicitWidth: 380
  implicitHeight: 540
  
  color: PopoutConfig.backgroundColor
  radius: PopoutConfig.cornerRadius
  border.width: PopoutConfig.borderWidth
  border.color: PopoutConfig.borderColor
  
  Component.onCompleted: NetworksList.scan()
  
  ColumnLayout {
    id: content
    anchors.fill: parent
    anchors.margins: 16
    spacing: 8
    
    // Current connection is the visual focus of the popup.
    Rectangle {
      visible: Network.connected
      Layout.fillWidth: true
      Layout.preferredHeight: 160
      color: Qt.rgba(1, 1, 1, 0.045)
      radius: 10
      border.width: 1
      border.color: Qt.rgba(1, 1, 1, 0.07)

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 7

        RowLayout {
          Layout.fillWidth: true
          spacing: 8

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
              Layout.fillWidth: true
              text: root.isWired ? "Wired connection" : Network.ssid
              font.pixelSize: 14
              font.weight: Font.Bold
              color: PopoutConfig.textColor
              elide: Text.ElideRight
              renderType: Text.NativeRendering
            }

            Text {
              text: Network.internetAccess ? Network.iface + " · Internet" : Network.iface + " · No internet"
              font.pixelSize: 10
              color: Network.internetAccess ? PopoutConfig.textColor : Colors.foregroundRed
              opacity: Network.internetAccess ? 0.48 : 0.9
              renderType: Text.NativeRendering
            }
          }

          Rectangle {
            Layout.preferredWidth: bandText.implicitWidth + 16
            Layout.preferredHeight: 25
            radius: 7
            color: Qt.rgba(root.bandColor.r, root.bandColor.g, root.bandColor.b,
                           root.is24Ghz ? 0.22 : 0.13)
            border.width: root.is24Ghz ? 1 : 0
            border.color: root.bandColor

            Text {
              id: bandText
              anchors.centerIn: parent
              text: root.isWired ? "ETHERNET"
                    : (Network.frequencyMhz >= 5925 ? "6 GHz"
                       : (Network.frequencyMhz >= 4900 ? "5 GHz" : "2.4 GHz"))
              font.pixelSize: 10
              font.weight: Font.Bold
              color: root.bandColor
              renderType: Text.NativeRendering
            }
          }
        }

        ConnectionMeter {
          Layout.fillWidth: true
          icon: root.isWired ? "settings_ethernet" : "wifi"
          label: "Signal"
          valueText: root.isWired ? "Linked" : Network.signalPercent + "%"
          value: root.isWired ? 1 : Network.signalPercent / 100
          accent: Network.signalPercent < 35 ? Colors.foregroundRed
                  : (Network.signalPercent < 60 ? Colors.todoPriorityMedium : Colors.foregroundCyan)
        }

        ConnectionMeter {
          Layout.fillWidth: true
          icon: "south"
          label: "Down"
          valueText: root.formatRate(Network.downMbps) + " Mbps"
          value: Network.downPercent
          accent: Colors.foregroundCyan
        }

        ConnectionMeter {
          Layout.fillWidth: true
          icon: "north"
          label: "Up"
          valueText: root.formatRate(Network.upMbps) + " Mbps"
          value: Network.upPercent
          accent: Colors.primary
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: 6

          Item { Layout.fillWidth: true }

          Text {
            text: NetworksList.reconnecting ? "Reconnecting…" : "Reconnect"
            font.pixelSize: 10
            color: PopoutConfig.textColor
            opacity: reconnectMouse.containsMouse ? 1 : 0.55
            renderType: Text.NativeRendering

            MouseArea {
              id: reconnectMouse
              anchors.fill: parent
              anchors.margins: -5
              enabled: !NetworksList.reconnecting
              hoverEnabled: true
              cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
              onClicked: NetworksList.reconnect(Network.ssid)
            }
          }

          Text {
            text: "·"
            color: PopoutConfig.textColor
            opacity: 0.25
          }

          Text {
            text: "Disconnect"
            font.pixelSize: 10
            color: disconnectMouse.containsMouse ? Colors.foregroundRed : PopoutConfig.textColor
            opacity: disconnectMouse.containsMouse ? 1 : 0.55
            renderType: Text.NativeRendering

            MouseArea {
              id: disconnectMouse
              anchors.fill: parent
              anchors.margins: -5
              enabled: !NetworksList.reconnecting
              hoverEnabled: true
              cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
              onClicked: NetworksList.disconnect()
            }
          }
        }
      }
    }

    // Available networks list
    ListView {
      id: listView
      Layout.fillWidth: true
      Layout.fillHeight: true
      clip: true
      spacing: 4
      
      model: NetworksList.networks
      
      delegate: Rectangle {
        required property var modelData
        required property int index
        
        visible: !modelData.connected
        width: listView.width
        height: modelData.connected ? 0 : 44
        color: mouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.045) : "transparent"
        radius: 7

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 8
          anchors.rightMargin: 8
          spacing: 9
          
          // WiFi icon with signal strength
          Text {
            text: {
              if (modelData.signal >= 75) return "signal_wifi_4_bar"
              else if (modelData.signal >= 50) return "network_wifi_3_bar"
              else if (modelData.signal >= 25) return "network_wifi_2_bar"
              else return "network_wifi_1_bar"
            }
            font.family: "Material Symbols Outlined"
            font.pixelSize: 19
            color: modelData.connected ? PopoutConfig.successColor : PopoutConfig.textColor
            opacity: modelData.connected ? Colors.opacity.foreground1 : 0.6
          }
          
          ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            RowLayout {
              spacing: 8
              
              Text {
                text: modelData.ssid
                font.pixelSize: 12
                font.weight: modelData.connected ? Font.Bold : Font.Medium
                color: PopoutConfig.textColor
                Layout.fillWidth: true
                elide: Text.ElideRight
              }
              
              Text {
                visible: modelData.connected
                text: "check_circle"
                font.family: "Material Symbols Outlined"
                font.pixelSize: 16
                color: PopoutConfig.successColor
              }
            }
            
            RowLayout {
              spacing: 8
              
              Text {
                text: modelData.signal + "%"
                font.pixelSize: 9
                color: PopoutConfig.textColor
                opacity: 0.55
              }

              Text {
                text: modelData.security
                font.pixelSize: 9
                color: PopoutConfig.textColor
                opacity: 0.5
              }
            }
          }
          
          Text {
            visible: !modelData.connected
            text: "chevron_right"
            font.family: "Material Symbols Outlined"
            font.pixelSize: 16
            color: PopoutConfig.textColor
            opacity: mouseArea.containsMouse ? Colors.opacity.foreground1 : Colors.opacity.background0
          }
        }
        
        MouseArea {
          id: mouseArea
          anchors.fill: parent
          hoverEnabled: true
          enabled: !modelData.connected
          onClicked: {
            NetworksList.connect(modelData.ssid)
            // Note: In production, you'd show a password dialog here for protected networks
          }
        }
      }
    }

    Rectangle {
      Layout.fillWidth: true
      height: 1
      color: PopoutConfig.borderColor
      opacity: 0.3
    }

    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: 44
      color: Qt.rgba(1, 1, 1, 0.04)
      radius: 8
      border.width: 1
      border.color: Qt.rgba(1, 1, 1, 0.055)

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 8
        spacing: 8

        Text {
          text: ProtonVpn.busy ? "sync" : (ProtonVpn.active ? "shield_lock" : "shield")
          font.family: "Material Symbols Outlined"
          font.pixelSize: 16
          color: ProtonVpn.active ? Colors.success
                 : (ProtonVpn.busy ? Colors.todoPriorityMedium : PopoutConfig.textColor)
          opacity: ProtonVpn.active || ProtonVpn.busy ? 1 : 0.55

          RotationAnimation on rotation {
            running: ProtonVpn.busy
            loops: Animation.Infinite
            from: 0
            to: 360
            duration: 900
          }
        }

        Text {
          text: "VPN"
          font.pixelSize: 11
          font.weight: Font.DemiBold
          color: PopoutConfig.textColor
          opacity: 0.72
          renderType: Text.NativeRendering
        }

        Rectangle {
          Layout.preferredWidth: 5
          Layout.preferredHeight: 5
          radius: 3
          color: ProtonVpn.active ? Colors.success
                 : (ProtonVpn.busy ? Colors.todoPriorityMedium : PopoutConfig.textColor)
          opacity: ProtonVpn.active || ProtonVpn.busy ? 0.9 : 0.3
        }

        Text {
          Layout.fillWidth: true
          text: ProtonVpn.busy ? ProtonVpn.statusText
                : (ProtonVpn.active
                   ? "Connected · " + ProtonVpn.selectedLocationLabel
                   : "Off · " + ProtonVpn.selectedLocationLabel)
          font.pixelSize: 10
          color: ProtonVpn.active ? Colors.success : PopoutConfig.textColor
          opacity: ProtonVpn.active ? 0.85 : 0.5
          elide: Text.ElideRight
          renderType: Text.NativeRendering
        }

        Rectangle {
          Layout.preferredWidth: ProtonVpn.active ? 76 : 64
          Layout.preferredHeight: 26
          radius: 6
          color: vpnMouse.containsMouse
                 ? Qt.rgba(Colors.foregroundCyan.r, Colors.foregroundCyan.g,
                           Colors.foregroundCyan.b, 0.14)
                 : "transparent"
          border.width: 1
          border.color: ProtonVpn.active
                        ? Qt.rgba(Colors.success.r, Colors.success.g, Colors.success.b, 0.35)
                        : Qt.rgba(Colors.foregroundCyan.r, Colors.foregroundCyan.g,
                                  Colors.foregroundCyan.b, 0.28)

          Text {
            anchors.centerIn: parent
            text: ProtonVpn.busy ? "Working…" : (ProtonVpn.active ? "Disconnect" : "Connect")
            font.pixelSize: 10
            font.weight: Font.DemiBold
            color: ProtonVpn.active ? Colors.success : Colors.foregroundCyan
            opacity: ProtonVpn.busy ? 0.55 : 0.9
            renderType: Text.NativeRendering
          }

          MouseArea {
            id: vpnMouse
            anchors.fill: parent
            enabled: !ProtonVpn.busy
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: ProtonVpn.toggle()
          }
        }
      }
    }

    RowLayout {
      Layout.fillWidth: true
      Layout.preferredHeight: 27
      spacing: 5

      Repeater {
        model: [
          { label: "Fastest", locationIndex: 0 },
          { label: "AU", locationIndex: 1 },
          { label: "NZ", locationIndex: 2 },
          { label: "US", locationIndex: 3 }
        ]

        Rectangle {
          required property var modelData
          readonly property bool selected: ProtonVpn.selectedLocationIndex === modelData.locationIndex

          Layout.fillWidth: true
          Layout.preferredHeight: 27
          radius: 6
          color: selected
                 ? Qt.rgba(Colors.foregroundCyan.r, Colors.foregroundCyan.g,
                           Colors.foregroundCyan.b, 0.12)
                 : (quickLocationMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent")
          border.width: 1
          border.color: selected
                        ? Qt.rgba(Colors.foregroundCyan.r, Colors.foregroundCyan.g,
                                  Colors.foregroundCyan.b, 0.3)
                        : Qt.rgba(1, 1, 1, 0.07)

          Text {
            anchors.centerIn: parent
            text: modelData.label
            font.pixelSize: 10
            font.weight: selected ? Font.DemiBold : Font.Normal
            color: selected ? Colors.foregroundCyan : PopoutConfig.textColor
            opacity: selected ? 0.95 : 0.55
            renderType: Text.NativeRendering
          }

          MouseArea {
            id: quickLocationMouse
            anchors.fill: parent
            enabled: !ProtonVpn.busy
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: ProtonVpn.connectLocation(modelData.locationIndex)
          }
        }
      }
    }

    ColumnLayout {
      // Full location list intentionally hidden; quick locations stay compact.
      visible: false
      Layout.fillWidth: true
      spacing: 6

      Text {
        text: "VPN location"
        font.pixelSize: 11
        font.weight: Font.DemiBold
        color: PopoutConfig.textColor
        opacity: 0.72
      }

      Repeater {
        model: ProtonVpn.locations

        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 30
          radius: 7
          color: index === ProtonVpn.selectedLocationIndex
                 ? Qt.rgba(137 / 255, 180 / 255, 250 / 255, 0.18)
                 : Qt.rgba(1, 1, 1, 0.035)
          border.width: 1
          border.color: index === ProtonVpn.selectedLocationIndex
                        ? Qt.rgba(137 / 255, 180 / 255, 250 / 255, 0.45)
                        : Qt.rgba(1, 1, 1, 0.06)

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 8

            Text {
              text: index === ProtonVpn.selectedLocationIndex ? "radio_button_checked" : "radio_button_unchecked"
              font.family: "Material Symbols Outlined"
              font.pixelSize: 14
              color: index === ProtonVpn.selectedLocationIndex ? "#89b4fa" : PopoutConfig.textColor
              opacity: index === ProtonVpn.selectedLocationIndex ? 1 : 0.55
            }

            Text {
              Layout.fillWidth: true
              text: modelData.label
              font.pixelSize: 12
              color: PopoutConfig.textColor
              opacity: ProtonVpn.busy ? 0.55 : 0.88
            }

            Text {
              visible: ProtonVpn.active && index === ProtonVpn.selectedLocationIndex
              text: "Connected"
              font.pixelSize: 10
              color: PopoutConfig.successColor
              opacity: 0.85
            }
          }

          MouseArea {
            anchors.fill: parent
            enabled: !ProtonVpn.busy
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: ProtonVpn.connectLocation(index)
          }
        }
      }
    }

    Text {
      visible: ProtonVpn.error !== ""
      text: "VPN error: " + ProtonVpn.error
      font.pixelSize: 12
      color: PopoutConfig.errorColor
      wrapMode: Text.Wrap
      Layout.fillWidth: true
    }
    
    // Loading/error states
    Text {
      visible: NetworksList.scanning
      text: "Scanning for networks..."
      font.pixelSize: 13
      color: PopoutConfig.textColor
      opacity: 0.6
      Layout.alignment: Qt.AlignHCenter
    }
    
    Text {
      visible: NetworksList.error !== ""
      text: NetworksList.error
      font.pixelSize: 13
      color: PopoutConfig.errorColor
      Layout.alignment: Qt.AlignHCenter
    }
    
    Text {
      visible: !NetworksList.scanning && NetworksList.networks.length === 0 && NetworksList.error === ""
      text: "No networks found"
      font.pixelSize: 13
      color: PopoutConfig.textColor
      opacity: 0.6
      Layout.alignment: Qt.AlignHCenter
    }
  }
}
