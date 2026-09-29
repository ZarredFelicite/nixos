import QtQuick

// Shared hover and click feedback for widgets placed directly in the bar layout.
// The effect observes existing MouseAreas instead of intercepting their events.
Item {
    id: effects

    property Item target
    property var observedMouseAreas: []
    property bool hovered: false
    property real hoverScale: 1.07
    property real bounceAmount: 0.11
    property real bounceProgress: 0
    property double lastBounceMs: 0

    function collectMouseAreas(item, result) {
        if (!item || !item.children)
            return

        for (let i = 0; i < item.children.length; i++) {
            const child = item.children[i]
            if (child === effects)
                continue

            if (typeof child.containsMouse === "boolean"
                    && typeof child.pressed === "boolean") {
                result.push(child)
            }
            collectMouseAreas(child, result)
        }
    }

    function refreshHover() {
        for (const mouseArea of observedMouseAreas) {
            if (mouseArea.containsMouse) {
                hovered = true
                return
            }
        }
        hovered = false
    }

    function bounce() {
        const now = Date.now()
        // A click can be seen by nested MouseAreas as well as their parent.
        if (now - lastBounceMs < 80)
            return
        lastBounceMs = now
        bounceAnimation.restart()
    }

    function observeMouseAreas() {
        const areas = []
        collectMouseAreas(target, areas)
        observedMouseAreas = areas

        refreshHover()
    }

    Instantiator {
        model: effects.observedMouseAreas

        delegate: Connections {
            required property var modelData
            target: modelData

            function onContainsMouseChanged() {
                effects.refreshHover()
            }

            function onPressedChanged() {
                if (modelData.pressed)
                    effects.bounce()
            }
        }
    }

    // The helper is a sibling overlay. Map nested widget coordinates into its layer.
    x: target ? target.mapToItem(parent, 0, 0).x : 0
    y: target ? target.mapToItem(parent, 0, 0).y : 0
    width: target ? target.width * target.scale : 0
    height: target ? target.height * target.scale : 0
    visible: !!target && target.visible && target.width > 0 && target.height > 0
    z: 5

    // Binding the transform keeps layout geometry unchanged while the widget grows.
    Binding {
        target: effects.target
        property: "scale"
        value: effects.hoveredScale * (1 + effects.bounceProgress * effects.bounceAmount)
        when: !!effects.target
    }

    property real hoveredScale: hovered ? hoverScale : 1.0
    Behavior on hoveredScale {
        NumberAnimation {
            duration: 130
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Math.min(width, height) / 2
        color: "white"
        opacity: effects.hovered ? 0.055 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: 110
                easing.type: Easing.OutCubic
            }
        }
    }

    SequentialAnimation {
        id: bounceAnimation
        property real durationIn: 90
        property real durationOut: 170
        onStopped: effects.bounceProgress = 0

        NumberAnimation {
            target: effects
            property: "bounceProgress"
            from: 0
            to: 1
            duration: bounceAnimation.durationIn
            easing.type: Easing.OutBack
        }
        NumberAnimation {
            target: effects
            property: "bounceProgress"
            from: 1
            to: 0
            duration: bounceAnimation.durationOut
            easing.type: Easing.OutBounce
        }
    }

    Component.onCompleted: observeMouseAreas()
}
