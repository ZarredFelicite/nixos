pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
    id: root

    property int connectionCount: 0
    property string connectedDevices: ""
    property int refCount: 0
    property bool powered: true
    property bool scanning: false
    property string error: ""
    property var devices: []
    property date lastUpdated: new Date(0)

    // Poll interval in ms
    property int interval: 5000

    property Timer pollTimer: Timer {
        id: pollTimer
        interval: root.interval
        running: false
        repeat: true
        onTriggered: update()
    }

    onRefCountChanged: {
        pollTimer.running = (root.refCount > 0)
        if (root.refCount > 0) update()
    }

    property var deviceList: []
    
    property Process bluetoothProcess: Process {
        id: bluetoothProcess
        running: false
        command: ["bash", "-c", "bluetoothctl devices Connected 2>/dev/null | sed 's/\\x1b\\[[0-9;]*m//g' | cat"]
        stdout: SplitParser { 
            onRead: function(data) { 
                root.parseBluetoothLine(data.toString())
            } 
        }
        onExited: function() {
            // Process is done, update final counts
            root.connectionCount = root.deviceList.length
            root.connectedDevices = root.deviceList.join(', ')
        }
    }

    property string deviceListOutput: ""

    property Process deviceListProcess: Process {
        id: deviceListProcess
        running: false
        command: ["bash", "-c", "bluetoothctl devices 2>/dev/null | sed 's/\\x1b\\[[0-9;]*m//g' | cat"]
        stdout: SplitParser {
            onRead: function(data) {
                root.deviceListOutput += data.toString()
            }
        }
        onExited: function(code) {
            root.parseDeviceListOutput()
        }
    }

    function parseBluetoothLine(line) {
        line = line.trim()
        
        if (line && line.startsWith('Device ')) {
            // Extract device name (everything after "Device MAC_ADDRESS ")
            var parts = line.split(' ')
            if (parts.length > 2) {
                var deviceName = parts.slice(2).join(' ')
                root.deviceList.push(deviceName)
            }
        }
    }

    function update() {
         if (root.refCount === 0) return
         // Clear device list before scanning
         root.deviceList = []
         bluetoothProcess.running = false
         bluetoothProcess.running = true
         
         // Also update device list with details
         updateDeviceList()
     }

     function updateDeviceList() {
         root.deviceListOutput = ""
         deviceListProcess.running = false
         deviceListProcess.running = true
     }

    function parseDeviceListOutput() {
         // Use regex to match all Device lines regardless of line breaks
         // Pattern: Device XX:XX:XX:XX:XX:XX NAME
         var deviceRegex = /Device ([A-F0-9:]+)\s+(.+?)(?=Device |$)/gi
         var newDevices = []
         var match
         
         while ((match = deviceRegex.exec(root.deviceListOutput)) !== null) {
             var mac = match[1]
             var name = match[2].trim()
             
             // Create device object (will be enriched)
             newDevices.push({
                 mac: mac,
                 name: name,
                 connected: false,
                 paired: false,
                 trusted: false,
                 rssi: 0,
                 battery: -1,
                 icon: ""
             })
         }
         
         if (newDevices.length === 0) {
             root.devices = []
             root.lastUpdated = new Date()
             return
         }
         
         // Enrich device info for each device
         enrichDeviceInfo(newDevices, 0)
     }

    function enrichDeviceInfo(deviceArray, index) {
         if (index >= deviceArray.length) {
             // All devices processed, update the property
             root.devices = deviceArray
             root.lastUpdated = new Date()
             return
         }
         
         var device = deviceArray[index]
         var infoOutput = ""
         
         var infoProcessCode = 'import Quickshell.Io; Process { running: false; command: ["sh", "-c", "bluetoothctl info ' + device.mac + ' 2>/dev/null"]; stdout: SplitParser { onRead: function(data) { } } }'
         
         var infoProcess = Qt.createQmlObject(infoProcessCode, root)
         
         // Capture stdout
         infoProcess.stdout.onRead.connect(function(data) {
             infoOutput += data.toString()
         })
         
          infoProcess.onExited.connect(function(code) {
              // Parse the info output - fields can be separated by tabs or newlines
              // Split by both tabs and newlines to get all fields
              var fields = infoOutput.split(/[\t\n]/)
              for (var i = 0; i < fields.length; i++) {
                  var field = fields[i].trim()
                  if (field.startsWith('Connected:')) {
                      device.connected = field.includes('yes')
                  } else if (field.startsWith('Paired:')) {
                      device.paired = field.includes('yes')
                  } else if (field.startsWith('Trusted:')) {
                      device.trusted = field.includes('yes')
                  } else if (field.startsWith('Icon:')) {
                      device.icon = field.substring(field.indexOf(':') + 1).trim()
                  } else if (field.startsWith('RSSI:')) {
                      // Format: "RSSI: 0xffffffb4 (-76)" or "RSSI: 0x0000 (0)"
                      var match = field.match(/RSSI:.*\((-?\d+)\)/)
                      if (match && match.length > 1) {
                          device.rssi = parseInt(match[1])
                      }
                  } else if (field.startsWith('Battery Percentage:')) {
                      // Format: "Battery Percentage: 0x46 (70)"
                      var batMatch = field.match(/Battery Percentage:.*\((\d+)\)/)
                      if (batMatch && batMatch.length > 1) {
                          device.battery = parseInt(batMatch[1])
                      }
                  }
              }
              
              // CRITICAL: Destroy process to prevent memory leak
              infoProcess.destroy()
              
              // Move to next device
              enrichDeviceInfo(deviceArray, index + 1)
          })
         
         infoProcess.running = true
     }

    // Bluetooth control functions
    function toggleBluetooth() {
        var toggleProcess = Qt.createQmlObject('import Quickshell.Io; Process { running: false; command: ["sh", "-c", "bluetoothctl show | grep -q \'Powered: yes\' && bluetoothctl power off || bluetoothctl power on"]; }', root)
        toggleProcess.onExited.connect(function() {
            Qt.callLater(function() { 
                updateDeviceList()
            })
            toggleProcess.destroy()
        })
        toggleProcess.running = true
    }

    function scan() {
        root.scanning = true
        root.error = ""
        
        // Start scan
        var scanProcess = Qt.createQmlObject('import Quickshell.Io; Process { running: false; command: ["sh", "-c", "timeout 5s bluetoothctl scan on 2>/dev/null || true"]; }', root)
        scanProcess.onExited.connect(function() {
            scanProcess.destroy()
        })
        scanProcess.running = true
        
        // Update device list after scan
        var timer = Qt.createQmlObject('import QtQuick; Timer { interval: 6000; repeat: false }', root)
        timer.onTriggered.connect(function() {
            root.scanning = false
            updateDeviceList()
            timer.destroy()
        })
        timer.start()
    }

    function connect(mac) {
        var connectProcess = Qt.createQmlObject('import Quickshell.Io; Process { running: false; command: ["sh", "-c", "bluetoothctl connect ' + mac + '"]; }', root)
        connectProcess.onExited.connect(function(exitCode) {
            Qt.callLater(function() { updateDeviceList() })
            connectProcess.destroy()
        })
        connectProcess.running = true
    }

    function disconnect(mac) {
        var disconnectProcess = Qt.createQmlObject('import Quickshell.Io; Process { running: false; command: ["sh", "-c", "bluetoothctl disconnect ' + mac + '"]; }', root)
        disconnectProcess.onExited.connect(function(exitCode) {
            Qt.callLater(function() { updateDeviceList() })
            disconnectProcess.destroy()
        })
        disconnectProcess.running = true
    }

    function pair(mac) {
        var pairProcess = Qt.createQmlObject('import Quickshell.Io; Process { running: false; command: ["sh", "-c", "bluetoothctl pair ' + mac + '"]; }', root)
        pairProcess.onExited.connect(function(exitCode) {
            Qt.callLater(function() { updateDeviceList() })
            pairProcess.destroy()
        })
        pairProcess.running = true
    }

    function openBluetoothSettings() {
        var settingsProcess = Qt.createQmlObject('import Quickshell.Io; Process { running: false; command: ["sh", "-c", "blueman-manager || gnome-control-center bluetooth || systemsettings5 bluetooth"]; }', root)
        settingsProcess.onExited.connect(function() {
            settingsProcess.destroy()
        })
        settingsProcess.running = true
    }
}
