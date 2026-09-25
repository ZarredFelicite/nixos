import QtQuick
import QtQuick.Controls
import Quickshell.Widgets
import Quickshell.Io
import "../../../services"
import "./"

// News tooltip with clickable entry boxes
// Uses JSON output from rss.py --json for structured data
// Clicking an entry expands it to show full details
ClippingRectangle {
  id: root
  property var wrapper: null
  property bool expanded: wrapper && wrapper.hasCurrent && wrapper.currentName === 'tooltip-news'
  property bool hasOwnBackground: true
  readonly property color textPrimary: Colors.surfaceText
  readonly property color textSecondary: Qt.rgba(textPrimary.r, textPrimary.g, textPrimary.b, 0.72)

  readonly property int hPadding: 16
  readonly property int vPadding: 12
  readonly property int maxContentWidth: 550
  readonly property int maxContentHeight: 500
  readonly property int entrySpacing: 8
  readonly property int entryPadding: 10
  readonly property int entryRadius: 8

  implicitWidth: maxContentWidth + hPadding * 2
  implicitHeight: expanded ? Math.min(contentColumn.implicitHeight + vPadding * 2, maxContentHeight) : 0

  y: 0
  opacity: expanded ? Colors.opacity.foreground1 : 0

  Behavior on implicitHeight { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
  Behavior on opacity { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

  color: PopoutConfig.backgroundColor
  // The visible frame is drawn once by the topmost Rectangle below.
  border.width: 0
  radius: PopoutConfig.cornerRadius
  contentInsideBorder: true

  function openEntry(entryId) {
    News.fetchEntryDetails(entryId)
  }

  function closeDetails() {
    News.clearSelectedEntry()
  }

  ScrollView {
    id: scrollView
    anchors.fill: parent
    anchors.margins: root.vPadding
    anchors.leftMargin: root.hPadding
    anchors.rightMargin: root.hPadding
    clip: true

    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
    ScrollBar.vertical.policy: ScrollBar.AsNeeded

    opacity: expanded ? Colors.opacity.foreground1 : 0
    Behavior on opacity { NumberAnimation { duration: 120 } }

    Column {
      id: contentColumn
      spacing: 12
      width: scrollView.width

      // Header
      Row {
        spacing: 8
        visible: News.selectedEntryId === ""

        Text {
          text: "Latest News"
          font.pixelSize: 15
          font.weight: Font.Bold
          color: root.textPrimary
          anchors.verticalCenter: parent.verticalCenter
        }

        Text {
          text: News.checking ? "(updating...)" : ("(" + News.entryCount + " entries)")
          font.pixelSize: 12
          color: root.textSecondary
          anchors.verticalCenter: parent.verticalCenter
        }
      }

      // Back button (when viewing entry details)
      Row {
        spacing: 8
        visible: News.selectedEntryId !== ""

        Item {
          width: backText.implicitWidth + 16
          height: backText.implicitHeight + 8

          Rectangle {
            anchors.fill: parent
            color: backHover.hovered ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
            radius: 6
          }

          Text {
            id: backText
            anchors.centerIn: parent
            text: "← Back to list"
            font.pixelSize: 13
            color: backHover.hovered ? root.textPrimary : root.textSecondary
          }

          HoverHandler {
            id: backHover
          }

          MouseArea {
            anchors.fill: parent
            onClicked: root.closeDetails()
          }
        }
      }

      // Entry details view (when entry selected)
      Column {
        spacing: 10
        width: parent.width
        visible: News.selectedEntryId !== ""

        // Loading indicator
          Text {
            width: parent.width
            text: "Loading entry details..."
            font.pixelSize: 13
            color: root.textPrimary
            wrapMode: Text.WordWrap
            visible: News.fetchingDetails
          }

        // Entry details content
        Column {
          spacing: 8
          width: parent.width
          visible: !News.fetchingDetails && News.selectedEntryData !== null

          // Title
          Text {
            width: parent.width
            text: News.selectedEntryData ? News.selectedEntryData.title : ""
            font.pixelSize: 15
            font.weight: Font.Bold
            color: root.textPrimary
            wrapMode: Text.WordWrap
            textFormat: Text.PlainText
          }

          // Metadata row
          Row {
            spacing: 8
            width: parent.width

            Text {
              text: News.selectedEntryData ? News.selectedEntryData.feed : ""
              font.pixelSize: 11
              color: root.textSecondary
              visible: News.selectedEntryData && News.selectedEntryData.feed !== ""
              textFormat: Text.PlainText
            }

            Text {
              text: "•"
              font.pixelSize: 11
              color: root.textSecondary
              visible: News.selectedEntryData && News.selectedEntryData.feed !== "" && News.selectedEntryData.date !== ""
            }

            Text {
              text: News.selectedEntryData ? News.selectedEntryData.date : ""
              font.pixelSize: 11
              color: root.textSecondary
              visible: News.selectedEntryData && News.selectedEntryData.date !== ""
              textFormat: Text.PlainText
            }
          }

          // Author
          Text {
            width: parent.width
            text: News.selectedEntryData && News.selectedEntryData.author ? "By: " + News.selectedEntryData.author : ""
            font.pixelSize: 11
            color: root.textSecondary
            visible: News.selectedEntryData && News.selectedEntryData.author !== ""
            textFormat: Text.PlainText
          }

          // AI Summary section
          Column {
            spacing: 4
            width: parent.width
            visible: News.selectedEntryData && News.selectedEntryData.summary && News.selectedEntryData.summary !== ""

            Rectangle {
              width: parent.width
              height: 1
              color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.3)
              visible: parent.visible
            }

            Text {
              width: parent.width
              text: "Summary"
              font.pixelSize: 12
              font.weight: Font.Medium
              color: root.textPrimary
            }

            Text {
              width: parent.width
              text: News.selectedEntryData ? News.selectedEntryData.summary : ""
              font.pixelSize: 12
              color: root.textPrimary
              wrapMode: Text.WordWrap
              textFormat: Text.PlainText
            }
          }

          // Content section
          Column {
            spacing: 4
            width: parent.width
            visible: News.selectedEntryData && News.selectedEntryData.content && News.selectedEntryData.content !== ""

            Rectangle {
              width: parent.width
              height: 1
              color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.3)
              visible: parent.visible
            }

            Text {
              width: parent.width
              text: "Full Content"
              font.pixelSize: 12
              font.weight: Font.Medium
              color: root.textPrimary
            }

            Text {
              width: parent.width
              text: News.selectedEntryData ? News.selectedEntryData.content : ""
              font.pixelSize: 12
              color: root.textPrimary
              wrapMode: Text.WordWrap
              textFormat: Text.PlainText
            }
          }

          // Categories
          Flow {
            spacing: 6
            width: parent.width
            visible: News.selectedEntryData && News.selectedEntryData.categories && News.selectedEntryData.categories.length > 0

            Repeater {
              model: News.selectedEntryData ? News.selectedEntryData.categories : []
              delegate: Rectangle {
                width: catText.implicitWidth + 12
                height: catText.implicitHeight + 6
                color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.15)
                radius: 4

                Text {
                  id: catText
                  anchors.centerIn: parent
                  text: modelData
                  font.pixelSize: 10
                  color: root.textPrimary
                  textFormat: Text.PlainText
                }
              }
            }
          }

          // Open in browser button
          Item {
            width: openText.implicitWidth + 20
            height: openText.implicitHeight + 10

            Rectangle {
              anchors.fill: parent
              color: openHover.hovered ? Colors.primary : Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.2)
              radius: 6
              border.width: 1
              border.color: Colors.primary
            }

                Text {
                  id: openText
                  anchors.centerIn: parent
                  text: "Open in Browser"
                  font.pixelSize: 12
                  font.weight: Font.Medium
                  color: root.textPrimary
                }

            HoverHandler {
              id: openHover
            }

            MouseArea {
              anchors.fill: parent
              onClicked: {
                if (News.selectedEntryData && News.selectedEntryData.url) {
                  Qt.openUrlExternally(News.selectedEntryData.url)
                }
              }
            }
          }
        }

        // Error state
        Text {
          width: parent.width
          text: "Error loading entry details"
          font.pixelSize: 13
          color: PopoutConfig.errorColor
          wrapMode: Text.WordWrap
          visible: !News.fetchingDetails && News.selectedEntryData === null && News.selectedEntryId !== ""
        }
      }

      // Entry list (when no entry selected)
      Column {
        spacing: root.entrySpacing
        width: parent.width
        visible: News.selectedEntryId === ""

        Repeater {
          model: News.entries

          Item {
            width: parent.width
            height: entryBox.height

            Rectangle {
              id: entryBox
              width: parent.width
              height: entryColumn.implicitHeight + root.entryPadding * 2
              color: entryHover.hovered ? Qt.rgba(1, 1, 1, 0.08) : PopoutConfig.secondaryBackgroundColor
              radius: root.entryRadius
              border.width: 1
              border.color: entryHover.hovered ? Colors.primary : Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.15)

              Behavior on color { ColorAnimation { duration: 100 } }
              Behavior on border.color { ColorAnimation { duration: 100 } }

              Column {
                id: entryColumn
                anchors.left: parent.left
                anchors.leftMargin: root.entryPadding
                anchors.right: parent.right
                anchors.rightMargin: root.entryPadding
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                // Title
                Text {
                  width: parent.width
                  text: modelData.title || "No title"
                  font.pixelSize: 13
                  font.weight: Font.Medium
                  color: root.textPrimary
                  wrapMode: Text.WordWrap
                  maximumLineCount: 2
                  elide: Text.ElideRight
                  textFormat: Text.PlainText
                }

                // Feed and Date row
                Row {
                  spacing: 8
                  width: parent.width

                  Text {
                    text: modelData.feed || ""
                    font.pixelSize: 11
                    color: root.textSecondary
                    visible: modelData.feed && modelData.feed !== ""
                    textFormat: Text.PlainText
                  }

                  Text {
                    text: "•"
                    font.pixelSize: 11
                    color: root.textSecondary
                    visible: modelData.feed && modelData.feed !== "" && modelData.date && modelData.date !== ""
                  }

                  Text {
                    text: modelData.date || ""
                    font.pixelSize: 11
                    color: root.textSecondary
                    visible: modelData.date && modelData.date !== ""
                    textFormat: Text.PlainText
                  }
                }
              }
            }

            HoverHandler {
              id: entryHover
            }

            MouseArea {
              anchors.fill: parent
              onClicked: {
                root.openEntry(modelData.id)
              }
            }
          }
        }

        // Empty state
        Text {
          visible: News.entries.length === 0 && !News.checking
          text: "No news entries available"
          font.pixelSize: 13
          color: root.textSecondary
          anchors.horizontalCenter: parent.horizontalCenter
        }

        // Loading state
        Text {
          visible: News.checking && News.entries.length === 0
          text: "Loading news..."
          font.pixelSize: 13
          color: root.textSecondary
          anchors.horizontalCenter: parent.horizontalCenter
        }
      }
    }
  }

  // Draw the frame just inside the clipping texture so horizontal and
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
}
