import Quickshell
import Quickshell.Io
import QtQuick

Scope {
    id: root

    property var cfg: ({})
    property var battery

    readonly property string tunedAdm: cfg.menus && cfg.menus.tuned_adm_path !== undefined ? cfg.menus.tuned_adm_path : "/usr/sbin/tuned-adm"

    property var mapping: ({ saver: "powersave", normal: "balanced", performance: "throughput-performance" })
    readonly property var states: Object.assign({ charging: "none", battery: "none", low: "none" },
        cfg.power && cfg.power.states ? cfg.power.states : {})

    readonly property string state: !battery || !battery.present ? ""
        : battery.plugged ? "charging" : battery.low ? "low" : "battery"

    FileView {
        path: Qt.resolvedUrl("power.json")
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try { root.mapping = Object.assign({}, root.mapping, JSON.parse(text())); } catch (e) {}
        }
    }

    Process { id: applyProc }

    function sync() {
        const mode = states[state];
        const profile = mode ? mapping[mode] : "";
        if (!profile) return;
        applyProc.command = [tunedAdm, "profile", profile];
        applyProc.running = true;
    }

    onStateChanged: sync()
    onStatesChanged: sync()
}
