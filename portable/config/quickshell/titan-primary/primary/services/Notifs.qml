pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick

Singleton {
  id: root

  readonly property list<Notif> list: []
  readonly property list<Notif> popups: list.filter(function(n) { return n.popup && !n.inline; })
  readonly property list<Notif> inlineNotifications: list.filter(function(n) { return n.popup && n.inline; })
  property int maxStoredNotifications: 80
  property int maxArchivedNotifications: 2000
  property int revision: 0
  property int ageTick: 0
  property bool historyLoaded: false
  property bool loadingHistory: false
  property string _loadOutput: ""
  property var archiveEntries: []
  property var pendingArchiveEntries: []
  property bool archiveLoaded: false
  property bool loadingArchive: false
  property var messengerConversationsData: []
  property var pendingMessengerSnapshots: []
  property bool messengerHistoryLoaded: false
  property bool loadingMessengerHistory: false
  property bool messengerStorageReady: false
  property bool messengerSavePending: false
  property bool messengerHistoryInvalid: false
  property bool messengerQuarantinePending: false
  property bool messengerPermissionRequestPending: false
  property int messengerRevision: 0
  readonly property int maxMessengerMessagesPerConversation: 80
  readonly property int maxMessengerMessagesTotal: 400
  readonly property int maxMessengerConversations: 32
  readonly property double maxMessengerAgeMs: 30 * 24 * 60 * 60 * 1000
  readonly property int messengerDedupWindowMs: 15 * 1000
  readonly property string messengerHistoryPath: {
    const stateHome = Quickshell.env("XDG_STATE_HOME")
      || `${Quickshell.env("HOME")}/.local/state`;
    return `${stateHome}/quickshell/messenger-history-v1.json`;
  }
  readonly property string archivePath: {
    const stateHome = Quickshell.env("XDG_STATE_HOME")
      || `${Quickshell.env("HOME")}/.local/state`;
    return `${stateHome}/quickshell/notification-history.json`;
  }

  function compactText(text): string {
    return (text || "")
      .replace(/<[^>]+>/g, " ")
      .replace(/\[([^\]]+)\]\(([^)]+)\)/g, "$1")
      .replace(/\s+/g, " ")
      .trim();
  }

  function truncateText(text, maxLen): string {
    const compact = compactText(text);
    if (compact.length <= maxLen)
      return compact;
    return compact.slice(0, Math.max(0, maxLen - 1)).trim() + "…";
  }

  function isMessengerNotification(notification): bool {
    return !!notification
      && compactText(notification.appName || "") === "KDE Connect"
      && compactText(notification.summary || "") === "Messenger";
  }

  function messengerSnapshot(notification): var {
    if (!root.isMessengerNotification(notification))
      return null;

    const body = compactText(notification.body || "");
    if (!body)
      return null;

    const sourceId = notification.id !== undefined && notification.id !== null
      ? String(notification.id) : "";
    const match = body.match(/^([^:\n]{1,80}):\s+(.+)$/);
    let sender = match ? compactText(match[1]) : "";
    if (!sender || !/^[A-Za-zÀ-ÖØ-öø-ÿ]/.test(sender))
      sender = "";

    const message = match && sender ? match[2] : body;
    if (!sender && !sourceId)
      return null;

    const key = sender
      ? sender.toLowerCase().replace(/\s+/g, " ").trim()
      : `unknown::${sourceId}`;
    return {
      key: key,
      label: sender || "Unknown conversation",
      sender: sender || "Unknown sender",
      body: truncateText(message, 2000),
      sourceId: sourceId,
      time: Date.now()
    };
  }

  function addMessengerSnapshot(snapshot): bool {
    if (!snapshot || !snapshot.body)
      return false;

    let conversation = null;
    for (const candidate of root.messengerConversationsData) {
      if (candidate.key === snapshot.key) {
        conversation = candidate;
        break;
      }
    }

    if (!conversation) {
      conversation = { key: snapshot.key, label: snapshot.label, messages: [] };
      root.messengerConversationsData = root.messengerConversationsData.concat([conversation]);
    }

    const newest = conversation.messages.length > 0 ? conversation.messages[0] : null;
    if (newest && newest.sender === snapshot.sender && newest.body === snapshot.body
        && snapshot.sourceId && newest.sourceId === snapshot.sourceId)
      return false;

    for (const message of conversation.messages) {
      if (message.sender !== snapshot.sender || message.body !== snapshot.body)
        continue;
      if ((!snapshot.sourceId || message.sourceId !== snapshot.sourceId)
          && Math.abs(snapshot.time - message.time) <= root.messengerDedupWindowMs)
        return false;
    }

    conversation.messages.unshift({
      time: snapshot.time,
      sender: snapshot.sender,
      sourceId: snapshot.sourceId || "",
      body: snapshot.body
    });
    root.pruneMessengerHistory();
    root.messengerRevision += 1;
    root.scheduleMessengerSave();
    return true;
  }

  function recordMessengerSnapshot(notification): void {
    const snapshot = root.messengerSnapshot(notification);
    if (!snapshot)
      return;

    if (!root.messengerHistoryLoaded) {
      root.pendingMessengerSnapshots = root.pendingMessengerSnapshots.concat([snapshot]);
      return;
    }
    root.addMessengerSnapshot(snapshot);
  }

  function pruneMessengerHistory(): bool {
    const cutoff = Date.now() - root.maxMessengerAgeMs;
    const conversations = [];
    let allMessages = [];
    let beforeCount = 0;
    for (const conversation of root.messengerConversationsData)
      beforeCount += (conversation.messages || []).length;
    const beforeConversationCount = root.messengerConversationsData.length;

    for (const conversation of root.messengerConversationsData) {
      const messages = (conversation.messages || [])
        .filter(function(message) {
          return message && isFinite(Number(message.time))
            && Number(message.time) >= cutoff
            && typeof message.body === "string" && message.body.length > 0;
        })
        .sort(function(a, b) { return Number(b.time) - Number(a.time); })
        .slice(0, root.maxMessengerMessagesPerConversation);
      if (messages.length === 0)
        continue;
      conversation.messages = messages;
      allMessages = allMessages.concat(messages.map(function(message) {
        return { conversation: conversation, message: message };
      }));
      conversations.push(conversation);
    }

    allMessages.sort(function(a, b) { return Number(b.message.time) - Number(a.message.time); });
    for (const entry of allMessages.slice(root.maxMessengerMessagesTotal)) {
      const index = entry.conversation.messages.indexOf(entry.message);
      if (index >= 0)
        entry.conversation.messages.splice(index, 1);
    }

    const kept = conversations.filter(function(conversation) {
      return conversation.messages.length > 0;
    }).sort(function(a, b) {
      return Number(b.messages[0].time) - Number(a.messages[0].time);
    }).slice(0, root.maxMessengerConversations);

    let afterCount = 0;
    for (const conversation of kept)
      afterCount += conversation.messages.length;
    const removed = afterCount < beforeCount || kept.length < beforeConversationCount;
    root.messengerConversationsData = kept;
    return removed;
  }

  function pruneMessengerHistoryPeriodically(): void {
    if (!root.messengerHistoryLoaded || !root.pruneMessengerHistory())
      return;
    root.messengerRevision += 1;
    root.scheduleMessengerSave();
  }

  function messengerConversations(): var {
    root.messengerRevision;
    return root.messengerConversationsData;
  }

  function clearMessengerConversation(key): void {
    const kept = root.messengerConversationsData.filter(function(conversation) {
      return conversation.key !== key;
    });
    if (kept.length === root.messengerConversationsData.length)
      return;
    root.messengerConversationsData = kept;
    root.messengerRevision += 1;
    root.scheduleMessengerSave();
  }

  function shouldInlineNotification(notification): bool {
    if (!notification)
      return false;

    const summary = compactText(notification.summary);
    const body = compactText(notification.body);
    const hasActions = notification.actions && notification.actions.length > 0;

    if (!summary && !body)
      return false;
    if (notification.urgency === NotificationUrgency.Critical)
      return true;
    if (notification.image || hasActions)
      return false;

    return summary.length <= 34
      && body.length <= 52
      && (summary.length + body.length) <= 70;
  }

  function pruneHistory(): void {
    while (root.list.length > root.maxStoredNotifications) {
      const removed = root.list.shift();
      if (removed) {
        archiveNotif(removed);
        removed.destroy();
      }
    }
  }

  function dismissNotif(notif): void {
    if (!notif)
      return;

    if (notif.notification) {
      notif.notification.dismiss();
    } else {
      archiveNotif(notif);
      removeNotif(notif);
    }
  }

  function removeNotif(notif): void {
    const idx = root.list.indexOf(notif);
    if (idx >= 0) {
      root.list.splice(idx, 1);
      root.revision += 1;
      notif.destroy();
      scheduleSave();
    }
  }

  function clearPopups(): void {
    for (const notif of root.list)
      notif.popup = false;
    scheduleSave();
  }

  function clearAll(): void {
    for (const notif of [...root.list])
      dismissNotif(notif);
  }

  function senderKey(notif): string {
    if (!notif)
      return "unknown";

    const app = compactText(notif.appName || "");
    if (app.length > 0)
      return app;

    return "Unknown sender";
  }

  function groupedBySender(): var {
    const groups = {};

    for (const notif of root.list) {
      const key = senderKey(notif);
      if (!groups[key]) {
        groups[key] = {
          key: key,
          label: key,
          count: 0,
          latest: notif.time,
          latestMs: notif.time.getTime(),
          items: []
        };
      }

      groups[key].items.unshift(notif);
      groups[key].count += 1;
      if (notif.time.getTime() > groups[key].latestMs) {
        groups[key].latest = notif.time;
        groups[key].latestMs = notif.time.getTime();
      }
    }

    return Object.values(groups).sort(function(a, b) {
      return b.latestMs - a.latestMs;
    });
  }

  function typeKey(notif): string {
    if (!notif)
      return "unknown";

    const app = senderKey(notif);
    let summary = compactText(notif.summary || "");

    // Agent notifications commonly encode the useful stream in the summary.
    // Keep the session name, but strip long one-off suffixes for better stacking.
    if (summary.indexOf(" | ") >= 0)
      summary = summary.split(" | ")[0];

    return `${app}::${summary || "Notification"}`;
  }

  function typeLabel(notif): string {
    const summary = compactText(notif.summary || "");
    return summary.length > 0 ? summary : senderKey(notif);
  }

  function bucketKey(time): string {
    const now = new Date();
    const startToday = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
    const ts = time.getTime();
    const ageMs = Date.now() - ts;

    if (ageMs < 60 * 60 * 1000)
      return "now";
    if (ts >= startToday)
      return "today";
    if (ts >= startToday - 24 * 60 * 60 * 1000)
      return "yesterday";
    return "older";
  }

  function bucketLabel(key): string {
    if (key === "now") return "Now";
    if (key === "today") return "Today";
    if (key === "yesterday") return "Yesterday";
    return "Older";
  }

  function recencySections(): var {
    const buckets = {
      now: { key: "now", label: "Now", latestMs: 0, count: 0, stacks: [] },
      today: { key: "today", label: "Today", latestMs: 0, count: 0, stacks: [] },
      yesterday: { key: "yesterday", label: "Yesterday", latestMs: 0, count: 0, stacks: [] },
      older: { key: "older", label: "Older", latestMs: 0, count: 0, stacks: [] }
    };
    const stackMap = {};

    for (const notif of [...root.list].sort(function(a, b) { return b.time.getTime() - a.time.getTime(); })) {
      const bkey = bucketKey(notif.time);
      const skey = `${bkey}::${typeKey(notif)}`;
      if (!stackMap[skey]) {
        stackMap[skey] = {
          key: skey,
          label: typeLabel(notif),
          sender: senderKey(notif),
          count: 0,
          latest: notif.time,
          latestMs: notif.time.getTime(),
          items: []
        };
        buckets[bkey].stacks.push(stackMap[skey]);
      }

      const stack = stackMap[skey];
      stack.items.push(notif);
      stack.count += 1;
      buckets[bkey].count += 1;
      if (notif.time.getTime() > stack.latestMs) {
        stack.latest = notif.time;
        stack.latestMs = notif.time.getTime();
      }
      buckets[bkey].latestMs = Math.max(buckets[bkey].latestMs, stack.latestMs);
    }

    return [buckets.now, buckets.today, buckets.yesterday, buckets.older]
      .filter(function(bucket) { return bucket.stacks.length > 0; })
      .map(function(bucket) {
        bucket.stacks.sort(function(a, b) { return b.latestMs - a.latestMs; });
        return bucket;
      });
  }

  function clearStack(items): void {
    for (const notif of [...items])
      dismissNotif(notif);
  }

  function clearSender(key): void {
    for (const notif of [...root.list]) {
      if (senderKey(notif) === key)
        dismissNotif(notif);
    }
  }

  function serializeNotif(notif): var {
    return {
      time: notif.time.getTime(),
      summary: truncateText(notif.summary || "", 300),
      body: truncateText(notif.body || "", 2000),
      appIcon: notif.appIcon || "",
      appName: notif.appName || "",
      image: notif.image || "",
      urgency: notif.urgency || NotificationUrgency.Normal,
      popup: false,
      inline: false
    };
  }

  function archiveNotif(notif): void {
    if (!notif || notif.archived)
      return;

    notif.archived = true;
    const entry = serializeNotif(notif);
    if (!root.archiveLoaded || root.loadingArchive) {
      root.pendingArchiveEntries = root.pendingArchiveEntries.concat([entry]);
      return;
    }

    root.archiveEntries = root.archiveEntries
      .concat([entry])
      .slice(-root.maxArchivedNotifications);
    scheduleArchiveSave();
  }

  function scheduleArchiveSave(): void {
    if (!root.archiveLoaded || root.loadingArchive)
      return;
    archiveSaveTimer.restart();
  }

  function scheduleMessengerSave(): void {
    if (!root.messengerHistoryLoaded)
      return;
    messengerSaveTimer.restart();
  }

  function ensureMessengerStorage(): void {
    if (root.messengerStorageReady || messengerDirProc.running)
      return;
    messengerDirProc.running = true;
  }

  function ensureMessengerFilePermissions(): void {
    root.messengerPermissionRequestPending = true;
    if (!messengerPermissionProc.running) {
      root.messengerPermissionRequestPending = false;
      messengerPermissionProc.running = true;
    }
  }

  function quarantineMessengerHistory(): void {
    if (!root.messengerHistoryInvalid)
      return;
    root.messengerQuarantinePending = true;
    if (!root.messengerStorageReady) {
      root.ensureMessengerStorage();
      return;
    }
    if (!messengerQuarantineProc.running)
      messengerQuarantineProc.running = true;
  }

  function saveMessengerHistory(): void {
    if (!root.messengerHistoryLoaded)
      return;
    if (root.messengerHistoryInvalid) {
      root.messengerSavePending = true;
      root.quarantineMessengerHistory();
      return;
    }
    if (!root.messengerStorageReady) {
      root.messengerSavePending = true;
      root.ensureMessengerStorage();
      return;
    }

    root.messengerSavePending = false;
    messengerHistoryFile.setText(JSON.stringify({
      version: 1,
      conversations: root.messengerConversationsData
    }));
  }

  function saveArchive(): void {
    archiveFile.setText(JSON.stringify(root.archiveEntries));
  }

  function scheduleSave(): void {
    if (!root.historyLoaded || root.loadingHistory)
      return;
    saveTimer.restart();
  }

  function saveHistory(): void {
    const data = JSON.stringify(root.list.map(serializeNotif));
    const proc = Qt.createQmlObject('import Quickshell.Io; Process { running: false }', root);
    proc.command = [
      "sh", "-c",
      "f=\"${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/notifications.json\"; " +
      "mkdir -p \"$(dirname \"$f\")\" && printf '%s' \"$1\" > \"$f\"",
      "save-notifications",
      data
    ];
    proc.onExited.connect(function() { proc.destroy(); });
    proc.running = true;
  }

  function loadHistory(): void {
    root.loadingHistory = true;
    root._loadOutput = "";
    loadProc.running = true;
  }

  function ingestHistory(output): void {
    const trimmed = (output || "").trim();
    if (!trimmed)
      return;

    try {
      const entries = JSON.parse(trimmed);
      if (!Array.isArray(entries))
        return;

      for (const entry of entries.slice(-root.maxStoredNotifications)) {
        root.list.push(notifComp.createObject(root, {
          popup: false,
          inline: false,
          notification: null,
          persistedTimeMs: Number(entry.time) || Date.now(),
          persistedSummary: truncateText(entry.summary || "", 300),
          persistedBody: truncateText(entry.body || "", 2000),
          persistedAppIcon: entry.appIcon || "",
          persistedAppName: entry.appName || "",
          persistedImage: entry.image || "",
          persistedUrgency: Number(entry.urgency) || NotificationUrgency.Normal
        }));
      }
    } catch (err) {
      console.warn(`[Notifs] failed to load notification list: ${err}`);
    }
  }

  function loadArchive(): void {
    root.loadingArchive = true;
    finishArchiveLoad(archiveFile.text());
  }

  function loadMessengerHistory(): void {
    root.loadingMessengerHistory = true;
    const valid = root.ingestMessengerHistory(messengerHistoryFile.text());
    root.loadingMessengerHistory = false;
    root.messengerHistoryLoaded = true;
    root.messengerHistoryInvalid = !valid;
    const pruned = root.pruneMessengerHistory();

    for (const snapshot of root.pendingMessengerSnapshots)
      root.addMessengerSnapshot(snapshot);
    root.pendingMessengerSnapshots = [];
    root.messengerRevision += 1;
    if (!valid) {
      root.messengerSavePending = true;
      root.quarantineMessengerHistory();
    }
    else if (pruned)
      root.scheduleMessengerSave();
  }

  function ingestMessengerHistory(output): bool {
    const trimmed = (output || "").trim();
    if (!trimmed)
      return true;

    try {
      const data = JSON.parse(trimmed);
      if (!data || data.version !== 1 || !Array.isArray(data.conversations)) {
        console.warn("[Notifs] preserving unsupported Messenger history format");
        return false;
      }

      let invalid = false;
      const conversations = [];
      for (const entry of data.conversations.slice(0, root.maxMessengerConversations)) {
        if (!entry || typeof entry.key !== "string" || !entry.key
            || !Array.isArray(entry.messages)) {
          invalid = true;
          continue;
        }
        if (entry.key === "unknown") {
          invalid = true;
          continue;
        }
        const messages = [];
        for (const message of entry.messages.slice(0, root.maxMessengerMessagesPerConversation)) {
          const time = Number(message && message.time);
          if (!isFinite(time) || typeof (message && message.body) !== "string" || !message.body) {
            invalid = true;
            continue;
          }
          messages.push({
            time: time,
            sender: typeof message.sender === "string" ? truncateText(message.sender, 80) : "Unknown sender",
            sourceId: typeof message.sourceId === "string" ? message.sourceId.slice(0, 128) : "",
            body: truncateText(message.body, 2000)
          });
        }
        if (messages.length > 0) {
          conversations.push({
            key: entry.key.slice(0, 200),
            label: typeof entry.label === "string" && entry.label
              ? truncateText(entry.label, 80) : "Unknown conversation",
            messages: messages
          });
        }
      }
      root.messengerConversationsData = conversations;
      return !invalid;
    } catch (err) {
      root.messengerConversationsData = [];
      console.warn("[Notifs] preserving malformed Messenger history");
      return false;
    }
  }

  function ingestArchive(output): void {
    const trimmed = (output || "").trim();
    if (!trimmed) {
      root.archiveEntries = [];
      return;
    }

    try {
      const entries = JSON.parse(trimmed);
      root.archiveEntries = Array.isArray(entries)
        ? entries.slice(-root.maxArchivedNotifications)
        : [];
    } catch (err) {
      root.archiveEntries = [];
      console.warn(`[Notifs] failed to load notification archive: ${err}`);
    }
  }

  Timer {
    id: saveTimer
    interval: 500
    repeat: false
    onTriggered: root.saveHistory()
  }

  Timer {
    id: archiveSaveTimer
    interval: 500
    repeat: false
    onTriggered: root.saveArchive()
  }

  Timer {
    id: messengerSaveTimer
    interval: 500
    repeat: false
    onTriggered: root.saveMessengerHistory()
  }

  Timer {
    id: messengerPruneTimer
    interval: 60000
    repeat: true
    running: root.messengerHistoryLoaded
    onTriggered: root.pruneMessengerHistoryPeriodically()
  }

  Timer {
    id: messengerPermissionRetryTimer
    interval: 5000
    repeat: false
    onTriggered: root.ensureMessengerFilePermissions()
  }

  Timer {
    id: messengerQuarantineRetryTimer
    interval: 5000
    repeat: false
    onTriggered: root.quarantineMessengerHistory()
  }

  Timer {
    id: messengerStorageRetryTimer
    interval: 5000
    repeat: false
    onTriggered: root.ensureMessengerStorage()
  }

  Timer {
    interval: 15000
    repeat: true
    running: root.list.length > 0
    onTriggered: root.ageTick += 1
  }

  Process {
    id: messengerDirProc
    running: false
    command: [
      "sh", "-c",
      "d=\"${XDG_STATE_HOME:-$HOME/.local/state}/quickshell\"; mkdir -p -- \"$d\""
    ]
    stderr: SplitParser { onRead: function(data) { } }
    onExited: function(exitCode) {
      root.messengerStorageReady = exitCode === 0;
      if (!root.messengerStorageReady) {
        messengerStorageRetryTimer.restart();
        return;
      }
      if (root.messengerHistoryInvalid)
        root.quarantineMessengerHistory();
      else if (root.messengerSavePending)
        root.saveMessengerHistory();
    }
  }

  Process {
    id: messengerQuarantineProc
    running: false
    command: [
      "sh", "-c",
      "f=\"${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/messenger-history-v1.json\"; " +
      "if [ ! -e \"$f\" ]; then exit 0; fi; " +
      "q=\"$f.quarantine-$(date +%s)-$$\"; mv -- \"$f\" \"$q\" && chmod 600 -- \"$q\""
    ]
    stderr: SplitParser { onRead: function(data) { } }
    onExited: function(exitCode) {
      if (exitCode !== 0) {
        root.messengerQuarantinePending = true;
        messengerQuarantineRetryTimer.restart();
        return;
      }
      root.messengerQuarantinePending = false;
      root.messengerHistoryInvalid = false;
      if (root.messengerSavePending)
        root.saveMessengerHistory();
    }
  }

  Process {
    id: messengerPermissionProc
    running: false
    command: [
      "sh", "-c",
      "d=\"${XDG_STATE_HOME:-$HOME/.local/state}/quickshell\"; " +
      "f=\"$d/messenger-history-v1.json\"; umask 077; " +
      "mkdir -p -- \"$d\" && chmod 700 -- \"$d\" && " +
      "if [ ! -e \"$f\" ]; then exit 0; fi; " +
      "chmod 600 -- \"$f\" && [ \"$(stat -c '%a' -- \"$d\")\" = 700 ] && " +
      "[ \"$(stat -c '%a' -- \"$f\")\" = 600 ]"
    ]
    stderr: SplitParser { onRead: function(data) { } }
    onExited: function(exitCode) {
      const rerun = root.messengerPermissionRequestPending;
      root.messengerPermissionRequestPending = false;
      if (exitCode !== 0) {
        root.messengerPermissionRequestPending = true;
        messengerPermissionRetryTimer.restart();
      } else if (rerun) {
        root.ensureMessengerFilePermissions();
      }
    }
  }

  FileView {
    id: messengerHistoryFile
    path: root.messengerHistoryPath
    preload: false
    blockLoading: true
    atomicWrites: true
    printErrors: false
    onSaved: root.ensureMessengerFilePermissions()
    onSaveFailed: function(error) {
      console.warn(`[Notifs] failed to save Messenger history: ${error}`);
    }
  }

  Process {
    id: loadProc
    running: false
    command: [
      "sh", "-c",
      "f=\"${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/notifications.json\"; [ -f \"$f\" ] && cat \"$f\" || true"
    ]
    stdout: SplitParser { onRead: function(data) { root._loadOutput += data.toString(); } }
    stderr: SplitParser { onRead: function(data) { } }
    onExited: function() {
      root.ingestHistory(root._loadOutput);
      root.loadingHistory = false;
      root.historyLoaded = true;
      root.revision += 1;
      root.pruneHistory();
      root.scheduleSave();
    }
  }

  function finishArchiveLoad(output): void {
    root.ingestArchive(output);
    root.loadingArchive = false;
    root.archiveLoaded = true;
    if (root.pendingArchiveEntries.length > 0) {
      root.archiveEntries = root.archiveEntries
        .concat(root.pendingArchiveEntries)
        .slice(-root.maxArchivedNotifications);
      root.pendingArchiveEntries = [];
      root.scheduleArchiveSave();
    }
  }

  FileView {
    id: archiveFile
    path: root.archivePath
    preload: false
    blockLoading: true
    blockWrites: true
    atomicWrites: true
    printErrors: false
    onSaveFailed: function(error) {
      console.warn(`[Notifs] failed to save notification archive: ${error}`);
    }
  }

  Component.onCompleted: {
    root.loadHistory();
    root.loadArchive();
    root.ensureMessengerStorage();
    root.ensureMessengerFilePermissions();
    root.loadMessengerHistory();
  }

  NotificationServer {
    id: server

    keepOnReload: false
    actionsSupported: true
    bodyHyperlinksSupported: true
    bodyImagesSupported: true
    bodyMarkupSupported: true
    imageSupported: true

    onNotification: function(notification) {
      notification.tracked = true;
      root.list.push(notifComp.createObject(root, {
        popup: true,
        inline: root.shouldInlineNotification(notification),
        notification: notification
      }));
      root.recordMessengerSnapshot(notification);
      root.revision += 1;
      root.pruneHistory();
      root.scheduleSave();
    }
  }

  component Notif: QtObject {
    id: notif

    property bool popup
    property bool inline: false
    property var notification: null
    property double persistedTimeMs: Date.now()
    property string persistedSummary: ""
    property string persistedBody: ""
    property string persistedAppIcon: ""
    property string persistedAppName: ""
    property string persistedImage: ""
    property int persistedUrgency: NotificationUrgency.Normal
    property bool archived: false
    property bool finalized: false
    property bool contentUpdatePending: false
    readonly property bool isLive: notification !== null
    readonly property date time: new Date(persistedTimeMs)
    readonly property string timeStr: {
      root.ageTick;
      const now = new Date();
      const ts = time.getTime();
      const diff = Date.now() - ts;
      const minutes = Math.floor(diff / 60000);
      const hours = Math.floor(minutes / 60);
      const startToday = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();

      if (hours < 1 && minutes < 1)
        return "now";
      if (hours < 1)
        return `${minutes}m`;
      if (hours < 12)
        return `${hours}h`;
      if (ts >= startToday)
        return Qt.formatTime(time, "h:mm AP");
      if (ts >= startToday - 24 * 60 * 60 * 1000)
        return `Yesterday ${Qt.formatTime(time, "h:mm AP")}`;
      return Qt.formatDate(time, "MMM d");
    }

    readonly property string summary: notification ? notification.summary : persistedSummary
    readonly property string body: notification ? notification.body : persistedBody
    readonly property string appIcon: notification ? notification.appIcon : persistedAppIcon
    readonly property string appName: notification ? notification.appName : persistedAppName
    readonly property string image: notification ? notification.image : persistedImage
    readonly property int urgency: notification ? notification.urgency : persistedUrgency
    readonly property var actions: notification ? notification.actions : []
    readonly property bool persistent: urgency === NotificationUrgency.Critical

    readonly property Timer timer: Timer {
      running: notif.popup && !notif.persistent
      interval: notification && notification.expireTimeout > 0 ? notification.expireTimeout : 5000
      onTriggered: notif.popup = false
    }

    readonly property Timer contentUpdateTimer: Timer {
      interval: 0
      repeat: false
      onTriggered: {
        notif.contentUpdatePending = false
        if (!notif.isLive || notif.finalized)
          return
        root.recordMessengerSnapshot(notif.notification)
        notif.popup = true
        notif.timer.restart()
      }
    }

    function scheduleContentUpdate(): void {
      if (!notif.isLive || notif.finalized || notif.contentUpdatePending)
        return
      notif.contentUpdatePending = true
      notif.contentUpdateTimer.start()
    }

    function finalizeLiveNotification(): void {
      if (finalized || !notification)
        return;

      finalized = true;
      root.archiveNotif(notif);
      root.removeNotif(notif);
    }

    readonly property Connections contentConn: Connections {
      target: notification

      function onSummaryChanged(): void {
        notif.scheduleContentUpdate()
      }

      function onBodyChanged(): void {
        notif.scheduleContentUpdate()
      }
    }

    readonly property Connections conn: Connections {
      target: notification ? notification.Retainable : null

      function onDropped(): void {
        notif.finalizeLiveNotification();
      }

      function onAboutToDestroy(): void {
        notif.finalizeLiveNotification();
      }
    }
  }

  Component {
    id: notifComp
    Notif {}
  }
}
