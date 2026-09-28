import QtQuick
import QtQuick.Layouts
import QtMultimedia
import "../../../services"
import "../../../widgets"

// 3D Printer control menu - comprehensive status and controls
Rectangle {
  id: root

  property bool hasOwnBackground: true
  property var wrapper: null
  property var widget: null  // Reference to Printer3DIndicator for locked state
  property int selectedSlot: -1
  property bool cameraExpanded: false

  implicitWidth: cameraExpanded ? 1000 : 460
  implicitHeight: contentCol.implicitHeight + 28

  color: PopoutConfig.backgroundColor
  radius: PopoutConfig.cornerRadius
  border.width: PopoutConfig.borderWidth
  border.color: PopoutConfig.borderColor

  ColumnLayout {
    id: contentCol
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: 14
    spacing: 6

    // === OFFLINE STATE ===
    Item {
      visible: !Printer3D.connected
      Layout.fillWidth: true
      Layout.preferredHeight: 110

      Column {
        anchors.centerIn: parent
        spacing: 8

        Text {
          text: "print_disabled"
          font.family: "Material Symbols Outlined"
          font.pixelSize: 36
          color: Colors.outline
          anchors.horizontalCenter: parent.horizontalCenter
          opacity: 0.3
        }

        Text {
          text: "Printer Offline"
          color: Colors.primary
          font.pixelSize: 14
          font.weight: Font.DemiBold
          font.letterSpacing: 0.5
          anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
          text: "Check gateway at localhost:4387"
          color: Colors.outline
          font.pixelSize: 10
          font.letterSpacing: 0.2
          anchors.horizontalCenter: parent.horizontalCenter
          opacity: 0.7
        }
      }
    }

    // === CAMERA FEED ===
    Rectangle {
      visible: Printer3D.connected
      Layout.fillWidth: true
      Layout.preferredHeight: cameraExpanded ? 548 : 250
      radius: PopoutConfig.innerRadius
      color: Colors.bg1
      clip: true
      border.width: 1
      border.color: Qt.rgba(1, 1, 1, 0.08)

      Image {
        id: cameraImage
        anchors.fill: parent
        anchors.margins: 1
        visible: !liveStreamActive
        fillMode: Image.PreserveAspectFit
        smooth: true
        // Each frame has a unique cache-busting URL. Do not retain every frame in
        // Qt's image cache, and keep the last frame visible while the next loads.
        cache: false
        retainWhileLoading: true
        asynchronous: true

        property int consecutiveErrors: 0
        property bool hasFrame: false
        property bool liveStreamActive: false
        property bool showFallback: false

        onStatusChanged: {
          if (status === Image.Ready) {
            consecutiveErrors = 0
            hasFrame = true
            showFallback = false
            errorResetTimer.stop()
          } else if (status === Image.Error) {
            consecutiveErrors++
            if (consecutiveErrors >= 4) {
              hasFrame = false
              showFallback = true
            }
            errorResetTimer.restart()
          }
        }

        Timer {
          id: refreshTimer
          interval: 500
          repeat: true
          running: Printer3D.connected && !cameraImage.liveStreamActive
          onTriggered: {
            cameraImage.source = Printer3D.cameraUrl + "?t=" + Date.now()
          }
        }

        Timer {
          id: errorResetTimer
          interval: 5000
          repeat: false
          onTriggered: {
            cameraImage.consecutiveErrors = 0
            cameraImage.showFallback = false
          }
        }

        Component.onCompleted: {
          if (Printer3D.connected) {
            source = Printer3D.cameraUrl + "?t=" + Date.now()
          }
        }
      }

      MediaPlayer {
        id: cameraPlayer
        source: Printer3D.cameraStreamUrl
        videoOutput: cameraVideoOutput

        onPlaybackStateChanged: {
          cameraImage.liveStreamActive = playbackState === MediaPlayer.PlayingState
        }

        onErrorOccurred: function(error, errorString) {
          cameraImage.liveStreamActive = false
          console.log("Printer3D camera stream error:", errorString)
        }

        Component.onCompleted: {
          if (Printer3D.connected) play()
        }
      }

      VideoOutput {
        id: cameraVideoOutput
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectFit
        visible: cameraImage.liveStreamActive
      }

      Connections {
        target: Printer3D

        function onConnectedChanged() {
          if (Printer3D.connected) cameraPlayer.play()
          else cameraPlayer.stop()
        }
      }

      Column {
        visible: cameraImage.showFallback && !cameraImage.liveStreamActive
        anchors.centerIn: parent
        spacing: 8

        Text {
          text: "videocam_off"
          font.family: "Material Symbols Outlined"
          font.pixelSize: 40
          color: Colors.outline
          opacity: 0.25
          anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
          text: "No camera feed"
          color: Colors.outline
          font.pixelSize: 11
          font.letterSpacing: 0.3
          opacity: 0.6
          anchors.horizontalCenter: parent.horizontalCenter
        }
      }

      // Live badge
      Rectangle {
        visible: (cameraImage.hasFrame || cameraImage.liveStreamActive) && !cameraImage.showFallback
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 8
        width: liveBadgeRow.width + 16
        height: 20
        radius: 10
        color: Qt.rgba(0, 0, 0, 0.6)
        border.width: 1
        border.color: Qt.rgba(235/255, 111/255, 146/255, 0.25)

        Row {
          id: liveBadgeRow
          anchors.centerIn: parent
          spacing: 5

          Rectangle {
            width: 5; height: 5; radius: 2.5
            color: Colors.foregroundRed
            anchors.verticalCenter: parent.verticalCenter
            SequentialAnimation on opacity {
              loops: Animation.Infinite
              NumberAnimation { to: 0.3; duration: 900; easing.type: Easing.InOutSine }
              NumberAnimation { to: 1.0; duration: 900; easing.type: Easing.InOutSine }
            }
          }

          Text {
            id: labelText
            text: "LIVE"
            color: "#ffffff"
            font.pixelSize: 9
            font.weight: Font.Bold
            font.letterSpacing: 1.0
            anchors.verticalCenter: parent.verticalCenter
          }
        }
      }

      // Click the video to toggle the larger preview.
      Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 8
        width: 24
        height: 20
        radius: 5
        color: Qt.rgba(0, 0, 0, 0.6)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.12)

        Text {
          anchors.centerIn: parent
          text: root.cameraExpanded ? "fullscreen_exit" : "fullscreen"
          font.family: "Material Symbols Outlined"
          font.pixelSize: 14
          color: "#ffffff"
          opacity: 0.85
        }
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.cameraExpanded = !root.cameraExpanded
      }
    }

    // === PROGRESS BAR ===
    Rectangle {
      visible: Printer3D.connected
      Layout.fillWidth: true
      Layout.preferredHeight: 48
      radius: PopoutConfig.innerRadius
      color: Qt.rgba(1, 1, 1, 0.03)
      border.width: 1
      border.color: Qt.rgba(1, 1, 1, 0.07)

      // Progress fill track
      Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: parent.width * Math.max(0, Printer3D.percentage / 100.0)
        radius: parent.radius
        color: Printer3D.state === "PAUSED" ?
               Qt.rgba(235/255, 111/255, 146/255, 0.10) :
               Qt.rgba(0/255, 255/255, 255/255, 0.06)
        Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }

        // Leading edge glow
        Rectangle {
          visible: parent.width > 4
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.bottom: parent.bottom
          width: 2
          color: Printer3D.state === "PAUSED" ? Qt.rgba(235/255, 111/255, 146/255, 0.4) : Qt.rgba(0, 1, 1, 0.35)
          radius: 1
        }
      }

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 8

        Text {
          text: Printer3D.state === "PAUSED" ? "pause_circle" : "play_circle"
          font.family: "Material Symbols Outlined"
          font.pixelSize: 20
          color: Printer3D.state === "PAUSED" ? Colors.foregroundRed : Colors.foregroundCyan
          opacity: 0.9
        }

        Column {
          Layout.fillWidth: true
          spacing: 2

          Text {
            text: Printer3D.percentage + "%  ·  Layer " + Printer3D.layerCurrent + "/" + Printer3D.layerTotal
            color: Colors.primary
            font.pixelSize: 11
            font.weight: Font.DemiBold
            font.letterSpacing: 0.3
          }

          Text {
            text: _formatTime(Printer3D.remainingTimeMinutes) + " remaining"
            color: Colors.outline
            font.pixelSize: 9
            font.letterSpacing: 0.2
          }
        }

        Rectangle {
          implicitWidth: statusLabel.implicitWidth + 12
          implicitHeight: 16
          radius: 8
          color: Printer3D.state === "PAUSED" ? Qt.rgba(235/255, 111/255, 146/255, 0.15) : Qt.rgba(0, 1, 1, 0.10)

          Text {
            id: statusLabel
            anchors.centerIn: parent
            text: Printer3D.state === "PAUSED" ? "PAUSED" : (Printer3D.state === "RUNNING" ? "PRINTING" : Printer3D.state)
            color: Printer3D.state === "PAUSED" ? Colors.foregroundRed : Colors.foregroundCyan
            font.pixelSize: 8
            font.weight: Font.Bold
            font.letterSpacing: 0.8
          }
        }
      }
    }

    // === SPEED SELECTOR ===
    RowLayout {
      visible: Printer3D.connected
      Layout.fillWidth: true
      Layout.preferredHeight: 26
      spacing: 4
      opacity: (Printer3D.state === "RUNNING" || Printer3D.state === "PAUSED") ? 1.0 : 0.35

      Text {
        text: "speed"
        font.family: "Material Symbols Outlined"
        font.pixelSize: 14
        color: Colors.outline
        Layout.alignment: Qt.AlignVCenter
        opacity: 0.7
      }

      Text {
        text: ["Silent", "Standard", "Sport", "Ludicrous"][Printer3D.speedLevel]
        color: Colors.primary
        font.pixelSize: 10
        font.weight: Font.DemiBold
        font.letterSpacing: 0.2
        Layout.alignment: Qt.AlignVCenter
      }

      Item { Layout.fillWidth: true }

      Repeater {
        model: ["50%", "100%", "124%", "166%"]

        Rectangle {
          Layout.preferredWidth: 46
          Layout.preferredHeight: 22
          radius: 11
          color: index === Printer3D.speedLevel ? Qt.rgba(0, 1, 1, 0.12) : (speedBtnMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent")
          border.width: index === Printer3D.speedLevel ? 1 : 0
          border.color: Qt.rgba(0, 1, 1, 0.3)
          Behavior on color { ColorAnimation { duration: 150 } }

          Text {
            anchors.centerIn: parent
            text: modelData
            color: index === Printer3D.speedLevel ? Colors.foregroundCyan : Colors.primary
            font.pixelSize: 9
            font.weight: Font.DemiBold
            font.letterSpacing: 0.2
          }

          MouseArea {
            id: speedBtnMouse
            anchors.fill: parent
            enabled: Printer3D.state === "RUNNING" || Printer3D.state === "PAUSED"
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Printer3D.setSpeedLevel(index)
          }
        }
      }
    }

    // === TEMPERATURE SECTION ===
    RowLayout {
      visible: Printer3D.connected
      Layout.fillWidth: true
      spacing: 6

      // Nozzle Control
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: nozzleCol.implicitHeight + 16
        radius: 8
        color: Qt.rgba(1, 1, 1, 0.03)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.07)

        ColumnLayout {
          id: nozzleCol
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.margins: 8
          spacing: 4

          RowLayout {
            Layout.fillWidth: true
            spacing: 5

            Text {
              text: "thermostat"
              font.family: "Material Symbols Outlined"
              font.pixelSize: 14
              color: Colors.foregroundRed
              opacity: 0.75
            }

            Text {
              text: "Nozzle"
              color: Colors.primary
              font.pixelSize: 10
              font.weight: Font.DemiBold
              font.letterSpacing: 0.2
            }

            Item { Layout.fillWidth: true }

            Rectangle {
              Layout.preferredWidth: nozzleTempLabel.implicitWidth + 10
              Layout.preferredHeight: 18
              radius: 4
              color: nozzleResetMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.04)
              Behavior on color { ColorAnimation { duration: 150 } }

              Text {
                id: nozzleTempLabel
                anchors.centerIn: parent
                text: Math.round(Printer3D.nozzleTemp) + "°"
                color: Colors.primary
                font.pixelSize: 11
                font.weight: Font.DemiBold
              }

              MouseArea {
                id: nozzleResetMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Printer3D.setTemperature("nozzle", 0)
              }
            }
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
              text: "Target"
              color: Colors.outline
              font.pixelSize: 9
              font.letterSpacing: 0.2
              opacity: 0.7
              Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }

            Rectangle {
              Layout.preferredWidth: 24
              Layout.preferredHeight: 24
              radius: 12
              color: nozzleLessMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.04)
              Behavior on color { ColorAnimation { duration: 150 } }

              Text {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -2
                text: "−"
                font.pixelSize: 15
                font.weight: Font.DemiBold
                color: Colors.primary
                opacity: 0.9
              }

              MouseArea {
                id: nozzleLessMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  var current = Printer3D.nozzleTarget > 0 ? Printer3D.nozzleTarget : Printer3D.nozzleTemp
                  var newTemp = Math.max(0, Math.round(current) - 5)
                  Printer3D.setTemperature("nozzle", newTemp)
                }
              }
            }

            Text {
              text: Math.round(Printer3D.nozzleTarget) + "°"
              color: Colors.foregroundCyan
              font.pixelSize: 11
              font.weight: Font.DemiBold
              Layout.preferredWidth: 30
              horizontalAlignment: Text.AlignHCenter
            }

            Rectangle {
              Layout.preferredWidth: 24
              Layout.preferredHeight: 24
              radius: 12
              color: nozzleMoreMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.04)
              Behavior on color { ColorAnimation { duration: 150 } }

              Text {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -1
                text: "+"
                font.pixelSize: 14
                font.weight: Font.DemiBold
                color: Colors.primary
                opacity: 0.9
              }

              MouseArea {
                id: nozzleMoreMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  var current = Printer3D.nozzleTarget > 0 ? Printer3D.nozzleTarget : Printer3D.nozzleTemp
                  var newTemp = Math.min(300, Math.round(current) + 5)
                  Printer3D.setTemperature("nozzle", newTemp)
                }
              }
            }
          }

          Text {
            text: Printer3D.nozzleDiameter + (Printer3D.nozzleType ? " " + Printer3D.nozzleType : "")
            color: Colors.outline
            font.pixelSize: 9
            font.letterSpacing: 0.2
            Layout.fillWidth: true
            elide: Text.ElideRight
            opacity: 0.6
          }
        }
      }

      // Bed Control
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: nozzleCol.implicitHeight + 16
        radius: 8
        color: Qt.rgba(1, 1, 1, 0.03)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.07)

        ColumnLayout {
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.margins: 8
          spacing: 4

          RowLayout {
            Layout.fillWidth: true
            spacing: 5

            Text {
              text: "heat"
              font.family: "Material Symbols Outlined"
              font.pixelSize: 14
              color: "#ebbcba"
              opacity: 0.75
            }

            Text {
              text: "Bed"
              color: Colors.primary
              font.pixelSize: 10
              font.weight: Font.DemiBold
              font.letterSpacing: 0.2
            }

            Item { Layout.fillWidth: true }

            Rectangle {
              Layout.preferredWidth: bedTempLabel.implicitWidth + 10
              Layout.preferredHeight: 18
              radius: 4
              color: bedResetMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.04)
              Behavior on color { ColorAnimation { duration: 150 } }

              Text {
                id: bedTempLabel
                anchors.centerIn: parent
                text: Math.round(Printer3D.bedTemp) + "°"
                color: Colors.primary
                font.pixelSize: 11
                font.weight: Font.DemiBold
              }

              MouseArea {
                id: bedResetMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Printer3D.setTemperature("bed", 0)
              }
            }
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
              text: "Target"
              color: Colors.outline
              font.pixelSize: 9
              font.letterSpacing: 0.2
              opacity: 0.7
              Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }

            Rectangle {
              Layout.preferredWidth: 24
              Layout.preferredHeight: 24
              radius: 12
              color: bedLessMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.04)
              Behavior on color { ColorAnimation { duration: 150 } }

              Text {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -2
                text: "−"
                font.pixelSize: 15
                font.weight: Font.DemiBold
                color: Colors.primary
                opacity: 0.9
              }

              MouseArea {
                id: bedLessMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  var current = Printer3D.bedTarget > 0 ? Printer3D.bedTarget : Printer3D.bedTemp
                  var newTemp = Math.max(0, Math.round(current) - 5)
                  Printer3D.setTemperature("bed", newTemp)
                }
              }
            }

            Text {
              text: Math.round(Printer3D.bedTarget) + "°"
              color: Colors.foregroundCyan
              font.pixelSize: 11
              font.weight: Font.DemiBold
              Layout.preferredWidth: 30
              horizontalAlignment: Text.AlignHCenter
            }

            Rectangle {
              Layout.preferredWidth: 24
              Layout.preferredHeight: 24
              radius: 12
              color: bedMoreMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.04)
              Behavior on color { ColorAnimation { duration: 150 } }

              Text {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -1
                text: "+"
                font.pixelSize: 14
                font.weight: Font.DemiBold
                color: Colors.primary
                opacity: 0.9
              }

              MouseArea {
                id: bedMoreMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  var current = Printer3D.bedTarget > 0 ? Printer3D.bedTarget : Printer3D.bedTemp
                  var newTemp = Math.min(120, Math.round(current) + 5)
                  Printer3D.setTemperature("bed", newTemp)
                }
              }
            }
          }
        }
      }

      // Chamber Info (Read only)
      Rectangle {
        Layout.preferredWidth: 80
        Layout.preferredHeight: nozzleCol.implicitHeight + 16
        radius: 8
        color: Qt.rgba(1, 1, 1, 0.03)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.07)

        Column {
          anchors.centerIn: parent
          spacing: 3

          Text {
            text: "domain"
            font.family: "Material Symbols Outlined"
            font.pixelSize: 16
            color: Colors.outline
            anchors.horizontalCenter: parent.horizontalCenter
            opacity: 0.7
          }

          Text {
            text: Math.round(Printer3D.chamberTemp) + "°"
            color: Colors.primary
            font.pixelSize: 14
            font.weight: Font.DemiBold
            anchors.horizontalCenter: parent.horizontalCenter
          }

          Text {
            text: "Chamber"
            color: Colors.outline
            font.pixelSize: 9
            font.letterSpacing: 0.3
            anchors.horizontalCenter: parent.horizontalCenter
            opacity: 0.6
          }
        }
      }
    }

    // === FAN CONTROL ===
    Rectangle {
      visible: Printer3D.connected
      Layout.fillWidth: true
      Layout.preferredHeight: fanCol.implicitHeight + 14
      radius: 8
      color: Qt.rgba(1, 1, 1, 0.03)
      border.width: 1
      border.color: Qt.rgba(1, 1, 1, 0.07)

      ColumnLayout {
        id: fanCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 8
        spacing: 5

        RowLayout {
          spacing: 5
          Text {
            text: "mode_fan"
            font.family: "Material Symbols Outlined"
            font.pixelSize: 14
            color: Colors.outline
            opacity: 0.7
          }
          Text {
            text: "Fans"
            color: Colors.primary
            font.pixelSize: 10
            font.weight: Font.DemiBold
            font.letterSpacing: 0.3
          }
        }

        Repeater {
          model: [
            { label: "Part", value: Printer3D.partFanSpeed },
            { label: "Aux", value: Printer3D.auxFanSpeed },
            { label: "Chamber", value: Printer3D.chamberFanSpeed }
          ]

          RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
              text: modelData.label
              color: Colors.outline
              font.pixelSize: 9
              font.letterSpacing: 0.2
              Layout.preferredWidth: 50
              opacity: 0.8
            }

            Rectangle {
              Layout.fillWidth: true
              Layout.preferredHeight: 4
              radius: 2
              color: Qt.rgba(1, 1, 1, 0.06)

              Rectangle {
                width: Math.max(0, (modelData.value / 100) * parent.width)
                height: parent.height
                radius: 2
                color: Qt.rgba(0, 1, 1, 0.4 + 0.4 * (modelData.value / 100))
                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
              }
            }

            Text {
              text: modelData.value + "%"
              color: Colors.primary
              font.pixelSize: 9
              font.weight: Font.DemiBold
              Layout.preferredWidth: 28
              horizontalAlignment: Text.AlignRight
              opacity: 0.9
            }
          }
        }
      }
    }

    // === AMS FILAMENT STATUS ===
    ColumnLayout {
      visible: Printer3D.connected
      Layout.fillWidth: true
      spacing: 6

      RowLayout {
        Layout.fillWidth: true
        spacing: 6

        Text { text: "colors"; font.family: "Material Symbols Outlined"; font.pixelSize: 16; color: Colors.outline }
        Text { text: "Filament"; color: Colors.primary; font.pixelSize: 11; font.weight: Font.DemiBold }

        Item { Layout.fillWidth: true }

        Rectangle {
          visible: root.selectedSlot !== -1
          Layout.preferredWidth: 50
          Layout.preferredHeight: 22
          radius: 11
          color: loadMouse.containsMouse ? Qt.rgba(0, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.06)
          border.width: 1
          border.color: Qt.rgba(0, 1, 1, 0.3)
          Behavior on color { ColorAnimation { duration: 150 } }

          Text {
            anchors.centerIn: parent
            text: "Load"
            color: Colors.foregroundCyan
            font.pixelSize: 10
            font.weight: Font.DemiBold
          }

          MouseArea {
            id: loadMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            enabled: Printer3D.state !== "RUNNING"
            onClicked: {
              if (root.selectedSlot >= 0 && root.selectedSlot <= 3) {
                Printer3D.loadFilament(root.selectedSlot)
              } else {
                // Handle external spool load or generic load
                Printer3D.loadFilament(254) 
              }
              root.selectedSlot = -1
            }
          }
        }

        Rectangle {
          visible: root.selectedSlot !== -1
          Layout.preferredWidth: 58
          Layout.preferredHeight: 22
          radius: 11
          color: unloadMouse.containsMouse ? Qt.rgba(235/255, 111/255, 146/255, 0.15) : Qt.rgba(1, 1, 1, 0.06)
          border.width: 1
          border.color: Qt.rgba(235/255, 111/255, 146/255, 0.3)
          Behavior on color { ColorAnimation { duration: 150 } }

          Text {
            anchors.centerIn: parent
            text: "Unload"
            color: Colors.foregroundRed
            font.pixelSize: 10
            font.weight: Font.DemiBold
          }

          MouseArea {
            id: unloadMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            enabled: Printer3D.state !== "RUNNING"
            onClicked: {
              Printer3D.unloadFilament()
              root.selectedSlot = -1
            }
          }
        }
      }

      // AMS Slots + External Spool Horizontal Layout
      RowLayout {
        Layout.fillWidth: true
        spacing: 6

        // 4 AMS Slots
        Repeater {
          model: 4

          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            radius: 8

            property var slot: Printer3D.amsSlots[index]
            property string trayColor: (slot && slot.color) ? "#" + slot.color.substring(0, 6) : "transparent"
            property bool hasFilament: !!(slot && slot.material)
            property bool isActive: index === Printer3D.activeSpool
            property bool isSelected: root.selectedSlot === index

            color: hasFilament ? Qt.darker(trayColor, 1.3) : Qt.rgba(1, 1, 1, 0.04)
            border.width: isSelected ? 2 : (isActive ? 2 : 1)
            border.color: isSelected ? "#ffffff" : (isActive ? Colors.foregroundCyan : (hasFilament ? Qt.lighter(trayColor, 1.4) : Qt.rgba(1, 1, 1, 0.08)))
            Behavior on border.color { ColorAnimation { duration: 200 } }

            // Color swatch strip
            Rectangle {
              visible: parent.hasFilament
              anchors.top: parent.top
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.topMargin: 1
              anchors.leftMargin: 1
              anchors.rightMargin: 1
              height: 4
              radius: 2
              color: parent.trayColor
            }

            Text {
              anchors.centerIn: parent
              anchors.verticalCenterOffset: parent.hasFilament ? 2 : 0
              text: parent.hasFilament ? parent.slot.material : "\u2014"
              color: parent.hasFilament ? _getContrastColor(Qt.darker(parent.trayColor, 1.3).toString()) : Colors.outline
              font.pixelSize: 9
              font.weight: Font.Bold
              wrapMode: Text.Wrap
              horizontalAlignment: Text.AlignHCenter
              width: parent.width - 6
            }

            // Active glow dot
            Rectangle {
              visible: parent.isActive
              width: 6
              height: 6
              radius: 3
              color: Colors.foregroundCyan
              anchors.right: parent.right
              anchors.top: parent.top
              anchors.margins: 4

              SequentialAnimation on opacity {
                loops: Animation.Infinite
                running: parent.visible
                NumberAnimation { to: 0.4; duration: 1000; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0; duration: 1000; easing.type: Easing.InOutSine }
              }
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                root.selectedSlot = (root.selectedSlot === index) ? -1 : index
              }
            }
          }
        }

        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 44
          radius: 8

          property var spool: Printer3D.externalSpool
          property string trayColor: (spool && spool.color) ? "#" + spool.color.substring(0, 6) : "transparent"
          property bool hasFilament: !!(spool && spool.material)
          property bool isSelected: root.selectedSlot === 254

          color: hasFilament ? Qt.darker(trayColor, 1.3) : Qt.rgba(1, 1, 1, 0.04)
          border.width: isSelected ? 2 : 1
          border.color: isSelected ? "#ffffff" : (hasFilament ? Qt.lighter(trayColor, 1.4) : Qt.rgba(1, 1, 1, 0.08))
          Behavior on border.color { ColorAnimation { duration: 200 } }

          Rectangle {
            visible: parent.hasFilament
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 1
            anchors.leftMargin: 1
            anchors.rightMargin: 1
            height: 4
            radius: 2
            color: parent.trayColor
          }

          Column {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: parent.hasFilament ? 2 : 0
            spacing: 1

            Text {
              text: parent.parent.hasFilament ? (parent.parent.spool.material || "Ext") : "Ext"
              color: parent.parent.hasFilament ? _getContrastColor(Qt.darker(parent.parent.trayColor, 1.3).toString()) : Colors.outline
              font.pixelSize: 9
              font.weight: Font.Bold
              horizontalAlignment: Text.AlignHCenter
              anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
              visible: parent.parent.hasFilament
              text: "EXT"
              color: _getContrastColor(Qt.darker(parent.parent.trayColor, 1.3).toString())
              font.pixelSize: 7
              font.letterSpacing: 0.5
              anchors.horizontalCenter: parent.horizontalCenter
              opacity: 0.6
            }
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              root.selectedSlot = (root.selectedSlot === 254) ? -1 : 254
            }
          }
        }
      }
    }

    // === PRIMARY CONTROLS ===
    RowLayout {
      visible: Printer3D.connected
      Layout.fillWidth: true
      Layout.preferredHeight: 42
      spacing: 6

      Item { Layout.fillWidth: true }

      // Pause
      Rectangle {
        Layout.preferredWidth: 40
        Layout.preferredHeight: 36
        radius: 10
        property bool isActive: Printer3D.state === "RUNNING"
        opacity: isActive ? 1.0 : 0.35
        color: pauseMouse.containsMouse && isActive ? Qt.rgba(100/255, 149/255, 237/255, 0.25) : Qt.rgba(1, 1, 1, 0.04)
        border.width: 1
        border.color: Qt.rgba(100/255, 149/255, 237/255, isActive ? 0.5 : 0.2)
        Behavior on color { ColorAnimation { duration: 150 } }

        Text {
          anchors.centerIn: parent
          text: "pause"
          font.family: "Material Symbols Outlined"
          font.pixelSize: 18
          color: "#6495ed"
        }

        MouseArea {
          id: pauseMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          enabled: parent.isActive
          onClicked: Printer3D.pause()
        }
      }

      // Resume
      Rectangle {
        Layout.preferredWidth: 40
        Layout.preferredHeight: 36
        radius: 10
        property bool isActive: Printer3D.state === "PAUSED"
        opacity: isActive ? 1.0 : 0.35
        color: resumeMouse.containsMouse && isActive ? Qt.rgba(100/255, 149/255, 237/255, 0.25) : Qt.rgba(1, 1, 1, 0.04)
        border.width: 1
        border.color: Qt.rgba(100/255, 149/255, 237/255, isActive ? 0.5 : 0.2)
        Behavior on color { ColorAnimation { duration: 150 } }

        Text {
          anchors.centerIn: parent
          text: "play_arrow"
          font.family: "Material Symbols Outlined"
          font.pixelSize: 18
          color: "#6495ed"
        }

        MouseArea {
          id: resumeMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          enabled: parent.isActive
          onClicked: Printer3D.resume()
        }
      }

      // Stop
      Rectangle {
        Layout.preferredWidth: 40
        Layout.preferredHeight: 36
        radius: 10
        property bool isActive: Printer3D.state === "RUNNING" || Printer3D.state === "PAUSED"
        opacity: isActive ? 1.0 : 0.35
        color: stopMouse.containsMouse && isActive ? Qt.rgba(235/255, 111/255, 146/255, 0.25) : Qt.rgba(1, 1, 1, 0.04)
        border.width: 1
        border.color: Qt.rgba(235/255, 111/255, 146/255, isActive ? 0.5 : 0.2)
        Behavior on color { ColorAnimation { duration: 150 } }

        Text {
          anchors.centerIn: parent
          text: "stop"
          font.family: "Material Symbols Outlined"
          font.pixelSize: 18
          color: Colors.foregroundRed
        }

        MouseArea {
          id: stopMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          enabled: parent.isActive
          onClicked: Printer3D.stop()
        }
      }

      // Separator
      Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 20; color: Qt.rgba(1, 1, 1, 0.08) }

      // Light
      Rectangle {
        Layout.preferredWidth: 40
        Layout.preferredHeight: 36
        radius: 10
        color: lightMouse.containsMouse ? Qt.rgba(0, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.04)
        border.width: 1
        border.color: Qt.rgba(0, 1, 1, 0.3)
        Behavior on color { ColorAnimation { duration: 150 } }

        Text {
          anchors.centerIn: parent
          text: Printer3D.lightState === "on" ? "lightbulb" : "light_mode"
          font.family: "Material Symbols Outlined"
          font.pixelSize: 18
          color: Colors.foregroundCyan
        }

        MouseArea {
          id: lightMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: Printer3D.toggleLight()
        }
      }

      // Home
      Rectangle {
        Layout.preferredWidth: 40
        Layout.preferredHeight: 36
        radius: 10
        color: homeMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.04)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.1)
        Behavior on color { ColorAnimation { duration: 150 } }

        Text {
          anchors.centerIn: parent
          text: "home"
          font.family: "Material Symbols Outlined"
          font.pixelSize: 18
          color: Colors.outline
        }

        MouseArea {
          id: homeMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: Printer3D.homeAxes()
        }
      }

      // Calibrate
      Rectangle {
        Layout.preferredWidth: 40
        Layout.preferredHeight: 36
        radius: 10
        property bool isActive: Printer3D.state !== "RUNNING"
        opacity: isActive ? 1.0 : 0.35
        color: calibrateMouse.containsMouse && isActive ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.04)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.1)
        Behavior on color { ColorAnimation { duration: 150 } }

        Text {
          anchors.centerIn: parent
          text: "tune"
          font.family: "Material Symbols Outlined"
          font.pixelSize: 18
          color: Colors.primary
        }

        MouseArea {
          id: calibrateMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          enabled: parent.isActive
          onClicked: Printer3D.calibratePrinter(true, true, true)
        }
      }

      Item { Layout.fillWidth: true }
    }

    // === FILE INFORMATION ===
    Rectangle {
      visible: Printer3D.connected
      Layout.fillWidth: true
      Layout.preferredHeight: 42
      radius: 8
      color: Qt.rgba(1, 1, 1, 0.04)
      border.width: 1
      border.color: Qt.rgba(1, 1, 1, 0.06)

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 8

        Text {
          text: "description"
          font.family: "Material Symbols Outlined"
          font.pixelSize: 14
          color: Colors.outline
        }

        Column {
          Layout.fillWidth: true
          spacing: 2

          Text {
            text: Printer3D.fileName || "(no file)"
            color: Colors.primary
            font.pixelSize: 10
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            width: parent.width
          }

          Row {
            spacing: 10

            Text {
              text: "wifi"
              font.family: "Material Symbols Outlined"
              font.pixelSize: 10
              color: Colors.outline
            }
            Text {
              text: Printer3D.wifiSignal
              color: Colors.outline
              font.pixelSize: 9
            }

            Text {
              text: Printer3D.printType
              color: Colors.outline
              font.pixelSize: 9
            }

            Text {
              text: Printer3D.errorCode === 0 ? "OK" : "Err " + Printer3D.errorCode
              color: Printer3D.errorCode === 0 ? Colors.success : Colors.foregroundRed
              font.pixelSize: 9
              font.weight: Font.DemiBold
            }
          }
        }

        Rectangle {
          visible: Printer3D.fileName.length > 0
          Layout.preferredWidth: 28
          Layout.preferredHeight: 28
          radius: 8
          color: deleteMouse.containsMouse ? Qt.rgba(235/255, 111/255, 146/255, 0.2) : Qt.rgba(1, 1, 1, 0.04)
          Behavior on color { ColorAnimation { duration: 150 } }

          Text {
            anchors.centerIn: parent
            text: "delete"
            font.family: "Material Symbols Outlined"
            font.pixelSize: 16
            color: Colors.foregroundRed
          }

          MouseArea {
            id: deleteMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            enabled: Printer3D.state !== "RUNNING"
            onClicked: Printer3D.deleteFile(Printer3D.fileName)
          }
        }
      }
    }
  }

  function _getContrastColor(hex) {
    if (!hex || hex === "transparent") return "#ffffff"
    // Remove #
    hex = hex.replace("#", "")
    if (hex.length === 6) {
      var r = parseInt(hex.substr(0, 2), 16)
      var g = parseInt(hex.substr(2, 2), 16)
      var b = parseInt(hex.substr(4, 2), 16)
      var yiq = ((r * 299) + (g * 587) + (b * 114)) / 1000
      return (yiq >= 128) ? "#000000" : "#ffffff"
    }
    return "#ffffff"
  }

  function _formatTime(minutes) {
    if (minutes <= 0) return "0m"
    var hours = Math.floor(minutes / 60)
    var mins = minutes % 60
    if (hours > 0) {
      return hours + "h " + mins + "m"
    }
    return mins + "m"
  }

  MouseArea {
    anchors.fill: parent
    propagateComposedEvents: true
    onClicked: {
      // Don't consume clicks, let them propagate
      mouse.accepted = false
    }
  }
}
