import QtQuick
import Quickshell.Widgets
import "../../../services"
import "./"

ClippingRectangle {
  id: root

  required property Item wrapper
  readonly property bool expanded: wrapper && wrapper.hasCurrent && wrapper.currentName === "pi-dashboard-questions"
  readonly property bool hasOwnBackground: true
  readonly property int contentWidth: 460
  readonly property int horizontalPadding: 14
  readonly property int verticalPadding: 12
  readonly property int maxListHeight: 440
  readonly property bool messageOnly: PiDashboardQuestions.visibleFinalMessages.length > 0
                                      && !PiDashboardQuestions.hasQuestions
  readonly property bool hasVisibleItems: PiDashboardQuestions.hasQuestions
                                          || PiDashboardQuestions.visibleFinalMessages.length > 0
  readonly property int listHeight: Math.min(maxListHeight, Math.max(64, questionColumn.implicitHeight))
  readonly property int messageListHeight: Math.min(maxListHeight, Math.max(1, messageColumn.implicitHeight))
  property bool hadPendingQuestions: false

  function scheduleCloseIfEmpty() {
    Qt.callLater(function() {
      if (root.expanded && !root.hasVisibleItems && root.wrapper)
        root.wrapper.close()
    })
  }

  function dismissPopup() {
    if (root.messageOnly) {
      var messages = PiDashboardQuestions.visibleFinalMessages.slice()
      for (var i = 0; i < messages.length; i++)
        PiDashboardQuestions.dismissFinalMessage(messages[i].id)
    }
    if (root.wrapper)
      root.wrapper.close()
  }

  implicitWidth: expanded ? contentWidth + horizontalPadding * 2 : 0
  implicitHeight: expanded
    ? messageOnly
      ? verticalPadding * 2 + messageListHeight
      : verticalPadding * 2 + header.height + 10 + listHeight + 10 + footer.height
    : 0

  layer.enabled: true
  layer.smooth: false
  color: "#1f1d2e"
  border.width: 1
  border.color: "#403d52"
  radius: 16
  contentInsideBorder: false

  onExpandedChanged: {
    if (expanded)
      hadPendingQuestions = PiDashboardQuestions.hasQuestions
    else
      hadPendingQuestions = false
  }

  TapHandler {
    acceptedButtons: Qt.MiddleButton
    onTapped: root.dismissPopup()
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    propagateComposedEvents: true
    onEntered: {
      if (!root.wrapper)
        return
      root.wrapper.currentHovered = true
      if (root.wrapper.closeTimer)
        root.wrapper.closeTimer.stop()
    }
    onExited: {
      if (!root.wrapper)
        return
      root.wrapper.currentHovered = false
      root.wrapper.scheduleClose()
    }
    onClicked: function(mouse) { mouse.accepted = false }
  }

  Connections {
    target: PiDashboardQuestions
    function onQuestionsChanged() {
      if (PiDashboardQuestions.hasQuestions) {
        root.hadPendingQuestions = true
      } else if (root.expanded && root.hadPendingQuestions) {
        root.scheduleCloseIfEmpty()
      }
    }

    function onVisibleFinalMessagesChanged() {
      if (PiDashboardQuestions.visibleFinalMessages.length === 0)
        root.scheduleCloseIfEmpty()
    }
  }

  component ActionButton: Rectangle {
    id: actionButton
    required property string label
    property bool primary: false
    property bool selected: false
    property bool busy: false
    signal clicked()

    implicitWidth: actionLabel.implicitWidth + 20
    implicitHeight: 32
    radius: 9
    color: actionButton.primary
      ? (actionButton.selected ? "#c4a7e7" : "#6e5a8e")
      : (actionButton.selected ? Qt.rgba(196 / 255, 167 / 255, 231 / 255, 0.18) : "#26233a")
    border.width: 1
    border.color: actionButton.primary ? "#c4a7e7" : "#403d52"
    opacity: enabled ? 1 : 0.45

    Text {
      id: actionLabel
      anchors.centerIn: parent
      text: actionButton.busy ? "Sending…" : actionButton.label
      color: actionButton.primary && actionButton.selected ? "#191724" : "#e0def4"
      font.pixelSize: 11
      font.weight: Font.DemiBold
      renderType: Text.NativeRendering
    }

    MouseArea {
      anchors.fill: parent
      enabled: actionButton.enabled
      cursorShape: Qt.PointingHandCursor
      onClicked: actionButton.clicked()
    }
  }

  component OptionButton: Rectangle {
    id: optionButton
    required property string option
    property bool selected: false
    property bool busy: false
    signal clicked()

    width: parent ? parent.width : root.contentWidth
    implicitHeight: optionLabel.implicitHeight + 16
    height: Math.max(34, implicitHeight)
    radius: 9
    color: optionButton.selected
      ? Qt.rgba(196 / 255, 167 / 255, 231 / 255, 0.18)
      : "#26233a"
    border.width: 1
    border.color: optionButton.selected ? "#c4a7e7" : "#403d52"
    opacity: enabled ? 1 : 0.45

    Text {
      id: optionLabel
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: 11
      anchors.rightMargin: 11
      text: optionButton.option
      color: "#e0def4"
      font.pixelSize: 11
      font.weight: optionButton.selected ? Font.DemiBold : Font.Normal
      wrapMode: Text.WordWrap
      renderType: Text.NativeRendering
    }

    MouseArea {
      anchors.fill: parent
      enabled: optionButton.enabled
      cursorShape: Qt.PointingHandCursor
      onClicked: optionButton.clicked()
    }
  }

  component QuestionCard: Rectangle {
    id: card
    required property var question
    property string inputText: ""
    property var selectedOptions: []
    property var batchAnswers: []

    width: root.contentWidth
    implicitHeight: cardColumn.implicitHeight + 22
    height: implicitHeight
    radius: 12
    color: "#26233a"
    border.width: 1
    border.color: question.answering ? "#6e6a86" : "#403d52"

    function initializeBatch() {
      var answers = []
      var batch = question.batchQuestions || []
      for (var i = 0; i < batch.length; i++) {
        if (batch[i].method === "input")
          answers.push({ value: "" })
        else if (batch[i].method === "multiselect")
          answers.push({ values: [] })
        else
          answers.push(undefined)
      }
      batchAnswers = answers
    }

    function batchValue(index) {
      return index >= 0 && index < batchAnswers.length ? batchAnswers[index] : undefined
    }

    function setBatchValue(index, value) {
      var next = batchAnswers.slice()
      next[index] = value
      batchAnswers = next
    }

    function toggleBatchOption(index, option) {
      var current = batchValue(index)
      var values = current && Array.isArray(current.values) ? current.values.slice() : []
      var position = values.indexOf(option)
      if (position >= 0)
        values.splice(position, 1)
      else
        values.push(option)
      setBatchValue(index, { values: values })
    }

    function canSubmitBatch() {
      var batch = question.batchQuestions || []
      if (batch.length === 0 || batchAnswers.length !== batch.length)
        return false
      for (var i = 0; i < batch.length; i++) {
        if (batchAnswers[i] === undefined)
          return false
      }
      return true
    }

    Component.onCompleted: initializeBatch()
    onQuestionChanged: initializeBatch()

    Column {
      id: cardColumn
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: 11
      spacing: 8

      Row {
        width: parent.width
        spacing: 7

        Rectangle {
          width: 7
          height: 7
          radius: 4
          anchors.verticalCenter: parent.verticalCenter
          color: question.answering ? "#6e6a86" : "#ebbcba"
        }

        Text {
          width: parent.width - 7 - 7 - questionType.implicitWidth
          text: question.sessionName
          color: "#908caa"
          font.pixelSize: 10
          font.weight: Font.DemiBold
          leftPadding: 2
          rightPadding: 2
          topPadding: 3
          bottomPadding: 3
          wrapMode: Text.WordWrap
          renderType: Text.NativeRendering
        }

        Text {
          id: questionType
          text: question.answering ? "SENDING" : question.type.toUpperCase()
          color: question.answering ? "#908caa" : "#f6c177"
          font.pixelSize: 9
          font.weight: Font.DemiBold
          renderType: Text.NativeRendering
        }
      }

      Text {
        width: parent.width
        text: question.question
        color: "#e0def4"
        font.pixelSize: 18
        font.weight: Font.DemiBold
        wrapMode: Text.WordWrap
        renderType: Text.NativeRendering
      }

      Text {
        visible: question.message.length > 0
        width: parent.width
        text: question.message
        color: "#908caa"
        font.pixelSize: 13
        wrapMode: Text.WordWrap
        renderType: Text.NativeRendering
      }

      Column {
        width: parent.width
        spacing: 5
        visible: question.type === "select"

        Repeater {
          model: question.options
          delegate: OptionButton {
            required property string modelData
            option: modelData
            enabled: !card.question.answering
            onClicked: PiDashboardQuestions.answer(card.question.id, { value: modelData })
          }
        }
      }

      Row {
        spacing: 6
        visible: question.type === "confirm"

        ActionButton {
          label: "Yes"
          primary: true
          enabled: !card.question.answering
          onClicked: PiDashboardQuestions.answer(card.question.id, { confirmed: true })
        }
        ActionButton {
          label: "No"
          enabled: !card.question.answering
          onClicked: PiDashboardQuestions.answer(card.question.id, { confirmed: false })
        }
      }

      Column {
        width: parent.width
        spacing: 5
        visible: question.type === "multiselect"

        Repeater {
          model: question.options
          delegate: OptionButton {
            required property string modelData
            option: modelData
            selected: card.selectedOptions.indexOf(modelData) >= 0
            enabled: !card.question.answering
            onClicked: {
              var next = card.selectedOptions.slice()
              var position = next.indexOf(modelData)
              if (position >= 0)
                next.splice(position, 1)
              else
                next.push(modelData)
              card.selectedOptions = next
            }
          }
        }

        ActionButton {
          label: card.selectedOptions.length > 0 ? "Submit (" + card.selectedOptions.length + ")" : "Submit"
          primary: true
          enabled: !card.question.answering
          onClicked: PiDashboardQuestions.answer(card.question.id, { values: card.selectedOptions })
        }
      }

      Row {
        width: parent.width
        spacing: 6
        visible: question.type === "input" || question.type === "editor"

        Rectangle {
          width: parent.width - sendInputButton.implicitWidth - 6
          height: 32
          radius: 9
          color: "#1f1d2e"
          border.width: 1
          border.color: "#403d52"

          Text {
            visible: input.text.length === 0 && card.question.placeholder.length > 0
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: card.question.placeholder
            color: "#6e6a86"
            font.pixelSize: 11
            elide: Text.ElideRight
            renderType: Text.NativeRendering
          }

          TextInput {
            id: input
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            text: card.inputText
            color: "#e0def4"
            selectedTextColor: "#191724"
            selectionColor: "#c4a7e7"
            font.pixelSize: 11
            clip: true
            enabled: !card.question.answering
            onTextChanged: card.inputText = text
            onAccepted: PiDashboardQuestions.answer(card.question.id, { value: text })
          }
        }

        ActionButton {
          id: sendInputButton
          label: "Send"
          primary: true
          enabled: !card.question.answering && card.inputText.length > 0
          onClicked: PiDashboardQuestions.answer(card.question.id, { value: card.inputText })
        }
      }

      Column {
        width: parent.width
        spacing: 7
        visible: question.type === "batch"

        Repeater {
          model: question.batchQuestions
          delegate: Rectangle {
            id: batchCard
            required property var modelData
            required property int index
            property var subQuestion: modelData

            width: parent.width
            implicitHeight: batchColumn.implicitHeight + 16
            height: implicitHeight
            radius: 9
            color: "#1f1d2e"
            border.width: 1
            border.color: "#403d52"

            Column {
              id: batchColumn
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.top: parent.top
              anchors.margins: 8
              spacing: 6

              Text {
                width: parent.width
                text: (batchCard.index + 1) + ". " + batchCard.subQuestion.title
                color: "#e0def4"
                font.pixelSize: 15
                font.weight: Font.DemiBold
                wrapMode: Text.WordWrap
                renderType: Text.NativeRendering
              }

              Text {
                visible: batchCard.subQuestion.message.length > 0
                width: parent.width
                text: batchCard.subQuestion.message
                color: "#908caa"
                font.pixelSize: 12
                wrapMode: Text.WordWrap
                renderType: Text.NativeRendering
              }

              Row {
                spacing: 5
                visible: batchCard.subQuestion.method === "confirm"

                ActionButton {
                  label: "Yes"
                  selected: !!card.batchValue(batchCard.index) && card.batchValue(batchCard.index).confirmed === true
                  enabled: !card.question.answering
                  onClicked: card.setBatchValue(batchCard.index, { confirmed: true })
                }
                ActionButton {
                  label: "No"
                  selected: !!card.batchValue(batchCard.index) && card.batchValue(batchCard.index).confirmed === false
                  enabled: !card.question.answering
                  onClicked: card.setBatchValue(batchCard.index, { confirmed: false })
                }
              }

              Column {
                width: parent.width
                spacing: 4
                visible: batchCard.subQuestion.method === "select"

                Repeater {
                  model: batchCard.subQuestion.options
                  delegate: OptionButton {
                    required property string modelData
                    option: modelData
                    selected: !!card.batchValue(batchCard.index) && card.batchValue(batchCard.index).value === modelData
                    enabled: !card.question.answering
                    onClicked: card.setBatchValue(batchCard.index, { value: modelData })
                  }
                }
              }

              Column {
                width: parent.width
                spacing: 4
                visible: batchCard.subQuestion.method === "multiselect"

                Repeater {
                  model: batchCard.subQuestion.options
                  delegate: OptionButton {
                    required property string modelData
                    option: modelData
                    selected: !!card.batchValue(batchCard.index)
                      && card.batchValue(batchCard.index).values.indexOf(modelData) >= 0
                    enabled: !card.question.answering
                    onClicked: card.toggleBatchOption(batchCard.index, modelData)
                  }
                }
              }

              Rectangle {
                width: parent.width
                height: 32
                radius: 8
                visible: batchCard.subQuestion.method === "input"
                color: "#26233a"
                border.width: 1
                border.color: "#403d52"

                TextInput {
                  anchors.fill: parent
                  anchors.leftMargin: 9
                  anchors.rightMargin: 9
                  text: {
                    var answer = card.batchValue(batchCard.index)
                    return answer && answer.value !== undefined ? answer.value : ""
                  }
                  color: "#e0def4"
                  font.pixelSize: 11
                  enabled: !card.question.answering
                  clip: true
                  onTextChanged: card.setBatchValue(batchCard.index, { value: text })
                }
              }
            }
          }
        }

        ActionButton {
          label: "Submit all"
          primary: true
          enabled: !card.question.answering && card.canSubmitBatch()
          onClicked: PiDashboardQuestions.answer(card.question.id, { answers: card.batchAnswers })
        }
      }

      ActionButton {
        label: card.question.answering ? "Waiting for dashboard…" : "Cancel question"
        enabled: !card.question.answering
        onClicked: PiDashboardQuestions.cancel(card.question.id)
      }
    }
  }

  component FinalMessageCard: Item {
    id: finalCard
    required property var finalMessage

    width: root.contentWidth
    implicitHeight: finalMessageText.implicitHeight + 12
    height: implicitHeight

    Text {
      id: finalMessageText
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: 6
      anchors.rightMargin: 6
      text: finalCard.finalMessage.text
      color: "#e0def4"
      font.pixelSize: 18
      lineHeight: 1.2
      wrapMode: Text.WordWrap
      textFormat: Text.MarkdownText
      renderType: Text.NativeRendering
    }
  }

  Flickable {
    visible: root.messageOnly
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.leftMargin: root.horizontalPadding
    anchors.rightMargin: root.horizontalPadding
    anchors.topMargin: root.verticalPadding
    height: root.messageListHeight
    clip: true
    contentWidth: width
    contentHeight: messageColumn.implicitHeight
    boundsBehavior: Flickable.StopAtBounds

    Column {
      id: messageColumn
      width: parent.width
      spacing: 8

      Repeater {
        model: PiDashboardQuestions.visibleFinalMessages
        delegate: FinalMessageCard {
          required property var modelData
          finalMessage: modelData
        }
      }
    }
  }

  Column {
    visible: !root.messageOnly
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: root.horizontalPadding
    spacing: 0

    Item {
      id: header
      width: parent.width
      height: 34

      Column {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1

        Text {
          text: "Coding agents"
          color: "#ebbcba"
          font.pixelSize: 15
          font.weight: Font.Bold
          renderType: Text.NativeRendering
        }
        Text {
          text: PiDashboardQuestions.hasQuestions
            ? PiDashboardQuestions.questions.length + " waiting for you"
            : PiDashboardQuestions.visibleFinalMessages.length > 0
              ? PiDashboardQuestions.visibleFinalMessages.length + " completed"
              : "No pending items"
          color: "#908caa"
          font.pixelSize: 10
          renderType: Text.NativeRendering
        }
      }

      ActionButton {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        label: "Dismiss"
        enabled: true
        onClicked: if (root.wrapper) root.wrapper.close()
      }
    }

    Rectangle {
      width: parent.width
      height: 1
      color: "#403d52"
    }

    Flickable {
      id: questionFlickable
      width: parent.width
      height: root.listHeight
      clip: true
      contentWidth: width
      contentHeight: questionColumn.implicitHeight
      boundsBehavior: Flickable.StopAtBounds

      Column {
        id: questionColumn
        width: questionFlickable.width
        spacing: 8

        Item { width: parent.width; height: 2 }

        Text {
          visible: PiDashboardQuestions.hasQuestions
          width: parent.width
          text: "NEEDS YOU"
          color: "#f6c177"
          font.pixelSize: 9
          font.weight: Font.DemiBold
          renderType: Text.NativeRendering
        }

        Repeater {
          model: PiDashboardQuestions.questions
          delegate: QuestionCard {
            required property var modelData
            question: modelData
          }
        }

        Text {
          visible: PiDashboardQuestions.visibleFinalMessages.length > 0
          width: parent.width
          topPadding: PiDashboardQuestions.hasQuestions ? 4 : 0
          text: "COMPLETED"
          color: "#9ccfd8"
          font.pixelSize: 9
          font.weight: Font.DemiBold
          renderType: Text.NativeRendering
        }

        Repeater {
          model: PiDashboardQuestions.visibleFinalMessages
          delegate: FinalMessageCard {
            required property var modelData
            finalMessage: modelData
          }
        }

        Text {
          visible: !root.hasVisibleItems
          width: parent.width
          text: "New questions and completed replies will appear here."
          color: "#908caa"
          font.pixelSize: 11
          wrapMode: Text.WordWrap
          horizontalAlignment: Text.AlignHCenter
          renderType: Text.NativeRendering
        }
      }
    }

    Rectangle {
      width: parent.width
      height: 1
      color: "#403d52"
    }

    Item {
      id: footer
      width: parent.width
      height: 28

      Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: PiDashboardQuestions.available ? "Live" : "Reconnecting…"
        color: PiDashboardQuestions.available ? "#9ccfd8" : "#908caa"
        font.pixelSize: 10
        renderType: Text.NativeRendering
      }

      Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: PiDashboardQuestions.hasQuestions ? "answers return to Pi" : "final replies stay until dismissed"
        color: "#6e6a86"
        font.pixelSize: 10
        renderType: Text.NativeRendering
      }
    }
  }
}
