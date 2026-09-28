import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Io
import "../../../services"
import "./"

ClippingRectangle {
  id: root
  property var wrapper: null
  property bool expanded: wrapper && wrapper.hasCurrent && wrapper.currentName === 'tooltip-todos'
  property bool hasOwnBackground: true

  readonly property int hPadding: 14
  readonly property int vPadding: 12
  readonly property int maxContentWidth: 460
  readonly property int maxContentHeight: 520

  // Tab state
  property string activeCategory: "all"
  property var categories: {
    var cats = ["all"]
    var keys = Object.keys(Todos.tasksByCategory)
    for (var i = 0; i < keys.length; i++) {
      if (keys[i]) cats.push(keys[i])
    }
    return cats
  }

  implicitWidth: maxContentWidth + hPadding * 2
  implicitHeight: expanded ? Math.min(mainColumn.implicitHeight + vPadding * 2, maxContentHeight) : 0

  y: 0
  opacity: expanded ? Colors.opacity.foreground1 : 0
  layer.enabled: true
  layer.smooth: false

  Behavior on implicitHeight { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
  Behavior on opacity { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

  color: PopoutConfig.backgroundColor
  border.width: PopoutConfig.borderWidth
  border.color: PopoutConfig.borderColor
  radius: PopoutConfig.cornerRadius
  contentInsideBorder: false

  // --- Helper functions ---

  function openInObsidian(filePath) {
    var uri = "obsidian://open?vault=home&file=" + encodeURIComponent(filePath)
    Qt.openUrlExternally(uri)
  }

  function toggleTaskCompletion(taskPath, taskObj) {
    var newStatus = taskObj.completed ? "open" : "done"
    Todos.updateTaskViaAPI(taskPath, { status: newStatus })
  }

  function updateTaskPriority(taskPath, taskObj, priority) {
    var apiPriority = priority === "high" ? "High" : (priority === "medium" ? "Normal" : "Low")
    Todos.updateTaskViaAPI(taskPath, { priority: apiPriority })
  }

  function updateDueDate(taskPath, taskObj, newDate) {
    Todos.updateTaskViaAPI(taskPath, { due: newDate || null })
  }

  function archiveTask(taskPath, taskObj) {
    Todos.updateTaskViaAPI(taskPath, { archived: true })
  }

  function relativeDate(dateStr) {
    if (!dateStr) return ""
    var d = new Date(dateStr)
    d.setHours(0, 0, 0, 0)
    var now = new Date()
    now.setHours(0, 0, 0, 0)
    var diffMs = d.getTime() - now.getTime()
    var diffDays = Math.round(diffMs / 86400000)

    if (diffDays === 0) return "Today"
    if (diffDays === 1) return "Tomorrow"
    if (diffDays === -1) return "Yesterday"
    if (diffDays < -1) return Math.abs(diffDays) + "d ago"
    if (diffDays <= 7) return "in " + diffDays + "d"
    var months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']
    return months[d.getMonth()] + " " + d.getDate()
  }

  function priorityColor(prio) {
    if (prio === 'high') return Colors.todoPriorityHigh
    if (prio === 'medium') return Colors.todoPriorityMedium
    return Colors.todoPriorityLow
  }

  function dateColor(task) {
    if (task.isOverdue) return Colors.todoDateOverdue
    if (task.hasDue) return Colors.todoDateDue
    return Colors.todoDateNoDue
  }

  function dateBgColor(task) {
    if (task.isOverdue) return Qt.rgba(235/255, 111/255, 146/255, 0.15)
    if (task.hasDue) return Qt.rgba(156/255, 207/255, 216/255, 0.15)
    return Qt.rgba(110/255, 106/255, 134/255, 0.15)
  }

  function getFilteredTasks() {
    var allTasks = []
    var keys = Object.keys(Todos.tasksByCategory)

    for (var i = 0; i < keys.length; i++) {
      var key = keys[i]
      var tasks = Todos.tasksByCategory[key]

      for (var j = 0; j < tasks.length; j++) {
        var task = tasks[j]
        if (!task.completed) {
          if (activeCategory !== "all" && key !== activeCategory) continue

          var displayDate = task.due || task.scheduled || task.created || ''
          var hasDue = !!task.due
          var today = new Date()
          today.setHours(0, 0, 0, 0)
          var isOverdue = hasDue && displayDate ? (new Date(displayDate) < today) : false

          allTasks.push({
            taskPath: task.path || '',
            text: task.text,
            completed: task.completed,
            priority: task.priority || 'low',
            due: task.due || '',
            scheduled: task.scheduled || '',
            created: task.created || '',
            displayDate: displayDate,
            hasDue: hasDue,
            isOverdue: isOverdue,
            status: task.status || 'open',
            tags: task.tags || [],
            category: key,
            fullTaskObj: task
          })
        }
      }
    }

    allTasks.sort(function(a, b) {
      if (a.isOverdue !== b.isOverdue) return a.isOverdue ? -1 : 1
      if (a.hasDue !== b.hasDue) return a.hasDue ? -1 : 1
      if (a.displayDate && b.displayDate) {
        var dateCompare = new Date(a.displayDate) - new Date(b.displayDate)
        if (dateCompare !== 0) return dateCompare
      }
      var priorityOrder = { 'high': 0, 'medium': 1, 'low': 2 }
      return (priorityOrder[a.priority] || 2) - (priorityOrder[b.priority] || 2)
    })

    return allTasks
  }


  Column {
    id: mainColumn
    spacing: 10
    anchors.top: parent.top
    anchors.topMargin: root.vPadding
    anchors.horizontalCenter: parent.horizontalCenter
    width: root.maxContentWidth
    opacity: expanded ? Colors.opacity.foreground1 : 0
    Behavior on opacity { NumberAnimation { duration: 120 } }

    // ── Hero section ──
    Rectangle {
      width: parent.width
      height: heroContent.height + 16
      radius: 10
      color: Qt.rgba(1, 1, 1, 0.03)
      border.width: 1
      border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.15)

      Rectangle {
        anchors.fill: parent
        radius: 10
        gradient: Gradient {
          orientation: Gradient.Horizontal
          GradientStop { position: 0.0; color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.08) }
          GradientStop { position: 1.0; color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.02) }
        }
      }

      Row {
        id: heroContent
        spacing: 16
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.top: parent.top
        anchors.topMargin: 10

        // Main count
        Row {
          spacing: 6
          anchors.verticalCenter: parent.verticalCenter

          Text {
            text: Todos.pendingTasks === 0 ? "check_circle" : Todos.pendingTasks.toString()
            font.pixelSize: Todos.pendingTasks === 0 ? 24 : 28
            font.weight: Font.Bold
            font.family: Todos.pendingTasks === 0 ? "Material Symbols Outlined" : Qt.application.font.family
            color: Todos.pendingTasks === 0 ? Colors.success : PopoutConfig.textColor
            renderType: Text.NativeRendering
          }
          Text {
            text: Todos.pendingTasks === 1 ? "task" : "tasks"
            font.pixelSize: 14
            color: PopoutConfig.textColor
            opacity: 0.7
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 4
            renderType: Text.NativeRendering
          }
        }

        // Stat badges
        Row {
          spacing: 6
          anchors.verticalCenter: parent.verticalCenter

          // Overdue badge
          Rectangle {
            visible: Todos.overdueTasks > 0
            width: overdueText.width + 14
            height: 22
            radius: 11
            color: Qt.rgba(235/255, 111/255, 146/255, 0.2)

            Text {
              id: overdueText
              anchors.centerIn: parent
              text: "!" + Todos.overdueTasks
              font.pixelSize: 11
              font.weight: Font.DemiBold
              color: Colors.todoDateOverdue
              renderType: Text.NativeRendering
            }
          }

          // Today badge
          Rectangle {
            visible: Todos.dueTodayTasks > 0
            width: todayText.width + 14
            height: 22
            radius: 11
            color: Qt.rgba(235/255, 188/255, 186/255, 0.2)

            Text {
              id: todayText
              anchors.centerIn: parent
              text: "Today " + Todos.dueTodayTasks
              font.pixelSize: 11
              font.weight: Font.DemiBold
              color: Colors.todoPriorityMedium
              renderType: Text.NativeRendering
            }
          }

          // Week badge
          Rectangle {
            visible: Todos.dueThisWeekTasks > 0 && Todos.dueTodayTasks === 0
            width: weekText.width + 14
            height: 22
            radius: 11
            color: Qt.rgba(1, 1, 1, 0.06)

            Text {
              id: weekText
              anchors.centerIn: parent
              text: "Week " + Todos.dueThisWeekTasks
              font.pixelSize: 11
              font.weight: Font.DemiBold
              color: PopoutConfig.textColor
              opacity: 0.8
              renderType: Text.NativeRendering
            }
          }
        }

        // Spacer
        Item { width: 1; height: 1; Layout.fillWidth: true }

        // Open in Obsidian
        Item {
          width: heroOpenText.implicitWidth + 12
          height: 24
          anchors.verticalCenter: parent.verticalCenter

          Rectangle {
            anchors.fill: parent
            radius: 6
            color: heroOpenHover.hovered ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
          }

          Text {
            id: heroOpenText
            anchors.centerIn: parent
            text: "open_in_new"
            font.family: "Material Symbols Outlined"
            font.pixelSize: 16
            color: Colors.primary
            opacity: heroOpenHover.hovered ? 1.0 : 0.6
            renderType: Text.NativeRendering
          }

          HoverHandler { id: heroOpenHover }
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.openInObsidian("todo.md")
          }
        }
      }
    }

    // ── Tab bar ──
    Row {
      id: tabBar
      spacing: 4
      width: parent.width

      Repeater {
        model: root.categories

        delegate: Rectangle {
          id: tabBtn
          required property var modelData
          required property int index
          property bool isActive: root.activeCategory === modelData
          property int catCount: {
            if (modelData === "all") return Todos.pendingTasks
            var catTasks = Todos.tasksByCategory[modelData]
            if (!catTasks) return 0
            var count = 0
            for (var i = 0; i < catTasks.length; i++) {
              if (!catTasks[i].completed) count++
            }
            return count
          }

          width: tabLabel.width + 16
          height: 26
          radius: 13
          color: isActive ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.2) : (tabHover.hovered ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(1, 1, 1, 0.03))
          border.width: isActive ? 1 : 0
          border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.4)
          visible: catCount > 0 || modelData === "all"

          Behavior on color { ColorAnimation { duration: 100 } }

          Text {
            id: tabLabel
            anchors.centerIn: parent
            text: modelData === "all" ? ("All " + parent.catCount) : (modelData.charAt(0).toUpperCase() + modelData.slice(1) + " " + parent.catCount)
            font.pixelSize: 11
            font.weight: parent.isActive ? Font.DemiBold : Font.Normal
            color: parent.isActive ? Colors.primary : PopoutConfig.textColor
            opacity: parent.isActive ? 1.0 : 0.7
            renderType: Text.NativeRendering
          }

          HoverHandler { id: tabHover }
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.activeCategory = parent.modelData
          }
        }
      }
    }

    // Divider
    Rectangle {
      width: parent.width
      height: 1
      color: PopoutConfig.borderColor
      opacity: 0.15
    }

    // ── Task list (scrollable) ──
    ScrollView {
      id: taskScrollView
      width: parent.width
      height: Math.min(taskList.implicitHeight, root.maxContentHeight - 180)
      clip: true

      ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
      ScrollBar.vertical.policy: ScrollBar.AsNeeded

      Column {
        id: taskList
        spacing: 3
        width: taskScrollView.width

        Repeater {
          model: root.getFilteredTasks()

          delegate: Rectangle {
            id: taskCard
            required property var modelData
            required property int index

            width: parent.width
            height: cardContent.implicitHeight + 12
            radius: 8
            color: cardHover.hovered ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(1, 1, 1, 0.02)
            border.width: 1
            border.color: cardHover.hovered ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.2) : Qt.rgba(1, 1, 1, 0.04)

            Behavior on color { ColorAnimation { duration: 80 } }
            Behavior on border.color { ColorAnimation { duration: 80 } }

            // Priority left accent bar
            Rectangle {
              width: 3
              height: parent.height - 8
              radius: 1.5
              anchors.left: parent.left
              anchors.leftMargin: 5
              anchors.verticalCenter: parent.verticalCenter
              color: root.priorityColor(taskCard.modelData.priority)
              opacity: 0.8
            }

            HoverHandler { id: cardHover }

            Column {
              id: cardContent
              anchors.left: parent.left
              anchors.leftMargin: 14
              anchors.right: parent.right
              anchors.rightMargin: 8
              anchors.verticalCenter: parent.verticalCenter
              spacing: 3

              // Row 1: checkbox + task text + archive
              Row {
                width: parent.width
                spacing: 6

                // Checkbox (Material icon)
                Text {
                  id: cbIcon
                  text: taskCard.modelData.completed ? "check_box" : "check_box_outline_blank"
                  font.family: "Material Symbols Outlined"
                  font.pixelSize: 18
                  color: taskCard.modelData.completed ? Colors.success : PopoutConfig.textColor
                  opacity: cbHover.hovered ? 1.0 : 0.6
                  anchors.verticalCenter: parent.verticalCenter
                  renderType: Text.NativeRendering

                  HoverHandler { id: cbHover }
                  MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleTaskCompletion(taskCard.modelData.taskPath, taskCard.modelData.fullTaskObj)
                  }
                }

                // Task text (clickable to open in Obsidian)
                Text {
                  id: taskTextLabel
                  text: taskCard.modelData.text
                  font.pixelSize: 12
                  color: PopoutConfig.textColor
                  elide: Text.ElideRight
                  width: parent.width - cbIcon.width - archiveBtn.width - 16
                  anchors.verticalCenter: parent.verticalCenter
                  renderType: Text.NativeRendering

                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.openInObsidian(taskCard.modelData.taskPath)
                  }
                }

                // Archive button
                Text {
                  id: archiveBtn
                  text: "close"
                  font.family: "Material Symbols Outlined"
                  font.pixelSize: 16
                  color: PopoutConfig.textColor
                  opacity: archiveHover.hovered ? 0.9 : 0.25
                  anchors.verticalCenter: parent.verticalCenter
                  renderType: Text.NativeRendering

                  HoverHandler { id: archiveHover }
                  MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.archiveTask(taskCard.modelData.taskPath, taskCard.modelData.fullTaskObj)
                  }
                }
              }

              // Row 2: category chip + date controls
              Row {
                width: parent.width
                spacing: 6
                leftPadding: 24  // align under task text (past checkbox)

                // Category chip (only in "all" tab)
                Rectangle {
                  visible: root.activeCategory === "all" && taskCard.modelData.category !== ""
                  width: catChipText.width + 10
                  height: 16
                  radius: 4
                  color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.12)
                  anchors.verticalCenter: parent.verticalCenter

                  Text {
                    id: catChipText
                    anchors.centerIn: parent
                    text: taskCard.modelData.category
                    font.pixelSize: 9
                    font.weight: Font.Medium
                    color: Colors.primary
                    opacity: 0.7
                    renderType: Text.NativeRendering
                  }
                }

                // Priority pip (clickable to cycle)
                Rectangle {
                  width: 8
                  height: 8
                  radius: 4
                  color: root.priorityColor(taskCard.modelData.priority)
                  opacity: prioHover.hovered ? 1.0 : 0.7
                  anchors.verticalCenter: parent.verticalCenter

                  HoverHandler { id: prioHover }
                  MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      var p = taskCard.modelData.priority
                      var nextPrio = p === 'low' ? 'medium' : (p === 'medium' ? 'high' : 'low')
                      root.updateTaskPriority(taskCard.modelData.taskPath, taskCard.modelData.fullTaskObj, nextPrio)
                    }
                  }
                }

                // Date badge
                Rectangle {
                  visible: taskCard.modelData.displayDate !== ''
                  width: dateBadgeLabel.width + 10
                  height: 16
                  radius: 4
                  color: root.dateBgColor(taskCard.modelData)
                  anchors.verticalCenter: parent.verticalCenter

                  Text {
                    id: dateBadgeLabel
                    anchors.centerIn: parent
                    text: root.relativeDate(taskCard.modelData.displayDate)
                    font.pixelSize: 9
                    font.weight: Font.Medium
                    color: root.dateColor(taskCard.modelData)
                    renderType: Text.NativeRendering
                  }

                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      if (taskCard.modelData.hasDue) {
                        root.updateDueDate(taskCard.modelData.taskPath, taskCard.modelData.fullTaskObj, "")
                      }
                    }
                  }
                }

                // Date navigation arrows (only when has due date)
                Row {
                  visible: taskCard.modelData.hasDue && taskCard.modelData.displayDate !== ''
                  spacing: 0
                  anchors.verticalCenter: parent.verticalCenter

                  Text {
                    text: "chevron_left"
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 14
                    color: Colors.primary
                    opacity: dateLeftHover.hovered ? 0.9 : 0.35
                    renderType: Text.NativeRendering

                    HoverHandler { id: dateLeftHover }
                    MouseArea {
                      anchors.fill: parent
                      anchors.margins: -3
                      cursorShape: Qt.PointingHandCursor
                      onClicked: {
                        var baseDate = new Date(taskCard.modelData.displayDate)
                        baseDate.setDate(baseDate.getDate() - 1)
                        root.updateDueDate(taskCard.modelData.taskPath, taskCard.modelData.fullTaskObj, baseDate.toISOString().split('T')[0])
                      }
                    }
                  }

                  Text {
                    text: "chevron_right"
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 14
                    color: Colors.primary
                    opacity: dateRightHover.hovered ? 0.9 : 0.35
                    renderType: Text.NativeRendering

                    HoverHandler { id: dateRightHover }
                    MouseArea {
                      anchors.fill: parent
                      anchors.margins: -3
                      cursorShape: Qt.PointingHandCursor
                      onClicked: {
                        var baseDate = new Date(taskCard.modelData.displayDate)
                        baseDate.setDate(baseDate.getDate() + 1)
                        root.updateDueDate(taskCard.modelData.taskPath, taskCard.modelData.fullTaskObj, baseDate.toISOString().split('T')[0])
                      }
                    }
                  }
                }

                // Add due date button (only when no due date)
                Text {
                  visible: !taskCard.modelData.hasDue
                  text: "event"
                  font.family: "Material Symbols Outlined"
                  font.pixelSize: 14
                  color: Colors.primary
                  opacity: addDateHover.hovered ? 0.8 : 0.3
                  anchors.verticalCenter: parent.verticalCenter
                  renderType: Text.NativeRendering

                  HoverHandler { id: addDateHover }
                  MouseArea {
                    anchors.fill: parent
                    anchors.margins: -3
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      var today = new Date()
                      root.updateDueDate(taskCard.modelData.taskPath, taskCard.modelData.fullTaskObj, today.toISOString().split('T')[0])
                    }
                  }
                }
              }
            }
          }
        }

        // Empty state
        Item {
          visible: root.getFilteredTasks().length === 0
          width: parent.width
          height: 60

          Column {
            anchors.centerIn: parent
            spacing: 4

            Text {
              text: "task_alt"
              font.family: "Material Symbols Outlined"
              font.pixelSize: 28
              color: Colors.success
              opacity: 0.5
              anchors.horizontalCenter: parent.horizontalCenter
              renderType: Text.NativeRendering
            }
            Text {
              text: root.activeCategory === "all" ? "All tasks complete!" : "No tasks in this category"
              font.pixelSize: 12
              color: PopoutConfig.textColor
              opacity: 0.5
              anchors.horizontalCenter: parent.horizontalCenter
              renderType: Text.NativeRendering
            }
          }
        }
      }
    }

    // Error state
    Rectangle {
      visible: Todos.error !== ""
      width: parent.width
      height: errorRow.height + 12
      radius: 6
      color: Qt.rgba(235/255, 111/255, 146/255, 0.1)

      Row {
        id: errorRow
        spacing: 6
        anchors.centerIn: parent

        Text {
          text: "warning"
          font.family: "Material Symbols Outlined"
          font.pixelSize: 14
          color: PopoutConfig.errorColor
          anchors.verticalCenter: parent.verticalCenter
          renderType: Text.NativeRendering
        }

        Text {
          text: Todos.error
          font.pixelSize: 11
          color: PopoutConfig.errorColor
          wrapMode: Text.Wrap
          width: root.maxContentWidth - 40
          renderType: Text.NativeRendering
        }
      }
    }
  }
}
