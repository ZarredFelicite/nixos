import QtQuick
import "../services"

Item {
    id: root
    clip: true
    
    // Configuration
    // Node density/complexity control (independent from on-screen widget size)
    // Formula: 6 * configScale + 12.
    // Scale 1 = 18 nodes. Scale 6 = 48 nodes.
    property int nodeCount: Math.round(6 * configScale + 12)
    onNodeCountChanged: initializeNodes()
    
    // Active nodes used for rendering/physics (same count across all modes).
    property int activeNodeCount: nodeCount
    
    property real baseConnectionDistance: 110
    property real connectionDistanceMultiplier: 1.0
    property real connectionLineWidth: 1.0
    property bool modulateConnectionLineWidth: false
    property real nodeSizeMultiplier: 1.0
    property bool ringNodes: false
    property real boundsScale: 0.92
    // 0 = unlimited. When set, strongest/nearest visible connections are drawn first.
    property int maxConnectionCount: 0
    property bool curvedMotion: true // Optional configuration

    // Visual color (default Rose Pine primary)
    property color graphColor: "#c4a7e7"
    property bool graphVisible: true
    property bool shadowVisible: true
    
    // Speed modes
    // "low" = 50% slower (0.25), "high" = 10% faster (0.55)
    property string speedMode: "low" // "low" or "high"
    property real baseSpeedFactor: 0.5
    // Optional multiplier for size-compensated speed (e.g. fullscreen graph)
    property real speedScaleMultiplier: 1.0
    property real speedFactor: {
        var base = (speedMode === "high") ? (baseSpeedFactor * 1.1) : (baseSpeedFactor * 0.5)
        return base * speedScaleMultiplier;
    }
    
    // Scaling
    // configScale now controls density only; physical graph size follows width/height.
    property real configScale: 6.0
    // Geometry scale derived from actual rendered size (keeps animation fitting its box).
    property real s: Math.max(0.08, Math.min(width, height) / 200.0)
    
    // Internal state
    property var nodes: []
    property bool ready: false
    property int frameCount: 0
    property int mode: 0 // 0=Brain, 1=Blob (TTS), 2=Ring
    property bool paused: false
    // Normalized 0..1 audio strength used for TTS node pulse sizing.
    property real ttsAudioStrength: 0.0
    // Visibility gating: only animate when actually visible
    readonly property bool renderActive: visible && width > 0 && height > 0 && opacity > 0
    // Performance profiling
    property int _physicsTime: 0
    property int _lineTime: 0
    // Debug logging flag - set to false in production
    property bool enableDebugLogging: false

    Component.onCompleted: {
        initializeNodes();
        ready = true;
        Cava.refCount++;
    }

    onWidthChanged: if (ready) initializeNodes()
    onHeightChanged: if (ready) initializeNodes()
    
    Component.onDestruction: {
        Cava.refCount--;
    }

    function initializeNodes() {
        var newNodes = [];
        // Create exactly nodeCount nodes (density controlled by configScale).
        var totalNodes = nodeCount;
        for (var i = 0; i < totalNodes; i++) {
            newNodes.push({
                x: width / 2 + (Math.random() - 0.5) * (200 * s),
                y: height / 2 + (Math.random() - 0.5) * (200 * s),
                vx: (Math.random() - 0.5) * (2 * s), // Scaled velocity
                vy: (Math.random() - 0.5) * (2 * s),
                // Scaled radius with boost at small scales
                // Formula: (s * 0.8 + 0.2) - slightly less aggressive boost than before
                radius: (3.4 + Math.random() * 3.8) * (s * 0.8 + 0.2) * root.nodeSizeMultiplier
            });
        }

        // Ensure every node starts inside the exact render bounds.
        for (var j = 0; j < newNodes.length; j++) {
            confineNodeToBounds(newNodes[j]);
        }

        nodes = newNodes;
    }

    function confineNodeToBounds(node) {
        if (!node) return;

        var cx = root.width / 2;
        var cy = root.height / 2;

        // Circular cutoff, slightly inset so the graph stays inside the background fade.
        var maxRadius = (Math.min(root.width, root.height) / 2) * root.boundsScale - node.radius;
        if (maxRadius <= 0) {
            node.x = cx;
            node.y = cy;
            node.vx = 0;
            node.vy = 0;
            return;
        }

        var dx = node.x - cx;
        var dy = node.y - cy;
        var dist = Math.sqrt(dx * dx + dy * dy);

        if (dist > maxRadius) {
            // Clamp position onto circle edge.
            var nx = dx / dist;
            var ny = dy / dist;
            node.x = cx + nx * maxRadius;
            node.y = cy + ny * maxRadius;

            // Reflect outward velocity component for soft bounce.
            var dot = node.vx * nx + node.vy * ny;
            if (dot > 0) {
                node.vx = node.vx - 2 * dot * nx;
                node.vy = node.vy - 2 * dot * ny;
                node.vx *= 0.85;
                node.vy *= 0.85;
            }
        }
    }

    // Manual toggle for testing
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton) {
                // Toggle mode: 0 (Brain) -> 1 (Blob) -> 2 (Ring) -> 0
                var nextMode = (root.mode + 1) % 3;
                root.mode = nextMode;
                
                // If switching BACK to Brain Mode (0), scatter the nodes!
                if (nextMode === 0) {
                     for (var i = 0; i < root.nodes.length; i++) {
                         var node = root.nodes[i];
                         // Random burst direction
                         var angle = Math.random() * 2 * Math.PI;
                         var speed = (1.0 + Math.random() * 2.0) * s; // Scaled Explosion speed
                         node.vx = Math.cos(angle) * speed;
                         node.vy = Math.sin(angle) * speed;
                     }
                }
            } else if (mouse.button === Qt.RightButton) {
                root.paused = !root.paused
            } else if (mouse.button === Qt.MiddleButton) {
                // Toggle speed mode (only in normal mode)
                if (root.mode === 0) {
                    root.speedMode = (root.speedMode === "low") ? "high" : "low"
                    console.log("[BrainGraph] Speed mode: " + root.speedMode)
                }
            }
        }
    }

    FrameAnimation {
        running: root.ready && !root.paused && root.renderActive
        onTriggered: {
            var physicsStart = Date.now();
            var dt = frameTime; 

            // Compute one normalized audio strength sample per frame for TTS pulse sizing.
            // Fast attack + short release for responsive visible pulsing.
            var frameAudioStrength = 0;
            if (root.mode === 1 && Cava.values && Cava.values.length > 0) {
                var peak = 0;
                var count = Math.min(Cava.values.length, 64);
                for (var sIdx = 0; sIdx < count; sIdx++) {
                    var v = (Cava.values[sIdx] || 0) / 100.0;
                    if (v > peak) peak = v;
                }
                frameAudioStrength = peak;
                if (frameAudioStrength < 0) frameAudioStrength = 0;
                if (frameAudioStrength > 1) frameAudioStrength = 1;
            }
            var release = 0.82;
            root.ttsAudioStrength = (frameAudioStrength > root.ttsAudioStrength)
                ? frameAudioStrength
                : (root.ttsAudioStrength * release);
            
            // Precompute frame constants for ring mode
            var centerX = 0, centerY = 0, radius = 0, angleStep = 0;
            if (root.mode === 2) {
                centerX = root.width / 2;
                centerY = root.height / 2;
                radius = 120 * s; // Scale ring radius
                angleStep = (2 * Math.PI) / activeNodeCount;
            }
            
            // Physics Loop
            for (var i = 0; i < activeNodeCount; i++) {
                var node = nodes[i];
                
                if (root.mode === 2) {
                    // --- RING MODE ---
                    // Target: Circle formation
                    var targetAngle = i * angleStep;
                    
                    var targetX = centerX + Math.cos(targetAngle) * radius;
                    var targetY = centerY + Math.sin(targetAngle) * radius;
                    
                    var dx = targetX - node.x;
                    var dy = targetY - node.y;
                    
                    // Slightly softer spring for ring
                    var stiffness = 0.04;
                    node.vx += dx * stiffness;
                    node.vy += dy * stiffness;
                    
                    // Damping
                    node.vx *= 0.85;
                    node.vy *= 0.85;
                    
                    // Ring Oscillation (Radial Jitter)
                    // Calculate vector from center to node to apply force along the radius
                    var rx = node.x - centerX;
                    var ry = node.y - centerY;
                    var len = Math.sqrt(rx*rx + ry*ry);
                    if (len > 0.001) {
                         // Normalize
                         rx /= len;
                         ry /= len;
                         // Apply random push in/out
                         var push = (Math.random() - 0.5) * (1.5 * s);
                         node.vx += rx * push;
                         node.vy += ry * push;
                    }
                    
                } else {
                    // --- BRAIN MODE (Wandering) ---
                    
                    // 2. Wandering Behavior
                    if (root.curvedMotion) {
                        // Smooth steering: slightly rotate velocity vector
                        var angle = Math.atan2(node.vy, node.vx);
                        // Add small random rotation (max 0.1 radians per frame)
                        angle += (Math.random() - 0.5) * 0.2;
                        
                        var speedSq = node.vx*node.vx + node.vy*node.vy;
                        // Maintain a minimum speed for nice curves (approx speed 0.5 -> sq 0.25)
                        if (speedSq < 0.25) speedSq = 0.25;
                        var speed = Math.sqrt(speedSq);
                        
                        node.vx = Math.cos(angle) * speed;
                        node.vy = Math.sin(angle) * speed;
                    } else {
                        // Classic Jittery Random Wandering
                        // Scaled wandering impulse
                        node.vx += (Math.random() - 0.5) * (0.1 * s);
                        node.vy += (Math.random() - 0.5) * (0.1 * s);
                    }

                    // 4. Friction/Speed Limit (prevent infinite acceleration)
                    var currentSpeedSq = node.vx*node.vx + node.vy*node.vy;
                    // Scale limit squared (2.0*s)^2 = 4.0*s*s
                    if (currentSpeedSq > 4.0 * s * s) { 
                        node.vx *= 0.95;
                        node.vy *= 0.95;
                    }
                }
                
                // GLOBAL: Apply Velocity to Position
                // In Line mode, we might want higher speed, but keeping factor ensures smoothness
                node.x += node.vx * speedFactor;
                node.y += node.vy * speedFactor;

                // Hard-clip every frame so nodes always stay inside widget cutoff width/height.
                confineNodeToBounds(node);
            }
            
            // Track physics timing
            root._physicsTime = Date.now() - physicsStart;
            
            // Request redraw of lines and nodes in one canvas to keep them visually synced.
            linesCanvas.requestPaint();
        }
    }

    // 0. Background Shadow (Static)
    Canvas {
        id: shadowCanvas
        anchors.fill: parent
        visible: root.shadowVisible
        // Use FramebufferObject for consistency, though it's static
        renderTarget: Canvas.FramebufferObject
        
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.clearRect(0, 0, width, height);
            
            // Radial Gradient: Center (w/2, h/2)
            // User requested disproportionate shadow scaling:
            // Scale 0.5 -> Tight fit (radius ~0.4 * w/2)
            // Scale 6.0 -> Full fit (radius 1.0 * w/2)
            
            var scaleProgress = (root.configScale - 0.5) / 5.5;
            scaleProgress = Math.max(0.0, Math.min(1.0, scaleProgress));
            
            var outerRadius = Math.min(width, height) / 2;
            var gradient = ctx.createRadialGradient(width/2, height/2, 0, width/2, height/2, outerRadius);

            // Soft dark-navy ambience. Keep the center translucent and fade to zero at the
            // widget edge so it reads as a glow instead of a hard dot or square.
            gradient.addColorStop(0.00, "rgba(8, 12, 28, 0.60)");
            gradient.addColorStop(0.18, "rgba(8, 12, 28, 0.57)");
            gradient.addColorStop(0.34, "rgba(8, 12, 28, 0.50)");
            gradient.addColorStop(0.50, "rgba(8, 12, 28, 0.39)");
            gradient.addColorStop(0.64, "rgba(8, 12, 28, 0.25)");
            gradient.addColorStop(0.76, "rgba(8, 12, 28, 0.13)");
            gradient.addColorStop(0.86, "rgba(8, 12, 28, 0.055)");
            gradient.addColorStop(0.94, "rgba(8, 12, 28, 0.015)");
            gradient.addColorStop(1.00, "rgba(8, 12, 28, 0.0)");

            ctx.fillStyle = gradient;
            ctx.fillRect(0, 0, width, height);
        }
        
        // Paint on startup and whenever the fade layer changes size.
        Component.onCompleted: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
    }

    // 1. Graph canvas: connection lines and nodes in one paint pass.
    Canvas {
        id: linesCanvas
        anchors.fill: parent
        antialiasing: true
        opacity: root.graphVisible ? 1 : 0
        renderStrategy: Canvas.Immediate
        renderTarget: Canvas.Image

        Connections {
            target: root
            function onGraphColorChanged() { linesCanvas.requestPaint(); }
            function onModeChanged() { linesCanvas.requestPaint(); }
        }
        
        // Optimization: Recycle bins and grid to prevent GC churn
        property var binCache: []
        property var gridCache: ({})
        property var gridKeys: []

        Component.onCompleted: {
            // Initialize 10 bins
            for (var b = 0; b < 10; b++) binCache[b] = [];
        }
        
        onPaint: {
            var startTime = Date.now();
            
            var ctx = getContext("2d");
            ctx.reset();
            ctx.clearRect(0, 0, width, height);
            
            // Base thickness, optionally pulsed by TTS audio strength.
            var baseLineWidth = root.connectionLineWidth * ((root.mode === 1)
                ? (0.5 + Math.pow(root.ttsAudioStrength, 0.7) * 2.0)
                : 1.0);
            
            // Clear bins without creating new arrays
            var bins = linesCanvas.binCache;
            for (var b = 0; b < 10; b++) bins[b].length = 0;
            
            // Scaled connection dist with boost at small scales (match node size boost)
            // Formula: (s * 0.8 + 0.2)
            var scaledDist = root.baseConnectionDistance * root.connectionDistanceMultiplier * (s * 0.8 + 0.2);
            var alphaCullThreshold = 0.05;
            var useBlobConnections = false;
            var blobDist = scaledDist * 1.35;
            var activeDist = useBlobConnections ? blobDist : scaledDist;
            var activeFalloff = useBlobConnections ? 2.2 : 3.0;
            // Match the existing alpha cull in the distance test. This avoids checking
            // pairs that would be thrown away as invisible anyway.
            var visibleDist = activeDist * (1.0 - Math.pow(alphaCullThreshold, 1.0 / activeFalloff));
            var connectionDistSq = visibleDist * visibleDist;
            var connectionCount = 0;
            
            // 2. Classify connections into bins
            // Spatial grid optimization: O(n) instead of O(n²)
            var cellSize = visibleDist; // Cell size = visible connection distance for optimal culling
            var invCellSize = 1.0 / cellSize;
            // Reuse grid object to prevent GC churn from creating new {} every frame
            var grid = linesCanvas.gridCache;
            var oldKeys = linesCanvas.gridKeys;
            for (var ki = 0; ki < oldKeys.length; ki++) {
                var ok = oldKeys[ki];
                grid[ok].length = 0;
            }
            oldKeys.length = 0;
            var pairsChecked = 0;

            // Build spatial grid - assign nodes to cells
            for (var i = 0; i < activeNodeCount; i++) {
                var n = root.nodes[i];
                var cellX = Math.floor(n.x * invCellSize);
                var cellY = Math.floor(n.y * invCellSize);
                var key = cellX + "," + cellY;
                if (!grid[key]) {
                    grid[key] = [];
                    oldKeys.push(key);
                } else if (grid[key].length === 0) {
                    oldKeys.push(key);
                }
                grid[key].push(n);
            }
            
            if (useBlobConnections) {
                // BLOB MODE: denser local web for a pulsing "blob" feel.
                var blobDistSq = connectionDistSq;

                // Process each cell and its neighbors
                for (var key in grid) {
                    var cellNodes = grid[key];
                    var parts = key.split(",");
                    var cx = parseInt(parts[0]);
                    var cy = parseInt(parts[1]);
                    
                    // Check all 9 cells (current + 8 neighbors)
                    for (var dx = -1; dx <= 1; dx++) {
                        for (var dy = -1; dy <= 1; dy++) {
                            var neighborKey = (cx + dx) + "," + (cy + dy);
                            var neighborNodes = grid[neighborKey];
                            if (!neighborNodes) continue;
                            
                            // Compare nodes in current cell with nodes in neighbor cell
                            for (var i = 0; i < cellNodes.length; i++) {
                                var n1 = cellNodes[i];
                                for (var j = 0; j < neighborNodes.length; j++) {
                                    var n2 = neighborNodes[j];
                                    // Avoid duplicate pairs: only process if n1 is "less than" n2
                                    // For same cell, use index comparison; for different cells, use pointer comparison
                                    if (key === neighborKey) {
                                        if (i >= j) continue; // Same cell: only check i < j
                                    } else if (n1 >= n2) {
                                        continue; // Different cells: avoid checking both (a,b) and (b,a)
                                    }
                                    
                                    pairsChecked++;
                                    var diffX = n1.x - n2.x;
                                    var diffY = n1.y - n2.y;
                                    var distSq = diffX*diffX + diffY*diffY;

                                    if (distSq < blobDistSq) {
                                        var dist = Math.sqrt(distSq);
                                        var ratio = dist / blobDist;
                                        var alpha = Math.pow(1.0 - ratio, 2.2);
                                        if (alpha < alphaCullThreshold) continue;

                                        connectionCount++;
                                        var binIndex = Math.floor(alpha * 9.9);
                                        if (binIndex < 0) binIndex = 0;
                                        if (binIndex > 9) binIndex = 9;
                                        bins[binIndex].push(n1.x, n1.y, n1.radius, n2.x, n2.y, n2.radius);
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                // BRAIN/RING MODES: Distance-based web with spatial grid
                // Process each cell and its neighbors
                for (var key in grid) {
                    var cellNodes = grid[key];
                    var parts = key.split(",");
                    var cx = parseInt(parts[0]);
                    var cy = parseInt(parts[1]);
                    
                    // Check all 9 cells (current + 8 neighbors)
                    for (var dx = -1; dx <= 1; dx++) {
                        for (var dy = -1; dy <= 1; dy++) {
                            var neighborKey = (cx + dx) + "," + (cy + dy);
                            var neighborNodes = grid[neighborKey];
                            if (!neighborNodes) continue;
                            
                            // Compare nodes in current cell with nodes in neighbor cell
                            for (var i = 0; i < cellNodes.length; i++) {
                                var n1 = cellNodes[i];
                                for (var j = 0; j < neighborNodes.length; j++) {
                                    var n2 = neighborNodes[j];
                                    // Avoid duplicate pairs: only process if n1 is "less than" n2
                                    // For same cell, use index comparison; for different cells, use pointer comparison
                                    if (key === neighborKey) {
                                        if (i >= j) continue; // Same cell: only check i < j
                                    } else if (n1 >= n2) {
                                        continue; // Different cells: avoid checking both (a,b) and (b,a)
                                    }
                                    
                                    pairsChecked++;
                                    var diffX = n1.x - n2.x;
                                    var diffY = n1.y - n2.y;
                                    var distSq = diffX*diffX + diffY*diffY;
                                    
                                    if (distSq < connectionDistSq) {
                                        var dist = Math.sqrt(distSq);
                                        var ratio = dist / scaledDist;
                                        // Cubic falloff
                                        var alpha = Math.pow(1.0 - ratio, 3.0);
                                        
                                        // Optimization: Cull invisible lines (lowest alpha)
                                        if (alpha < alphaCullThreshold) continue;
                                        
                                        connectionCount++;
                
                                        // Map 0.0-1.0 to 0-9 index
                                        var binIndex = Math.floor(alpha * 9.9);
                                        if (binIndex < 0) binIndex = 0;
                                        if (binIndex > 9) binIndex = 9;
                                        
                                        // Store coordinates and radii: x1, y1, r1, x2, y2, r2
                                        bins[binIndex].push(n1.x, n1.y, n1.radius, n2.x, n2.y, n2.radius);
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // Shared node scale for line endpoint offsets and node drawing.
            var ttsScale = (root.mode === 1)
                ? (0.5 + Math.pow(root.ttsAudioStrength, 0.7) * 1.5)
                : 1.0;

            // 3. Render connection batches. Draw strongest/nearest bins first so the
            // max limit trims weak distant lines before important local structure.
            var drawCalls = 0;
            var drawnConnections = 0;
            var maxConnections = root.maxConnectionCount > 0
                ? Math.min(root.maxConnectionCount, connectionCount)
                : connectionCount;
            for (var k = 9; k >= 0 && drawnConnections < maxConnections; k--) {
                var bin = bins[k];
                if (bin.length > 0) {
                    drawCalls++;
                    // Calculate alpha for this bin (center of bin range)
                    var binAlpha = (k + 0.5) / 10.0;
                    var connectionBudget = maxConnections - drawnConnections;
                    var segmentsToDraw = Math.min(Math.floor(bin.length / 6), connectionBudget);
                    ctx.lineWidth = root.modulateConnectionLineWidth
                        ? baseLineWidth * (0.15 + binAlpha * 2.2)
                        : baseLineWidth;
                    ctx.strokeStyle = Qt.rgba(root.graphColor.r, root.graphColor.g, root.graphColor.b, binAlpha * 0.8);
                    ctx.beginPath();
                    
                    for (var m = 0; m < segmentsToDraw * 6; m += 6) {
                        var x1 = bin[m];
                        var y1 = bin[m + 1];
                        var endpointRadiusFactor = root.ringNodes ? 0.48 : 0.0;
                        var r1 = bin[m + 2] * ttsScale * endpointRadiusFactor;
                        var x2 = bin[m + 3];
                        var y2 = bin[m + 4];
                        var r2 = bin[m + 5] * ttsScale * endpointRadiusFactor;
                        var lx = x2 - x1;
                        var ly = y2 - y1;
                        var len = Math.sqrt(lx * lx + ly * ly);
                        if (len <= r1 + r2) continue;
                        var ux = lx / len;
                        var uy = ly / len;

                        ctx.moveTo(x1 + ux * r1, y1 + uy * r1);
                        ctx.lineTo(x2 - ux * r2, y2 - uy * r2);
                    }
                    ctx.stroke();
                    drawnConnections += segmentsToDraw;
                }
            }

            // 4. Render nodes on the same canvas/frame as line endpoints.
            ctx.globalAlpha = 0.95;

            for (var nodeIdx = 0; nodeIdx < root.activeNodeCount; nodeIdx++) {
                var drawNode = root.nodes[nodeIdx];
                if (!drawNode) continue;

                var nodeRadius = drawNode.radius * ttsScale;
                var diameter = nodeRadius * 2;
                ctx.drawImage(
                    nodeStamp,
                    drawNode.x - nodeRadius,
                    drawNode.y - nodeRadius,
                    diameter,
                    diameter
                );
            }
            ctx.globalAlpha = 1.0;
            
            var endTime = Date.now();
            root._lineTime = endTime - startTime;
            
            // Log every 60 frames (approx 1 second) - only if debug enabled
            root.frameCount++;
            if (root.enableDebugLogging && root.frameCount % 60 === 0) { 
                console.log("[BrainGraph] Physics: " + root._physicsTime + "ms | Lines: " + root._lineTime + "ms | Connections: " + drawnConnections + "/" + connectionCount + " | Checked: " + pairsChecked + " | DrawCalls: " + drawCalls);
            }
        }
    }

    // 2. Pre-rendered node stamp to avoid creating gradient objects every frame (leak fix).
    Canvas {
        id: nodeStamp
        visible: false
        width: 64
        height: 64
        renderTarget: Canvas.Image

        property color stampColor: root.graphColor

        onStampColorChanged: requestPaint()
        Connections {
            target: root
            function onRingNodesChanged() { nodeStamp.requestPaint(); }
        }
        Component.onCompleted: requestPaint()

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.clearRect(0, 0, width, height);
            var cx = width / 2;
            var cy = height / 2;
            var r = cx;
            var g = ctx.createRadialGradient(cx, cy, 0, cx, cy, r);
            if (root.ringNodes) {
                g.addColorStop(0.00, Qt.rgba(stampColor.r, stampColor.g, stampColor.b, 0.00));
                g.addColorStop(0.34, Qt.rgba(stampColor.r, stampColor.g, stampColor.b, 0.00));
                g.addColorStop(0.48, Qt.rgba(stampColor.r, stampColor.g, stampColor.b, 0.95));
                g.addColorStop(0.72, Qt.rgba(stampColor.r, stampColor.g, stampColor.b, 0.80));
                g.addColorStop(1.00, Qt.rgba(stampColor.r, stampColor.g, stampColor.b, 0.00));
            } else {
                g.addColorStop(0.00, Qt.rgba(stampColor.r, stampColor.g, stampColor.b, 0.95));
                g.addColorStop(0.70, Qt.rgba(stampColor.r, stampColor.g, stampColor.b, 0.90));
                g.addColorStop(1.00, Qt.rgba(stampColor.r, stampColor.g, stampColor.b, 0.00));
            }
            ctx.fillStyle = g;
            ctx.beginPath();
            ctx.arc(cx, cy, r, 0, 2 * Math.PI);
            ctx.fill();
        }
    }

}
