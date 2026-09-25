pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// 3D Printer service: monitors Bambu printer via gateway API
// Provides status, camera feed, temperature, and print control
// Properties:
//  - connected: gateway connection status
//  - state: printer state (IDLE, RUNNING, PAUSED, etc)
//  - percentage: print progress 0-100
//  - remainingTimeMinutes: time remaining in minutes
//  - fileName: current file being printed
//  - nozzleTemp: current nozzle temperature
//  - bedTemp: current bed temperature
//  - fanSpeed: fan speed percentage
//  - cameraUrl: URL to fetch camera image
//  - available: data successfully fetched
//  - refresh(): force status update
//  - pause/resume/stop(): print control
QtObject {
  id: root

  property string gatewayUrl: "http://localhost:4387"
  property int updateInterval: 5 * 1000  // 5 seconds
  property int minFetchInterval: 2 * 1000  // 2 seconds between manual refreshes
  property int retryDelay: 10 * 1000  // 10 seconds retry delay
  property int maxRetryAttempts: 3
  property int retryAttempts: 0
  property int lastFetchTime: 0

  property bool available: false
  property bool loading: false
  property bool connected: false
  property string error: ""

  // Status properties
  property string state: "UNKNOWN"
  property string currentState: ""
  property int percentage: 0
  property int layerCurrent: 0
  property int layerTotal: 0
  property int remainingTimeMinutes: 0
  property string fileName: ""
  property string gcodeFile: ""
  property string subtaskName: ""
  property string printType: ""
  property string lightState: "unknown"
  property string wifiSignal: ""
  property int errorCode: 0

  // Recent file tracking
  property var recentFiles: []

  // Temperature properties
  property real nozzleTemp: 0
  property real nozzleTarget: 0
  property real bedTemp: 0
  property real bedTarget: 0
  property real chamberTemp: 0
  property int fanSpeed: 0

  // Speed and nozzle properties
  property int speedLevel: 1  // 0-3: Silent, Standard, Sport, Ludicrous
  property string nozzleDiameter: "0.4mm"
  property string nozzleType: ""

  // Fan control properties
  property int partFanSpeed: 0  // 0-100%
  property int auxFanSpeed: 0   // 0-100%
  property int chamberFanSpeed: 0  // 0-100%

  // AMS filament properties
  property var amsSlots: []  // Array of AMS slot objects
  property var externalSpool: null  // External spool info
  property int activeSpool: -1  // Which spool is currently active

  // Camera
  property string cameraUrl: gatewayUrl + "/camera"
  property string cameraStreamUrl: gatewayUrl + "/camera/stream"
  property string cameraBase64Url: gatewayUrl + "/camera/base64"

  property double _lastManualRefreshMs: 0
  property string _lastRecordedRecentKey: ""
  property string _statusBuffer: ""
  property string _temperatureBuffer: ""
  property string _nozzleBuffer: ""
  property string _speedBuffer: ""
  property string _amsBuffer: ""
  property string _externalSpoolBuffer: ""
  property string _fansBuffer: ""

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

    var statusUrl = gatewayUrl + "/status"
    _statusBuffer = ""
    statusProc.running = false
    statusProc.command = ["curl", "-sS", "--fail", "--connect-timeout", "2", "--max-time", "4", statusUrl]
    lastFetchTime = Date.now()
    statusProc.running = true
  }

  function _handleStatusProcExit(code) {
      var output = _statusBuffer
      _statusBuffer = ""
      if (code === 0) {
        _handleStatusResponse(output.trim())
      } else {
        _handleStatusFailure()
      }
  }

  function _handleStatusResponse(raw) {
    var trimmed = (raw || "").trim()
    if (!trimmed) {
      _handleStatusFailure()
      return
    }

    try {
      var data = JSON.parse(trimmed)

      connected = data.connected || false
      state = data.state || "UNKNOWN"
      currentState = data.current_state || ""
      percentage = data.percentage || 0
      layerCurrent = data.layer ? (data.layer.current || 0) : 0
      layerTotal = data.layer ? (data.layer.total || 0) : 0
      remainingTimeMinutes = data.remaining_time_minutes || 0
      fileName = data.file_name || ""
      gcodeFile = data.gcode_file || ""
      subtaskName = data.subtask_name || ""
      printType = data.print_type || ""
      lightState = data.light_state || "unknown"
      wifiSignal = data.wifi_signal || ""
      errorCode = data.error_code || 0

      _trackRecentFile(data)

      var resolvedSpool = _resolveActiveSpool(data)
      if (resolvedSpool >= 0) {
        activeSpool = resolvedSpool
      } else if (state !== "RUNNING" && state !== "PAUSED") {
        activeSpool = -1
      }

      available = true
      _handleStatusSuccess()

      // Fetch temperature separately
      _fetchTemperature()
    } catch (e) {
      error = "Parse error: " + e.toString()
      _handleStatusFailure()
    }
  }

  function _resolveActiveSpool(data) {
    if (!data) return -1
    var keys = ["current_spool", "active_spool", "current_slot", "active_slot"]
    for (var i = 0; i < keys.length; i++) {
      var value = data[keys[i]]
      if (value === undefined || value === null || value === "") continue
      var parsed = parseInt(value)
      if (!isNaN(parsed)) return parsed
    }
    return -1
  }

  function _trackRecentFile(data) {
    if (!data) return
    var displayName = data.file_name || data.subtask_name || data.gcode_file || ""
    if (!displayName) {
      if (data.state !== "RUNNING" && data.state !== "PAUSED") {
        _lastRecordedRecentKey = ""
      }
      return
    }

    var key = displayName + "|" + (data.gcode_file || "")
    var isActiveState = data.state === "RUNNING" || data.state === "PAUSED"

    if (isActiveState && key !== _lastRecordedRecentKey) {
      _appendRecentEntry(displayName, data.gcode_file || "", data.print_type || "", data.timestamp)
      _lastRecordedRecentKey = key
    }

    if (!isActiveState) {
      _lastRecordedRecentKey = ""
    }
  }

  function _appendRecentEntry(name, gcodePath, printTypeValue, timestampValue) {
    if (!name) return
    var entry = {
      key: name + "|" + gcodePath,
      filename: name,
      gcodeFile: gcodePath || "",
      printType: printTypeValue || "",
      recordedAt: timestampValue ? Date.parse(timestampValue) || Date.now() : Date.now()
    }

    var filtered = []
    for (var i = 0; i < recentFiles.length; i++) {
      var existing = recentFiles[i]
      if (existing && existing.key !== entry.key) {
        filtered.push(existing)
      }
    }
    filtered.unshift(entry)
    if (filtered.length > 5) {
      filtered = filtered.slice(0, 5)
    }
    recentFiles = filtered
  }

  function _fetchTemperature() {
    var tempUrl = gatewayUrl + "/temperature"
    _temperatureBuffer = ""
    temperatureProc.running = false
    temperatureProc.command = ["curl", "-sS", "--fail", "--connect-timeout", "2", "--max-time", "4", tempUrl]
    temperatureProc.running = true
  }

  function _handleTemperatureProcExit(code) {
      var output = _temperatureBuffer
      _temperatureBuffer = ""
      if (code === 0) {
        _handleTemperatureResponse(output.trim())
      }
  }

  property double _lastNozzleSetTime: 0
  property double _lastBedSetTime: 0

  function _handleTemperatureResponse(raw) {
     var trimmed = (raw || "").trim()
     if (!trimmed) return

     try {
       var data = JSON.parse(trimmed)
       var now = Date.now()

       nozzleTemp = data.nozzle ? (data.nozzle.current || 0) : 0
       
       // Only update target from API if outside grace period AND target is not null
       if (now - _lastNozzleSetTime > 3000) {
         var apiTarget = data.nozzle ? data.nozzle.target : null
         if (apiTarget !== null) {
           nozzleTarget = apiTarget
         }
       }

       bedTemp = data.bed ? (data.bed.current || 0) : 0
       
       // Only update target from API if outside grace period AND target is not null
       if (now - _lastBedSetTime > 3000) {
         var apiBedTarget = data.bed ? data.bed.target : null
         if (apiBedTarget !== null) {
           bedTarget = apiBedTarget
         }
       }

       chamberTemp = data.chamber || 0

       fanSpeed = state === "RUNNING" ? 100 : 0
     } catch (e) {
       // Temperature fetch is optional
     }
   }

  function _fetchNozzleInfo() {
    var nozzleUrl = gatewayUrl + "/nozzle"
    _nozzleBuffer = ""
    nozzleProc.running = false
    nozzleProc.command = ["curl", "-sS", "--fail", "--connect-timeout", "2", "--max-time", "4", nozzleUrl]
    nozzleProc.running = true
  }

  function _handleNozzleProcExit(code) {
      var output = _nozzleBuffer
      _nozzleBuffer = ""
      if (code === 0) {
        try {
          var data = JSON.parse(output.trim())
          nozzleDiameter = (data.diameter || "0.4") + "mm"
          nozzleType = data.type || ""
        } catch (e) {
          // Nozzle fetch is optional
        }
      }
  }

  function _fetchSpeedLevel() {
    var speedUrl = gatewayUrl + "/speed"
    _speedBuffer = ""
    speedProc.running = false
    speedProc.command = ["curl", "-sS", "--fail", "--connect-timeout", "2", "--max-time", "4", speedUrl]
    speedProc.running = true
  }

  function _handleSpeedProcExit(code) {
      var output = _speedBuffer
      _speedBuffer = ""
      if (code === 0) {
        try {
          var data = JSON.parse(output.trim())
          // Map 1-4 (API) to 0-3 (UI)
          // Default to Standard (2) -> Index 1
          var rawLevel = data.level || 2
          speedLevel = Math.max(0, Math.min(3, rawLevel - 1))
        } catch (e) {
          // Speed fetch is optional
        }
      }
  }

  function _fetchAmsInfo() {
    var amsUrl = gatewayUrl + "/ams"
    _amsBuffer = ""
    amsProc.running = false
    amsProc.command = ["curl", "-sS", "--fail", "--connect-timeout", "2", "--max-time", "4", amsUrl]
    amsProc.running = true
  }

  function _handleAmsProcExit(code) {
      var output = _amsBuffer
      _amsBuffer = ""
      if (code === 0) {
        try {
          var data = JSON.parse(output.trim())
          var hub = data.ams_hub || {}
          var slots = []
          
          // Flatten nested AMS structure: ams_hub -> ams_id -> trays -> tray_id
          var keys = Object.keys(hub).sort()
          for (var i = 0; i < keys.length; i++) {
            var ams = hub[keys[i]]
            if (ams && ams.trays) {
              var trayKeys = Object.keys(ams.trays).sort()
              for (var j = 0; j < trayKeys.length; j++) {
                var rawTray = ams.trays[trayKeys[j]]
                // Map raw fields to UI expected fields
                slots.push({
                  material: rawTray.tray_sub_brands || rawTray.tray_type || "Unknown",
                  color: rawTray.tray_color,
                  remaining: 100, // Placeholder as API doesn't provide remaining % yet
                  id: trayKeys[j]
                })
              }
            }
          }
          
          amsSlots = slots
          // activeSpool not currently available in /ams endpoint
          // activeSpool = data.current_spool || -1 
        } catch (e) {
          // AMS fetch is optional
        }
      }
  }

  function _fetchExternalSpool() {
    var externalUrl = gatewayUrl + "/external-spool"
    _externalSpoolBuffer = ""
    externalSpoolProc.running = false
    externalSpoolProc.command = ["curl", "-sS", "--fail", "--connect-timeout", "2", "--max-time", "4", externalUrl]
    externalSpoolProc.running = true
  }

  function _handleExternalSpoolProcExit(code) {
      var output = _externalSpoolBuffer
      _externalSpoolBuffer = ""
      if (code === 0) {
        try {
          var data = JSON.parse(output.trim())
          var raw = data.external_spool
          if (raw) {
            externalSpool = {
              material: raw.tray_sub_brands || raw.tray_type || "Unknown",
              color: raw.tray_color,
              remaining: 100
            }
          } else {
            externalSpool = null
          }
        } catch (e) {
          externalSpool = null
        }
      }
  }

  function _fetchFanSpeeds() {
    var fansUrl = gatewayUrl + "/fans"
    _fansBuffer = ""
    fansProc.running = false
    fansProc.command = ["curl", "-sS", "--fail", "--connect-timeout", "2", "--max-time", "4", fansUrl]
    fansProc.running = true
  }

  function _handleFansProcExit(code) {
    var output = _fansBuffer
    _fansBuffer = ""
    if (code === 0) {
      try {
        var data = JSON.parse(output.trim())
        if (data.part !== undefined) partFanSpeed = data.part
        if (data.aux !== undefined) auxFanSpeed = data.aux
        if (data.chamber !== undefined) chamberFanSpeed = data.chamber
      } catch (e) {
        // Fan fetch is optional
      }
    }
  }

  function _handleStatusSuccess() {
    loading = false
    retryAttempts = 0
    retryTimer.stop()
    updateTimer.interval = updateInterval
  }

  function _handleStatusFailure() {
    loading = false
    retryAttempts++

    if (retryAttempts < maxRetryAttempts) {
      retryTimer.start()
    } else {
      retryAttempts = 0
      if (!available) {
        loading = false
      }
    }
  }

  // Control functions
  function pause() {
    _sendControl("pause")
  }

  function resume() {
    _sendControl("resume")
  }

  function stop() {
    _sendControl("stop")
  }

  function toggleLight() {
    var newState = lightState === "on" ? "off" : "on"
    _sendLightControl(newState)
  }

  function _sendControl(action) {
    var procCode = 'import Quickshell.Io; Process { running: false }'
    var proc = Qt.createQmlObject(procCode, root)

    proc.onExited.connect(function(code) {
      if (code === 0) {
        // Refresh status after control command
        var timer = Qt.createQmlObject('import QtQuick; Timer { interval: 500; repeat: false }', root)
        timer.triggered.connect(function() {
          refresh(false)
          timer.destroy()
        })
        timer.start()
      }
      proc.destroy()
    })

    var payload = JSON.stringify({"action": action})
    proc.command = ["curl", "-sS", "-X", "POST", gatewayUrl + "/control",
                    "-H", "Content-Type: application/json",
                    "-d", payload]
    proc.running = true
  }

  function _sendLightControl(state) {
     var procCode = 'import Quickshell.Io; Process { running: false }'
     var proc = Qt.createQmlObject(procCode, root)

     proc.onExited.connect(function(code) {
       if (code === 0) {
         var timer = Qt.createQmlObject('import QtQuick; Timer { interval: 500; repeat: false }', root)
         timer.triggered.connect(function() {
           refresh(false)
           timer.destroy()
         })
         timer.start()
       }
       proc.destroy()
     })

     var payload = JSON.stringify({"action": "light", "state": state})
     proc.command = ["curl", "-sS", "-X", "POST", gatewayUrl + "/control",
                     "-H", "Content-Type: application/json",
                     "-d", payload]
     proc.running = true
   }

  function startPrint(filename) {
    if (!filename) return
    var trimmed = filename.trim()
    if (!trimmed) return

    var procCode = 'import Quickshell.Io; Process { running: false; stdout: SplitParser { onRead: function(data) { } } }'
    var proc = Qt.createQmlObject(procCode, root)

    var output = ""
    proc.stdout.onRead.connect(function(data) {
      output += data.toString()
    })

    proc.onExited.connect(function(code) {
      if (code === 0) {
        refresh(false)
      } else {
        console.log("Printer3D.startPrint failed", code, output)
      }
      proc.destroy()
    })

    var payload = JSON.stringify({"filename": trimmed})
    proc.command = ["curl", "-sS", "-X", "POST", gatewayUrl + "/print",
                    "-H", "Content-Type: application/json",
                    "-d", payload]
    proc.running = true
  }

  // Temperature control
  function setTemperature(type, value) {
    // Optimistic update: update UI immediately
    if (type === "nozzle") {
      nozzleTarget = value
      _lastNozzleSetTime = Date.now()
    } else if (type === "bed") {
      bedTarget = value
      _lastBedSetTime = Date.now()
    }

    var procCode = 'import Quickshell.Io; Process { running: false }'
    var proc = Qt.createQmlObject(procCode, root)

    proc.onExited.connect(function(code) {
      proc.destroy()
    })

    var payload = {}
    if (type === "nozzle") {
      payload = {"nozzle": value, "override": true}
    } else if (type === "bed") {
      payload = {"bed": value, "override": true}
    }

    proc.command = ["curl", "-sS", "-X", "POST", gatewayUrl + "/temperature",
                    "-H", "Content-Type: application/json",
                    "-d", JSON.stringify(payload)]
    proc.running = true
  }

  // Speed control
  function setSpeedLevel(level) {
    var procCode = 'import Quickshell.Io; Process { running: false }'
    var proc = Qt.createQmlObject(procCode, root)

    proc.onExited.connect(function(code) {
      if (code === 0) {
        speedLevel = level
      }
      proc.destroy()
    })

    // Map 0-3 (UI) to 1-4 (API)
    var apiLevel = level + 1
    var payload = JSON.stringify({"level": apiLevel})
    proc.command = ["curl", "-sS", "-X", "POST", gatewayUrl + "/speed",
                    "-H", "Content-Type: application/json",
                    "-d", payload]
    proc.running = true
  }

  // Fan control
  function setFanSpeed(part, aux, chamber) {
    var procCode = 'import Quickshell.Io; Process { running: false }'
    var proc = Qt.createQmlObject(procCode, root)

    proc.onExited.connect(function(code) {
      if (code === 0) {
        if (part !== undefined) partFanSpeed = part
        if (aux !== undefined) auxFanSpeed = aux
        if (chamber !== undefined) chamberFanSpeed = chamber
      }
      proc.destroy()
    })

    var payload = {}
    if (part !== undefined) payload.part = part
    if (aux !== undefined) payload.aux = aux
    if (chamber !== undefined) payload.chamber = chamber

    proc.command = ["curl", "-sS", "-X", "POST", gatewayUrl + "/fans",
                    "-H", "Content-Type: application/json",
                    "-d", JSON.stringify(payload)]
    proc.running = true
  }

  // Maintenance functions
  function homeAxes() {
    var procCode = 'import Quickshell.Io; Process { running: false }'
    var proc = Qt.createQmlObject(procCode, root)

    proc.onExited.connect(function(code) {
      if (code === 0) {
        var timer = Qt.createQmlObject('import QtQuick; Timer { interval: 3000; repeat: false }', root)
        timer.triggered.connect(function() {
          refresh(false)
          timer.destroy()
        })
        timer.start()
      }
      proc.destroy()
    })

    proc.command = ["curl", "-sS", "-X", "POST", gatewayUrl + "/home",
                    "-H", "Content-Type: application/json",
                    "-d", "{}"]
    proc.running = true
  }

  // Filament control
  function loadFilament(slot) {
    var procCode = 'import Quickshell.Io; Process { running: false }'
    var proc = Qt.createQmlObject(procCode, root)

    proc.onExited.connect(function(code) {
      if (code === 0) {
        var timer = Qt.createQmlObject('import QtQuick; Timer { interval: 2000; repeat: false }', root)
        timer.triggered.connect(function() {
          _fetchAmsInfo()
          timer.destroy()
        })
        timer.start()
      }
      proc.destroy()
    })

    var payload = JSON.stringify({"action": "load", "target": slot})
    proc.command = ["curl", "-sS", "-X", "POST", gatewayUrl + "/filament",
                    "-H", "Content-Type: application/json",
                    "-d", payload]
    proc.running = true
  }

  function unloadFilament() {
    var procCode = 'import Quickshell.Io; Process { running: false }'
    var proc = Qt.createQmlObject(procCode, root)

    proc.onExited.connect(function(code) {
      if (code === 0) {
        var timer = Qt.createQmlObject('import QtQuick; Timer { interval: 2000; repeat: false }', root)
        timer.triggered.connect(function() {
          _fetchAmsInfo()
          timer.destroy()
        })
        timer.start()
      }
      proc.destroy()
    })

    var payload = JSON.stringify({"action": "unload"})
    proc.command = ["curl", "-sS", "-X", "POST", gatewayUrl + "/filament",
                    "-H", "Content-Type: application/json",
                    "-d", payload]
    proc.running = true
  }

  // Calibration
  function calibratePrinter(bedLevel, motorNoise, vibration) {
    var procCode = 'import Quickshell.Io; Process { running: false }'
    var proc = Qt.createQmlObject(procCode, root)

    proc.onExited.connect(function(code) {
      if (code === 0) {
        // Calibration takes ~15 minutes, refresh after
        var timer = Qt.createQmlObject('import QtQuick; Timer { interval: 60000; repeat: false }', root)
        timer.triggered.connect(function() {
          refresh(false)
          timer.destroy()
        })
        timer.start()
      }
      proc.destroy()
    })

    var payload = JSON.stringify({
      "bed_level": bedLevel !== false,
      "motor_noise": motorNoise !== false,
      "vibration": vibration !== false
    })
    proc.command = ["curl", "-sS", "-X", "POST", gatewayUrl + "/calibrate",
                    "-H", "Content-Type: application/json",
                    "-d", payload]
    proc.running = true
  }

  // File deletion
  function deleteFile(filename) {
    var procCode = 'import Quickshell.Io; Process { running: false }'
    var proc = Qt.createQmlObject(procCode, root)

    proc.onExited.connect(function(code) {
      if (code === 0) {
        fileName = ""
        refresh(false)
      }
      proc.destroy()
    })

    proc.command = ["curl", "-sS", "-X", "DELETE", gatewayUrl + "/file?filename=" + encodeURIComponent(filename),
                    "-H", "Content-Type: application/json"]
    proc.running = true
  }

  property Process statusProc: Process {
    running: false
    stdout: SplitParser {
      onRead: function(data) {
        root._statusBuffer += data.toString()
      }
    }
    stderr: SplitParser {
      onRead: function(_) {
      }
    }
    onExited: function(code) {
      root._handleStatusProcExit(code)
    }
  }

  property Process temperatureProc: Process {
    running: false
    stdout: SplitParser {
      onRead: function(data) {
        root._temperatureBuffer += data.toString()
      }
    }
    stderr: SplitParser {
      onRead: function(_) {
      }
    }
    onExited: function(code) {
      root._handleTemperatureProcExit(code)
    }
  }

  property Process nozzleProc: Process {
    running: false
    stdout: SplitParser {
      onRead: function(data) {
        root._nozzleBuffer += data.toString()
      }
    }
    stderr: SplitParser {
      onRead: function(_) {
      }
    }
    onExited: function(code) {
      root._handleNozzleProcExit(code)
    }
  }

  property Process speedProc: Process {
    running: false
    stdout: SplitParser {
      onRead: function(data) {
        root._speedBuffer += data.toString()
      }
    }
    stderr: SplitParser {
      onRead: function(_) {
      }
    }
    onExited: function(code) {
      root._handleSpeedProcExit(code)
    }
  }

  property Process amsProc: Process {
    running: false
    stdout: SplitParser {
      onRead: function(data) {
        root._amsBuffer += data.toString()
      }
    }
    stderr: SplitParser {
      onRead: function(_) {
      }
    }
    onExited: function(code) {
      root._handleAmsProcExit(code)
    }
  }

  property Process externalSpoolProc: Process {
    running: false
    stdout: SplitParser {
      onRead: function(data) {
        root._externalSpoolBuffer += data.toString()
      }
    }
    stderr: SplitParser {
      onRead: function(_) {
      }
    }
    onExited: function(code) {
      root._handleExternalSpoolProcExit(code)
    }
  }

  property Process fansProc: Process {
    running: false
    stdout: SplitParser {
      onRead: function(data) {
        root._fansBuffer += data.toString()
      }
    }
    stderr: SplitParser {
      onRead: function(_) {
      }
    }
    onExited: function(code) {
      root._handleFansProcExit(code)
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

  // AMS polling (every 10 seconds, slower than main status)
  property Timer amsTimer: Timer {
    interval: 10 * 1000
    repeat: true
    running: available
    onTriggered: {
      _fetchAmsInfo()
      _fetchExternalSpool()
      _fetchSpeedLevel()
      _fetchFanSpeeds()
    }
  }

  Component.onCompleted: {
    _fetchNozzleInfo()  // Fetch once, rarely changes
    refresh(false)
  }
}
