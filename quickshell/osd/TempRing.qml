import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property real temp: 0
    property real offsetX: -1

    readonly property color ringColor: temp >= 85 ? "#ff453a" : "#ffffff"

    width: 32
    height: 36

    property real sweep: Math.max(6, 360 * Math.max(0, Math.min(1, (temp - 30) / 70)))
    Behavior on sweep { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

    Shape {
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: root.offsetX
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
            strokeColor: root.ringColor
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: 14; centerY: 14; radiusX: 12; radiusY: 12
                startAngle: -90
                sweepAngle: root.sweep
            }
        }
    }

    Text {
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: root.offsetX
        text: Math.round(root.temp)
        color: root.ringColor
        font.pixelSize: 10
        font.bold: true
    }
}
