import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Widgets
import "../../../services"
import "../../../widgets"
import "./"

// Music player menu — modern glass-morphism design with hero album art
ClippingRectangle {
  id: root
  property bool hasOwnBackground: true
  property var wrapper: null

  readonly property int hPad: 16
  readonly property int vPad: 14

  implicitWidth: 420
  implicitHeight: mainColumn.implicitHeight + vPad * 2

  // ClippingRectangle already renders through a ShaderEffect. Layering the
  // whole control again can clip the outer frame at rounded corners.
  color: PopoutConfig.backgroundColor
  // The visible frame is drawn once by the topmost Rectangle below.
  border.width: 0
  radius: PopoutConfig.cornerRadius
  contentInsideBorder: false

  Column {
    id: mainColumn
    spacing: 12
    anchors {
      top: parent.top; topMargin: root.vPad
      horizontalCenter: parent.horizontalCenter
    }
    width: root.implicitWidth - root.hPad * 2

    // ═══════════════════════════════════════════════════════
    // HERO CARD — Album art, song info, controls, progress
    // ═══════════════════════════════════════════════════════
    Rectangle {
      width: parent.width
      height: heroCol.height + 24
      radius: 12
      color: Qt.rgba(1, 1, 1, 0.03)
      border.width: 1
      border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.15)

      Rectangle {
        anchors.fill: parent; radius: parent.radius
        gradient: Gradient {
          orientation: Gradient.Horizontal
          GradientStop { position: 0.0; color: Qt.rgba(0, 1, 1, 0.03) }
          GradientStop { position: 1.0; color: "transparent" }
        }
      }

      Column {
        id: heroCol
        spacing: 10
        anchors {
          top: parent.top; topMargin: 12
          left: parent.left; leftMargin: 14
          right: parent.right; rightMargin: 14
        }

        // ── Album art + song info ──
        Row {
          spacing: 14; width: parent.width

          // Album art (120x120)
          Rectangle {
            width: 120; height: 120; radius: 10
            color: Qt.rgba(1, 1, 1, 0.04); clip: true
            border.width: albumArt.visible ? 0 : 1
            border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.12)

            Image {
              id: albumArt
              anchors.fill: parent
              source: MusicPlayer.albumArtUrl
              cache: false; asynchronous: true
              fillMode: Image.PreserveAspectCrop; smooth: true
              visible: MusicPlayer.albumArtUrl.length > 0 && status === Image.Ready
            }

            Text {
              anchors.centerIn: parent; visible: !albumArt.visible
              text: "album"; font.family: "Material Symbols Outlined"
              font.pixelSize: 52; color: Colors.primary; opacity: 0.2
              renderType: Text.NativeRendering
            }
          }

          // Song info + playback controls
          Column {
            spacing: 3
            width: parent.width - 120 - parent.spacing
            anchors.verticalCenter: parent.verticalCenter

            Text {
              text: MusicPlayer.currentSong || "No song playing"
              color: Colors.primary; font.pixelSize: 15; font.weight: Font.Bold
              elide: Text.ElideRight; width: parent.width
              renderType: Text.NativeRendering
            }

            Text {
              text: MusicPlayer.currentArtist || "Unknown artist"
              color: Colors.primary; opacity: 0.7; font.pixelSize: 12
              elide: Text.ElideRight; width: parent.width
              renderType: Text.NativeRendering
            }

            Text {
              text: MusicPlayer.currentAlbum || ""
              color: Colors.primary; opacity: 0.4; font.pixelSize: 11
              elide: Text.ElideRight; width: parent.width
              visible: text.length > 0
              renderType: Text.NativeRendering
            }

            Item { width: 1; height: 6 }

            // ── Playback controls ──
            Row {
              spacing: 2

              // Previous
              Rectangle {
                width: 32; height: 32; radius: 6
                color: prevMa.containsMouse ? Qt.rgba(1,1,1,0.08) : "transparent"
                anchors.verticalCenter: parent.verticalCenter
                Text {
                  anchors.centerIn: parent; text: "skip_previous"
                  font.family: "Material Symbols Outlined"; font.pixelSize: 20
                  color: Colors.primary; opacity: 0.8; renderType: Text.NativeRendering
                }
                MouseArea {
                  id: prevMa; anchors.fill: parent; hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor; onClicked: MusicPlayer.previous()
                }
              }

              // Play/Pause (accent circle)
              Rectangle {
                width: 40; height: 40; radius: 20
                color: playMa.containsMouse ? Qt.rgba(0,1,1,0.22) : Qt.rgba(0,1,1,0.10)
                border.width: 1; border.color: Qt.rgba(0,1,1,0.3)
                anchors.verticalCenter: parent.verticalCenter
                Text {
                  anchors.centerIn: parent
                  text: MusicPlayer.status === "playing" ? "pause" : "play_arrow"
                  font.family: "Material Symbols Outlined"; font.pixelSize: 24
                  color: Colors.foregroundCyan; renderType: Text.NativeRendering
                }
                MouseArea {
                  id: playMa; anchors.fill: parent; hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor; onClicked: MusicPlayer.togglePlayPause()
                }
              }

              // Next
              Rectangle {
                width: 32; height: 32; radius: 6
                color: nextMa.containsMouse ? Qt.rgba(1,1,1,0.08) : "transparent"
                anchors.verticalCenter: parent.verticalCenter
                Text {
                  anchors.centerIn: parent; text: "skip_next"
                  font.family: "Material Symbols Outlined"; font.pixelSize: 20
                  color: Colors.primary; opacity: 0.8; renderType: Text.NativeRendering
                }
                MouseArea {
                  id: nextMa; anchors.fill: parent; hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor; onClicked: MusicPlayer.next()
                }
              }

              // Stop
              Rectangle {
                width: 28; height: 28; radius: 6
                color: stopMa.containsMouse ? Qt.rgba(1,1,1,0.08) : "transparent"
                anchors.verticalCenter: parent.verticalCenter
                Text {
                  anchors.centerIn: parent; text: "stop"
                  font.family: "Material Symbols Outlined"; font.pixelSize: 18
                  color: Colors.primary; opacity: 0.5; renderType: Text.NativeRendering
                }
                MouseArea {
                  id: stopMa; anchors.fill: parent; hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor; onClicked: MusicPlayer.stop()
                }
              }

              Item { width: 8; height: 1 }

              // Bookmark current song
              Rectangle {
                width: 28; height: 28; radius: 6
                color: bmCurMa.containsMouse ? Qt.rgba(1,1,1,0.08) : "transparent"
                anchors.verticalCenter: parent.verticalCenter
                Text {
                  anchors.centerIn: parent; text: "bookmark_add"
                  font.family: "Material Symbols Outlined"; font.pixelSize: 18
                  color: Colors.foregroundCyan; opacity: 0.6; renderType: Text.NativeRendering
                }
                MouseArea {
                  id: bmCurMa; anchors.fill: parent; hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    if (MusicPlayer.currentSong)
                      MusicPlayer.addBookmark("song", MusicPlayer.currentSong,
                        "file:'" + MusicPlayer.currentFile + "'")
                  }
                }
              }
            }
          }
        }

        // ── Progress bar ──
        RowLayout {
          width: parent.width; spacing: 8

          Text {
            text: _formatTime(MusicPlayer.currentPosition)
            color: Colors.primary; opacity: 0.5; font.pixelSize: 10
            Layout.preferredWidth: 32; renderType: Text.NativeRendering
          }

          Item {
            Layout.fillWidth: true; height: 16

            Rectangle {
              width: parent.width; height: 6; radius: 3
              color: Qt.rgba(1, 1, 1, 0.08)
              anchors.verticalCenter: parent.verticalCenter

              Rectangle {
                height: parent.height; radius: 3
                width: MusicPlayer.currentDuration > 0
                  ? (MusicPlayer.currentPosition / MusicPlayer.currentDuration) * parent.width : 0
                color: Colors.foregroundCyan

                // Seek knob
                Rectangle {
                  width: 10; height: 10; radius: 5
                  color: Colors.foregroundCyan
                  border.width: 2; border.color: Colors.bg2
                  anchors.verticalCenter: parent.verticalCenter
                  anchors.right: parent.right; anchors.rightMargin: -5
                  visible: MusicPlayer.currentDuration > 0
                }
              }
            }

            MouseArea {
              anchors.fill: parent
              onClicked: function(mouse) {
                if (MusicPlayer.currentDuration > 0)
                  MusicPlayer.seek(Math.round((mouse.x / width) * MusicPlayer.currentDuration))
              }
              onPositionChanged: function(mouse) {
                if (pressed && MusicPlayer.currentDuration > 0)
                  MusicPlayer.seek(Math.max(0, Math.min(MusicPlayer.currentDuration,
                    Math.round((mouse.x / width) * MusicPlayer.currentDuration))))
              }
            }
          }

          Text {
            text: _formatTime(MusicPlayer.currentDuration)
            color: Colors.primary; opacity: 0.5; font.pixelSize: 10
            Layout.preferredWidth: 32; horizontalAlignment: Text.AlignRight
            renderType: Text.NativeRendering
          }
        }

        // ── Mode toggles + volume ──
        RowLayout {
          width: parent.width; spacing: 0

          Row {
            spacing: 4

            // Repeat
            Rectangle {
              width: 28; height: 22; radius: 11
              color: MusicPlayer.repeat ? Qt.rgba(0,1,1,0.15) : Qt.rgba(1,1,1,0.04)
              border.width: MusicPlayer.repeat ? 1 : 0
              border.color: Qt.rgba(0,1,1,0.4)
              Text {
                anchors.centerIn: parent; text: "repeat"
                font.family: "Material Symbols Outlined"; font.pixelSize: 14
                color: MusicPlayer.repeat ? Colors.foregroundCyan : Colors.primary
                opacity: MusicPlayer.repeat ? 1 : 0.4; renderType: Text.NativeRendering
              }
              MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: MusicPlayer.toggleRepeat()
              }
            }

            // Shuffle
            Rectangle {
              width: 28; height: 22; radius: 11
              color: MusicPlayer.random ? Qt.rgba(0,1,1,0.15) : Qt.rgba(1,1,1,0.04)
              border.width: MusicPlayer.random ? 1 : 0
              border.color: Qt.rgba(0,1,1,0.4)
              Text {
                anchors.centerIn: parent; text: "shuffle"
                font.family: "Material Symbols Outlined"; font.pixelSize: 14
                color: MusicPlayer.random ? Colors.foregroundCyan : Colors.primary
                opacity: MusicPlayer.random ? 1 : 0.4; renderType: Text.NativeRendering
              }
              MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: MusicPlayer.toggleRandom()
              }
            }

            // Consume
            Rectangle {
              width: 28; height: 22; radius: 11
              color: MusicPlayer.consume ? Qt.rgba(0,1,1,0.15) : Qt.rgba(1,1,1,0.04)
              border.width: MusicPlayer.consume ? 1 : 0
              border.color: Qt.rgba(0,1,1,0.4)
              Text {
                anchors.centerIn: parent; text: "delete_sweep"
                font.family: "Material Symbols Outlined"; font.pixelSize: 14
                color: MusicPlayer.consume ? Colors.foregroundCyan : Colors.primary
                opacity: MusicPlayer.consume ? 1 : 0.4; renderType: Text.NativeRendering
              }
              MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: MusicPlayer.toggleConsume()
              }
            }
          }

          Item { Layout.fillWidth: true }

          // Volume
          Row {
            spacing: 6

            Text {
              text: MusicPlayer.volume > 66 ? "volume_up"
                : MusicPlayer.volume > 33 ? "volume_down"
                : MusicPlayer.volume > 0 ? "volume_mute" : "volume_off"
              font.family: "Material Symbols Outlined"; font.pixelSize: 16
              color: Colors.primary; opacity: 0.4
              anchors.verticalCenter: parent.verticalCenter
              renderType: Text.NativeRendering
            }

            Item {
              width: 80; height: 14
              anchors.verticalCenter: parent.verticalCenter

              Rectangle {
                width: parent.width; height: 4; radius: 2
                color: Qt.rgba(1,1,1,0.08)
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                  width: (MusicPlayer.volume / 100) * parent.width
                  height: parent.height; radius: 2
                  color: Colors.foregroundCyan; opacity: 0.6
                }
              }

              MouseArea {
                anchors.fill: parent
                onClicked: function(mouse) {
                  MusicPlayer.setVolume(Math.max(0, Math.min(100,
                    Math.round((mouse.x / width) * 100))))
                }
                onPositionChanged: function(mouse) {
                  if (pressed) MusicPlayer.setVolume(Math.max(0, Math.min(100,
                    Math.round((mouse.x / width) * 100))))
                }
              }
            }

            Text {
              text: MusicPlayer.volume + "%"
              color: Colors.primary; opacity: 0.4; font.pixelSize: 10
              anchors.verticalCenter: parent.verticalCenter
              renderType: Text.NativeRendering
            }
          }
        }
      }
    }

    // ═══════════════════════════════════════════════════════
    // BOOKMARKS
    // ═══════════════════════════════════════════════════════
    Column {
      width: parent.width; spacing: 6
      visible: MusicPlayer.bookmarks.length > 0

      Text {
        text: "Bookmarks"; color: Colors.primary; opacity: 0.6
        font.pixelSize: 11; font.weight: Font.DemiBold
        renderType: Text.NativeRendering
      }

      Rectangle {
        width: parent.width
        height: Math.min(130, bookmarkCol.height)
        radius: 8; clip: true
        color: Qt.rgba(1, 1, 1, 0.03)
        border.width: 1
        border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.1)

        Column {
          id: bookmarkCol
          width: parent.width; spacing: 1

          Repeater {
            model: Math.min(6, MusicPlayer.bookmarks.length)

            RowLayout {
              required property int index
              width: parent.width; height: 32; spacing: 4

              // Main clickable area
              Rectangle {
                Layout.fillWidth: true; Layout.fillHeight: true
                radius: 4
                color: bmItemMa.containsMouse ? Qt.rgba(1,1,1,0.06) : "transparent"

                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: 10; anchors.rightMargin: 6; spacing: 8

                  Text {
                    text: {
                      var bm = MusicPlayer.bookmarks[index]
                      if (!bm) return "music_note"
                      return bm.type === "album" ? "album"
                        : bm.type === "artist" ? "person"
                        : bm.type === "playlist" ? "queue_music" : "music_note"
                    }
                    font.family: "Material Symbols Outlined"; font.pixelSize: 14
                    color: Colors.foregroundCyan; opacity: 0.6
                    renderType: Text.NativeRendering
                  }

                  Text {
                    text: MusicPlayer.bookmarks[index] ? MusicPlayer.bookmarks[index].name : ""
                    color: Colors.primary; font.pixelSize: 11
                    elide: Text.ElideRight; Layout.fillWidth: true
                    renderType: Text.NativeRendering
                  }

                  Text {
                    text: {
                      var bm = MusicPlayer.bookmarks[index]
                      if (!bm) return ""
                      return bm.type === "album" ? "Album"
                        : bm.type === "artist" ? "Artist"
                        : bm.type === "playlist" ? "Playlist" : "Song"
                    }
                    color: Colors.primary; opacity: 0.3; font.pixelSize: 9
                    renderType: Text.NativeRendering
                  }
                }

                MouseArea {
                  id: bmItemMa; anchors.fill: parent
                  hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                  onClicked: _executeBookmark(index)
                }
              }

              // Remove button
              Rectangle {
                width: 22; height: 22; radius: 4
                color: rmBmMa.containsMouse
                  ? Qt.rgba(Colors.foregroundRed.r, Colors.foregroundRed.g, Colors.foregroundRed.b, 0.15)
                  : "transparent"
                Layout.alignment: Qt.AlignVCenter

                Text {
                  anchors.centerIn: parent; text: "close"
                  font.family: "Material Symbols Outlined"; font.pixelSize: 12
                  color: rmBmMa.containsMouse ? Colors.foregroundRed : Colors.primary
                  opacity: rmBmMa.containsMouse ? 1 : 0.3
                  renderType: Text.NativeRendering
                }

                MouseArea {
                  id: rmBmMa; anchors.fill: parent
                  hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                  onClicked: MusicPlayer.removeBookmark(index)
                }
              }
            }
          }
        }
      }
    }

    // ═══════════════════════════════════════════════════════
    // UP NEXT (Queue)
    // ═══════════════════════════════════════════════════════
    Column {
      width: parent.width; spacing: 6
      visible: MusicPlayer.queue.length > MusicPlayer.queuePosition + 1

      RowLayout {
        width: parent.width

        Text {
          text: "Up Next"; color: Colors.primary; opacity: 0.6
          font.pixelSize: 11; font.weight: Font.DemiBold
          renderType: Text.NativeRendering
        }

        Item { Layout.fillWidth: true }

        // Clear queue
        Rectangle {
          width: 22; height: 22; radius: 4
          color: clearQMa.containsMouse
            ? Qt.rgba(Colors.foregroundRed.r, Colors.foregroundRed.g, Colors.foregroundRed.b, 0.15)
            : "transparent"

          Text {
            anchors.centerIn: parent; text: "delete_sweep"
            font.family: "Material Symbols Outlined"; font.pixelSize: 14
            color: clearQMa.containsMouse ? Colors.foregroundRed : Colors.primary
            opacity: clearQMa.containsMouse ? 1 : 0.4
            renderType: Text.NativeRendering
          }

          MouseArea {
            id: clearQMa; anchors.fill: parent
            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: MusicPlayer.clearQueue()
          }
        }
      }

      Rectangle {
        width: parent.width
        height: Math.min(160, queueCol.height)
        radius: 8; clip: true
        color: Qt.rgba(1, 1, 1, 0.03)
        border.width: 1
        border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.1)

        Flickable {
          anchors.fill: parent
          contentHeight: queueCol.height
          clip: true; boundsBehavior: Flickable.StopAtBounds

          Column {
            id: queueCol
            width: parent.width; spacing: 1

            Repeater {
              model: Math.min(20, Math.max(0,
                MusicPlayer.queue.length - MusicPlayer.queuePosition - 1))

              RowLayout {
                required property int index
                width: parent.width; height: 36; spacing: 4

                property var queueItem: {
                  var idx = MusicPlayer.queuePosition + 1 + index
                  return idx < MusicPlayer.queue.length ? MusicPlayer.queue[idx] : null
                }

                // Main clickable area
                Rectangle {
                  Layout.fillWidth: true; Layout.fillHeight: true
                  radius: 4
                  color: qItemMa.containsMouse ? Qt.rgba(1,1,1,0.06) : "transparent"

                  Column {
                    anchors.fill: parent
                    anchors.leftMargin: 10; anchors.rightMargin: 6
                    anchors.topMargin: 5; anchors.bottomMargin: 5
                    spacing: 1

                    Text {
                      text: queueItem ? queueItem.title : ""
                      color: Colors.primary; font.pixelSize: 11
                      elide: Text.ElideRight; width: parent.width
                      renderType: Text.NativeRendering
                    }

                    Text {
                      text: (queueItem ? queueItem.artist : "")
                        + (queueItem && queueItem.duration ? "  ·  " + queueItem.duration : "")
                      color: Colors.primary; opacity: 0.35; font.pixelSize: 9
                      elide: Text.ElideRight; width: parent.width
                      renderType: Text.NativeRendering
                    }
                  }

                  MouseArea {
                    id: qItemMa; anchors.fill: parent
                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: MusicPlayer.playQueuePosition(
                      MusicPlayer.queuePosition + 1 + index)
                  }
                }

                // Bookmark queue item
                Rectangle {
                  width: 22; height: 22; radius: 4
                  color: bmQMa.containsMouse ? Qt.rgba(1,1,1,0.08) : "transparent"
                  Layout.alignment: Qt.AlignVCenter

                  Text {
                    anchors.centerIn: parent; text: "bookmark_add"
                    font.family: "Material Symbols Outlined"; font.pixelSize: 12
                    color: Colors.foregroundCyan
                    opacity: bmQMa.containsMouse ? 0.8 : 0.3
                    renderType: Text.NativeRendering
                  }

                  MouseArea {
                    id: bmQMa; anchors.fill: parent
                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      if (queueItem) MusicPlayer.addBookmark("song",
                        queueItem.title, "file:'" + queueItem.file + "'")
                    }
                  }
                }

                // Remove from queue
                Rectangle {
                  width: 22; height: 22; radius: 4
                  color: rmQMa.containsMouse
                    ? Qt.rgba(Colors.foregroundRed.r, Colors.foregroundRed.g, Colors.foregroundRed.b, 0.15)
                    : "transparent"
                  Layout.alignment: Qt.AlignVCenter

                  Text {
                    anchors.centerIn: parent; text: "close"
                    font.family: "Material Symbols Outlined"; font.pixelSize: 12
                    color: rmQMa.containsMouse ? Colors.foregroundRed : Colors.primary
                    opacity: rmQMa.containsMouse ? 1 : 0.3
                    renderType: Text.NativeRendering
                  }

                  MouseArea {
                    id: rmQMa; anchors.fill: parent
                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: MusicPlayer.removeFromQueue(
                      MusicPlayer.queuePosition + 1 + index)
                  }
                }
              }
            }
          }
        }
      }
    }

    // ═══════════════════════════════════════════════════════
    // SEARCH BAR
    // ═══════════════════════════════════════════════════════
    Rectangle {
      width: parent.width; height: 32; radius: 8
      color: Qt.rgba(1, 1, 1, 0.04)
      border.width: searchInput.focus ? 1 : 0
      border.color: Qt.rgba(0, 1, 1, 0.4)

      RowLayout {
        anchors.fill: parent; anchors.margins: 8; spacing: 8

        Text {
          text: "search"; font.family: "Material Symbols Outlined"
          font.pixelSize: 16; color: Colors.primary; opacity: 0.4
          renderType: Text.NativeRendering
        }

        TextInput {
          id: searchInput
          Layout.fillWidth: true
          color: Colors.primary; selectionColor: Colors.foregroundCyan
          font.pixelSize: 12

          Text {
            anchors.fill: parent
            text: "Search albums, artists..."
            color: Colors.primary; opacity: 0.3; font.pixelSize: 12
            visible: !parent.text && !parent.focus
            renderType: Text.NativeRendering
          }

          onTextChanged: searchDebounce.restart()
        }

        // Refresh button
        Rectangle {
          Layout.preferredWidth: 24; Layout.preferredHeight: 24
          radius: 6
          color: refreshMa.containsMouse ? Qt.rgba(1,1,1,0.08) : "transparent"
          opacity: MusicPlayer.updating ? 0.6 : 1

          Text {
            anchors.centerIn: parent; text: "refresh"
            font.family: "Material Symbols Outlined"; font.pixelSize: 16
            color: Colors.foregroundCyan; opacity: 0.7
            rotation: MusicPlayer.updating ? 90 : 0
            Behavior on rotation { NumberAnimation { duration: 150 } }
            renderType: Text.NativeRendering
          }

          MouseArea {
            id: refreshMa; anchors.fill: parent
            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: MusicPlayer.manualRefresh()
          }
        }
      }
    }

    // ═══════════════════════════════════════════════════════
    // SEARCH RESULTS
    // ═══════════════════════════════════════════════════════
    Rectangle {
      width: parent.width
      height: searchInput.text.length > 0 && MusicPlayer.searchResults.length > 0
        ? Math.min(220, MusicPlayer.searchResults.length * 44) : 0
      visible: searchInput.text.length > 0 && MusicPlayer.searchResults.length > 0
      radius: 8; clip: true
      color: Qt.rgba(1, 1, 1, 0.03)
      border.width: 1
      border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.1)

      ListView {
        id: searchResultsList
        anchors.fill: parent; clip: true; spacing: 2
        boundsBehavior: Flickable.StopAtBounds
        model: searchInput.text.length > 0 ? MusicPlayer.searchResults : []

        delegate: Rectangle {
          required property var modelData
          required property int index
          width: searchResultsList.width; height: 44
          radius: 4
          color: resultHoverMa.containsMouse ? Qt.rgba(1,1,1,0.06) : "transparent"

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10; anchors.rightMargin: 6; spacing: 8

            Text {
              text: modelData.type === "album" ? "album"
                : modelData.type === "artist" ? "person" : "music_note"
              font.family: "Material Symbols Outlined"; font.pixelSize: 20
              color: modelData.type === "album" ? Colors.foregroundCyan
                : modelData.type === "artist" ? "#9ccfd8" : Colors.primary
              renderType: Text.NativeRendering
            }

            Column {
              Layout.fillWidth: true; spacing: 2

              Text {
                text: modelData.name; color: Colors.primary; font.pixelSize: 11
                elide: Text.ElideRight; width: parent.width
                renderType: Text.NativeRendering
              }

              Text {
                text: modelData.artist || modelData.type
                color: Colors.primary; opacity: 0.4; font.pixelSize: 9
                elide: Text.ElideRight; width: parent.width
                renderType: Text.NativeRendering
              }
            }

            // Play
            Rectangle {
              width: 24; height: 24; radius: 6
              color: playResultMa.containsMouse ? Qt.rgba(0,1,1,0.12) : "transparent"
              Layout.alignment: Qt.AlignVCenter

              Text {
                anchors.centerIn: parent; text: "play_arrow"
                font.family: "Material Symbols Outlined"; font.pixelSize: 16
                color: Colors.foregroundCyan; opacity: 0.8
                renderType: Text.NativeRendering
              }

              MouseArea {
                id: playResultMa; anchors.fill: parent
                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: _playSearchResult(modelData)
              }
            }

            // Add to queue
            Rectangle {
              width: 24; height: 24; radius: 6
              color: queueResultMa.containsMouse ? Qt.rgba(1,1,1,0.08) : "transparent"
              Layout.alignment: Qt.AlignVCenter

              Text {
                anchors.centerIn: parent; text: "queue_music"
                font.family: "Material Symbols Outlined"; font.pixelSize: 16
                color: Colors.primary; opacity: 0.6
                renderType: Text.NativeRendering
              }

              MouseArea {
                id: queueResultMa; anchors.fill: parent
                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: _addToQueueSearchResult(modelData)
              }
            }
          }

          // Background hover (behind buttons via z-order: declared first)
          MouseArea {
            id: resultHoverMa; anchors.fill: parent
            hoverEnabled: true; propagateComposedEvents: true
            onClicked: function(mouse) { mouse.accepted = false }
          }
        }
      }
    }
  }

  // ═══════════════════════════════════════════════════════
  // SEARCH DEBOUNCE & HELPERS
  // ═══════════════════════════════════════════════════════
  // Draw the frame just inside the clipping texture so both antialiased
  // vertical edges are sampled equally.
  Rectangle {
    anchors.fill: parent
    anchors.margins: 0.5
    color: "transparent"
    radius: PopoutConfig.cornerRadius - 0.5
    border.width: PopoutConfig.borderWidth
    border.color: PopoutConfig.borderColor
    border.pixelAligned: true
    z: 100
  }

  Timer {
    id: searchDebounce; interval: 300
    onTriggered: {
      if (searchInput.text.length > 1)
        MusicPlayer.searchAll(searchInput.text)
      else
        MusicPlayer.searchResults = []
    }
  }

  function _formatTime(seconds) {
    if (seconds <= 0) return "0:00"
    var mins = Math.floor(seconds / 60)
    var secs = Math.floor(seconds % 60)
    return mins + ":" + (secs < 10 ? "0" : "") + secs
  }

  function _executeBookmark(index) {
    if (index >= MusicPlayer.bookmarks.length) return
    var bm = MusicPlayer.bookmarks[index]

    if (bm.type === "album") {
      MusicPlayer.playAlbum(bm.name)
    } else if (bm.type === "artist") {
      MusicPlayer.playArtist(bm.name)
    } else if (bm.type === "playlist") {
      MusicPlayer._executeCommand(["mpc", "load", bm.name], "loadPlaylist", function() {
        MusicPlayer.refreshQueue()
        MusicPlayer.play()
      })
    } else if (bm.type === "song") {
      MusicPlayer.playSong(bm.query.match(/'([^']+)'/)[1])
    }
  }

  function _playSearchResult(item) {
    if (item.type === "album") MusicPlayer.playAlbum(item.name)
    else if (item.type === "artist") MusicPlayer.playArtist(item.name)
    else if (item.type === "song") MusicPlayer.playSong(item.file)
    searchInput.text = ""
  }

  function _addToQueueSearchResult(item) {
    if (item.type === "album") MusicPlayer.addAlbumToQueue(item.name)
    else if (item.type === "artist") MusicPlayer.addArtistToQueue(item.name)
    else if (item.type === "song") MusicPlayer.addSongToQueue(item.file)
  }
}
