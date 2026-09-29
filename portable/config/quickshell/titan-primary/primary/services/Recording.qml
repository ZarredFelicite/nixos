pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool isRecording: false
    property string recordingFilename: ""
    property string recordingPid: ""
    property var availableMonitors: []
    readonly property bool lowPowerMode: Quickshell.env("QUICKSHELL_LOW_POWER_MODE") === "1"
    readonly property int recordingPollIntervalMs: lowPowerMode ? 3000 : 1000

    readonly property string tooltipText: isRecording ? 
        `Recording: ${recordingFilename}` : "Not recording"

    property int refCount: 0
    
    // Load available monitors on startup
    Component.onCompleted: {
        root.getAllMonitors(function(monitors) {
            root.availableMonitors = monitors
        })
    }


    // Generate timestamp for filenames: YYYY-MM-DD-HHMMSS
    function getTimestamp() {
        const now = new Date()
        const year = now.getFullYear()
        const month = String(now.getMonth() + 1).padStart(2, '0')
        const day = String(now.getDate()).padStart(2, '0')
        const hours = String(now.getHours()).padStart(2, '0')
        const minutes = String(now.getMinutes()).padStart(2, '0')
        const seconds = String(now.getSeconds()).padStart(2, '0')
        return `${year}-${month}-${day}-${hours}${minutes}${seconds}`
    }

    Timer {
        id: updateTimer
        interval: root.recordingPollIntervalMs  // Process-state polling; event-driven refresh remains immediate
        running: root.refCount > 0
        repeat: true
        triggeredOnStart: true
        onTriggered: root.checkRecording()
    }

    function checkRecording() {
        // Check for wf-recorder process
        const proc = Qt.createQmlObject(
            'import Quickshell.Io; Process { running: false; stdout: SplitParser { onRead: function(data) { } } }',
            root
        )
        proc.command = ["pgrep", "-f", "wf-recorder"]
        
        var output = ""
        proc.stdout.onRead.connect(function(data) {
            output += data.toString()
        })
        
        proc.onExited.connect(function(code) {
            if (code === 0 && output.trim().length > 0) {
                // Process found, extract recording details
                root.recordingPid = output.trim().split('\n')[0]
                root.isRecording = true
                extractRecordingFilename()
            } else {
                root.isRecording = false
                root.recordingFilename = ""
                root.recordingPid = ""
            }
            proc.destroy()
        })
        
        proc.running = true
    }

    function extractRecordingFilename() {
        // Extract filename from wf-recorder command line
        if (!root.recordingPid) return
        
        const proc = Qt.createQmlObject(
            'import Quickshell.Io; Process { running: false; stdout: SplitParser { onRead: function(data) { } } }',
            root
        )
        proc.command = ["sh", "-c", `ps -ef | grep wf-recorder | grep -v grep | head -n1 | grep -oP '\\-f \\K[^ ]+'`]
        
        var output = ""
        proc.stdout.onRead.connect(function(data) {
            output += data.toString()
        })
        
        proc.onExited.connect(function(code) {
            if (code === 0) {
                root.recordingFilename = output.trim()
            }
            proc.destroy()
        })
        
        proc.running = true
    }

    // Get focused window geometry
    function getFocusedGeometry(callback) {
        const proc = Qt.createQmlObject(
            'import Quickshell.Io; Process { running: false; stdout: SplitParser { onRead: function(data) { } } }',
            root
        )
        proc.command = ["sh", "-c", "hyprctl -j activewindow | jq -r '\"\\(.at[0]),\\(.at[1]) \\(.size[0])x\\(.size[1])\"'"]
        
        var output = ""
        proc.stdout.onRead.connect(function(data) {
            output += data.toString()
        })
        
        proc.onExited.connect(function(code) {
            if (callback) callback(output.trim())
            proc.destroy()
        })
        
        proc.running = true
    }

    // Get list of all monitors
    function getAllMonitors(callback) {
        const proc = Qt.createQmlObject(
            'import Quickshell.Io; Process { running: false; stdout: SplitParser { onRead: function(data) { } } }',
            root
        )
        proc.command = ["hyprctl", "monitors", "-j"]
        
        var output = ""
        proc.stdout.onRead.connect(function(data) {
            output += data.toString()
        })
        
        proc.onExited.connect(function(code) {
            if (code === 0 && output) {
                try {
                    const monitors = JSON.parse(output)
                    const names = monitors.map(m => m.name)
                    if (callback) callback(names)
                } catch (e) {
                    console.log("Failed to parse monitors JSON:", e)
                    if (callback) callback([])
                }
            } else {
                if (callback) callback([])
            }
            proc.destroy()
        })
        
        proc.running = true
    }

    // Get primary monitor name
    function getMonitor(callback) {
        const proc = Qt.createQmlObject(
            'import Quickshell.Io; Process { running: false; stdout: SplitParser { onRead: function(data) { } } }',
            root
        )
        proc.command = ["hyprctl", "monitors", "-j"]
        
        var output = ""
        proc.stdout.onRead.connect(function(data) {
            output += data.toString()
        })
        
        proc.onExited.connect(function(code) {
            if (code === 0 && output) {
                try {
                    const monitors = JSON.parse(output)
                    if (monitors.length > 0) {
                        if (callback) callback(monitors[0].name)
                    }
                } catch (e) {
                    console.log("Failed to parse monitors JSON:", e)
                    if (callback) callback(null)
                }
            } else {
                if (callback) callback(null)
            }
            proc.destroy()
        })
        
        proc.running = true
    }

    // Get audio device name
    function getAudioDevice(callback) {
        const proc = Qt.createQmlObject(
            'import Quickshell.Io; Process { running: false; stdout: SplitParser { onRead: function(data) { } } }',
            root
        )
        proc.command = ["sh", "-c", "wpctl inspect @DEFAULT_SINK@ | grep 'node.name' | grep -oP '\"\\K[^\"]+' | head -1"]
        
        var output = ""
        proc.stdout.onRead.connect(function(data) {
            output += data.toString()
        })
        
        proc.onExited.connect(function(code) {
            if (callback) callback(output.trim())
            proc.destroy()
        })
        
        proc.running = true
    }

    // Get microphone device name
    function getMicDevice(callback) {
        const proc = Qt.createQmlObject(
            'import Quickshell.Io; Process { running: false; stdout: SplitParser { onRead: function(data) { } } }',
            root
        )
        proc.command = ["sh", "-c", "wpctl inspect @DEFAULT_SOURCE@ | grep 'node.name' | grep -oP '\"\\K[^\"]+' | head -1"]
        
        var output = ""
        proc.stdout.onRead.connect(function(data) {
            output += data.toString()
        })
        
        proc.onExited.connect(function(code) {
            if (callback) callback(output.trim())
            proc.destroy()
        })
        
        proc.running = true
    }

    // Screenshot: fullscreen
    function screenshotFullscreen() {
        const filename = "/home/zarred/pictures/screenshots/" + getTimestamp() + "_screenshot.png"
        const proc = Qt.createQmlObject('import Quickshell.Io; Process { }', root)
        proc.command = ["grim", filename]
        proc.running = true
        
        proc.exited.connect(function() {
            notifyScreenshot(filename)
            proc.destroy()
        })
    }

    // Screenshot: fullscreen on specific monitor
    function screenshotFullscreenOnMonitor(monitor) {
        const filename = "/home/zarred/pictures/screenshots/" + getTimestamp() + "_screenshot.png"
        const proc = Qt.createQmlObject('import Quickshell.Io; Process { }', root)
        // Use hyprctl to get the monitor's geometry and pass it to grim
        const geometryProc = Qt.createQmlObject(
            'import Quickshell.Io; Process { running: false; stdout: SplitParser { onRead: function(data) { } } }',
            root
        )
        geometryProc.command = ["sh", "-c", `hyprctl monitors -j | jq -r '.[] | select(.name=="${monitor}") | "\\(.x),\\(.y) \\(.width)x\\(.height)"'`]
        
        var geometry = ""
        geometryProc.stdout.onRead.connect(function(data) {
            geometry += data.toString()
        })
        
        geometryProc.onExited.connect(function(code) {
            if (code === 0 && geometry.trim()) {
                proc.command = ["grim", "-g", geometry.trim(), filename]
                proc.running = true
                
                proc.exited.connect(function() {
                    notifyScreenshot(filename)
                    proc.destroy()
                })
            }
            geometryProc.destroy()
        })
        
        geometryProc.running = true
    }

    // Screenshot: focused window
    function screenshotFocused() {
        root.getFocusedGeometry(function(geometry) {
            if (!geometry) {
                notifyError("Failed to get window geometry")
                return
            }
            
            const filename = "/home/zarred/pictures/screenshots/" + getTimestamp() + "_screenshot.png"
            const proc = Qt.createQmlObject('import Quickshell.Io; Process { }', root)
            proc.command = ["grim", "-g", geometry, filename]
            proc.running = true
            
            proc.exited.connect(function() {
                notifyScreenshot(filename)
                proc.destroy()
            })
        })
    }

    // Screenshot: region (user selects with slurp)
    function screenshotRegion() {
        const filename = "/home/zarred/pictures/screenshots/" + getTimestamp() + "_screenshot.png"
        const basename = filename.split('/').pop()
        const scriptPath = "/home/zarred/.config/quickshell/primary/scripts/screenshot-handler.sh"
        const proc = Qt.createQmlObject(
            'import Quickshell.Io; Process { running: false; stdout: SplitParser { onRead: function(data) { } } }',
            root
        )
        // Run slurp in background to avoid blocking parent process
        proc.command = ["sh", "-c", `(slurp | grim -g - "${filename}" && notify-send "Screenshot" "Saved as <i>'${basename}'</i>\\n${filename}" -i "${filename}" --action=default=Open && "${scriptPath}" "${filename}") &`]
        
        proc.onExited.connect(function(code) {
            // Background process launched
            proc.destroy()
        })
        
        proc.running = true
        
        // Close menu since process runs in background
        screenshotCompleted()
    }

    // Screenshot: selected window
    function screenshotWindow() {
        const proc = Qt.createQmlObject(
            'import Quickshell.Io; Process { running: false; stdout: SplitParser { onRead: function(data) { } } }',
            root
        )
        proc.command = ["sh", "-c", "hyprctl clients -j | jq -r '.[] | select(.workspace.id == '$(hyprctl activewindow -j | jq -r '.workspace.id')') | \"\\(.at[0]),\\(.at[1]) \\(.size[0])x\\(.size[1])\"' | slurp -r"]
        
        var output = ""
        proc.stdout.onRead.connect(function(data) {
            output += data.toString()
        })
        
        proc.onExited.connect(function(code) {
            if (code === 0 && output.trim()) {
                const filename = "/home/zarred/pictures/screenshots/" + getTimestamp() + "_screenshot.png"
                const grimProc = Qt.createQmlObject('import Quickshell.Io; Process { }', root)
                grimProc.command = ["grim", "-g", output.trim(), filename]
                grimProc.running = true
                
                grimProc.exited.connect(function() {
                    notifyScreenshot(filename)
                    grimProc.destroy()
                })
            }
            proc.destroy()
        })
        
        proc.running = true
    }

    // Record: fullscreen
    function recordFullscreen(recordMic) {
        root.getMonitor(function(monitor) {
            if (!monitor) {
                notifyError("Failed to get monitor")
                return
            }
            
            root.getAudioDevice(function(audioDevice) {
                if (!audioDevice) {
                    notifyError("Failed to get audio device")
                    return
                }
                
                const filename = "/home/zarred/pictures/screencaptures/" + getTimestamp() + "_screencapture.mkv"
                const proc = Qt.createQmlObject('import Quickshell.Io; Process { }', root)
                proc.command = ["wf-recorder", "--audio-backend=pipewire", "--audio", audioDevice, "-o", monitor, "-f", filename]
                proc.onExited.connect(function() { proc.destroy() })
                proc.running = true
            
            if (recordMic) {
                root.getMicDevice(function(micDevice) {
                    if (micDevice) {
                        const micFile = filename.replace('.mkv', '_mic.wav')
                        const micProc = Qt.createQmlObject('import Quickshell.Io; Process { }', root)
                        micProc.command = ["sh", "-c", `sleep 0.5 && setsid pw-record --target ${micDevice} ${micFile} &`]
                        micProc.onExited.connect(function() { micProc.destroy() })
                        micProc.running = true
                    }
                })
            }
            
            notifyRecordingStarted(filename)
            root.checkRecording()
            })
        })
    }

    // Record: fullscreen on specific monitor
    function recordFullscreenOnMonitor(monitor, recordMic) {
        root.getAudioDevice(function(audioDevice) {
            if (!audioDevice) {
                notifyError("Failed to get audio device")
                return
            }
            
            const filename = "/home/zarred/pictures/screencaptures/" + getTimestamp() + "_screencapture.mkv"
            const proc = Qt.createQmlObject('import Quickshell.Io; Process { }', root)
            proc.command = ["wf-recorder", "--audio-backend=pipewire", "--audio", audioDevice, "-o", monitor, "-f", filename]
            proc.onExited.connect(function() { proc.destroy() })
            proc.running = true
            
            if (recordMic) {
                root.getMicDevice(function(micDevice) {
                    if (micDevice) {
                        const micFile = filename.replace('.mkv', '_mic.wav')
                        const micProc = Qt.createQmlObject('import Quickshell.Io; Process { }', root)
                        micProc.command = ["sh", "-c", `sleep 0.5 && setsid pw-record --target ${micDevice} ${micFile} &`]
                        micProc.onExited.connect(function() { micProc.destroy() })
                        micProc.running = true
                    }
                })
            }
            
            notifyRecordingStarted(filename)
            root.checkRecording()
        })
    }

    // Record: focused window
    function recordFocused(recordMic) {
        root.getFocusedGeometry(function(geometry) {
            if (!geometry) {
                notifyError("Failed to get window geometry")
                return
            }
            
            root.getAudioDevice(function(audioDevice) {
                if (!audioDevice) {
                    notifyError("Failed to get audio device")
                    return
                }
                
                const filename = "/home/zarred/pictures/screencaptures/" + getTimestamp() + "_screencapture.mkv"
                const proc = Qt.createQmlObject('import Quickshell.Io; Process { }', root)
                proc.command = ["wf-recorder", "--audio-backend=pipewire", "--audio", audioDevice, "-g", geometry, "-f", filename]
                proc.onExited.connect(function() { proc.destroy() })
                proc.running = true
                
                if (recordMic) {
                    root.getMicDevice(function(micDevice) {
                        if (micDevice) {
                            const micFile = filename.replace('.mkv', '_mic.wav')
                            const micProc = Qt.createQmlObject('import Quickshell.Io; Process { }', root)
                            micProc.command = ["sh", "-c", `sleep 0.5 && setsid pw-record --target ${micDevice} ${micFile} &`]
                            micProc.onExited.connect(function() { micProc.destroy() })
                            micProc.running = true
                        }
                    })
                }
                
                notifyRecordingStarted(filename)
                root.checkRecording()
            })
        })
    }

    // Record: region (user selects with slurp)
    function recordRegion(recordMic) {
        root.getAudioDevice(function(audioDevice) {
            if (!audioDevice) {
                notifyError("Failed to get audio device")
                return
            }
            
            const filename = "/home/zarred/pictures/screencaptures/" + getTimestamp() + "_screencapture.mkv"
            const basename = filename.split('/').pop()
            const logfile = "/home/zarred/.config/quickshell/primary/region-record.log"
            

            
            const proc = Qt.createQmlObject(
                'import Quickshell.Io; Process { running: false; stdout: SplitParser { onRead: function(data) { } } }',
                root
            )
            
            // Build command with proper shell escaping
            // Use heredoc-style approach to avoid escaping issues
            const shellScript = `
echo "$(date): Starting region recording" >> ${logfile}
region=$(slurp 2>&1)
slurp_exit=$?
echo "$(date): slurp exited with code $slurp_exit, region='$region'" >> ${logfile}

if [ $slurp_exit -eq 0 ] && [ -n "$region" ]; then
    echo "$(date): Region selected successfully, starting wf-recorder" >> ${logfile}
    notify-send "Recording" "Starting region recording..."
    wf-recorder --audio-backend=pipewire --audio "${audioDevice}" -g "$region" -f "${filename}" >> ${logfile} 2>&1 &
    wf_pid=$!
    echo "$(date): wf-recorder started with PID $wf_pid" >> ${logfile}
else
    echo "$(date): Region selection failed or cancelled" >> ${logfile}
    notify-send "Recording" "Region selection cancelled"
fi
`
            
            // Run in background with explicit backgrounding
            proc.command = ["sh", "-c", `(${shellScript}) &`]
            
            proc.onExited.connect(function(code) {
                // Background process launched
                proc.destroy()
            })
            
            proc.running = true
            
            // Check recording status after a delay
            const checkTimer = Qt.createQmlObject('import QtQuick; Timer { interval: 2000; repeat: false }', root)
            checkTimer.triggered.connect(function() {
                console.log("Checking recording status...")
                root.checkRecording()
                checkTimer.destroy()
            })
            checkTimer.start()
        })
    }

    // Record: selected window
    function recordWindow(recordMic) {
        const proc = Qt.createQmlObject(
            'import Quickshell.Io; Process { running: false; stdout: SplitParser { onRead: function(data) { } } }',
            root
        )
        proc.command = ["sh", "-c", "hyprctl clients -j | jq -r '.[] | select(.workspace.id == '$(hyprctl activewindow -j | jq -r '.workspace.id')') | \"\\(.at[0]),\\(.at[1]) \\(.size[0])x\\(.size[1])\"' | slurp -r"]
        
        var output = ""
        proc.stdout.onRead.connect(function(data) {
            output += data.toString()
        })
        
        proc.onExited.connect(function(code) {
            if (code === 0 && output.trim()) {
                root.getAudioDevice(function(audioDevice) {
                    if (!audioDevice) {
                        notifyError("Failed to get audio device")
                        return
                    }
                    
                    const filename = "/home/zarred/pictures/screencaptures/" + getTimestamp() + "_screencapture.mkv"
                    const grimProc = Qt.createQmlObject('import Quickshell.Io; Process { }', root)
                    grimProc.command = ["wf-recorder", "--audio-backend=pipewire", "--audio", audioDevice, "-g", output.trim(), "-f", filename]
                    grimProc.onExited.connect(function() {
                        grimProc.destroy()
                    })
                    grimProc.running = true
                    
                    if (recordMic) {
                        root.getMicDevice(function(micDevice) {
                            if (micDevice) {
                                const micFile = filename.replace('.mkv', '_mic.wav')
                                const micProc = Qt.createQmlObject('import Quickshell.Io; Process { }', root)
                                micProc.command = ["sh", "-c", `sleep 0.5 && setsid pw-record --target ${micDevice} ${micFile} &`]
                                micProc.onExited.connect(function() {
                                    micProc.destroy()
                                })
                                micProc.running = true
                            }
                        })
                    }
                    
                    notifyRecordingStarted(filename)
                    root.checkRecording()
                })
            }
            proc.destroy()
        })
        
        proc.running = true
    }

    // Capture filename before stopping (will be cleared by checkRecording)
    property string stoppedRecordingFilename: ""
    
    // Stop recording
    function stopRecording() {
        if (!root.isRecording) return
        
        // Capture filename NOW before it gets cleared
        root.stoppedRecordingFilename = root.recordingFilename
        console.log("stopRecording: captured filename:", root.stoppedRecordingFilename)
        
        const proc = Qt.createQmlObject('import Quickshell.Io; Process { }', root)
        proc.command = ["pkill", "-2", "wf-recorder"]
        proc.running = true
        
        proc.exited.connect(function() {
            // Stop microphone recording if running
            const micProc = Qt.createQmlObject('import Quickshell.Io; Process { }', root)
            micProc.command = ["pkill", "-2", "-f", "pw-record"]
            micProc.running = true
            
            micProc.exited.connect(function() {
                stopTimer.start()
                micProc.destroy()
            })
            proc.destroy()
        })
    }

    Timer {
        id: stopTimer
        interval: 1000
        onTriggered: {
            // Use the filename we captured in stopRecording()
            root.checkRecording()
            notifyRecordingStopped(root.stoppedRecordingFilename)
        }
    }

    // Signal when screenshot/recording completes (for closing popout)
    signal screenshotCompleted()
    signal recordingCompleted()

    // Notification helpers
    function notifyScreenshot(filename) {
        const basename = filename.split('/').pop()
        const scriptPath = "/home/zarred/.config/quickshell/primary/scripts/screenshot-handler.sh"
        
        const proc = Qt.createQmlObject('import Quickshell.Io; Process { }', root)
        // Show notification with image preview and action button that opens handler menu
        proc.command = ["sh", "-c", `notify-send "Screenshot" "Saved as <i>'${basename}'</i>\\n${filename}" -i "${filename}" --action=default=Open && "${scriptPath}" "${filename}"`]
        proc.onExited.connect(function() { proc.destroy() })
        proc.running = true
        
        // Emit signal to close the popout
        screenshotCompleted()
    }

    function notifyRecordingStarted(filename) {
        const proc = Qt.createQmlObject('import Quickshell.Io; Process { }', root)
        proc.command = ["notify-send", "Recording", `Started: ${filename.split('/').pop()}`]
        proc.onExited.connect(function() { proc.destroy() })
        proc.running = true
    }

    function notifyRecordingStopped(filename) {
        // Use passed filename parameter instead of property (which gets cleared)
        const recordingFilename = filename || root.recordingFilename
        
        console.log("notifyRecordingStopped called with:", filename, "current recordingFilename:", root.recordingFilename)
        
        if (!recordingFilename) {
            console.log("No recording filename available, showing generic notification")
            const proc = Qt.createQmlObject('import Quickshell.Io; Process { }', root)
            proc.command = ["notify-send", "Recording", "Stopped"]
            proc.onExited.connect(function() { proc.destroy() })
            proc.running = true
            return
        }

        const basename = recordingFilename.split('/').pop()
        const thumbnailPath = recordingFilename.replace('.mkv', '_thumb.jpg')
        const scriptPath = "/home/zarred/.config/quickshell/primary/scripts/recording-handler.sh"
        
        console.log("Extracting thumbnail from:", recordingFilename)
        console.log("Thumbnail path:", thumbnailPath)
        
        // Extract first frame as thumbnail using ffmpeg
        const extractProc = Qt.createQmlObject(
            'import Quickshell.Io; Process { running: false; stdout: SplitParser { onRead: function(data) { } } }',
            root
        )
        
        extractProc.command = ["sh", "-c", `ffmpeg -i "${recordingFilename}" -vframes 1 -update 1 "${thumbnailPath}" -y 2>&1`]
        
        var ffmpegOutput = ""
        extractProc.stdout.onRead.connect(function(data) {
            ffmpegOutput += data.toString()
        })
        
        extractProc.onExited.connect(function(code) {
            console.log("ffmpeg extraction exited with code:", code)
            if (code !== 0) {
                console.log("ffmpeg error output:", ffmpegOutput.substring(0, 500))
            }
            
            // Show notification with thumbnail and action button
            const notifyProc = Qt.createQmlObject('import Quickshell.Io; Process { }', root)
            
            if (code === 0) {
                console.log("Showing notification WITH thumbnail")
                notifyProc.command = ["sh", "-c", `notify-send "Recording" "Saved as <i>'${basename}'</i>\\n${recordingFilename}" -i "${thumbnailPath}" --action=default=Open && "${scriptPath}" "${recordingFilename}"`]
            } else {
                console.log("Showing notification WITHOUT thumbnail (ffmpeg failed)")
                notifyProc.command = ["sh", "-c", `notify-send "Recording" "Saved as <i>'${basename}'</i>\\n${recordingFilename}" --action=default=Open && "${scriptPath}" "${recordingFilename}"`]
            }
            
            notifyProc.onExited.connect(function() { notifyProc.destroy() })
            notifyProc.running = true
            
            extractProc.destroy()
        })
        
        extractProc.running = true
    }

    function notifyError(message) {
        const proc = Qt.createQmlObject('import Quickshell.Io; Process { }', root)
        proc.command = ["notify-send", "Error", message, "-u", "critical"]
        proc.onExited.connect(function() { proc.destroy() })
        proc.running = true
    }

    // Allow external signal to trigger immediate check
    function refresh() {
        checkRecording()
    }
}
