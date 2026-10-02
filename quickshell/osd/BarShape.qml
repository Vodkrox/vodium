import QtQuick
import QtQuick.Shapes

Shape {
    id: root
    property bool mirrored: false
    property real radius: 20
    property color fill: "#000000"
    property color stroke: "#ffffff"
    Behavior on stroke { ColorAnimation { duration: 250 } }

    readonly property real w: width
    readonly property real h: height

    layer.enabled: true
    layer.samples: 4
    transform: Scale { xScale: root.mirrored ? -1 : 1; origin.x: root.width / 2 }

    ShapePath {
        strokeWidth: -1
        fillColor: root.fill
        startX: root.w; startY: 0
        PathLine { x: root.radius; y: 0 }
        PathArc { x: 0; y: root.radius; radiusX: root.radius; radiusY: root.radius; direction: PathArc.Counterclockwise }
        PathLine { x: 0; y: root.h - root.radius }
        PathArc { x: root.radius; y: root.h; radiusX: root.radius; radiusY: root.radius; direction: PathArc.Counterclockwise }
        PathLine { x: root.w; y: root.h }
        PathLine { x: root.w; y: 0 }
    }

    ShapePath {
        strokeWidth: 1
        strokeColor: root.stroke
        fillColor: "transparent"
        capStyle: ShapePath.FlatCap
        startX: root.w; startY: 0.5
        PathLine { x: root.radius; y: 0.5 }
        PathArc { x: 0.5; y: root.radius; radiusX: root.radius - 0.5; radiusY: root.radius - 0.5; direction: PathArc.Counterclockwise }
        PathLine { x: 0.5; y: root.h - root.radius }
        PathArc { x: root.radius; y: root.h - 0.5; radiusX: root.radius - 0.5; radiusY: root.radius - 0.5; direction: PathArc.Counterclockwise }
        PathLine { x: root.w; y: root.h - 0.5 }
    }
}
