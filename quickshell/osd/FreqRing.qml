import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property real frac: 0
    property bool hot: false
    property bool on: true
    property bool active: true
    property real offsetX: 0

    width: 32
    height: 42

    readonly property real minSpeed: 90
    readonly property real maxSpeed: 900

    property real speed: (minSpeed + (maxSpeed - minSpeed) * frac) * (hot ? 2 : 1)
    Behavior on speed { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

    property real angle: -90
    Timer {
        interval: 50
        repeat: true
        running: root.active && root.on && root.visible
        onTriggered: root.angle = (root.angle + root.speed * interval / 1000) % 360
    }

    Item {
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: root.offsetX
        anchors.verticalCenterOffset: 3
        width: 24; height: 24

        Shape {
            anchors.fill: parent
            layer.enabled: true
            layer.samples: 4
            ShapePath {
                strokeWidth: 2.5
                strokeColor: root.hot ? "#ff453a" : "#2a2a2a"
                fillColor: "transparent"
                PathAngleArc {
                    centerX: 12; centerY: 12; radiusX: 10; radiusY: 10
                    startAngle: 0; sweepAngle: 359.9
                }
            }
        }

        Rectangle {
            width: 5; height: 5; radius: 2.5
            color: "#ffffff"
            opacity: root.on ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 300 } }
            x: 12 + 10 * Math.cos(root.angle * Math.PI / 180) - width / 2
            y: 12 + 10 * Math.sin(root.angle * Math.PI / 180) - height / 2
        }
    }
}
