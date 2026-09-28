pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import "../../../services"
import "../../../widgets"

Item {
    id: root

    required property Item wrapper

    anchors.centerIn: parent

    // Determine if the active child supplies its own background so we can suppress outer padding
    function activeChild() { return content.children.find(c => c.shouldBeActive) }
    function activeHasOwnBg() {
        const child = activeChild();
        return child && child.item && child.item.hasOwnBackground;
    }
    // Measure the loaded item's implicit size, not the Loader's (Loader implicit* often 0)
    implicitWidth: ((activeChild()?.item?.implicitWidth) || 0) + (activeHasOwnBg() ? 0 : 32)
    implicitHeight: ((activeChild()?.item?.implicitHeight) || 0) + (activeHasOwnBg() ? 0 : 32)

    Rectangle {
        anchors.fill: parent
        // Hide outer background if inner popout supplies its own background
        visible: !(content.children.some(c => c.shouldBeActive && c.item && c.item.hasOwnBackground))
        color: PopoutConfig.backgroundColor
        radius: PopoutConfig.cornerRadius
        border.width: PopoutConfig.borderWidth
        border.color: PopoutConfig.borderColor
    }

    // Mouse hover detection moved to TrayMenu.qml

    Item {
        id: content

        anchors.fill: parent
        anchors.margins: root.activeHasOwnBg() ? 0 : 16

        // Bluetooth tooltip popout (overlay)
        Popout {
            id: bluetoothTooltip
            name: "bluetooth"
            sourceComponent: Component {
                BluetoothTooltip {
                    wrapper: root.wrapper
                }
            }
        }
        Popout {
            id: notificationsTooltip
            name: "notifications"
            sourceComponent: Component {
                NotificationsPanel {
                    wrapper: root.wrapper
                }
            }
        }
        // Network tooltip popout
        Popout {
            id: networkTooltip
            name: "network"
            sourceComponent: Component {
                NetworkTooltip {
                    wrapper: root.wrapper
                }
            }
        }
        // AI settings popout
        Popout {
            id: aiSettingsPopout
            name: "ai-settings"
            sourceComponent: Component {
                AiSettingsPopout {
                    wrapper: root.wrapper
                }
            }
        }

        // Home Assistant Beam lights menu
        Popout {
            id: homeAssistantMenu
            name: "home-assistant"
            sourceComponent: Component {
                HomeAssistantMenu {
                    wrapper: root.wrapper
                }
            }
        }

        // Audio device popouts
        Popout {
            id: audioOutTooltip
            name: "audio-out"
            sourceComponent: Component {
                AudioDevicesTooltip {
                    wrapper: root.wrapper
                    mode: 'out'
                }
            }
        }
        Popout {
            id: audioInTooltip
            name: "audio-in"
            sourceComponent: Component {
                AudioDevicesTooltip {
                    wrapper: root.wrapper
                    mode: 'in'
                }
            }
        }
        // Brightness popout
        Popout {
            id: brightnessTooltip
            name: "brightness"
            sourceComponent: Component {
                BrightnessTooltip {
                    wrapper: root.wrapper
                }
            }
        }

        // Generic tooltip popouts for widgets
        Popout {
            id: newsTooltip
            name: "tooltip-news"
            sourceComponent: Component {
                NewsTooltip {
                    wrapper: root.wrapper
                }
            }
        }
        Popout {
            id: stocksTooltip
            name: "tooltip-stocks"
            sourceComponent: Component {
                StocksTooltip {
                    wrapper: root.wrapper
                }
            }
        }

        Popout {
            id: codexUsageTooltip
            name: "tooltip-codex-usage"
            sourceComponent: Component {
                CodexUsageTooltip {
                    wrapper: root.wrapper
                }
            }
        }

        Popout {
            id: piDashboardQuestionsTooltip
            name: "pi-dashboard-questions"
            sourceComponent: Component {
                PiDashboardQuestionsTooltip {
                    wrapper: root.wrapper
                }
            }
        }

        // Players list tooltip for MPRIS
        Popout {
            id: playersTooltip
            name: "tooltip-players"
            sourceComponent: Component {
                PlayersTooltip {
                    wrapper: root.wrapper
                }
            }
        }

        Popout {
            id: zmkTooltip
            name: "tooltip-zmk"
            sourceComponent: Component {
                ZmkKeymapTooltip {
                    wrapper: root.wrapper
                }
            }
        }

        Popout {
            id: hyprlandShortcutsPopup
            name: "shortcuts"
            sourceComponent: Component {
                HyprlandShortcutsPopup {
                    wrapper: root.wrapper
                }
            }
        }

        Popout {
            id: bluetoothBatteryTooltip
            name: "tooltip-bluetooth-battery"
            sourceComponent: Component {
                TooltipContent {
                    wrapper: root.wrapper
                    tooltipText: BluetoothBattery.tooltipText
                }
            }
        }

        Popout {
            id: weatherTooltip
            name: "tooltip-weather"
            sourceComponent: Component {
                WeatherTooltip {
                    wrapper: root.wrapper
                }
            }
        }

        Popout {
            id: updatesTooltip
            name: "tooltip-updates"
            sourceComponent: Component {
                UpdatesTooltip {
                    wrapper: root.wrapper
                }
            }
        }

        Popout {
            id: systemdFailedTooltip
            name: "tooltip-systemd"
            sourceComponent: Component {
                SystemdFailedTooltip {
                    wrapper: root.wrapper
                }
            }
        }

        Popout {
            id: todosTooltip
            name: "tooltip-todos"
            sourceComponent: Component {
                TodosTooltip {
                    wrapper: root.wrapper
                }
            }
        }
        Popout {
            id: agentTodosTooltip
            name: "tooltip-agent-todos"
            sourceComponent: Component {
                TooltipContent {
                    wrapper: root.wrapper
                    tooltipText: AgentTodos.tooltipText
                }
            }
        }
 
        Popout {
            id: memoryTooltip

            name: "tooltip-memory"
            sourceComponent: Component {
                MemoryTooltip {
                    wrapper: root.wrapper
                }
            }
        }

        Popout {
            id: cpuTooltip
            name: "tooltip-cpu"
            sourceComponent: Component {
                CpuTooltip {
                    wrapper: root.wrapper
                }
            }
        }

        Popout {
            id: batteryTooltip
            name: "tooltip-battery"
            sourceComponent: Component {
                BatteryTooltip {
                    wrapper: root.wrapper
                }
            }
        }

        Popout {
            id: timerTooltip
            name: "tooltip-timer"
            sourceComponent: Component {
                TimerTooltip {
                    wrapper: root.wrapper
                }
            }
        }

        Popout {
            id: calendarAgenda
            name: "calendar-agenda"
            sourceComponent: Component {
                CalendarAgenda {
                    wrapper: root.wrapper
                }
            }
        }

        Popout {
            id: nvidiaGpuTooltip
            name: "tooltip-gpu-nvidia"
            sourceComponent: Component {
                GpuTooltip {
                    wrapper: root.wrapper
                    gpuType: "nvidia"
                }
            }
        }
        Popout {
            id: amdGpuTooltip
            name: "tooltip-gpu-amd"
            sourceComponent: Component {
                GpuTooltip {
                    wrapper: root.wrapper
                    gpuType: "amd"
                }
            }
        }
        
        Popout {
            id: diskTooltip
            name: "tooltip-disk"
            sourceComponent: Component {
                DiskTooltip { wrapper: root.wrapper }
            }
        }
        Popout {
            id: resticTooltip
            name: "restic-tooltip"
            sourceComponent: Component {
                ResticTooltip { wrapper: root.wrapper }
            }
        }
        Popout {
            id: alphaessTooltip
            name: "tooltip-alphaess"
            sourceComponent: Component {
                AlphaESSTooltip { wrapper: root.wrapper }
            }
        }

        // Video stream tooltip (RTSP camera)
        Popout {
            id: videoStreamTooltip
            name: "tooltip-video-stream"
            sourceComponent: Component {
                VideoStreamTooltip {
                    wrapper: root.wrapper
                }
            }
        }

        Popout {
            id: mailTooltip
            name: "tooltip-mail"
            sourceComponent: Component {
                TooltipContent {
                    wrapper: root.wrapper
                    tooltipText: Mail.lastMail
                }
            }
        }

        Popout {
            id: submapTooltip
            name: "tooltip-submap"
            sourceComponent: Component {
                TooltipContent {
                    wrapper: root.wrapper
                    tooltipText: HyprlandSubmap.tooltipText
                }
            }
        }

        // Screen recording tooltip
        Popout {
            id: recordingTooltip
            name: "tooltip-recording"
            sourceComponent: Component {
                TooltipContent {
                    wrapper: root.wrapper
                    tooltipText: Recording.tooltipText
                }
            }
        }

        // Screen recording menu
        Popout {
            id: recordingMenu
            name: "screen-recording-menu"
            sourceComponent: Component {
                ScreenRecordingMenu {
                    wrapper: root.wrapper
                }
            }
        }

        // Screen recording popout (for hover tooltip)
        Popout {
            id: screenRecordingPopout
            name: "screen-recording"
            sourceComponent: Component {
                TooltipContent {
                    wrapper: root.wrapper
                    tooltipText: Recording.tooltipText
                }
            }
        }

        // System menu popout
        Popout {
            id: systemMenu
            name: "systemMenu"
            sourceComponent: Component {
                SystemMenu {
                }
            }
        }

        // Generations menu popout
        Popout {
            id: generationsMenu
            name: "generations-menu"
            sourceComponent: Component {
                GenerationsMenu {
                    wrapper: root.wrapper
                }
            }
        }

        // Generation details popout
        Popout {
            id: generationDetails
            name: "generation-details"
            sourceComponent: Component {
                GenerationDetails {
                    wrapper: root.wrapper
                }
            }
        }

         // Networks menu popout
         Popout {
             id: networksMenu
             name: "networks-menu"
             sourceComponent: Component {
                 NetworksMenu {
                     wrapper: root.wrapper
                 }
             }
         }

          // Bluetooth menu popout
          Popout {
              id: bluetoothMenu
              name: "bluetooth-menu"
              sourceComponent: Component {
                  BluetoothMenu {
                      wrapper: root.wrapper
                  }
              }
          }

          // Music player menu popout
          Popout {
              id: musicPlayerMenu
              name: "music-player"
              sourceComponent: Component {
                  MusicPlayerMenu {
                      wrapper: root.wrapper
                  }
              }
          }

          // 3D Printer menu popout
          Popout {
              id: printer3dMenu
              name: "printer3d-menu"
              sourceComponent: Component {
                  Printer3DMenu {
                      wrapper: root.wrapper
                  }
              }
          }

          // Computer status tooltip popout
          Popout {
              id: computerStatusTooltip
              name: "computer-status"
              sourceComponent: Component {
                  TooltipContent {
                      wrapper: root.wrapper
                      tooltipText: ComputerStatus.getTooltipText()
                  }
              }
          }

          Repeater {
            model: ScriptModel {
                values: [...SystemTray.items.values]
            }

            Popout {
                id: trayMenu

                required property SystemTrayItem modelData
                required property int index

                name: `traymenu${index}`
                sourceComponent: trayMenuComp

                Connections {
                    target: root.wrapper

                    function onHasCurrentChanged(): void {
                        if (root.wrapper.hasCurrent && trayMenu.shouldBeActive) {
                            trayMenu.sourceComponent = null;
                            trayMenu.sourceComponent = trayMenuComp;
                        }
                    }
                }

                Component {
                    id: trayMenuComp

                    TrayMenu {
                        popouts: root.wrapper
                        trayItem: trayMenu.modelData.menu
                    }
                }
            }
        }
    }

    component Popout: Loader {
        id: popout

        required property string name
        property bool shouldBeActive: root.wrapper.currentName === name

        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right

        // Internal opacity simply follows activation; Wrapper provides global unfold animation
        opacity: shouldBeActive ? Colors.opacity.foreground1 : 0
        enabled: shouldBeActive
        scale: 1
        // Keep CCTV's MediaPlayer alive while another popout is active; its
        // tooltip clears the source whenever it is not the selected popout.
        active: shouldBeActive || name === "tooltip-video-stream"
        asynchronous: false  // Synchronous for immediate measurement
        // Per-popout animations removed; centralized in Wrapper + PopoutConfig
    }
}
