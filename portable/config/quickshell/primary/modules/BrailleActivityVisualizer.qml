import QtQuick

// A uniformly spaced dot field inspired by the activity-spinner animations.
// The animation is timer-driven rather than dynamically creating QML objects.
Item {
  id: root

  property string activityMode: "idle" // automatic activity state
  property string manualMode: "auto" // auto, thinking, generating, compacting, completion, idle
  property bool gatewayUp: true
  property bool visualizerEnabled: true
  property bool audioActive: false
  property real audioLevel: 0
  property string audioSource: "none" // none, tts, stt
  property bool audioGateActive: false
  property int audioGateClockMs: 0
  property int audioLastAudibleMs: 0
  property var audioBarHeights: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
  property var audioBarTargets: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
  property var audioBarAnimationFrom: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
  readonly property real audioGain: 8.25
  readonly property bool audioModeActive: manualMode === "auto"
    && ((audioActive && (audioSource === "tts" || audioSource === "stt")) || audioGateActive)
  property int audioSampleIndex: 0
  property int audioAnimationElapsedMs: 0
  readonly property bool audioRenderActive: manualMode === "auto"
    && ((audioActive && audioSource === "stt") || audioGateActive)
  readonly property int gridColumns: 12
  readonly property int gridRows: 5
  readonly property color dimIris: "#5b546f"
  readonly property color brightIris: "#c4a7e7"
  readonly property string normalizedActivityMode: normalizeMode(activityMode)
  readonly property string normalizedManualMode: normalizeMode(manualMode)
  readonly property string effectiveActivityMode: manualMode === "auto"
    ? normalizedActivityMode : normalizedManualMode
  readonly property bool manualCompletionHold: manualMode === "completion"
  readonly property int completionVisualDuration: 1000
  readonly property real dotDiameter: Math.min(8, Math.max(3, Math.min(width / gridColumns, height / gridRows) * 0.48))
  readonly property real dotPitch: Math.min(
    (width - dotDiameter) / (gridColumns - 1),
    (height - dotDiameter) / (gridRows - 1)
  )
  readonly property real dotFieldWidth: dotDiameter + (gridColumns - 1) * dotPitch
  readonly property real dotFieldHeight: dotDiameter + (gridRows - 1) * dotPitch
  // The fade follows a capsule distance field. The outer feather expands equally
  // on both axes, while the inner paths keep the original capsule centerline.
  readonly property real baseBackgroundPaddingX: Math.max(12, dotDiameter * 6)
  readonly property real baseBackgroundPaddingY: Math.max(8, dotDiameter * 4)
  readonly property real backgroundFadeExpansion: Math.max(8, dotDiameter * 2)
  readonly property real baseBackgroundWidth: dotFieldWidth + baseBackgroundPaddingX * 2
  readonly property real baseBackgroundHeight: dotFieldHeight + baseBackgroundPaddingY * 2
  readonly property real backgroundPaddingX: baseBackgroundPaddingX + backgroundFadeExpansion
  readonly property real backgroundPaddingY: baseBackgroundPaddingY + backgroundFadeExpansion
  readonly property real backgroundWidth: dotFieldWidth + backgroundPaddingX * 2
  readonly property real backgroundHeight: dotFieldHeight + backgroundPaddingY * 2
  property string renderedMode: "idle"
  property double animationStartedAt: 0
  property double elapsedMs: 0
  property bool initialized: false

  implicitWidth: 56
  implicitHeight: 36
  width: implicitWidth
  height: implicitHeight

  function normalizeMode(value) {
    var mode = String(value || "idle").toLowerCase()
    if (mode === "tool" || mode === "reasoning") return "thinking"
    if (mode === "text" || mode === "streaming") return "generating"
    if (mode === "compact" || mode === "compaction") return "compacting"
    if (mode === "thinking" || mode === "generating" || mode === "compacting"
        || mode === "completion" || mode === "idle") return mode
    return "idle"
  }

  function intervalFor(mode) {
    if (mode === "completion") return 35
    if (mode === "thinking" || mode === "generating" || mode === "compacting") return 16
    if (mode === "idle") return 40
    return 0
  }

  function beginMode(mode) {
    root.renderedMode = mode
    root.animationStartedAt = Date.now()
    root.elapsedMs = 0
    refreshTimer.interval = root.intervalFor(mode)
    refreshTimer.restart()
  }

  function finishToIdle() {
    root.renderedMode = "idle"
    root.animationStartedAt = Date.now()
    root.elapsedMs = 0
  }

  function startCompletion() {
    root.renderedMode = "completion"
    root.animationStartedAt = Date.now()
    root.elapsedMs = 0
    refreshTimer.interval = 35
    refreshTimer.restart()
  }

  function refreshFrame() {
    if (!root.visualizerEnabled) {
      refreshTimer.stop()
      return
    }

    root.elapsedMs = Math.max(0, Date.now() - root.animationStartedAt)
    if (root.renderedMode === "completion") {
      if (!root.manualCompletionHold && root.elapsedMs >= 5000) {
        root.finishToIdle()
      } else if (root.manualCompletionHold && root.elapsedMs >= root.completionVisualDuration) {
        // Manual preview keeps its selection, but the success ripple is one-shot.
        refreshTimer.stop()
      }
    }
  }

  function rgbColor(red, green, blue, alpha) {
    return Qt.rgba(red / 255, green / 255, blue / 255, alpha === undefined ? 1 : alpha)
  }

  function irisColor(intensity, alpha) {
    var safeIntensity = Math.max(0, Math.min(1, intensity))
    return root.rgbColor(
      Math.round(root.dimIris.r * 255 + (root.brightIris.r * 255 - root.dimIris.r * 255) * safeIntensity),
      Math.round(root.dimIris.g * 255 + (root.brightIris.g * 255 - root.dimIris.g * 255) * safeIntensity),
      Math.round(root.dimIris.b * 255 + (root.brightIris.b * 255 - root.dimIris.b * 255) * safeIntensity),
      alpha
    )
  }

  function normalizedDotPosition(index) {
    var column = index % root.gridColumns
    var row = Math.floor(index / root.gridColumns)
    return {
      x: column / (root.gridColumns - 1),
      y: row / (root.gridRows - 1)
    }
  }

  function gaussian(value, width) {
    return Math.exp(-(value * value) / width)
  }

  function deterministicHash(seed) {
    var value = Math.sin(seed * 12.9898 + 78.233) * 43758.5453
    return value - Math.floor(value)
  }

  function smoothStep(value) {
    var clamped = Math.max(0, Math.min(1, value))
    return clamped * clamped * (3 - 2 * clamped)
  }

  function neuronTwinkle(index) {
    var firstSeed = deterministicHash(index * 17.31 + 1)
    var secondSeed = deterministicHash(index * 31.73 + 11)
    var period = 4200
    var phaseSeed = (index * 0.61803398875 + firstSeed * 0.22) % 1
    var offset = phaseSeed * period
    var attackDuration = 120 + secondSeed * 60
    var decayDuration = 420 + deterministicHash(index * 61.41 + 37) * 230
    var eventDuration = attackDuration + decayDuration
    var eventTime = (root.elapsedMs + offset) % period
    var pulse = eventTime < attackDuration
      ? smoothStep(eventTime / attackDuration)
      : (eventTime < eventDuration
        ? smoothStep(1 - (eventTime - attackDuration) / decayDuration)
        : 0)
    var peak = 0.62 + deterministicHash(index * 73.87 + 47) * 0.38
    return pulse * peak
  }

  function updateAudioGate() {
    var now = root.audioGateClockMs
    if (root.audioSource === "tts" && root.audioActive) {
      if (root.audioLevel > 0.006) {
        root.audioGateActive = true
        root.audioLastAudibleMs = now
      } else if (root.audioGateActive && now - root.audioLastAudibleMs > 1500) {
        root.audioGateActive = false
      }
      return
    }
    if (root.audioGateActive && now - root.audioLastAudibleMs > 1500)
      root.audioGateActive = false
  }

  function inOutSine(value) {
    return 0.5 - 0.5 * Math.cos(Math.PI * Math.max(0, Math.min(1, value)))
  }

  function updateAudioAnimation(stepMs) {
    var progress = root.audioAnimationElapsedMs / 190
    var eased = root.inOutSine(progress)
    var next = []
    for (var i = 0; i < root.gridColumns; i++) {
      var from = Number(root.audioBarAnimationFrom[i]) || 0
      var target = Number(root.audioBarTargets[i]) || 0
      next.push(from + (target - from) * eased)
    }
    root.audioBarHeights = next
    root.audioAnimationElapsedMs = Math.min(190, root.audioAnimationElapsedMs + (stepMs || 0))
  }

  function updateAudioTargets() {
    root.updateAudioAnimation(0)
    var level = Math.max(0, Math.min(1, root.audioLevel))
    var peak = Math.min(1, Math.pow(Math.max(0, (level - 0.012) * root.audioGain), 0.8))
    var heightScale = root.audioSource === "stt" ? 12 : 18
    var next = []
    for (var column = 0; column < root.gridColumns; column++) {
      var centerBias = 0.55 + Math.sin((column + 1) / (root.gridColumns + 1) * Math.PI) * 0.45
      var bandBias = 0.55 + ((column * 43) % 11) / 10
      var randomBand = 0.28 + root.deterministicHash(root.audioSampleIndex * 97.13
        + column * 17.31 + 0.71) * 1.15
      var target = peak * centerBias * bandBias * randomBand * heightScale
      var previous = Number(root.audioBarTargets[column]) || 0
      var blendedTarget = previous * 0.28 + target * 0.72
      next.push(blendedTarget)
    }
    root.audioBarAnimationFrom = root.audioBarHeights.slice(0)
    root.audioBarTargets = next
    root.audioAnimationElapsedMs = 0
    root.audioSampleIndex++
  }

  onAudioActiveChanged: root.updateAudioGate()
  onAudioSourceChanged: root.updateAudioGate()
  onManualModeChanged: if (root.manualMode === "auto") root.updateAudioGate()

  function audioDotIntensity(index) {
    var row = Math.floor(index / root.gridColumns)
    var column = index % root.gridColumns
    var barHeight = Number(root.audioBarHeights[column])
    if (!isFinite(barHeight)) barHeight = 0

    // Each row is a 1/5 cell in the common 24px reference envelope. Measuring
    // overlap keeps centered symmetry while preserving fractional edge coverage.
    var heightFraction = Math.max(0, Math.min(1, barHeight / 24))
    var barTop = 0.5 - heightFraction / 2
    var barBottom = 0.5 + heightFraction / 2
    var cellHeight = 1 / root.gridRows
    var cellTop = row * cellHeight
    var cellBottom = cellTop + cellHeight
    var overlap = Math.max(0, Math.min(barBottom, cellBottom) - Math.max(barTop, cellTop))
    return Math.max(0, Math.min(1, overlap / cellHeight))
  }

  function dotIntensity(index) {
    var position = root.normalizedDotPosition(index)
    var x = position.x
    var y = position.y
    var dx = x - 0.5
    var dy = y - 0.5
    if (root.audioModeActive) {
      return root.audioRenderActive ? root.audioDotIntensity(index) : 0
    }

    var intensity = 0

    if (root.renderedMode === "thinking") {
      // Independent deterministic neuron events create irregular, asynchronous
      // twinkles without random reseeding, shared motion, or field-wide pulsing.
      intensity += root.neuronTwinkle(index) * 0.92
    } else if (root.renderedMode === "generating") {
      // Rows share a phase so vertical bands flow left to right. The head
      // fades beyond each edge, so the cycle joins without a hard seam.
      var generatingPhase = (root.elapsedMs / 1300) % 1
      var headX = -0.04 + generatingPhase * 1.08
      var entryProgress = Math.max(0, Math.min(1, (headX + 0.04) / 0.04))
      var exitProgress = Math.max(0, Math.min(1, (1.04 - headX) / 0.04))
      entryProgress = entryProgress * entryProgress * (3 - 2 * entryProgress)
      exitProgress = exitProgress * exitProgress * (3 - 2 * exitProgress)
      var streamEnvelope = Math.min(entryProgress, exitProgress)
      var distanceBehind = headX - x
      var trailOnset = Math.max(0, Math.min(1, (distanceBehind + 0.06) / 0.06))
      trailOnset = trailOnset * trailOnset * (3 - 2 * trailOnset)
      var fadingTrail = Math.exp(-Math.max(distanceBehind, 0) / 0.23) * trailOnset
      var brightLead = gaussian(distanceBehind, 0.0028)
      intensity += (fadingTrail * 0.78 + brightLead * 0.34) * streamEnvelope
      intensity += gaussian(distanceBehind - 0.10, 0.012) * 0.10 * streamEnvelope
    } else if (root.renderedMode === "compacting") {
      var compactProgress = (root.elapsedMs % 1000) / 1000
      var ringRadius = 0.78 * (1 - compactProgress)
      var radius = Math.sqrt(dx * dx + dy * dy)
      intensity += gaussian(radius - ringRadius, 0.012) * 0.88
      intensity += gaussian(radius, 0.035) * (0.15 + compactProgress * 0.72)
    } else if (root.renderedMode === "completion") {
      // A restrained one-shot success ripple: center first, then an orderly
      // expanding ring that fades into the normal idle presence.
      var completionProgress = Math.min(1, root.elapsedMs / root.completionVisualDuration)
      var completionRadius = Math.sqrt(dx * dx + dy * dy)
      var idlePresence = gaussian(completionRadius, 0.13) * 0.18
      if (completionProgress < 1) {
        var pulseRadius = 0.02 + completionProgress * 0.70
        var rippleEnvelope = 0.72 * (1 - completionProgress)
        var centerEnvelope = 0.30 * (1 - completionProgress)
        intensity += gaussian(completionRadius - pulseRadius, 0.018) * rippleEnvelope
        intensity += gaussian(completionRadius, 0.055) * centerEnvelope
        intensity += idlePresence * completionProgress
      } else {
        intensity += idlePresence
      }
    } else {
      // Idle is a calm, unmistakable horizon: only the middle row is lit,
      // with a bright center and visible but softly tapered ends.
      var horizonProfile = 0.26 + (1 - Math.abs(dx) * 2) * 0.74
      var centerRow = Math.max(0, 1 - Math.abs(dy) * 8)
      var horizonStrength = root.gatewayUp ? 1.0 : 0.62
      intensity += horizonProfile * centerRow * horizonStrength
    }

    return Math.max(0, Math.min(1, intensity))
  }

  function colorAt(index) {
    var intensity = root.dotIntensity(index)
    if (root.renderedMode === "idle" && !root.audioModeActive) {
      var idleColorBase = root.gatewayUp ? 0.32 : 0.27
      var idleColorGain = root.gatewayUp ? 0.68 : 0.55
      return root.irisColor(idleColorBase + intensity * idleColorGain)
    }
    return root.irisColor(0.34 + intensity * 0.66)
  }

  function opacityAt(index) {
    var intensity = root.dotIntensity(index)
    if (root.audioModeActive) return Math.min(1, intensity * 1.3)
    if (root.renderedMode === "idle" && !root.audioRenderActive) {
      var idleOpacityGain = root.gatewayUp ? 0.88 : 0.62
      return Math.min(1, intensity * idleOpacityGain * 1.3)
    }
    return Math.min(1, intensity * 0.84 * 1.3)
  }

  onEffectiveActivityModeChanged: {
    if (!root.initialized) return
    if (!root.visualizerEnabled) {
      root.finishToIdle()
      return
    }
    var nextMode = root.effectiveActivityMode
    if (nextMode === "completion") {
      root.beginMode("completion")
    } else if (nextMode === "idle") {
      // Explicit Idle is inspectable immediately. Auto Idle retains the
      // normal five-second completion pulse after real activity ends.
      if (root.manualMode !== "auto") {
        root.finishToIdle()
      } else if (root.renderedMode !== "idle" && root.renderedMode !== "completion") {
        root.startCompletion()
      } else if (root.renderedMode === "completion"
                 && root.elapsedMs >= root.completionVisualDuration) {
        root.finishToIdle()
      } else if (root.renderedMode === "idle") {
        root.finishToIdle()
      }
    } else {
      root.beginMode(nextMode)
    }
  }

  onVisualizerEnabledChanged: {
    if (!root.initialized) return
    if (!root.visualizerEnabled) {
      root.finishToIdle()
      return
    }
    if (root.effectiveActivityMode !== "idle") root.beginMode(root.effectiveActivityMode)
  }

  Component.onCompleted: {
    root.initialized = true
    root.animationStartedAt = Date.now()
    refreshTimer.interval = root.intervalFor(root.renderedMode)
    root.updateAudioGate()
    if (root.effectiveActivityMode !== "idle") root.beginMode(root.effectiveActivityMode)
  }

  function originalFadeAlpha(distance) {
    var safeDistance = Math.max(0, Math.min(1, distance))
    var coreEnd = 0.04
    if (safeDistance <= coreEnd) {
      var coreProgress = safeDistance / coreEnd
      var coreEase = coreProgress * coreProgress * coreProgress
        * (coreProgress * (coreProgress * 6 - 15) + 10)
      return 0.50 - 0.05 * Math.pow(coreEase, 0.9)
    }

    var featherProgress = (safeDistance - coreEnd) / (1 - coreEnd)
    var featherEase = featherProgress * featherProgress * featherProgress
      * (featherProgress * (featherProgress * 6 - 15) + 10)
    return 0.45 * (1 - Math.pow(featherEase, 0.9))
  }

  function fillCapsule(context, left, top, width, height, alpha) {
    var radius = height / 2
    context.beginPath()
    context.moveTo(left + radius, top)
    context.lineTo(left + width - radius, top)
    context.arc(left + width - radius, top + radius, radius, -Math.PI / 2, Math.PI / 2)
    context.lineTo(left + radius, top + height)
    context.arc(left + radius, top + radius, radius, Math.PI / 2, Math.PI * 1.5)
    context.closePath()
    context.fillStyle = "rgba(8, 12, 28, " + alpha + ")"
    context.fill()
  }

  // User-tuned capsule fade from the isolated browser preview. Concentric
  // paths preserve the inner geometry while feathering the outer boundary.
  Canvas {
    id: backgroundFade
    x: (root.width - root.backgroundWidth) / 2
    y: (root.height - root.backgroundHeight) / 2
    width: root.backgroundWidth
    height: root.backgroundHeight
    z: -1
    visible: root.visible && root.visualizerEnabled
    renderTarget: Canvas.FramebufferObject

    onPaint: {
      var context = getContext("2d")
      context.reset()
      context.clearRect(0, 0, width, height)

      var samples = 128
      var previousAlpha = 0
      var coreLineWidth = root.baseBackgroundWidth - root.baseBackgroundHeight
      var baseRadius = root.baseBackgroundHeight / 2
      var featherGeometryStart = 0.36
      for (var sample = 0; sample <= samples; sample++) {
        var distance = 1 - sample / samples
        var targetAlpha = root.originalFadeAlpha(distance)
        var layerAlpha = (targetAlpha - previousAlpha) / (1 - previousAlpha)
        if (layerAlpha > 0.0001) {
          // Keep the dark inner capsule at its original geometry; only the
          // low-alpha outer feather grows into the larger canvas.
          var geometryProgress = Math.max(0, Math.min(1,
            (distance - featherGeometryStart) / (1 - featherGeometryStart)))
          var geometryEase = geometryProgress * geometryProgress * geometryProgress
            * (geometryProgress * (geometryProgress * 6 - 15) + 10)
          var radius = baseRadius * distance + root.backgroundFadeExpansion * geometryEase
          var shapeWidth = coreLineWidth + radius * 2
          root.fillCapsule(context, (width - shapeWidth) / 2,
            (height - radius * 2) / 2, shapeWidth, radius * 2, layerAlpha)
        }
        previousAlpha = targetAlpha
      }
    }

    Component.onCompleted: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
  }

  Item {
    id: dotField
    anchors.fill: parent

    Repeater {
      model: root.gridColumns * root.gridRows

      Rectangle {
        required property int index
        readonly property int column: index % root.gridColumns
        readonly property int row: Math.floor(index / root.gridColumns)

        x: (root.width - root.dotFieldWidth) / 2 + column * root.dotPitch
        y: (root.height - root.dotFieldHeight) / 2 + row * root.dotPitch
        // Round the field's ends into a pill silhouette.
        visible: (row !== 0 && row !== root.gridRows - 1)
          || (column > 0 && column < root.gridColumns - 1)
        width: root.dotDiameter
        height: root.dotDiameter
        radius: width / 2
        color: root.colorAt(index)
        opacity: root.opacityAt(index)

        Behavior on color {
          ColorAnimation { duration: 55; easing.type: Easing.OutCubic }
        }
        Behavior on opacity {
          NumberAnimation { duration: 55; easing.type: Easing.InOutSine }
        }
      }
    }
  }

  Timer {
    id: audioGateTimer
    interval: 80
    repeat: true
    running: root.visualizerEnabled && root.visible && root.manualMode === "auto"
      && ((root.audioActive && root.audioSource === "tts") || root.audioGateActive)
    onTriggered: {
      root.audioGateClockMs += 80
      root.updateAudioGate()
    }
  }

  Timer {
    id: audioSampleTimer
    interval: 160
    repeat: true
    running: root.visualizerEnabled && root.visible && root.audioRenderActive
    onTriggered: root.updateAudioTargets()
  }

  Timer {
    id: audioAnimationTimer
    interval: 16
    repeat: true
    running: root.visualizerEnabled && root.visible && root.audioRenderActive
    onTriggered: root.updateAudioAnimation(16)
  }

  Timer {
    id: refreshTimer
    interval: 40
    repeat: true
    running: root.initialized && root.visualizerEnabled && root.visible
      && root.renderedMode !== "idle"
    onTriggered: root.refreshFrame()
  }
}
