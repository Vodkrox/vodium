import Quickshell
import Quickshell.Wayland
import QtQuick

Scope {
    id: win

    property var screen
    property bool active: true
    property bool paused: false
    property bool hot: false
    property real hotSpeedMultiplier: 10
    property real boost: hot ? hotSpeedMultiplier : 1
    Behavior on boost { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

    property int frame: 32
    readonly property int cornerW: 360
    readonly property int cornerH: 200
    readonly property real radius: 250
    readonly property real radiusY: 130
    readonly property real meanRadius: (radius + radiusY) / 2
    readonly property real arc: Math.PI * meanRadius / 2
    readonly property real pitch: 27
    readonly property int count: Math.ceil(arc * 1.6 / pitch) + 4

    property real clock: 0
    FrameAnimation {
        running: win.fade > 0
        onTriggered: win.clock += Math.min(frameTime, 0.1) * win.boost
    }

    readonly property real speed: 40
    readonly property real offset: (clock * speed) % (2 * pitch)

    property real waviness: hot ? 0 : 1
    Behavior on waviness { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
    readonly property real amplitude: 18 * waviness
    readonly property real wavelength: 300
    readonly property real amplitude2: 5 * waviness
    readonly property real wavelength2: 170
    readonly property real bulge: 24
    readonly property real waveSeconds: 6.5
    readonly property real phase: (clock * 2 * Math.PI / waveSeconds) % (2 * Math.PI)

    function build(ph) {
        const step = 4;
        const sMin = -3 * pitch, sMax = arc * 1.6 + 3 * pitch;
        const n = Math.ceil((sMax - sMin) / step);
        const fr = frame, r = radius, ry = radiusY, mr = meanRadius, a = arc;
        const amp = amplitude, wl = wavelength, amp2 = amplitude2, wl2 = wavelength2, bg = bulge;
        const half = Math.PI / 2, tau = 2 * Math.PI;
        const xs = new Array(n + 1), ys = new Array(n + 1), ls = new Array(n + 1);
        let acc = 0, l0 = 0, l1 = -1, px = 0, py = 0;
        for (let i = 0; i <= n; i++) {
            const s = sMin + i * step;
            const phi = half - s / mr;
            let wave = 0;
            if (s > 0 && s < a) {
                const u = s / a;
                wave = Math.sin(Math.PI * u) * (
                    amp * Math.sin(tau * s / wl - ph)
                  + amp2 * Math.sin(tau * s / wl2 + 2 * ph + 1.3)
                  + bg * Math.sin(tau * u * 0.75 + 0.6));
            }
            const x = fr + (r + wave) * Math.cos(phi), y = (ry + wave) * Math.sin(phi);
            if (i > 0) acc += Math.hypot(x - px, y - py);
            xs[i] = x; ys[i] = y; ls[i] = acc;
            px = x; py = y;
            if (s <= 0) l0 = acc;
            if (l1 < 0 && s > 0 && y <= 0) l1 = acc;
        }
        if (l1 < 0) l1 = acc;
        return { xs: xs, ys: ys, ls: ls, l0: l0, l1: l1 };
    }
    property var path: build(phase)

    function at(l) {
        const ls = path.ls;
        let lo = 0, hi = ls.length - 1;
        if (l <= ls[0]) hi = 1;
        else if (l >= ls[hi]) lo = hi - 1;
        else {
            while (hi - lo > 1) {
                const mid = (lo + hi) >> 1;
                if (ls[mid] <= l) lo = mid; else hi = mid;
            }
        }
        const dl = ls[lo + 1] - ls[lo] || 1;
        const t = (l - ls[lo]) / dl;
        const dx = path.xs[lo + 1] - path.xs[lo], dy = path.ys[lo + 1] - path.ys[lo];
        return { x: path.xs[lo] + dx * t, y: path.ys[lo] + dy * t, angle: Math.atan2(dy, dx) * 180 / Math.PI };
    }

    readonly property var poses: {
        const out = new Array(count);
        for (let i = 0; i < count; i++) {
            const l = path.l0 + (i - 2) * pitch + offset;
            out[i] = (l > path.l0 - pitch && l < path.l1 + pitch) ? at(l) : null;
        }
        return out;
    }

    property real fade: active ? 1 : 0
    Behavior on fade { NumberAnimation { duration: active ? 400 : 150; easing.type: Easing.InOutQuad } }

    Variants {
        model: [0, 1, 2, 3]

        PanelWindow {
            id: corner
            required property int modelData
            readonly property bool mirrored: (modelData & 1) === 1
            readonly property bool flipped: (modelData & 2) === 2

            screen: win.screen
            anchors { top: !flipped; bottom: flipped; left: !mirrored; right: mirrored }
            implicitWidth: win.cornerW
            implicitHeight: win.cornerH
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.namespace: "chains"
            mask: Region {}

            visible: win.fade > 0

            Item {
                id: holder
                anchors.fill: parent
                opacity: win.fade

                Repeater {
                    id: links
                    model: win.count
                    delegate: ChainLink {
                        required property int index
                        edge: index % 2 === 1
                        visible: false
                    }
                }
                function place() {
                    const ps = win.poses, w = win.cornerW, h = win.cornerH;
                    const mir = corner.mirrored, flip = corner.flipped;
                    const sign = mir !== flip ? -1 : 1, base = mir ? 180 : 0;
                    for (let i = 0; i < win.count; i++) {
                        const it = links.itemAt(i), p = ps[i];
                        if (!it) continue;
                        if (p === null || p === undefined) { it.visible = false; continue; }
                        it.x = (mir ? w - p.x : p.x) - it.width / 2;
                        it.y = (flip ? h - p.y : p.y) - it.height / 2;
                        it.rotation = base + sign * p.angle;
                        it.visible = true;
                    }
                }
                Connections { target: win; function onPosesChanged() { holder.place(); } }
                Component.onCompleted: place()
            }
        }
    }
}
