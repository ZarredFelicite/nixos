import QtQuick
import Quickshell
import "../services"

// Weather indicator pill: shows weather icon + temperature, popout with details on hover.
Item {
    id: root
    objectName: "WeatherIndicator"
    property var popouts: null

    implicitWidth: row.implicitWidth + 8
    implicitHeight: Colors.pillHeight

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onEntered: {
            if (root.popouts) {
                var pos = root.popouts.mapFromItem(root, root.width / 2, root.height)
                root.popouts.openPopout("tooltip-weather", pos.x, pos.y, 350)
            }
        }
        onExited: {
        }
        onClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton || mouse.button === Qt.MiddleButton) {
                Weather.refresh(true)
            }
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 4

        Text {
            id: icon
            text: Weather.getWeatherIcon(Weather.weatherCode)
            font.pixelSize: 16
            color: Colors.primary
            opacity: Weather.loading ? 0.6 : 1.0
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            id: temp
            text: {
                var temp = Weather.temperature
                if (!Weather.available || temp === undefined || temp === null || temp === 0) {
                    return "--°C"
                }
                return temp + "°C"
            }
            font.pixelSize: 14
            font.weight: Font.Medium
            color: Colors.primary
            opacity: Weather.loading ? 0.6 : 1.0
            verticalAlignment: Text.AlignVCenter
        }
    }
}
