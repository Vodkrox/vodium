import QtQuick
import QtQuick.Shapes
import QtQuick.Effects

Item {
    id: root
    property var pts: []
    property real t: 0
    property real core: 4
    property real flash: 0
    property real gain: 1
    property real lit: 1
    readonly property real unlit: 0.28
    readonly property real level: root.gain * (root.unlit + (1 - root.unlit) * root.lit)
    property bool glow: true

    readonly property var partial: {
        const p = root.pts;
        if (p.length < 2 || root.t <= 0) return [];
        let total = 0;
        for (let i = 1; i < p.length; i++) total += Math.hypot(p[i].x - p[i-1].x, p[i].y - p[i-1].y);
        let left = total * Math.min(1, root.t);
        const out = [p[0]];
        for (let i = 1; i < p.length && left > 0; i++) {
            const seg = Math.hypot(p[i].x - p[i-1].x, p[i].y - p[i-1].y);
            if (left >= seg) { out.push(p[i]); left -= seg; }
            else {
                const k = left / seg;
                out.push(Qt.point(p[i-1].x + (p[i].x - p[i-1].x) * k, p[i-1].y + (p[i].y - p[i-1].y) * k));
                left = 0;
            }
        }
        return out;
    }

    Shape {
        id: line
        anchors.fill: parent
        layer.enabled: true
        layer.samples: 4
        ShapePath {
            strokeWidth: root.core * (1 + 0.7 * root.flash)
            strokeColor: Qt.rgba(root.level, root.level, root.level, 1)
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathPolyline { path: root.partial }
        }
    }

    MultiEffect {
        visible: root.glow && root.lit > 0.01 && root.partial.length > 1
        anchors.fill: line
        source: line
        z: -1
        autoPaddingEnabled: false
        blurEnabled: true
        blurMax: 64
        blur: 1.0
        opacity: root.lit
        brightness: 0.5 + 1.0 * root.flash
    }
    MultiEffect {
        visible: root.glow && root.lit > 0.01 && root.partial.length > 1
        anchors.fill: line
        source: line
        z: -1
        autoPaddingEnabled: false
        blurEnabled: true
        blurMax: 40
        blur: 0.75
        opacity: root.lit
        brightness: 0.5 + 1.0 * root.flash
    }
    MultiEffect {
        visible: root.glow && root.lit > 0.01 && root.partial.length > 1
        anchors.fill: line
        source: line
        z: -1
        autoPaddingEnabled: false
        blurEnabled: true
        blurMax: 24
        blur: 0.5
        opacity: root.lit
        brightness: 0.5 + 1.0 * root.flash
    }
}
