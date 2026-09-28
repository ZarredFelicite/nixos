pragma Singleton

import QtQuick

QtObject {
    id: root

    property int totalTasks: 0
    property int completedTasks: 0
    property int pendingTasks: 0
    property int highPriorityTasks: 0
    property int dueTodayTasks: 0
    property int overdueTasks: 0
    property int dueThisWeekTasks: 0
    property var tasksByCategory: ({})
    property var allTasksMap: ({})  // Map of task path -> full task object
    property string tooltipText: ""
    property string richTooltipText: ""
    
    property bool loading: false
    property date lastUpdated: new Date(0)
    property string error: ""
    
    property int intervalMs: 2 * 60 * 1000
    
    // TaskNotes HTTP API settings
    property string apiBaseUrl: "http://localhost:8787/api"
    property bool apiAvailable: false
    property string apiToken: ""  // Optional bearer token
    property var _healthXhr: null
    property var _tasksXhr: null
    
    property Timer pollTimer: Timer {
        interval: root.intervalMs
        repeat: true
        running: true
        onTriggered: root.refresh()
    }
    
    property Timer apiHealthCheckTimer: Timer {
        interval: 5000  // Check API health every 5 seconds
        repeat: true
        running: true
        onTriggered: root._checkApiHealth()
    }
    
    property bool _initialized: false
    
    Component.onCompleted: {
        // Initial health check before first refresh
        _checkApiHealth()
    }
    
    function refresh() {
        if (loading) return
        _refreshFromAPI()
    }
    
    function _checkApiHealth() {
        if (root._healthXhr && root._healthXhr.readyState !== XMLHttpRequest.DONE) {
            root._healthXhr.abort()
        }

        var xhr = new XMLHttpRequest()
        var self = root
        root._healthXhr = xhr

        xhr.timeout = 4000
        xhr.onreadystatechange = function() {
            if (root._healthXhr !== xhr)
                return
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    self.apiAvailable = true
                } else {
                    self.apiAvailable = false
                }
                root._healthXhr = null
            }
        }
        xhr.onerror = function() {
            if (root._healthXhr !== xhr)
                return
            self.apiAvailable = false
            root._healthXhr = null
        }
        xhr.ontimeout = function() {
            if (root._healthXhr !== xhr)
                return
            self.apiAvailable = false
            root._healthXhr = null
        }
        xhr.open("GET", root.apiBaseUrl + "/health", true)
        xhr.send()
    }
    
    function _refreshFromAPI() {
        root.loading = true
        root.error = ""

        if (root._tasksXhr && root._tasksXhr.readyState !== XMLHttpRequest.DONE) {
            root._tasksXhr.abort()
        }
        
        var xhr = new XMLHttpRequest()
        var self = root
        root._tasksXhr = xhr

        xhr.timeout = 10000
        xhr.onreadystatechange = function() {
            if (root._tasksXhr !== xhr)
                return
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText)
                        if (response.success && response.data && response.data.tasks) {
                            // Filter tasks client-side: exclude archived and done tasks
                            var filteredTasks = []
                            var tasks = response.data.tasks
                            for (var i = 0; i < tasks.length; i++) {
                                var task = tasks[i]
                                if (!task.archived && task.status !== "done") {
                                    filteredTasks.push(task)
                                }
                            }
                            self._parseAPITasks(filteredTasks)
                        } else {
                            self.error = "Invalid API response"
                            self.loading = false
                        }
                    } catch (e) {
                        self.error = "Failed to parse API response: " + e
                        self.loading = false
                    }
                } else {
                    self.error = "API request failed: " + xhr.status
                    self.loading = false
                }
                if (!self.error) {
                    self.loading = false
                }
                root._tasksXhr = null
            }
        }
        xhr.onerror = function() {
            if (root._tasksXhr !== xhr)
                return
            self.error = "API connection failed"
            self.apiAvailable = false
            self.loading = false
            root._tasksXhr = null
        }
        xhr.ontimeout = function() {
            if (root._tasksXhr !== xhr)
                return
            self.error = "API request timed out"
            self.apiAvailable = false
            self.loading = false
            root._tasksXhr = null
        }
        
        // GET all tasks with high limit to avoid pagination (default is 50)
        xhr.open("GET", root.apiBaseUrl + "/tasks?limit=1000", true)
        if (root.apiToken) {
            xhr.setRequestHeader("Authorization", "Bearer " + root.apiToken)
        }
        xhr.send()
    }
    
    function _parseAPITasks(apiTasks) {
        // Convert API tasks to internal format grouped by category
        var temp = {}
        allTasksMap = {}
        
        for (var i = 0; i < apiTasks.length; i++) {
            var task = apiTasks[i]
            var category = _extractCategory(task.path) || "general"
            
            if (!temp[category]) {
                temp[category] = []
            }
            
            // Normalize priority from API (High/Normal/Low) to lowercase
            var priority = task.priority || "Normal"
            priority = priority.toLowerCase()
            if (priority === "normal") priority = "medium"
            
            var taskObj = {
                completed: task.status === "done",
                text: task.title,
                priority: priority,
                due: task.due || "",
                scheduled: task.scheduled || "",
                created: task.dateCreated ? task.dateCreated.split('T')[0] : "",
                path: task.path,
                status: task.status,
                tags: task.tags || [],
                projects: task.projects || [],
                contexts: task.contexts || []
            }
            
            temp[category].push(taskObj)
            allTasksMap[task.path] = taskObj
        }
        
        tasksByCategory = temp
        _finishRefresh()
    }
    
    function _extractCategory(taskPath) {
        // Extract category from TaskNotes path
        // Examples: "TaskNotes/Tasks/work-project.md" -> look for folder hints
        // For now, infer from path structure or fallback to "general"
        if (taskPath.indexOf("work") !== -1) return "work"
        if (taskPath.indexOf("tech") !== -1) return "tech"
        if (taskPath.indexOf("career") !== -1) return "career"
        if (taskPath.indexOf("3d") !== -1 || taskPath.indexOf("3dp") !== -1) return "3dp"
        if (taskPath.indexOf("health") !== -1) return "health"
        return "general"
    }
    

    
    function _finishRefresh() {
        var allTasks = []
        var categories = Object.keys(tasksByCategory)
        for (var i = 0; i < categories.length; i++) {
            var catTasks = tasksByCategory[categories[i]]
            allTasks = allTasks.concat(catTasks)
        }
        
        var completed = 0
        var pending = 0
        var highPrio = 0
        var dueToday = 0
        var overdue = 0
        var dueThisWeek = 0
        
        var today = new Date()
        today.setHours(0, 0, 0, 0)
        
        var oneWeek = new Date(today)
        oneWeek.setDate(oneWeek.getDate() + 7)
        
        for (var j = 0; j < allTasks.length; j++) {
            var task = allTasks[j]
            if (task.completed) {
                completed++
            } else {
                pending++
                
                if (task.priority === "high") {
                    highPrio++
                }
                
                if (task.due) {
                    var dueDate = new Date(task.due)
                    dueDate.setHours(0, 0, 0, 0)
                    
                    if (dueDate.getTime() === today.getTime()) {
                        dueToday++
                    } else if (dueDate < today) {
                        overdue++
                    } else if (dueDate <= oneWeek) {
                        dueThisWeek++
                    }
                }
            }
        }
        
        totalTasks = allTasks.length
        completedTasks = completed
        pendingTasks = pending
        highPriorityTasks = highPrio
        dueTodayTasks = dueToday
        overdueTasks = overdue
        dueThisWeekTasks = dueThisWeek
        
        _buildTooltip()
        lastUpdated = new Date()
        loading = false
    }
    
    function _buildTooltip() {
        var lines = []
        
        if (pendingTasks === 0) {
            lines.push("All tasks complete! ✓")
            tooltipText = lines.join("\n")
            richTooltipText = tooltipText
            return
        }
        
        lines.push("📋 " + pendingTasks + " tasks pending")
        
        if (overdueTasks > 0) {
            lines.push("🔴 " + overdueTasks + " overdue")
        }
        if (dueTodayTasks > 0) {
            lines.push("⚠️  " + dueTodayTasks + " due today")
        }
        if (dueThisWeekTasks > 0) {
            lines.push("📅 " + dueThisWeekTasks + " due this week")
        }
        if (highPriorityTasks > 0) {
            lines.push("❗ " + highPriorityTasks + " high priority")
        }
        
        var categories = Object.keys(tasksByCategory)
        var today = new Date()
        today.setHours(0, 0, 0, 0)
        
        for (var i = 0; i < categories.length; i++) {
            var cat = categories[i]
            var tasks = tasksByCategory[cat]
            var pendingInCat = 0
            var urgentTasks = []
            var highPrio = []
            
            for (var j = 0; j < tasks.length; j++) {
                var task = tasks[j]
                if (!task.completed) {
                    pendingInCat++
                    
                    if (task.due) {
                        var dueDate = new Date(task.due)
                        dueDate.setHours(0, 0, 0, 0)
                        if (dueDate <= today) {
                            urgentTasks.push({ text: task.text, overdue: dueDate < today })
                        }
                    }
                    
                    if (task.priority === "high" && urgentTasks.length === 0) {
                        highPrio.push(task.text)
                    }
                }
            }
            
            if (pendingInCat > 0) {
                lines.push("")
                lines.push("─ " + cat + ": " + pendingInCat)
                
                for (var k = 0; k < Math.min(2, urgentTasks.length); k++) {
                    var taskText = urgentTasks[k].text
                    if (taskText.length > 35) taskText = taskText.substring(0, 32) + "..."
                    var prefix = urgentTasks[k].overdue ? "  🔴 " : "  ⚠️  "
                    lines.push(prefix + taskText)
                }
                
                if (urgentTasks.length === 0 && highPrio.length > 0) {
                    for (var k = 0; k < Math.min(2, highPrio.length); k++) {
                        var taskText = highPrio[k]
                        if (taskText.length > 35) taskText = taskText.substring(0, 32) + "..."
                        lines.push("  ❗ " + taskText)
                    }
                }
            }
        }
        
        tooltipText = lines.join("\n")
        richTooltipText = tooltipText
    }
    
    // API-based task update methods
    function updateTaskViaAPI(taskPath, updates) {
        console.log("Todos: updateTaskViaAPI - path:", taskPath, "updates:", JSON.stringify(updates))
        var xhr = new XMLHttpRequest()
        var self = root
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                console.log("Todos: Update response - status:", xhr.status, "response:", xhr.responseText)
                // Wait 100ms before refreshing to allow API to finish writing
                Qt.callLater(function() {
                    var timer = Qt.createQmlObject('import QtQuick; Timer { interval: 100; repeat: false; running: true }', self)
                    timer.triggered.connect(function() {
                        console.log("Todos: Refreshing after 100ms delay")
                        self.refresh()
                        timer.destroy()
                    })
                })
            }
        }
        xhr.onerror = function() {
            console.log("Todos: Update error - failed to update task")
            self.error = "Failed to update task via API"
        }
        
        var encodedPath = encodeURIComponent(taskPath)
        var url = root.apiBaseUrl + "/tasks/" + encodedPath
        console.log("Todos: Sending PUT to:", url)
        xhr.open("PUT", url, true)
        if (root.apiToken) {
            xhr.setRequestHeader("Authorization", "Bearer " + root.apiToken)
        }
        xhr.setRequestHeader("Content-Type", "application/json")
        xhr.send(JSON.stringify(updates))
    }
}
