import QtQuick

Item {
    id: root
    property real progress: 0
    property real lit: 0
    property real flash: 0
    readonly property real u: height * 0.010

    readonly property real boxX: 0.10
    readonly property real boxW: 0.30
    readonly property real boxY: 0.425
    readonly property real boxH: 0.15

    function stage(from, to) { return Math.max(0, Math.min(1, (progress - from) / (to - from))); }

    function pt(a, b) { return Qt.point(width * (boxX + (1 - a) * boxW), height * (boxY + b * boxH)); }

    GlowLine {
        anchors.fill: parent
        core: root.u * 0.4; gain: 0.15; glow: false
        t: root.stage(0, 0.6)
        pts: [root.pt(0.0, 0.71), root.pt(0.12, 0.54), root.pt(0.31, 0.30), root.pt(0.76, 0.09),
              root.pt(0.95, 0.0), root.pt(1.0, 0.18), root.pt(0.96, 0.59), root.pt(0.76, 0.86),
              root.pt(0.45, 0.98), root.pt(0.20, 1.0), root.pt(0.04, 0.91), root.pt(0.0, 0.71)]
    }
    GlowLine {
        anchors.fill: parent
        core: root.u; flash: root.flash
        t: root.stage(0.2, 0.8)
        lit: Math.min(1, root.lit / 0.6)
        pts: [root.pt(0.214, 0.90), root.pt(0.445, 0.90), root.pt(0.518, 0.52), root.pt(0.464, 0.35)]
    }
    GlowLine {
        anchors.fill: parent
        core: root.u; flash: root.flash
        t: root.stage(0.4, 1.0)
        lit: Math.max(0, (root.lit - 0.4) / 0.6)
        pts: [root.pt(0.527, 0.74), root.pt(0.750, 0.79), root.pt(0.845, 0.34), root.pt(0.795, 0.20)]
    }
}
