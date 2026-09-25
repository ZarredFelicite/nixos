pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Weather service: fetches data from Open-Meteo API
// Provides detailed weather information including forecast, humidity, wind, etc.
// Properties:
//  - temperature: current temperature in °C
//  - temperatureF: current temperature in °F
//  - feelsLike: feels-like temperature in °C
//  - feelsLikeF: feels-like temperature in °F
//  - city: location city name
//  - country: location country
//  - weatherCode: WMO weather code
//  - humidity: relative humidity percentage
//  - wind: wind speed and direction
//  - sunrise/sunset: times
//  - pressure: atmospheric pressure
//  - precipitationProbability: precipitation chance
//  - isDay: whether it's currently daytime
//  - forecast: array of daily forecasts
//  - available: data successfully fetched
//  - loading: currently fetching data
//  - refresh(): force weather update
QtObject {
    id: root

    property var location: null
    property int updateInterval: 15 * 60 * 1000  // 15 minutes
    property int minFetchInterval: 30 * 1000     // 30 seconds between manual refreshes
    property int retryDelay: 30 * 1000           // 30 seconds retry delay
    property int maxRetryAttempts: 3
    property int retryAttempts: 0
    property int persistentRetryCount: 0
    property int lastFetchTime: 0

    // Coordinates: Melbourne
    property string latitude: "-37.99116"
    property string longitude: "145.17385"

    property bool available: false
    property bool loading: false
    property string error: ""

    property real temperature: 0
    property real temperatureF: 0
    property real feelsLike: 0
    property real feelsLikeF: 0
    property string city: ""
    property string country: ""
    property int weatherCode: 0
    property int humidity: 0
    property string wind: ""
    property string sunrise: "06:00"
    property string sunset: "18:00"
    property int pressure: 0
    property int precipitationProbability: 0
    property bool isDay: true

    property var forecast: []

    property double _lastManualRefreshMs: 0

    // Weather icons mapping for WMO codes
    property var weatherIcons: ({
        "0": "☀️", "1": "☀️", "2": "⛅", "3": "☁️",
        "45": "🌫️", "48": "🌫️",
        "51": "🌧️", "53": "🌧️", "55": "🌧️", "56": "🌧️", "57": "🌧️",
        "61": "🌧️", "63": "🌧️", "65": "🌧️", "66": "🌧️", "67": "🌧️",
        "71": "🌨️", "73": "🌨️", "75": "❄️", "77": "🌨️",
        "80": "🌧️", "81": "🌧️", "82": "⛈️",
        "85": "🌨️", "86": "❄️",
        "95": "⛈️", "96": "⛈️", "99": "⛈️"
    })

    property var weatherConditions: ({
        "0": "Clear", "1": "Clear", "2": "Partly cloudy", "3": "Overcast",
        "45": "Fog", "48": "Fog",
        "51": "Drizzle", "53": "Drizzle", "55": "Drizzle",
        "56": "Freezing drizzle", "57": "Freezing drizzle",
        "61": "Light rain", "63": "Rain", "65": "Heavy rain",
        "66": "Light rain", "67": "Heavy rain",
        "71": "Light snow", "73": "Snow", "75": "Heavy snow", "77": "Snow",
        "80": "Light rain", "81": "Rain", "82": "Heavy rain",
        "85": "Light snow showers", "86": "Heavy snow showers",
        "95": "Thunderstorm", "96": "Thunderstorm with hail", "99": "Thunderstorm with hail"
    })

    function getWeatherIcon(code) {
        return weatherIcons[String(code)] || "❓"
    }

    function getWeatherCondition(code) {
        return weatherConditions[String(code)] || "Unknown"
    }

    function formatTime(isoString) {
        if (!isoString) return "--"
        try {
            var date = new Date(isoString + "Z")
            var hours = String(date.getHours()).padStart(2, "0")
            var minutes = String(date.getMinutes()).padStart(2, "0")
            return hours + ":" + minutes
        } catch (e) {
            return "--"
        }
    }

    function formatForecastDay(isoString, index) {
        if (!isoString) return "--"
        try {
            // Parse YYYY-MM-DD format
            var parts = isoString.split("-")
            if (parts.length < 3) return "--"
            var year = parseInt(parts[0])
            var month = parseInt(parts[1]) - 1
            var day = parseInt(parts[2])
            var date = new Date(year, month, day)
            var days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            return days[date.getDay()]
        } catch (e) {
            return "--"
        }
    }

    function buildWeatherUrl() {
        var params = [
            "latitude=" + latitude,
            "longitude=" + longitude,
            "current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,weather_code,surface_pressure,wind_speed_10m",
            "daily=sunrise,sunset,temperature_2m_max,temperature_2m_min,weather_code,precipitation_probability_max",
            "timezone=auto",
            "forecast_days=7"
        ]
        return "https://api.open-meteo.com/v1/forecast?" + params.join("&")
    }

    function canManualRefresh() {
        var now = Date.now()
        return (now - _lastManualRefreshMs) >= minFetchInterval
    }

    function refresh(manual) {
        if (loading) return
        if (manual === true && !canManualRefresh()) return
        if (manual === true) _lastManualRefreshMs = Date.now()

        loading = true
        error = ""

        var weatherUrl = buildWeatherUrl()
        var proc = Qt.createQmlObject(
            'import Quickshell.Io; import QtQuick; Process { id: weatherProc; stdout: SplitParser { onRead: function(line){ root._handleWeatherLine(line) } } }',
            root
        )

        proc.onExited.connect(function(code) {
            if (code !== 0) {
                _handleWeatherFailure()
            }
            proc.destroy()
        })

        proc.command = ["curl", "-sS", "--fail", "--connect-timeout", "3", "--max-time", "6", weatherUrl]
        lastFetchTime = Date.now()
        proc.running = true
    }

    function _handleWeatherLine(line) {
        var trimmed = (line || "").trim()
        if (!trimmed) return
        _handleWeatherResponse(trimmed)
    }

    function _handleWeatherResponse(raw) {
        var trimmed = (raw || "").trim()
        if (!trimmed) {
            _handleWeatherFailure()
            return
        }

        try {
            var data = JSON.parse(trimmed)

            if (!data.current || !data.daily) {
                throw new Error("Missing weather data")
            }

            var current = data.current
            var daily = data.daily
            var currentUnits = data.current_units || {}

            var tempC = current.temperature_2m || 0
            var feelsC = current.apparent_temperature || tempC

            temperature = Math.round(tempC)
            temperatureF = Math.round(tempC * 9/5 + 32)
            feelsLike = Math.round(feelsC)
            feelsLikeF = Math.round(feelsC * 9/5 + 32)
            humidity = Math.round(current.relative_humidity_2m || 0)
            pressure = Math.round(current.surface_pressure || 0)
            wind = Math.round(current.wind_speed_10m || 0) + " " + (currentUnits.wind_speed_10m || "m/s")
            weatherCode = current.weather_code || 0
            isDay = Boolean(current.is_day)
            precipitationProbability = Math.round(daily.precipitation_probability_max?.[0] || 0)

            // Extract city from timezone (e.g., "Australia/Melbourne" -> "Melbourne")
            if (data.timezone) {
                var tzParts = data.timezone.split("/")
                if (tzParts.length > 1) {
                    city = tzParts[tzParts.length - 1].replace(/_/g, " ")
                    country = tzParts[0]
                } else {
                    city = data.timezone
                }
            }

            // Format sunrise/sunset
            if (daily.sunrise && daily.sunrise.length > 0) {
                sunrise = formatTime(daily.sunrise[0])
            }
            if (daily.sunset && daily.sunset.length > 0) {
                sunset = formatTime(daily.sunset[0])
            }

            // Build forecast
            var newForecast = []
            if (daily.time && daily.time.length > 0) {
                for (var i = 0; i < Math.min(daily.time.length, 7); i++) {
                    var tempMinC = daily.temperature_2m_min?.[i] || 0
                    var tempMaxC = daily.temperature_2m_max?.[i] || 0

                    newForecast.push({
                        "day": formatForecastDay(daily.time[i], i),
                        "date": daily.time[i],
                        "wCode": daily.weather_code?.[i] || 0,
                        "tempMin": Math.round(tempMinC),
                        "tempMax": Math.round(tempMaxC),
                        "tempMinF": Math.round(tempMinC * 9/5 + 32),
                        "tempMaxF": Math.round(tempMaxC * 9/5 + 32),
                        "precipitationProbability": Math.round(daily.precipitation_probability_max?.[i] || 0),
                        "sunrise": daily.sunrise?.[i] ? formatTime(daily.sunrise[i]) : "",
                        "sunset": daily.sunset?.[i] ? formatTime(daily.sunset[i]) : ""
                    })
                }
            }
            forecast = newForecast

            available = true
            _handleWeatherSuccess()
        } catch (e) {
            error = "Parse error: " + e.toString()
            _handleWeatherFailure()
        }
    }

    function _handleWeatherSuccess() {
        loading = false
        retryAttempts = 0
        persistentRetryCount = 0
        retryTimer.stop()
        persistentRetryTimer.stop()
        updateTimer.interval = updateInterval
    }

    function _handleWeatherFailure() {
        loading = false
        retryAttempts++

        if (retryAttempts < maxRetryAttempts) {
            retryTimer.start()
        } else {
            retryAttempts = 0
            if (!available) {
                loading = false
            }
            var backoffDelay = Math.min(60000 * Math.pow(2, persistentRetryCount), 300000)
            persistentRetryCount++
            persistentRetryTimer.interval = backoffDelay
            persistentRetryTimer.start()
        }
    }

    property Timer updateTimer: Timer {
        interval: root.updateInterval
        repeat: true
        running: true
        onTriggered: refresh(false)
    }

    property Timer retryTimer: Timer {
        interval: root.retryDelay
        repeat: false
        running: false
        onTriggered: refresh(false)
    }

    property Timer persistentRetryTimer: Timer {
        interval: 60000
        repeat: false
        running: false
        onTriggered: refresh(false)
    }

    Component.onCompleted: refresh(false)
}
