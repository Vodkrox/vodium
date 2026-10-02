import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import QtQuick

Scope {
    id: bar

    property var menus
    property var battery
    property var launcher
    property var clipboard
    property var freq
    property var notifications
    property bool trayOpen: false
    property color accent: "#ffffff"
    property var cfg: ({})
    function opt(key, def) { return cfg.bar && cfg.bar[key] !== undefined ? cfg.bar[key] : def; }
    readonly property color dim: "#404040"
    readonly property int radius: 20
    readonly property int width: 32
    readonly property int edgeHoverWidth: 3
    readonly property color hotColor: "#ff453a"

    property bool cameraActive: false
    property bool micActive: false

    Process {
        id: cameraProc
        command: [decodeURIComponent(Qt.resolvedUrl("scripts/privacy.sh").toString().replace("file://", "")), "camera"]
        stdout: StdioCollector {
            onStreamFinished: { try { bar.cameraActive = JSON.parse(text).text !== ""; } catch (e) {} }
        }
    }
    Process {
        id: micProc
        command: [decodeURIComponent(Qt.resolvedUrl("scripts/privacy.sh").toString().replace("file://", "")), "mic"]
        stdout: StdioCollector {
            onStreamFinished: { try { bar.micActive = JSON.parse(text).text !== ""; } catch (e) {} }
        }
    }
    Timer {
        interval: 2000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: { cameraProc.running = true; micProc.running = true; }
    }

    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [bar.sink] }
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false
    readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
    readonly property string volumeIcon: muted ? "󰖁" : volume < 0.33 ? "󰕿" : volume < 0.66 ? "󰖀" : "󰕾"

    function scrollVolume(dy) {
        if (!sink || !sink.audio) return;
        const s = bar.opt("volume_scroll_step", 0.05);
        const step = dy > 0 ? s : -s;
        sink.audio.volume = Math.max(0, Math.min(1, sink.audio.volume + step));
    }

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool btOn: adapter ? adapter.enabled : false
    readonly property bool btConnected: [...Bluetooth.devices.values].some(d => d.connected)
    readonly property string btIcon: !btOn ? "󰂲" : btConnected ? "󰂱" : "󰂯"

    property bool wifiRadio: true
    property bool ethernet: false
    property bool wifi: false
    property int signal: 0
    readonly property string netIcon: ethernet ? "󰈀"
        : wifi ? (signal > 66 ? "󰤨" : signal > 33 ? "󰤢" : "󰤟")
        : "󰤭"
    readonly property bool netDim: !ethernet && !wifi

    Process {
        id: netProc
        command: ["sh", "-c", "nmcli radio wifi; nmcli -t -f TYPE,STATE device; nmcli -t -f IN-USE,SIGNAL dev wifi"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n");
                bar.wifiRadio = lines[0].trim() === "enabled";
                let eth = false, wifi = false, sig = 0;
                for (const l of lines.slice(1)) {
                    if (l.startsWith("ethernet:connected")) eth = true;
                    else if (l.startsWith("wifi:connected")) wifi = true;
                    const m = l.match(/^\*:(\d+)/);
                    if (m) sig = parseInt(m[1]);
                }
                bar.ethernet = eth;
                bar.wifi = wifi;
                bar.signal = sig;
            }
        }
    }
    Timer {
        interval: 3000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: netProc.running = true
    }

    property var workspaces: ({})

    function covered(output) {
        for (const id in workspaces) {
            const w = workspaces[id];
            if (w.output === output && w.active) return w.hasWindow;
        }
        return false;
    }

    function refreshWorkspaces() { hyprState.running = true; }

    Process {
        id: hyprState
        running: true
        command: ["sh", "-c", "hyprctl -j monitors; echo '===SPLIT==='; hyprctl -j workspaces"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.split("===SPLIT===");
                if (parts.length < 2) return;
                let mons, ws;
                try { mons = JSON.parse(parts[0]); ws = JSON.parse(parts[1]); } catch (e) { return; }
                const activeByOutput = {};
                for (const m of mons) if (m.activeWorkspace) activeByOutput[m.name] = m.activeWorkspace.id;
                const next = {};
                for (const w of ws)
                    next[w.id] = { output: w.monitor, active: activeByOutput[w.monitor] === w.id, hasWindow: w.windows > 0 };
                bar.workspaces = next;
            }
        }
    }

    Process {
        command: ["sh", "-c", "socat -u UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock -"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                const ev = line.split(">>")[0];
                if (ev === "workspacev2" || ev === "focusedmonv2" || ev === "moveworkspacev2"
                    || ev === "createworkspacev2" || ev === "destroyworkspacev2"
                    || ev === "openwindow" || ev === "closewindow" || ev === "movewindowv2")
                    bar.refreshWorkspaces();
            }
        }
    }

    IpcHandler {
        target: "tray"
        function toggle(): void { bar.trayOpen = !bar.trayOpen; }
        function close(): void { bar.trayOpen = false; }
    }

    Connections {
        target: bar.notifications
        function onOpenChanged() { if (bar.notifications.open) bar.trayOpen = false; }
    }

    readonly property string primaryName: {
        const internal = bar.cfg.display && bar.cfg.display.internal_monitor;
        const ext = Quickshell.screens.find(s => s.name !== internal);
        return ext ? ext.name : internal;
    }

    Variants {
        model: Quickshell.screens

        Scope {
            required property var modelData

            Chains {
                screen: modelData; active: !bar.covered(modelData.name); hot: bar.freq.cpuHot
                frame: bar.width
                hotSpeedMultiplier: bar.cfg.chains && bar.cfg.chains.hot_speed_multiplier !== undefined ? bar.cfg.chains.hot_speed_multiplier : 10
            }

            Loader {
                active: modelData.name === bar.primaryName
                sourceComponent: ClaudeStatus {
                    screen: modelData
                }
            }

            Loader {
                active: modelData.name === bar.primaryName
                sourceComponent: TrayPanel {
                    screen: modelData
                    open: bar.trayOpen
                    onCloseRequested: bar.trayOpen = false
                    barWidth: bar.width
                    accent: bar.accent
                }
            }

            BarPanel {
                id: leftPanel
                screen: modelData
                onLeft: true
                covered: bar.covered(modelData.name)
                pinned: bar.menus.current !== "" || (bar.trayOpen && modelData.name === bar.primaryName)
                expanded: bar.notifications.open
                expandedWidth: bar.notifications.panelWidth
                barWidth: bar.width
                edgeWidth: bar.edgeHoverWidth
                WlrLayershell.namespace: "bar-left"

                BarShape { anchors.fill: parent; stroke: bar.freq.cpuHot ? bar.hotColor : "#ffffff"; mirrored: true; radius: bar.radius }

                NotificationPanel {
                    anchors { top: parent.top; bottom: parent.bottom; left: parent.left; right: parent.right }
                    anchors.topMargin: 44
                    anchors.bottomMargin: 44
                    anchors.leftMargin: 14
                    anchors.rightMargin: 20
                    opacity: bar.notifications.open ? 1 : 0
                    visible: opacity > 0
                    holding: bar.notifications.holding
                    holdProgress: bar.notifications.holdProgress
                    Behavior on opacity { NumberAnimation { duration: 160 } }
                    notifications: bar.notifications
                    accent: bar.accent
                }

                TempRing {
                    visible: modelData.name === bar.primaryName && opacity > 0
                    anchors.top: parent.top
                    anchors.topMargin: 44
                    anchors.left: parent.left
                    temp: bar.freq.cpuTemp
                    opacity: bar.notifications.open ? 0 : 1
                    Behavior on opacity { NumberAnimation { duration: 160 } }
                }

                Item {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    width: bar.width
                    height: 36

                    Rectangle {
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: -2
                        width: 8; height: 8; radius: 4
                        color: bar.notifications.count > 0 || bar.notifications.open ? bar.accent : bar.dim
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: bar.notifications.open = !bar.notifications.open
                    }
                }

                BarIcon {
                    visible: modelData.name === bar.primaryName && opacity > 0
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: (bar.width - width) / 2 - 2
                    glyph: "󰅂"
                    family: "RobotoMono Nerd Font Propo"
                    size: 16
                    color: bar.trayOpen ? bar.accent : bar.dim
                    rotation: bar.trayOpen ? 180 : 0
                    opacity: bar.notifications.open ? 0 : 1
                    Behavior on rotation { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 160 } }
                    Behavior on color { ColorAnimation { duration: 150 } }
                    onClicked: bar.trayOpen = !bar.trayOpen
                }

                BarIcon {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 36
                    anchors.left: parent.left
                    anchors.leftMargin: (bar.width - width) / 2 - 2
                    glyph: "󰅌"
                    size: 18
                    color: bar.clipboard.open ? bar.accent : bar.dim
                    opacity: bar.notifications.open ? 0 : 1
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 160 } }
                    Behavior on color { ColorAnimation { duration: 150 } }
                    onClicked: bar.clipboard.open = !bar.clipboard.open
                }
            }

            BarPanel {
                id: rightPanel
                screen: modelData
                covered: bar.covered(modelData.name)
                pinned: bar.menus.current !== ""
                barWidth: bar.width
                edgeWidth: bar.edgeHoverWidth
                WlrLayershell.namespace: "bar-right"

                BarShape { anchors.fill: parent; stroke: bar.freq.cpuHot ? bar.hotColor : "#ffffff"; radius: bar.radius }

                Column {
                    visible: modelData.name === bar.primaryName
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter

                    FreqRing {
                        active: rightPanel.shown
                        frac: bar.freq.cpu
                        hot: bar.freq.cpuHot
                        offsetX: 3
                    }

                    BarIcon {
                        visible: bar.cameraActive
                        glyph: "󰄀"
                        color: "#30d158"
                    }
                    BarIcon {
                        visible: bar.micActive
                        glyph: "󰍬"
                        color: "#30d158"
                    }
                }

                Column {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter

                    BatteryRing { battery: bar.battery; onClicked: bar.menus.toggle("power") }

                    BarIcon {
                        visible: modelData.name === bar.primaryName
                        glyph: bar.volumeIcon
                        family: "RobotoMono Nerd Font Propo"
                        size: 19
                        inkCentered: true
                        color: bar.muted ? bar.dim : "#ffffff"
                        onClicked: bar.menus.toggle("sound")
                        onScrolled: dy => bar.scrollVolume(dy)
                    }
                    BarIcon {
                        visible: modelData.name === bar.primaryName
                        glyph: bar.btIcon
                        color: bar.btOn ? "#ffffff" : bar.dim
                        onClicked: bar.menus.toggle("bluetooth")
                    }
                    BarIcon {
                        visible: modelData.name === bar.primaryName
                        glyph: bar.netIcon
                        size: 23
                        color: bar.netDim ? bar.dim : "#ffffff"
                        onClicked: bar.menus.toggle("wifi")
                    }
                }
            }
        }
    }
}
