import Quickshell
import Quickshell.Io
import QtQuick

Scope {
    id: root

    property var cfg: ({})
    property real cpu: 0
    property real cpuGhz: 0
    property real cpuUsage: 0
    readonly property real hotGhzThreshold: cfg.cpu && cfg.cpu.hot_ghz_threshold !== undefined ? cfg.cpu.hot_ghz_threshold : 3.4
    readonly property real hotUsageThreshold: cfg.cpu && cfg.cpu.hot_usage_threshold !== undefined ? cfg.cpu.hot_usage_threshold : 0.8
    readonly property bool cpuHot: cpuGhz > hotGhzThreshold && cpuUsage > hotUsageThreshold
    property real cpuTemp: 0
    property var prevCores: []

    readonly property string hwmonName: cfg.cpu && cfg.cpu.hwmon_name !== undefined ? cfg.cpu.hwmon_name : "coretemp"

    readonly property string script: `
        hwmon_name=${hwmonName}
        c=/sys/devices/system/cpu
        cpu=$(cat $c/cpu*/cpufreq/scaling_cur_freq 2>/dev/null | awk '{s+=$1;n++} END{if(n) printf "%d", s/n}')
        min=$(cat $c/cpu0/cpufreq/cpuinfo_min_freq 2>/dev/null)
        max=$(cat $c/cpu0/cpufreq/cpuinfo_max_freq 2>/dev/null)
        stat=$(awk '/^cpu[0-9]/{printf "%s%d,%d", (n++ ? ";" : ""), $2+$3+$4+$5+$6+$7+$8, $5+$6}' /proc/stat)
        temp=0
        for h in /sys/class/hwmon/hwmon*; do
            [ "$(cat $h/name 2>/dev/null)" = "$hwmon_name" ] && temp=$(cat $h/temp1_input 2>/dev/null)
        done
        echo "$cpu $min $max $stat \${temp:-0}"
    `

    function update(text) {
        const p = text.trim().split(" ");
        if (p.length < 4) return;
        const cur = parseFloat(p[0]), min = parseFloat(p[1]), max = parseFloat(p[2]);
        if (p.length >= 5) cpuTemp = parseFloat(p[4]) / 1000;
        if (cur > 0) cpuGhz = cur / 1e6;
        const cores = p[3].split(";").map(c => c.split(",").map(parseFloat));
        let peak = 0;
        for (let i = 0; i < cores.length && i < prevCores.length; i++) {
            const dt = cores[i][0] - prevCores[i][0], di = cores[i][1] - prevCores[i][1];
            if (dt > 0) peak = Math.max(peak, 1 - di / dt);
        }
        cpuUsage = peak;
        prevCores = cores;
        if (max > min) cpu = Math.max(0, Math.min(1, (cur - min) / (max - min)));
    }

    Process {
        id: proc
        command: ["sh", "-c", root.script]
        stdout: StdioCollector { onStreamFinished: root.update(text) }
    }
    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!proc.running) proc.running = true
    }
}
