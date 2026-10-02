import Quickshell
import Quickshell.Io
import QtQuick

Scope {
    id: root

    property var cfg: ({})
    property bool present: false
    property int percent: 0
    property string status: "Unknown"
    property bool plugged: false
    property bool spinning: false

    readonly property bool charging: plugged && status !== "Full"
    readonly property bool low: !plugged && percent < thresholds[0]

    signal warning(int level, int percent)
    signal plugChanged(bool plugged)

    property bool ready: false
    property int warnedLevel: 100
    readonly property var thresholds: cfg.battery && cfg.battery.warning_thresholds !== undefined ? cfg.battery.warning_thresholds : [20, 10, 5]

    function update(text) {
        const p = text.trim().split(" ");
        if (p[0] === "none" || p.length < 2) { present = false; return; }

        const wasPlugged = plugged;
        present = true;
        percent = parseInt(p[0]);
        status = p[1];
        plugged = p[2] === "1" || status === "Charging";

        if (ready && plugged !== wasPlugged) {
            plugChanged(plugged);
            spinning = plugged;
            if (plugged) spinTimer.restart(); else spinTimer.stop();
        }
        ready = true;

        if (plugged || percent > thresholds[0]) {
            warnedLevel = 100;
            return;
        }
        const crossed = thresholds.filter(t => percent <= t && t < warnedLevel);
        if (crossed.length > 0) {
            warnedLevel = Math.min(...crossed);
            warning(warnedLevel, percent);
        }
    }

    Timer {
        id: spinTimer
        interval: 3000
        onTriggered: root.spinning = false
    }

    readonly property string batteryPath: cfg.battery && cfg.battery.sysfs_battery !== undefined ? cfg.battery.sysfs_battery : ""
    readonly property string acGlob: cfg.battery && cfg.battery.sysfs_ac_glob !== undefined ? cfg.battery.sysfs_ac_glob : ""

    Process {
        id: proc
        command: ["sh", "-c",
            "b=\"$1\"; [ -d \"$b\" ] || { echo none; exit; }; " +
            "echo \"$(cat $b/capacity) $(tr ' ' _ < $b/status) $(cat $2 2>/dev/null | head -1)\"",
            "sh", root.batteryPath, root.acGlob]
        stdout: StdioCollector { onStreamFinished: { root.update(text); } }
    }
    Timer {
        interval: 1000
        running: true; repeat: true; triggeredOnStart: true
        onTriggered: proc.running = true
    }
}
