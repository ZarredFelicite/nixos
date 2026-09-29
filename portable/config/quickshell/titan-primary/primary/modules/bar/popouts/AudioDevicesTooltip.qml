import QtQuick
import Quickshell.Widgets
import Quickshell.Io
import "../../../services"

// Generic audio device chooser popup. mode: 'out' | 'in'
ClippingRectangle {
  id: root
  required property Item wrapper
  // 'out' => sinks, 'in' => sources
  required property string mode

  property bool expanded: wrapper && wrapper.hasCurrent && (wrapper.currentName === (root.mode === 'out' ? 'audio-out' : 'audio-in'))
  property bool hasOwnBackground: true

  readonly property int hPadding: 16
  readonly property int vPadding: 10

  // Size to accommodate full device names
  property int minContentWidth: 350
  implicitWidth: Math.max(minContentWidth, column.implicitWidth + hPadding * 2)
  implicitHeight: expanded ? (column.implicitHeight + vPadding * 2) : 0

  y: 0
  opacity: expanded ? Colors.opacity.foreground1 : 0

  color: PopoutConfig.backgroundColor
  border.width: PopoutConfig.borderWidth
  border.color: PopoutConfig.borderColor
  radius: PopoutConfig.cornerRadius
  contentInsideBorder: false

  Behavior on implicitHeight { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
  Behavior on opacity { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

  // Device model: [{id, name, isDefault}]
  // Enable for layout diagnostics
  property bool debugLayout: false
  property var devices: []

  // (Initial refresh moved to merged Component.onCompleted below)
  onExpandedChanged: { if (expanded) refresh() }
  
  // Listen for device changes from AudioInput service to sync popout state
  Connections {
    target: root.mode === 'in' ? AudioInput : null
    function onDeviceChanged() {
      if (expanded) refresh()
    }
  }
  
  // Listen for device changes from AudioOutput service to sync popout state
  Connections {
    target: root.mode === 'out' ? AudioOutput : null
    function onDeviceChanged() {
      if (expanded) refresh()
    }
  }

  function friendlyDeviceName(name) {
    if (!name) return ""
    return name
      .replace(/Cambridge Silicon Radio, Ltd\s*/g, "")
      .replace(/Mpow HC5 Headset in charging mode - HID \/ Mass Storage/g, "Qudelix-5K USB DAC")
      .replace(/Mpow HC5 Headset in charging mode - USB Hub/g, "Qudelix-5K USB DAC")
      .replace(/Mpow HC5 Headset in charging mode/g, "Qudelix-5K USB DAC")
  }

  function refresh() {
    devices = []
    statusProc.running = false
    statusProc.running = true
  }

  // Parse wpctl status to extract sinks/sources and pactl for monitor sources
  Process {
    id: statusProc
    running: false
    command: ["sh","-c","wpctl status 2>/dev/null; echo '=== DEFAULT ==='; pactl get-default-source 2>/dev/null; echo '=== DEFAULT_SINK ==='; pactl get-default-sink 2>/dev/null; echo '=== DEFAULT_SINK_NODE ==='; wpctl inspect @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk -F'\"' '/node.name =/ {print $2; exit}'; echo '=== DEFAULT_SOURCE_NODE ==='; wpctl inspect @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | awk -F'\"' '/node.name =/ {print $2; exit}'; echo '=== SOURCES ==='; pactl list sources short 2>/dev/null; echo '=== NODES ==='; pw-cli ls Node 2>/dev/null | awk '/^\\tid [0-9]+/ {id=$2} /node\\.name/ || /node\\.description/ {print id, $0}'; echo '=== LINKS ==='; pw-link -l 2>/dev/null; echo '=== OUTPUT_PORTS ==='; pw-link -o 2>/dev/null; echo '=== INPUT_PORTS ==='; pw-link -i 2>/dev/null"]
    stdout: SplitParser {
      onRead: function(line) { root._collect(line.toString()) }
    }
    onExited: function(){ root._finalizeCollect() }
  }

  // simple collector
  property var _lines: []
  function _collect(s) {
    _lines = _lines.concat(s.split(/\n+/))
  }
  function _finalizeCollect() {
    try {
      var lines = _lines
      _lines = []
      var out = []
      
      // Build node ID -> node.name/description mapping
      var nodeIdToName = {}
      var nodeIdToDescription = {}
      var filterInputNodeName = ""
      var inNodesSection = false
      for (var i=0;i<lines.length;i++) {
        var L = lines[i]
        if (L.indexOf('=== NODES ===') !== -1) {
          inNodesSection = true
          continue
        }
        if (!inNodesSection) continue
        
        // Format: "ID,  node.name = \"name\""
        var nodeNameMatch = L.match(/^([0-9]+),.*node\.name = "([^"]+)"/)
        if (nodeNameMatch) {
          var nodeId = parseInt(nodeNameMatch[1])
          var nodeName = nodeNameMatch[2]
          nodeIdToName[nodeId] = nodeName
          if (!filterInputNodeName && nodeName.indexOf('input.filter-chain-') === 0) {
            filterInputNodeName = nodeName
          }
        }
        var nodeDescMatch = L.match(/^([0-9]+),.*node\.description = "([^"]+)"/)
        if (nodeDescMatch) {
          var descId = parseInt(nodeDescMatch[1])
          var nodeDesc = nodeDescMatch[2]
          nodeIdToDescription[descId] = nodeDesc
        }
      }
      
      // Extract the default source and sink from pactl output
      var defaultSource = ""
      var defaultSink = ""
      var defaultSourceNode = ""
      var defaultSinkNode = ""
      var inDefaultSection = false
      var inDefaultSinkSection = false
      var inDefaultSinkNodeSection = false
      var inDefaultSourceNodeSection = false
      for (var i=0;i<lines.length;i++) {
        var L = lines[i]
        if (L.indexOf('=== DEFAULT ===') !== -1) { 
          inDefaultSection = true
          continue 
        }
        if (L.indexOf('=== DEFAULT_SINK ===') !== -1) {
          inDefaultSection = false
          inDefaultSinkSection = true
          continue
        }
        if (L.indexOf('=== DEFAULT_SINK_NODE ===') !== -1) {
          inDefaultSection = false
          inDefaultSinkSection = false
          inDefaultSinkNodeSection = true
          continue
        }
        if (L.indexOf('=== DEFAULT_SOURCE_NODE ===') !== -1) {
          inDefaultSection = false
          inDefaultSinkSection = false
          inDefaultSinkNodeSection = false
          inDefaultSourceNodeSection = true
          continue
        }
        if (L.indexOf('=== SOURCES ===') !== -1) {
          inDefaultSection = false
          inDefaultSinkSection = false
          inDefaultSinkNodeSection = false
          inDefaultSourceNodeSection = false
          break
        }
        if (inDefaultSection && L.trim()) {
          defaultSource = L.trim()
        }
        if (inDefaultSinkSection && L.trim()) {
          defaultSink = L.trim()
        }
        if (inDefaultSinkNodeSection && L.trim()) {
          defaultSinkNode = L.trim()
        }
        if (inDefaultSourceNodeSection && L.trim()) {
          defaultSourceNode = L.trim()
        }
      }

      // Fallback: parse wpctl status default configured devices
      if (!defaultSource || !defaultSink) {
        var inDefaultsBlock = false
        for (var i=0;i<lines.length;i++) {
          var L = lines[i]
          if (L.indexOf('Default Configured Devices:') !== -1) {
            inDefaultsBlock = true
            continue
          }
          if (!inDefaultsBlock) continue
          if (!L.trim()) break

          if (!defaultSink) {
            var sinkMatch = L.match(/Audio\/Sink\s+([^\s]+)/)
            if (sinkMatch) defaultSink = sinkMatch[1]
          }
          if (!defaultSource) {
            var sourceMatch = L.match(/Audio\/Source\s+([^\s]+)/)
            if (sourceMatch) defaultSource = sourceMatch[1]
          }
          if (defaultSink && defaultSource) break
        }
      }

      // Prefer node names from wpctl inspect when available
      if (defaultSinkNode) defaultSink = defaultSinkNode
      if (defaultSourceNode) defaultSource = defaultSourceNode

      // Normalize numeric defaults to node names for pw-link compatibility
      if (defaultSink && /^\d+$/.test(defaultSink)) {
        var sinkId = parseInt(defaultSink)
        if (nodeIdToName[sinkId]) defaultSink = nodeIdToName[sinkId]
      }
      if (defaultSource && /^\d+$/.test(defaultSource)) {
        var sourceId = parseInt(defaultSource)
        if (nodeIdToName[sourceId]) defaultSource = nodeIdToName[sourceId]
      }

      // Parse pw-link -l to build a link map (outPort -> [inPorts])
      var linkMap = {}
      var inLinksSection = false
      var currentPort = ""
      for (var i=0;i<lines.length;i++) {
        var L = lines[i]
        if (L.indexOf('=== LINKS ===') !== -1) {
          inLinksSection = true
          continue
        }
        if (L.indexOf('=== OUTPUT_PORTS ===') !== -1) {
          inLinksSection = false
          break
        }
        if (!inLinksSection) continue
        if (!L.trim()) continue

        if (L.indexOf('|->') === -1 && L.indexOf('|<-') === -1 && L.indexOf(':') !== -1) {
          currentPort = L.trim()
          continue
        }

        var outMatch = L.match(/\|->\s*(.+)$/)
        if (outMatch && currentPort) {
          var target = outMatch[1].trim()
          if (!linkMap[currentPort]) linkMap[currentPort] = []
          linkMap[currentPort].push(target)
          continue
        }

        var inMatch = L.match(/\|<-\s*(.+)$/)
        if (inMatch && currentPort) {
          var source = inMatch[1].trim()
          if (!linkMap[source]) linkMap[source] = []
          linkMap[source].push(currentPort)
        }
      }

      // Parse port lists for linking
      var outputPortsByNode = {}
      var inputPortsByNode = {}
      var inOutputPorts = false
      var inInputPorts = false
      for (var i=0;i<lines.length;i++) {
        var L = lines[i]
        if (L.indexOf('=== OUTPUT_PORTS ===') !== -1) {
          inOutputPorts = true
          inInputPorts = false
          continue
        }
        if (L.indexOf('=== INPUT_PORTS ===') !== -1) {
          inOutputPorts = false
          inInputPorts = true
          continue
        }
        if (!inOutputPorts && !inInputPorts) continue
        if (!L.trim()) continue

        var portLine = L.trim()
        var splitIdx = portLine.indexOf(':')
        if (splitIdx === -1) continue
        var nodeName = portLine.slice(0, splitIdx)
        var portName = portLine

        if (inOutputPorts) {
          if (!outputPortsByNode[nodeName]) outputPortsByNode[nodeName] = []
          outputPortsByNode[nodeName].push(portName)
        }
        if (inInputPorts) {
          if (!inputPortsByNode[nodeName]) inputPortsByNode[nodeName] = []
          inputPortsByNode[nodeName].push(portName)
        }
      }
      
      if (root.mode === 'out') {
        // For output devices, parse Sinks section
        var wantStart = 'Sinks:'
        var wantEnd = 'Sources:'
        var inBlock = false
        for (var i=0;i<lines.length;i++) {
          var L = lines[i]
          if (L.indexOf(wantStart) !== -1) { inBlock = true; continue }
          if (inBlock && L.indexOf(wantEnd) !== -1) { break }
          if (!inBlock) continue
          // match lines like: "  * 42. Device Name [vol: 0.56]"
          var m = L.match(/^[\s│]*([* ])\s*([0-9]+)\.?\s+(.*?)(?:\s+\[vol:.*)?$/)
          if (m) {
            var isDef = (m[1] === '*')
            var id = parseInt(m[2])
            var name = root.friendlyDeviceName((m[3] || '').trim())
            var nodeName = nodeIdToName[id] || ''
            if (name) out.push({ id: id, name: name, isDefault: isDef, isMonitor: false, pactlName: '', nodeName: nodeName })
          }
        }
      } else {
        // For input devices, parse regular sources, filter sources, and monitor sources
        
        // Parse pactl list sources short to get all available sources with their internal names
        var pactlSources = {}  // Map: wpctl_id -> {name, description, isMonitor}
        var inSourcesList = false
        for (var i=0;i<lines.length;i++) {
          var L = lines[i]
          if (L.indexOf('=== SOURCES ===') !== -1) {
            inSourcesList = true
            continue
          }
          if (!inSourcesList) continue
          
          // Format: "ID\tNAME\tMODULE\tSTATE"
          // Example: "45	alsa_output.pci-0000_0b_00.4.analog-stereo.monitor	module-alsa-card	SUSPENDED"
          var parts = L.split(/\t+/)
          if (parts.length >= 2) {
            var srcId = parts[0].trim()
            var srcName = parts[1].trim()
            var isMonitor = srcName.endsWith('.monitor')
            pactlSources[srcName] = { id: srcId, name: srcName, isMonitor: isMonitor }
          }
        }
        
        // Parse wpctl status to get device descriptions and IDs
        var sourcesStart = 'Sources:'
        var sourcesEnd = 'Filters:'
        var inSourcesBlock = false
        var wpctlToName = {}  // Map wpctl id to description
        
        for (var i=0;i<lines.length;i++) {
          var L = lines[i]
          if (L.indexOf(sourcesStart) !== -1) { inSourcesBlock = true; continue }
          if (inSourcesBlock && L.indexOf(sourcesEnd) !== -1) { break }
          if (!inSourcesBlock) continue
          
          // match lines like: "  * 42. Device Name [vol: 0.56]"
          var m = L.match(/^[\s│]*([* ])\s*([0-9]+)\.?\s+(.*?)(?:\s+\[vol:.*)?$/)
          if (m) {
            var isDef = (m[1] === '*')
            var wpctlId = parseInt(m[2])
            var description = root.friendlyDeviceName((m[3] || '').trim())
            wpctlToName[wpctlId] = description
            
            // Add regular sources
            var nodeName = nodeIdToName[wpctlId] || ''
            out.push({ 
              id: wpctlId, 
              name: description, 
              isDefault: isDef, 
              isMonitor: false,
              pactlName: '',
              nodeName: nodeName
            })
          }
        }
        
        // Parse filter nodes (Audio/Source) from Filters section
        var filtersStart = 'Filters:'
        var filtersEnd = 'Streams:'
        var inFiltersBlock = false
        for (var i=0;i<lines.length;i++) {
          var L = lines[i]
          if (L.indexOf(filtersStart) !== -1) { inFiltersBlock = true; continue }
          if (inFiltersBlock && L.indexOf(filtersEnd) !== -1) { break }
          if (!inFiltersBlock) continue

          // match lines like: "  40. output.filter-chain-... [Audio/Source]"
          var f = L.match(/^[\s│]*([* ]?)\s*([0-9]+)\.\s+(.*?)(?:\s+\[([^\]]+)\])?$/)
          if (f) {
            var filterId = parseInt(f[2])
            var filterLabel = (f[3] || '').trim()
            var mediaClass = (f[4] || '')
            if (mediaClass.indexOf('Audio/Source') !== -1) {
              var filterNodeName = nodeIdToName[filterId] || ''
              var filterDesc = nodeIdToDescription[filterId] || ''
              var isFilterDefault = filterNodeName && (defaultSource === filterNodeName)
              out.push({
                id: filterId,
                name: filterDesc || filterLabel || filterNodeName,
                isDefault: isFilterDefault,
                isMonitor: false,
                pactlName: '',
                nodeName: filterNodeName
              })
            }
          }
        }

        // Build a map of sink node names to their friendly descriptions
        // We need to run wpctl inspect for each sink to get node.name
        var sinkNodeNames = {}  // Map: node.name -> friendly description
        var sinkStart = 'Sinks:'
        var sinkEnd = 'Sources:'
        var inSinkBlock = false
        
        for (var i=0;i<lines.length;i++) {
          var L = lines[i]
          if (L.indexOf(sinkStart) !== -1) { inSinkBlock = true; continue }
          if (inSinkBlock && L.indexOf(sinkEnd) !== -1) { break }
          if (!inSinkBlock) continue
          
          // Match sink entries
          var sinkMatch = L.match(/^[\s│]*[* ]\s*([0-9]+)\.?\s+(.*?)(?:\s+\[vol:.*)?$/)
          if (sinkMatch) {
            var sinkId = parseInt(sinkMatch[1])
            var sinkDesc = root.friendlyDeviceName(sinkMatch[2].trim())
            // We'll use a heuristic: extract key identifiers from the sink description
            // and match them with pactl source names
            sinkNodeNames[sinkDesc] = sinkDesc
          }
        }
        
        // Now add monitor sources from pactl list
        for (var pactlName in pactlSources) {
          var srcInfo = pactlSources[pactlName]
          if (srcInfo.isMonitor) {
            // Extract parent device name from monitor source name
            // Example: "alsa_output.pci-0000_0b_00.4.analog-stereo.monitor" -> "alsa_output.pci-0000_0b_00.4.analog-stereo"
            var parentName = pactlName.replace('.monitor', '')
            
            // Try to find a friendly name by matching key parts of the pactl name
            var friendlyName = null
            
            // Match patterns for common devices
            if (pactlName.indexOf('bluez_output') !== -1) {
              // Bluetooth device
              for (var sinkDesc in sinkNodeNames) {
                if (sinkDesc.toLowerCase().indexOf('airpods') !== -1 || 
                    sinkDesc.toLowerCase().indexOf('bluetooth') !== -1) {
                  friendlyName = sinkDesc + " (Monitor)"
                  break
                }
              }
            } else if (pactlName.indexOf('qudelix') !== -1 || pactlName.indexOf('Qudelix') !== -1) {
              // Qudelix device
              for (var sinkDesc in sinkNodeNames) {
                if (sinkDesc.toLowerCase().indexOf('qudelix') !== -1) {
                  friendlyName = sinkDesc + " (Monitor)"
                  break
                }
              }
            } else if (pactlName.indexOf('hdmi') !== -1) {
              // HDMI device
              for (var sinkDesc in sinkNodeNames) {
                if (sinkDesc.toLowerCase().indexOf('hdmi') !== -1) {
                  friendlyName = sinkDesc + " (Monitor)"
                  break
                }
              }
            } else if (pactlName.indexOf('pci') !== -1) {
              // PCI sound card
              for (var sinkDesc in sinkNodeNames) {
                if (sinkDesc.toLowerCase().indexOf('starship') !== -1 || 
                    sinkDesc.toLowerCase().indexOf('analog') !== -1) {
                  friendlyName = sinkDesc + " (Monitor)"
                  break
                }
              }
            } else if (pactlName.indexOf('aloop') !== -1 || pactlName.indexOf('loopback') !== -1) {
              friendlyName = "Loopback (Monitor)"
            }
            
            // Fallback: use the pactl name
            if (!friendlyName) {
              friendlyName = root.friendlyDeviceName(parentName.replace(/_/g, ' ')) + " (Monitor)"
            }
            
            // Check if this monitor is the default source
            var isMonitorDefault = (defaultSource === pactlName)
            
            out.push({
              id: -1,  // No wpctl ID for monitor sources
              name: friendlyName,
              isDefault: isMonitorDefault,
              isMonitor: true,
              pactlName: pactlName,
              nodeName: ''
            })
          }
        }
      }
      
      // de-dup by name (prefer entries with real IDs)
      var seen = {}
      var finalArr = []
      for (var j=0;j<out.length;j++) { 
        var rec = out[j]
        var key = rec.isMonitor ? rec.pactlName : rec.id.toString()
        if (!seen[key]) { 
          seen[key] = true
          finalArr.push(rec) 
        } 
      }

      // Attach link status for each device
      for (var k=0;k<finalArr.length;k++) {
        var d = finalArr[k]
        d.isFilterLinked = false
        d.isSinkLinked = false
        if (!d.nodeName) continue

        var outPrefix = d.nodeName + ':'
        for (var outPort in linkMap) {
          if (outPort.indexOf(outPrefix) !== 0) continue
          var targets = linkMap[outPort] || []
          for (var t=0;t<targets.length;t++) {
            var targetPort = targets[t]
            if (filterInputNodeName && targetPort.indexOf(filterInputNodeName + ':input_') === 0) {
              d.isFilterLinked = true
            }
            if (root.mode === 'in' && defaultSink && targetPort.indexOf(defaultSink + ':playback_') === 0) {
              d.isSinkLinked = true
            }
          }
        }

        if (root.mode === 'out' && defaultSink && d.nodeName) {
          var defaultSinkPrefix = defaultSink + ':monitor_'
          for (var srcPort in linkMap) {
            if (srcPort.indexOf(defaultSinkPrefix) !== 0) continue
            var sinkTargets = linkMap[srcPort] || []
            for (var st=0;st<sinkTargets.length;st++) {
              var sinkPort = sinkTargets[st]
              if (sinkPort.indexOf(d.nodeName + ':playback_') === 0) {
                d.isSinkLinked = true
              }
            }
          }
        }
      }

      root._filterInputNodeName = filterInputNodeName
      root._defaultSinkNodeName = defaultSink
      root._outputPortsByNodeName = outputPortsByNode
      root._inputPortsByNodeName = inputPortsByNode
      devices = finalArr
    } catch(e) {
      console.log("Error parsing audio devices:", e)
      devices = []
    }
  }

  // Set default device
  Process {
    id: setDefaultProc
    running: false
    stdout: SplitParser {
      onRead: function(data) {
        console.log("setDefaultProc output:", data.toString())
      }
    }
    stderr: SplitParser {
      onRead: function(data) {
        console.log("setDefaultProc error:", data.toString())
      }
    }
    onExited: function(code){ 
      console.log("setDefaultProc exited with code:", code)
      if (root.mode === 'out') AudioOutput.refreshDeviceIcon(); else AudioInput.refreshDeviceIcon(); 
    }
  }


  function setDefault(deviceInfo) {
    if (!deviceInfo) return
    
    setDefaultProc.running = false
    
    if (deviceInfo.isMonitor && deviceInfo.pactlName) {
      // Monitor source - use pactl with the full source name
      console.log("Setting monitor source as default:", deviceInfo.pactlName)
      setDefaultProc.command = ["sh","-c", `pactl set-default-source "${deviceInfo.pactlName}" 2>/dev/null && echo "Set default source to: ${deviceInfo.pactlName}"`]
      setDefaultProc.running = true
    } else if (deviceInfo.id && deviceInfo.id > 0) {
      // Regular source/sink - use wpctl set-default
      console.log("Setting regular device as default:", deviceInfo.id)
      setDefaultProc.command = ["sh","-c", `wpctl set-default ${deviceInfo.id} 2>/dev/null && wpctl status 2>/dev/null`]
      setDefaultProc.running = true
    }
    
    // Refresh list to reflect new default
    Qt.callLater(function() { refresh() })
  }

  // Toggle linking between a source and the DeepFilterNet input
  function toggleFilter(deviceInfo) {
    if (!deviceInfo || !deviceInfo.nodeName || !root._filterInputNodeName) return

    var srcPorts = root._getOutputPorts(deviceInfo.nodeName)
    var dstPorts = root._getInputPortsForFilter(root._filterInputNodeName)
    var remove = deviceInfo.isFilterLinked
    var parts = []

    console.log("[AudioDevicesTooltip] toggleFilter", JSON.stringify({
      device: deviceInfo.name,
      nodeName: deviceInfo.nodeName,
      filterNode: root._filterInputNodeName,
      remove: remove,
      srcPorts: srcPorts,
      dstPorts: dstPorts
    }))

    parts = parts.concat(root._buildLinkCommands(srcPorts, dstPorts, remove))

    console.log("[AudioDevicesTooltip] pw-link", parts.join("; "))

    setDefaultProc.running = false
    setDefaultProc.command = ["sh","-c", parts.join("; ")]
    setDefaultProc.running = true
    Qt.callLater(function() { refresh() })
  }

  // Toggle piping a source directly into the default sink
  function toggleToSink(deviceInfo) {
    if (!deviceInfo || !deviceInfo.nodeName || !root._defaultSinkNodeName) return

    var srcPorts = root._getOutputPorts(deviceInfo.nodeName)
    var dstPorts = root._getInputPortsForSink(root._defaultSinkNodeName)
    var remove = deviceInfo.isSinkLinked
    var parts = []

    console.log("[AudioDevicesTooltip] toggleToSink", JSON.stringify({
      device: deviceInfo.name,
      nodeName: deviceInfo.nodeName,
      defaultSink: root._defaultSinkNodeName,
      remove: remove,
      srcPorts: srcPorts,
      dstPorts: dstPorts
    }))

    parts = parts.concat(root._buildLinkCommands(srcPorts, dstPorts, remove))

    console.log("[AudioDevicesTooltip] pw-link", parts.join("; "))

    setDefaultProc.running = false
    setDefaultProc.command = ["sh","-c", parts.join("; ")]
    setDefaultProc.running = true
    Qt.callLater(function() { refresh() })
  }

  // Toggle piping the default sink into another sink
  function toggleFromDefaultSinkToSink(deviceInfo) {
    if (!deviceInfo || !deviceInfo.nodeName || !root._defaultSinkNodeName) return

    var srcPorts = root._getOutputPortsForSink(root._defaultSinkNodeName)
    var dstPorts = root._getInputPortsForSink(deviceInfo.nodeName)
    var remove = deviceInfo.isSinkLinked
    var parts = []

    console.log("[AudioDevicesTooltip] toggleFromDefaultSinkToSink", JSON.stringify({
      device: deviceInfo.name,
      nodeName: deviceInfo.nodeName,
      defaultSink: root._defaultSinkNodeName,
      remove: remove,
      srcPorts: srcPorts,
      dstPorts: dstPorts
    }))

    parts = parts.concat(root._buildLinkCommands(srcPorts, dstPorts, remove))

    console.log("[AudioDevicesTooltip] pw-link", parts.join("; "))

    setDefaultProc.running = false
    setDefaultProc.command = ["sh","-c", parts.join("; ")]
    setDefaultProc.running = true
    Qt.callLater(function() { refresh() })
  }

  // Internal state
  property string _filterInputNodeName: ""
  property string _defaultSinkNodeName: ""
  property var _outputPortsByNodeName: ({})
  property var _inputPortsByNodeName: ({})

  function _getOutputPorts(nodeName) {
    var ports = root._outputPortsByNodeName[nodeName]
    if (ports && ports.length > 0) return ports
    return [nodeName + ":capture_MONO", nodeName + ":capture_FL", nodeName + ":capture_FR"]
  }

  function _getInputPorts(nodeName) {
    var ports = root._inputPortsByNodeName[nodeName]
    if (ports && ports.length > 0) return ports
    return [nodeName + ":input_FL", nodeName + ":input_FR", nodeName + ":playback_FL", nodeName + ":playback_FR"]
  }

  function _filterPorts(ports, substr) {
    if (!ports || ports.length === 0) return []
    var filtered = []
    for (var i=0;i<ports.length;i++) {
      if (ports[i].indexOf(substr) !== -1) filtered.push(ports[i])
    }
    return filtered.length > 0 ? filtered : ports
  }

  function _getInputPortsForFilter(nodeName) {
    var ports = root._getInputPorts(nodeName)
    return root._filterPorts(ports, ":input_")
  }

  function _getInputPortsForSink(nodeName) {
    var ports = root._getInputPorts(nodeName)
    return root._filterPorts(ports, ":playback_")
  }

  function _getOutputPortsForSink(nodeName) {
    var ports = root._getOutputPorts(nodeName)
    return root._filterPorts(ports, ":monitor_")
  }

  function _buildLinkCommands(srcPorts, dstPorts, remove) {
    var cmds = []
    if (!srcPorts || !dstPorts || srcPorts.length === 0 || dstPorts.length === 0) return cmds

    console.log("[AudioDevicesTooltip] buildLinkCommands", JSON.stringify({
      remove: remove,
      srcPorts: srcPorts,
      dstPorts: dstPorts
    }))

    var monoSrc = srcPorts.length === 1
    if (monoSrc) {
      for (var i=0;i<dstPorts.length;i++) {
        cmds.push(`pw-link ${remove ? '-d ' : ''}"${srcPorts[0]}" "${dstPorts[i]}"`)
      }
      return cmds
    }

    var srcBySuffix = {}
    for (var s=0;s<srcPorts.length;s++) {
      if (srcPorts[s].indexOf('_FL') !== -1) srcBySuffix.FL = srcPorts[s]
      if (srcPorts[s].indexOf('_FR') !== -1) srcBySuffix.FR = srcPorts[s]
      if (srcPorts[s].indexOf('_MONO') !== -1) srcBySuffix.MONO = srcPorts[s]
    }

    for (var d=0;d<dstPorts.length;d++) {
      var dst = dstPorts[d]
      if (dst.indexOf('_FL') !== -1 && srcBySuffix.FL) {
        cmds.push(`pw-link ${remove ? '-d ' : ''}"${srcBySuffix.FL}" "${dst}"`)
        continue
      }
      if (dst.indexOf('_FR') !== -1 && srcBySuffix.FR) {
        cmds.push(`pw-link ${remove ? '-d ' : ''}"${srcBySuffix.FR}" "${dst}"`)
        continue
      }
      if (srcBySuffix.MONO) {
        cmds.push(`pw-link ${remove ? '-d ' : ''}"${srcBySuffix.MONO}" "${dst}"`)
      }
    }

    return cmds
  }

  // Merge debug logging into initial completion handler
  Component.onCompleted: {
    if (expanded) refresh()
    if (debugLayout) console.log('[AudioDevicesTooltip] implicitWidth', implicitWidth, 'column', column.implicitWidth)
  }
  onImplicitWidthChanged: if (debugLayout) console.log('[AudioDevicesTooltip] width change', implicitWidth, 'col', column.implicitWidth)

  Column {
    // Visual debug when enabled
    Rectangle { visible: debugLayout; anchors.fill: parent; color: 'transparent'; border.color: 'magenta'; border.width: 1; z: -1 }

    id: column
    spacing: 6
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.topMargin: root.vPadding - 2
    anchors.leftMargin: root.hPadding
    anchors.rightMargin: root.hPadding
    opacity: expanded ? Colors.opacity.foreground1 : 0
    Behavior on opacity { NumberAnimation { duration: 120 } }

    Text { text: root.mode === 'out' ? 'Output Devices' : 'Input Devices'; font.pixelSize: 13; font.weight: Font.DemiBold; color: PopoutConfig.textColor }

    Repeater {
      model: root.devices.length
      delegate: Item {
        implicitWidth: row.implicitWidth
        height: 22
        width: parent.width
        property var rec: root.devices[index]

        PipewireLevelMonitor {
          id: deviceLevelMonitor
          nodeId: rec && rec.id && rec.id > 0 ? rec.id : -1
          nodeName: rec && rec.nodeName ? rec.nodeName : ""
          enabled: root.expanded
          monitorSink: root.mode === 'out'
          isDefault: rec && rec.isDefault
        }

        HoverHandler { }
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: if (root.mode === 'out') root.setDefault(rec)
        }

        Row {
          id: row
          spacing: 8
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          Rectangle {
            id: defaultIndicator
            width: 10
            height: 10
            radius: 5
            visible: root.mode === 'out'
            color: rec && rec.isDefault ? Colors.foregroundCyan : Colors.primaryTransparent
            border.width: 1
            border.color: Colors.foregroundCyan
          }
          Rectangle {
            id: outputLinkButton
            width: 10
            height: 10
            radius: 5
            visible: root.mode === 'out' && rec && rec.id > 0
            color: rec && rec.isSinkLinked ? Colors.foregroundCyan : Colors.primaryTransparent
            border.width: 1
            border.color: Colors.foregroundCyan
            HoverHandler { }
            MouseArea {
              anchors.fill: parent
              onClicked: root.toggleFromDefaultSinkToSink(rec)
              cursorShape: Qt.PointingHandCursor
            }
          }
          Row {
            id: actionsRow
            spacing: 6
            visible: root.mode === 'in' && rec && rec.id > 0

            Rectangle {
              id: defaultButton
              width: 10
              height: 10
              radius: 5
              color: rec && rec.isDefault ? Colors.foregroundCyan : Colors.primaryTransparent
              border.width: 1
              border.color: Colors.foregroundCyan
              HoverHandler { }
              MouseArea {
                anchors.fill: parent
                onClicked: root.setDefault(rec)
                cursorShape: Qt.PointingHandCursor
              }
            }

            Rectangle {
              id: filterButton
              width: 10
              height: 10
              radius: 5
              color: rec && rec.isFilterLinked ? Colors.foregroundCyan : Colors.primaryTransparent
              border.width: 1
              border.color: Colors.foregroundCyan
              opacity: rec && rec.nodeName && rec.nodeName.indexOf('output.filter-chain-') === 0 ? 0.35 : 1
              HoverHandler { }
              MouseArea {
                anchors.fill: parent
                enabled: !(rec && rec.nodeName && rec.nodeName.indexOf('output.filter-chain-') === 0)
                onClicked: root.toggleFilter(rec)
                cursorShape: Qt.PointingHandCursor
              }
            }

            Rectangle {
              id: sinkButton
              width: 10
              height: 10
              radius: 5
              color: rec && rec.isSinkLinked ? Colors.foregroundCyan : Colors.primaryTransparent
              border.width: 1
              border.color: Colors.foregroundCyan
              HoverHandler { }
              MouseArea {
                anchors.fill: parent
                onClicked: root.toggleToSink(rec)
                cursorShape: Qt.PointingHandCursor
              }
            }
          }
          Text {
            id: nameText
            text: rec ? rec.name : ""
            color: PopoutConfig.textColor
            font.pixelSize: 12
            elide: Text.ElideRight
            width: Math.max(60, row.width - (actionsRow.visible ? actionsRow.width : (defaultIndicator.width + (outputLinkButton.visible ? outputLinkButton.width : 0) + 6)) - 12)
          }
        }

        Rectangle {
          id: levelTrack
          width: parent.width
          height: 3
          radius: height / 2
          color: Qt.rgba(1, 1, 1, 0.12)
          opacity: rec && rec.id > 0 ? 1 : 0.35
          anchors.bottom: parent.bottom
          Rectangle {
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            width: parent.width * Math.min(1, deviceLevelMonitor.level)
            radius: parent.radius
            color: root.mode === 'out' ? Colors.foregroundCyan : Colors.foregroundRed
            visible: width > 0
          }
        }
      }
    }
    Text { text: root.devices.length === 0 ? 'No devices found' : ''; font.pixelSize: 12; color: PopoutConfig.textColor }
  }
}
