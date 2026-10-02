import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property var battery
    signal clicked()
    visible: battery && battery.present
    width: 32
    height: visible ? 36 : 0

    readonly property color blue: "#0a84ff"
    readonly property color green: "#30d158"
    readonly property color red: "#ff453a"

    readonly property bool spinning: battery && battery.spinning && battery.plugged
    readonly property color ringColor: {
        if (!battery) return "#ffffff";
        if (spinning) return blue;
        if (battery.plugged) return green;
        return battery.low ? red : "#ffffff";
    }

    property real angle: -90
    property real sweep: spinning ? 100 : Math.max(6, 360 * (battery ? battery.percent : 0) / 100)
    property real start: spinning ? angle : -90
    property color ring: ringColor
    Behavior on sweep { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
    Behavior on ring { ColorAnimation { duration: 200 } }

    Timer {
        interval: 50
        repeat: true
        running: root.spinning && root.visible
        onTriggered: root.angle = (root.angle + 360 * interval / 380 + 90) % 360 - 90
    }

    Shape {
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: 0.7
        width: 28; height: 28
        layer.enabled: true
        layer.samples: 4

        ShapePath {
            strokeWidth: 2.5
            strokeColor: "#2a2a2a"
            fillColor: "transparent"
            PathAngleArc {
                centerX: 14; centerY: 14; radiusX: 12; radiusY: 12
                startAngle: 0; sweepAngle: 359.9
            }
        }
        ShapePath {
            strokeWidth: 2.5
            strokeColor: root.ring
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: 14; centerY: 14; radiusX: 12; radiusY: 12
                startAngle: root.start
                sweepAngle: root.sweep
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    Text {
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: 0.7
        text: root.battery ? root.battery.percent : ""
        color: root.battery && root.battery.low ? root.red : "#ffffff"
        font.pixelSize: 10
        font.bold: true
    }
}
