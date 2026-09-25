import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import "../../../services"
import "./"

// Weather tooltip: current conditions + 7-day forecast
// Redesigned with better visual hierarchy and modern styling
ClippingRectangle {
  id: root
  required property Item wrapper
  property bool expanded: wrapper && wrapper.hasCurrent && wrapper.currentName === "tooltip-weather"
  property bool hasOwnBackground: true

  readonly property int hPadding: 16
  readonly property int vPadding: 14
  readonly property int maxContentWidth: 340

  implicitWidth: expanded ? (Math.min(mainColumn.implicitWidth + hPadding * 2, maxContentWidth + hPadding * 2)) : 0
  implicitHeight: expanded ? (mainColumn.implicitHeight + vPadding * 2) : 0

  y: 0
  
  // Force crisp rendering
  layer.enabled: true
  layer.smooth: false

  Behavior on implicitHeight { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
  Behavior on opacity { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

  color: PopoutConfig.backgroundColor
  border.width: PopoutConfig.borderWidth
  border.color: PopoutConfig.borderColor
  radius: PopoutConfig.cornerRadius
  contentInsideBorder: false

  // Helper function to get temperature color
  function getTempColor(temp) {
    if (temp === undefined || temp === null) return PopoutConfig.textColor
    if (temp <= 5) return "#89b4fa"  // Cold blue
    if (temp <= 15) return "#94e2d5" // Cool teal
    if (temp <= 25) return "#f9e2af" // Warm yellow
    if (temp <= 35) return "#fab387" // Hot orange
    return "#f38ba8"                  // Very hot red
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onExited: if (root.wrapper) root.wrapper.scheduleClose()
  }

  Column {
    id: mainColumn
    spacing: 12
    anchors.top: parent.top
    anchors.topMargin: root.vPadding
    anchors.horizontalCenter: parent.horizontalCenter
    width: root.maxContentWidth
    opacity: expanded ? Colors.opacity.foreground1 : 0
    Behavior on opacity { NumberAnimation { duration: 120 } }

    // Hero section: Current conditions with gradient background
    Rectangle {
      width: parent.width
      height: heroContent.height + 20
      radius: 12
      color: Qt.rgba(1, 1, 1, 0.03)
      border.width: 1
      border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.15)

      // Subtle gradient overlay
      Rectangle {
        anchors.fill: parent
        radius: 12
        gradient: Gradient {
          orientation: Gradient.Horizontal
          GradientStop { position: 0.0; color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.08) }
          GradientStop { position: 1.0; color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.02) }
        }
      }

      Row {
        id: heroContent
        spacing: 16
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.top: parent.top
        anchors.topMargin: 12

        // Large weather icon
        Rectangle {
          width: 72
          height: 72
          radius: 16
          color: Qt.rgba(1, 1, 1, 0.04)
          anchors.verticalCenter: parent.verticalCenter

          Text {
            anchors.centerIn: parent
            text: Weather.getWeatherIcon(Weather.weatherCode)
            font.pixelSize: 48
            renderType: Text.NativeRendering
          }
        }

        // Temperature and details
        Column {
          spacing: 4
          anchors.verticalCenter: parent.verticalCenter

          Row {
            spacing: 4
            Text {
              text: Weather.available ? Weather.temperature : "--"
              font.pixelSize: 42
              font.weight: Font.Bold
              color: root.getTempColor(Weather.temperature)
              renderType: Text.NativeRendering
            }
            Text {
              text: "°C"
              font.pixelSize: 22
              font.weight: Font.Light
              color: PopoutConfig.textColor
              opacity: 0.7
              anchors.bottom: parent.bottom
              anchors.bottomMargin: 8
              renderType: Text.NativeRendering
            }
          }

          Text {
            text: Weather.getWeatherCondition(Weather.weatherCode)
            font.pixelSize: 14
            font.weight: Font.Medium
            color: Colors.primary
            renderType: Text.NativeRendering
          }

          Row {
            spacing: 8
            Text {
              text: "Feels like"
              font.pixelSize: 11
              color: PopoutConfig.textColor
              opacity: 0.6
              renderType: Text.NativeRendering
            }
            Text {
              text: Weather.available ? Weather.feelsLike + "°" : "--°"
              font.pixelSize: 12
              font.weight: Font.Medium
              color: root.getTempColor(Weather.feelsLike)
              renderType: Text.NativeRendering
            }
          }
        }
      }

      // Location badge
      Rectangle {
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.top: parent.top
        anchors.topMargin: 12
        width: locationText.width + 16
        height: locationText.height + 8
        radius: 8
        color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.1)

        Text {
          id: locationText
          anchors.centerIn: parent
          text: Weather.available ? Weather.city : "Loading..."
          font.pixelSize: 10
          font.weight: Font.Medium
          color: Colors.primary
          renderType: Text.NativeRendering
        }
      }
    }

    // Current conditions grid - 2x4 layout
    Grid {
      spacing: 10
      columns: 4
      width: parent.width
      horizontalItemAlignment: Grid.AlignHCenter

      // Humidity
      Column {
        spacing: 4
        width: (parent.width - parent.spacing * 3) / 4

        Text {
          text: "💧"
          font.pixelSize: 18
          anchors.horizontalCenter: parent.horizontalCenter
          renderType: Text.NativeRendering
        }

        Text {
          text: Weather.available ? Weather.humidity + "%" : "--"
          font.pixelSize: 14
          font.weight: Font.DemiBold
          color: PopoutConfig.textColor
          anchors.horizontalCenter: parent.horizontalCenter
          renderType: Text.NativeRendering
        }

        Text {
          text: "Humidity"
          font.pixelSize: 9
          color: PopoutConfig.textColor
          opacity: 0.5
          anchors.horizontalCenter: parent.horizontalCenter
          renderType: Text.NativeRendering
        }
      }

      // Wind
      Column {
        spacing: 4
        width: (parent.width - parent.spacing * 3) / 4

        Text {
          text: "🌬️"
          font.pixelSize: 18
          anchors.horizontalCenter: parent.horizontalCenter
          renderType: Text.NativeRendering
        }

        Text {
          text: Weather.available ? Weather.wind.split(" ")[0] : "--"
          font.pixelSize: 14
          font.weight: Font.DemiBold
          color: PopoutConfig.textColor
          anchors.horizontalCenter: parent.horizontalCenter
          renderType: Text.NativeRendering
        }

        Text {
          text: "Wind"
          font.pixelSize: 9
          color: PopoutConfig.textColor
          opacity: 0.5
          anchors.horizontalCenter: parent.horizontalCenter
          renderType: Text.NativeRendering
        }
      }

      // Pressure
      Column {
        spacing: 4
        width: (parent.width - parent.spacing * 3) / 4

        Text {
          text: "📊"
          font.pixelSize: 18
          anchors.horizontalCenter: parent.horizontalCenter
          renderType: Text.NativeRendering
        }

        Text {
          text: Weather.available ? Weather.pressure : "--"
          font.pixelSize: 14
          font.weight: Font.DemiBold
          color: PopoutConfig.textColor
          anchors.horizontalCenter: parent.horizontalCenter
          renderType: Text.NativeRendering
        }

        Text {
          text: "hPa"
          font.pixelSize: 9
          color: PopoutConfig.textColor
          opacity: 0.5
          anchors.horizontalCenter: parent.horizontalCenter
          renderType: Text.NativeRendering
        }
      }

      // Rain chance
      Column {
        spacing: 4
        width: (parent.width - parent.spacing * 3) / 4

        Text {
          text: "🌧️"
          font.pixelSize: 18
          anchors.horizontalCenter: parent.horizontalCenter
          renderType: Text.NativeRendering
        }

        Text {
          text: Weather.available ? Weather.precipitationProbability + "%" : "--"
          font.pixelSize: 14
          font.weight: Font.DemiBold
          color: Weather.precipitationProbability > 50 ? "#89b4fa" : PopoutConfig.textColor
          anchors.horizontalCenter: parent.horizontalCenter
          renderType: Text.NativeRendering
        }

        Text {
          text: "Rain"
          font.pixelSize: 9
          color: PopoutConfig.textColor
          opacity: 0.5
          anchors.horizontalCenter: parent.horizontalCenter
          renderType: Text.NativeRendering
        }
      }
    }

    // Sun times row
    Row {
      spacing: parent.width / 3
      width: parent.width

      Row {
        spacing: 6
        Text {
          text: "🌅"
          font.pixelSize: 16
          anchors.verticalCenter: parent.verticalCenter
          renderType: Text.NativeRendering
        }
        Column {
          Text {
            text: Weather.sunrise
            font.pixelSize: 13
            font.weight: Font.Medium
            color: "#f9e2af"
            renderType: Text.NativeRendering
          }
          Text {
            text: "Sunrise"
            font.pixelSize: 9
            color: PopoutConfig.textColor
            opacity: 0.5
            renderType: Text.NativeRendering
          }
        }
      }

      Row {
        spacing: 6
        Text {
          text: "🌇"
          font.pixelSize: 16
          anchors.verticalCenter: parent.verticalCenter
          renderType: Text.NativeRendering
        }
        Column {
          Text {
            text: Weather.sunset
            font.pixelSize: 13
            font.weight: Font.Medium
            color: "#fab387"
            renderType: Text.NativeRendering
          }
          Text {
            text: "Sunset"
            font.pixelSize: 9
            color: PopoutConfig.textColor
            opacity: 0.5
            renderType: Text.NativeRendering
          }
        }
      }
    }

    // Divider
    Rectangle {
      width: parent.width
      height: 1
      color: PopoutConfig.borderColor
      opacity: 0.3
    }

    // 7-day forecast header
    Row {
      width: parent.width
      spacing: 8

      Text {
        text: "📅"
        font.pixelSize: 14
        anchors.verticalCenter: parent.verticalCenter
        renderType: Text.NativeRendering
      }

      Text {
        text: "7-Day Forecast"
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: PopoutConfig.textColor
        anchors.verticalCenter: parent.verticalCenter
        renderType: Text.NativeRendering
      }
    }

    // Forecast list with temperature bars
    Column {
      spacing: 6
      width: parent.width

      Repeater {
        model: Math.min(Weather.forecast.length, 7)

        delegate: Item {
          width: parent.width
          height: 28
          property var day: Weather.forecast[index]

          Row {
            spacing: 10
            anchors.fill: parent
            anchors.leftMargin: 4
            anchors.rightMargin: 4

            // Day name
            Text {
              text: day && day.day ? day.day : "--"
              font.pixelSize: 12
              font.weight: index === 0 ? Font.DemiBold : Font.Normal
              color: index === 0 ? Colors.primary : PopoutConfig.textColor
              width: 42
              anchors.verticalCenter: parent.verticalCenter
              renderType: Text.NativeRendering
            }

            // Weather icon
            Text {
              text: day && day.wCode !== undefined ? Weather.getWeatherIcon(day.wCode) : "?"
              font.pixelSize: 18
              anchors.verticalCenter: parent.verticalCenter
              renderType: Text.NativeRendering
            }

            // Temperature bar container
            Item {
              width: 120
              height: parent.height
              anchors.verticalCenter: parent.verticalCenter

              // Background bar
              Rectangle {
                anchors.centerIn: parent
                width: parent.width
                height: 8
                radius: 4
                color: Qt.rgba(1, 1, 1, 0.05)
              }

              // Temperature range bar
              Rectangle {
                id: tempBar
                property real minTemp: day ? day.tempMin : 0
                property real maxTemp: day ? day.tempMax : 0
                property real allMin: -5  // Scale minimum
                property real allMax: 45  // Scale maximum
                property real range: allMax - allMin

                anchors.verticalCenter: parent.verticalCenter
                x: parent.width * ((minTemp - allMin) / range)
                width: Math.max(16, parent.width * ((maxTemp - minTemp) / range))
                height: 8
                radius: 4

                gradient: Gradient {
                  orientation: Gradient.Horizontal
                  GradientStop { position: 0.0; color: root.getTempColor(tempBar.minTemp) }
                  GradientStop { position: 1.0; color: root.getTempColor(tempBar.maxTemp) }
                }
              }
            }

            // Min/Max temps
            Text {
              text: day && day.tempMin !== undefined ? day.tempMin + "°" : "--°"
              font.pixelSize: 11
              color: PopoutConfig.textColor
              opacity: 0.6
              anchors.verticalCenter: parent.verticalCenter
              renderType: Text.NativeRendering
            }

            Text {
              text: day && day.tempMax !== undefined ? day.tempMax + "°" : "--°"
              font.pixelSize: 12
              font.weight: Font.Medium
              color: root.getTempColor(day ? day.tempMax : 0)
              anchors.verticalCenter: parent.verticalCenter
              renderType: Text.NativeRendering
            }

            // Precipitation badge (only if > 0%)
            Rectangle {
              visible: day && day.precipitationProbability > 0
              width: precipText.width + 8
              height: 18
              radius: 9
              color: Qt.rgba(137/255, 180/255, 250/255, 0.15)
              anchors.verticalCenter: parent.verticalCenter

              Text {
                id: precipText
                anchors.centerIn: parent
                text: day ? day.precipitationProbability + "%" : ""
                font.pixelSize: 9
                font.weight: Font.Medium
                color: "#89b4fa"
                renderType: Text.NativeRendering
              }
            }
          }
        }
      }
    }

    // Loading/Error states
    Row {
      spacing: 6
      width: parent.width
      visible: Weather.loading || Weather.error

      Text {
        text: Weather.loading ? "⏳" : "⚠️"
        font.pixelSize: 12
        anchors.verticalCenter: parent.verticalCenter
        renderType: Text.NativeRendering
      }

      Text {
        text: Weather.loading ? "Updating..." : Weather.error
        font.pixelSize: 11
        color: Weather.loading ? PopoutConfig.textColor : PopoutConfig.errorColor
        opacity: Weather.loading ? 0.6 : 1.0
        wrapMode: Text.Wrap
        width: parent.width - 20
        renderType: Text.NativeRendering
      }
    }
  }
}