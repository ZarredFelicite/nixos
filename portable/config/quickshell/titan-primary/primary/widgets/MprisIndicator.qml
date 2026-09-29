import QtQuick
import QtQuick.Effects
import Quickshell
import "../services"

// MPRIS media player indicator showing current track info
// Matches waybar mpris format: status_icon + dynamic text (title/artist)
Item {
    id: root
    property var popouts: null
    property bool shouldShrink: false  // Set by parent when spacer gets too small
    property real maxTextWidth: 99999  // Will be reduced when shouldShrink is true
    readonly property real contentSpacing: 6
    readonly property real iconSize: Colors.pillHeight - 8
    property bool albumArtFailed: false
    readonly property bool hasAlbumArt: Mpris.artUrl && Mpris.artUrl.length > 0
    readonly property bool shouldShowAlbumArt: hasAlbumArt && !albumArtFailed
    readonly property real devicePixelRatio: (typeof Screen !== "undefined" && Screen.devicePixelRatio) ? Screen.devicePixelRatio : 1
    property real screenWidth: 9999
    property bool titleHidden: screenWidth < 2500
    readonly property real textVisibleWidth: titleHidden ? 0 : Math.min(textItem.implicitWidth, maxTextWidth)

    implicitWidth: (iconsRow.visible ? iconsRow.implicitWidth + contentSpacing : 0)
        + textVisibleWidth
    implicitHeight: Colors.pillHeight

    // Only show if there's an active player
    visible: Mpris.hasActivePlayer
    width: visible ? implicitWidth : 0
    opacity: visible ? 1 : 0

    Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    property string tooltip: Mpris.tooltipText

    Connections {
        target: Mpris
        function onArtUrlChanged() {
            root.albumArtFailed = false
        }
    }
    
    // When spacer gets too small, progressively reduce text width
    onShouldShrinkChanged: {
        if (shouldShrink && textItem.width > 100 && maxTextWidth > 100) {
            const newMax = textItem.width * 0.95  // Reduce by 5% of current text width
            maxTextWidth = Math.max(100, newMax)  // Never go below 100px
        }
        // Don't reset - keep the reduced width to prevent oscillation
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        
        onEntered: {
            if (root.popouts) {
                var pos = root.popouts.mapFromItem(root, root.width / 2, root.height)
                root.popouts.openPopout("tooltip-players", pos.x, pos.y, root.width)
            }
        }
        
        onExited: {
        }
        
        onClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton) {
                Mpris.togglePlayback()
            } else if (mouse.button === Qt.RightButton) {
                root.titleHidden = !root.titleHidden
            } else if (mouse.button === Qt.MiddleButton) {
                Mpris.previous()
            }
        }
    }

    // Container with clipping to enforce elide/inset
    Row {
        id: container
        anchors.fill: parent
        anchors.leftMargin: 0
        anchors.rightMargin: 0
        spacing: root.contentSpacing
        clip: true

        // Players icons (from playerctl -l)
        Row {
            id: iconsRow
            spacing: 2
            anchors.verticalCenter: parent.verticalCenter
            visible: Playerctl.players && Playerctl.players.length > 0
            Repeater {
                model: Playerctl.players
                delegate: Item {
                    readonly property string name: modelData
                    readonly property var mprisPlayer: Mpris.findPlayerByName(name)
                    readonly property bool isActive: mprisPlayer && mprisPlayer === Mpris.activePlayer
                    readonly property bool showAlbumArt: isActive && root.shouldShowAlbumArt
                    width: root.iconSize
                    height: root.iconSize
                    anchors.verticalCenter: parent.verticalCenter
                    // Dim inactive players to 30% opacity, keep cyan tint
                    opacity: {
                        if (!Mpris.activePlayer) return 0.3
                        if (!mprisPlayer) return 0.3
                        return isActive ? 1.0 : 0.3
                    }

                    Rectangle {
                        id: albumArtFrame
                        anchors.fill: parent
                        visible: showAlbumArt
                        radius: 4
                        color: Colors.surface
                        border.color: Colors.outline
                        border.width: 1
                        clip: true

                        Image {
                            id: albumArtImage
                            anchors.fill: parent
                            source: showAlbumArt ? Mpris.artUrl : ""
                            visible: showAlbumArt
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            smooth: true
                            sourceSize.width: width * root.devicePixelRatio
                            sourceSize.height: height * root.devicePixelRatio
                            onStatusChanged: {
                                if (!showAlbumArt) return
                                if (status === Image.Ready) {
                                    root.albumArtFailed = false
                                } else if (status === Image.Error) {
                                    root.albumArtFailed = true
                                }
                            }
                            onSourceChanged: {
                                if (showAlbumArt) root.albumArtFailed = false
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: showAlbumArt && albumArtImage.status !== Image.Ready
                            text: "*"
                            color: Colors.primary
                            font.pixelSize: Math.round(parent.height * 0.6)
                        }
                    }

                    // Icon fallback (hidden when album art is available for the active player)
                    Image {
                        id: iconImg
                        anchors.centerIn: parent
                        width: Math.round(parent.width)
                        height: Math.round(parent.height)
                        visible: !showAlbumArt
                        fillMode: Image.PreserveAspectFit
                        source: Playerctl.iconFor(name)
                        smooth: false
                        antialiasing: false
                        mipmap: false
                        sourceSize.width: width * root.devicePixelRatio
                        sourceSize.height: height * root.devicePixelRatio
                    }
                    // Fallback letter if no icon found
                    Text {
                        anchors.centerIn: parent
                        visible: !showAlbumArt && iconImg.status !== Image.Ready
                        text: name ? name.charAt(0).toUpperCase() : "?"
                        color: Colors.foregroundCyan
                        font.pixelSize: Math.round(parent.height * 0.8)
                        font.bold: true
                    }
                    // Colorize overlay (always cyan; delegate opacity handles inactive dimming)
                    MultiEffect {
                        anchors.fill: iconImg
                        source: iconImg
                        colorization: 1.0
                        colorizationColor: Colors.foregroundCyan
                        visible: !showAlbumArt && iconImg.status === Image.Ready
                    }
                }
            }
        }

        Text {
            id: textItem
            text: Mpris.displayText
            font.pixelSize: 14
            font.weight: Font.Medium
            color: Colors.primary
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
            anchors.verticalCenter: parent.verticalCenter
            opacity: Mpris.isPlaying ? 1.0 : 0.7
            visible: !root.titleHidden
            // Apply width constraint and elide when needed
            width: root.textVisibleWidth
            elide: Text.ElideRight
        }
    }
}
