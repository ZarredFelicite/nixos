pragma Singleton

import QtQuick

// Portable image: retain the agenda API without starting personal account integrations.
QtObject {
  property int refCount: 0
  property bool connected: false
  property bool checking: false
  property string error: "Calendar sync is disabled on this portable system"
  property var events: []
  property date lastUpdated: new Date(0)
  property double lastManualRefreshMs: 0

  function refresh(manual) {
    // No account access, including manual requests from the agenda popout.
  }
}
