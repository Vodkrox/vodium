import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property string kind: "volume"
    property bool muted: false
    property real level: 1
    property bool armed: true
    property bool charging: false
    property bool gpuOn: false
    property bool low: false

    property color base: muted ? "#8a8a8a" : "#ffffff"
    readonly property color cross: "#ff6b6b"

    width: 30
    height: 30

    property real crossP: muted ? 1 : 0
    property real wave1: (!muted && level > 0.001) ? 1 : 0
    property real wave2: (!muted && level > 0.4) ? 1 : 0
    Behavior on crossP { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    Behavior on wave1 { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
    Behavior on wave2 { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
    property real sun: level
    Behavior on sun { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
    property real fill: level
    Behavior on fill { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
    property real blink: 1
    SequentialAnimation on blink {
        running: root.kind === "battery" && root.low && root.visible
        loops: Animation.Infinite
        NumberAnimation { to: 0.25; duration: 260; easing.type: Easing.InOutQuad }
        NumberAnimation { to: 1; duration: 260; easing.type: Easing.InOutQuad }
    }
    property real fanSpeed: gpuOn ? 540 : 0
    Behavior on fanSpeed { NumberAnimation { duration: gpuOn ? 350 : 900; easing.type: Easing.OutCubic } }
    property real fanAngle: 0
    FrameAnimation {
        running: root.kind === "gpu" && root.visible && root.fanSpeed > 0.5
        onTriggered: root.fanAngle = (root.fanAngle + root.fanSpeed * Math.min(frameTime, 0.05)) % 360
    }
    onGpuOnChanged: if (armed && kind === "gpu") popAnim.restart()
    onVisibleChanged: if (visible && armed && kind === "battery") popAnim.restart()
    Behavior on base { ColorAnimation { duration: 120 } }

    onMutedChanged: {
        if (!armed) return;
        popAnim.restart();
        if (!muted && kind === "mic") pulseAnim.restart();
    }

    Item {
        id: art
        anchors.fill: parent
        transformOrigin: Item.Center

        SequentialAnimation {
            id: popAnim
            NumberAnimation { target: art; property: "scale"; to: 0.78; duration: 55; easing.type: Easing.OutQuad }
            NumberAnimation { target: art; property: "scale"; to: 1; duration: 170; easing.type: Easing.OutBack; easing.overshoot: 3 }
        }

        Item {
            id: gpu
            visible: root.kind === "gpu"
            anchors.fill: parent
            property color tint: root.gpuOn ? "#30d158" : "#8a8a8a"
            Behavior on tint { ColorAnimation { duration: 250 } }

            Repeater {
                model: 3
                Item {
                    required property int index
                    Rectangle { x: 8.5 + index * 6 - 1; y: 2; width: 2; height: 4; radius: 1; color: gpu.tint }
                    Rectangle { x: 8.5 + index * 6 - 1; y: 24; width: 2; height: 4; radius: 1; color: gpu.tint }
                    Rectangle { x: 2; y: 8.5 + index * 6 - 1; width: 4; height: 2; radius: 1; color: gpu.tint }
                    Rectangle { x: 24; y: 8.5 + index * 6 - 1; width: 4; height: 2; radius: 1; color: gpu.tint }
                }
            }
            Rectangle {
                x: 5; y: 5; width: 20; height: 20; radius: 4
                color: "transparent"
                border.width: 2
                border.color: gpu.tint
            }
            Item {
                x: 15 - 6; y: 15 - 6; width: 12; height: 12
                rotation: root.fanAngle
                Rectangle { anchors.centerIn: parent; width: 12; height: 3; radius: 1.5; color: gpu.tint }
                Rectangle { anchors.centerIn: parent; width: 3; height: 12; radius: 1.5; color: gpu.tint }
            }
        }

        Item {
            id: battery
            visible: root.kind === "battery"
            anchors.fill: parent
            readonly property color tint: root.low ? "#ff453a" : (root.charging ? "#30d158" : "#ffffff")

            Rectangle {
                x: 1.5; y: 8; width: 23; height: 14; radius: 3.5
                color: "transparent"
                border.width: 2
                border.color: battery.tint
                opacity: root.low ? 0.5 + 0.5 * root.blink : 1
            }
            Rectangle {
                x: 25.5; y: 12; width: 3; height: 6; radius: 1.5
                color: battery.tint
                opacity: root.low ? 0.5 + 0.5 * root.blink : 1
            }
            Rectangle {
                x: 4; y: 10.5
                width: 18.5 * Math.max(root.fill, root.fill > 0 ? 0.08 : 0)
                height: 9; radius: 1.5
                color: battery.tint
                opacity: root.low ? root.blink : 1
            }
        }
        Shape {
            anchors.fill: parent
            visible: root.kind === "battery"
            opacity: root.charging ? 1 : 0
            scale: root.charging ? 1 : 0.4
            Behavior on opacity { NumberAnimation { duration: 150 } }
            Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutBack; easing.overshoot: 3 } }
            layer.enabled: true
            layer.samples: 4
            ShapePath {
                strokeWidth: 1.2
                strokeColor: "#000000"
                fillColor: "#ffffff"
                joinStyle: ShapePath.RoundJoin
                startX: 15.5; startY: 6
                PathLine { x: 10; y: 15.5 }
                PathLine { x: 14; y: 15.5 }
                PathLine { x: 12.5; y: 24 }
                PathLine { x: 19; y: 13.5 }
                PathLine { x: 15; y: 13.5 }
                PathLine { x: 15.5; y: 6 }
            }
        }

        Item {
            visible: root.kind === "brightness"
            x: 15; y: 15
            rotation: root.sun * 90

            Rectangle {
                readonly property real r: 4 + 2.5 * root.sun
                x: -r; y: -r; width: 2 * r; height: 2 * r; radius: r
                color: root.base
            }
            Repeater {
                model: 8
                Item {
                    required property int index
                    rotation: index * 45
                    Rectangle {
                        readonly property real len: 2 + 3 * root.sun
                        x: -1.1; y: -(8.5 + len); width: 2.2; height: len; radius: 1.1
                        color: root.base
                    }
                }
            }
        }

        Shape {
            anchors.fill: parent
            visible: root.kind === "volume"
            layer.enabled: true
            layer.samples: 4

            ShapePath {
                strokeWidth: 2
                strokeColor: root.base
                fillColor: root.base
                joinStyle: ShapePath.RoundJoin
                startX: 4; startY: 11
                PathLine { x: 9; y: 11 }
                PathLine { x: 15; y: 6 }
                PathLine { x: 15; y: 22 }
                PathLine { x: 9; y: 17 }
                PathLine { x: 4; y: 17 }
                PathLine { x: 4; y: 11 }
            }
            ShapePath {
                strokeWidth: 2
                strokeColor: Qt.alpha(root.base, Math.min(1, root.wave1 * 3))
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: 15; centerY: 14; radiusX: 6; radiusY: 6
                    startAngle: -45 * root.wave1
                    sweepAngle: 90 * root.wave1
                }
            }
            ShapePath {
                strokeWidth: 2
                strokeColor: Qt.alpha(root.base, Math.min(1, root.wave2 * 3))
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: 15; centerY: 14; radiusX: 10.5; radiusY: 10.5
                    startAngle: -45 * root.wave2
                    sweepAngle: 90 * root.wave2
                }
            }
            ShapePath {
                strokeWidth: 2.4
                strokeColor: Qt.alpha(root.cross, Math.min(1, root.crossP * 4))
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                startX: 19; startY: 10
                PathLine { x: 19 + 8 * root.crossP; y: 10 + 8 * root.crossP }
            }
            ShapePath {
                strokeWidth: 2.4
                strokeColor: Qt.alpha(root.cross, Math.min(1, root.crossP * 4))
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                startX: 27; startY: 10
                PathLine { x: 27 - 8 * root.crossP; y: 10 + 8 * root.crossP }
            }
        }

        Rectangle {
            visible: root.kind === "mic"
            x: 10; y: 2; width: 10; height: 15; radius: 5
            color: root.base
        }
        Shape {
            anchors.fill: parent
            visible: root.kind === "mic"
            layer.enabled: true
            layer.samples: 4

            ShapePath {
                strokeWidth: 2
                strokeColor: root.base
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: 15; centerY: 12; radiusX: 8; radiusY: 8
                    startAngle: 0; sweepAngle: 180
                }
            }
            ShapePath {
                strokeWidth: 2
                strokeColor: root.base
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                startX: 15; startY: 20
                PathLine { x: 15; y: 26 }
            }
            ShapePath {
                strokeWidth: 2
                strokeColor: root.base
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                startX: 11; startY: 26
                PathLine { x: 19; y: 26 }
            }
        }

        Shape {
            anchors.fill: parent
            visible: root.kind === "mic"
            layer.enabled: true
            layer.samples: 4
            ShapePath {
                strokeWidth: 5.5
                strokeColor: Qt.alpha("#000000", Math.min(1, root.crossP * 4))
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                startX: 5; startY: 4
                PathLine { x: 5 + 20 * root.crossP; y: 4 + 22 * root.crossP }
            }
        }
        Shape {
            anchors.fill: parent
            visible: root.kind === "mic"
            layer.enabled: true
            layer.samples: 4
            ShapePath {
                strokeWidth: 2.4
                strokeColor: Qt.alpha(root.cross, Math.min(1, root.crossP * 4))
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                startX: 5; startY: 4
                PathLine { x: 5 + 20 * root.crossP; y: 4 + 22 * root.crossP }
            }
        }
    }

    Rectangle {
        id: pulse
        anchors.centerIn: parent
        width: 26; height: 26; radius: 13
        color: "transparent"
        border.width: 2
        border.color: "#ffffff"
        opacity: 0
        visible: root.kind === "mic"

        ParallelAnimation {
            id: pulseAnim
            NumberAnimation { target: pulse; property: "scale"; from: 0.6; to: 1.7; duration: 300; easing.type: Easing.OutCubic }
            NumberAnimation { target: pulse; property: "opacity"; from: 0.8; to: 0; duration: 300; easing.type: Easing.OutQuad }
        }
    }
}
