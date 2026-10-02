import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import QtQuick

ShellRoot {
    id: root

    property string title: ""
    property real value: 0
    property bool muted: false
    property bool hasBar: true
    property string stateText: ""
    property bool shown: false
    readonly property string iconKind: title === "Volumen" ? "volume" : title === "Micrófono" ? "mic" : title === "Brillo" ? "brightness" : title === "Batería" ? "battery" : title === "GPU" ? "gpu" : ""
    property bool armed: false

    property var cfg: ({})
    FileView {
        path: Quickshell.shellPath("../../config.json")
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try { root.cfg = JSON.parse(text()); } catch (e) {}
        }
        onLoadFailed: genConfig.running = true
    }
    Process {
        id: genConfig
        command: [Quickshell.shellPath("../../hypr/scripts/generate-conf.py")]
    }
    function expandHome(p) {
        return p.startsWith("~/") ? Quickshell.env("HOME") + p.slice(1) : p;
    }
    function opt(section, key, def) {
        return root.cfg[section] && root.cfg[section][key] !== undefined ? root.cfg[section][key] : def;
    }

    Process { id: awwwApply }
    Process {
        id: awwwQuery
        command: ["awww", "query"]
        onExited: code => {
            if (code === 0) {
                awwwApply.command = ["awww", "img", root.expandHome(root.opt("wallpaper", "path", "")),
                    "--transition-type", "grow", "--transition-pos", "0.5,0.5",
                    "--transition-duration", "1.2", "--transition-fps", "60"];
                awwwApply.running = true;
            } else if (awwwRetry.count < 50) {
                awwwRetry.restart();
            }
        }
    }
    Timer {
        id: awwwRetry
        interval: 100
        property int count: 0
        onTriggered: { count++; awwwQuery.running = true; }
    }
    Component.onCompleted: awwwQuery.running = true

    function show(title, value, muted, hasBar, stateText) {
        if (!armed) return;
        root.title = title;
        root.value = value;
        root.muted = muted;
        root.hasBar = hasBar;
        root.stateText = stateText;
        root.shown = true;
        hideTimer.interval = 1500;
        hideTimer.restart();
    }

    function showBattery(text) {
        show("Batería", batteryHost.percent / 100, false, false, text);
        hideTimer.interval = 3000;
        hideTimer.restart();
    }

    property bool windowVisible: false
    onShownChanged: {
        if (shown) {
            hideAnim.stop();
            if (!windowVisible) {
                pill.scale = 0.7;
                pill.opacity = 0;
            }
            windowVisible = true;
            showAnim.restart();
        } else {
            showAnim.stop();
            hideAnim.restart();
        }
    }

    Timer { interval: 1000; running: true; onTriggered: root.armed = true }
    Timer { id: hideTimer; interval: 1500; onTriggered: root.shown = false }

    property color accent: "#ffffff"

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    PwObjectTracker { objects: [root.sink, root.source] }

    Connections {
        target: root.sink ? root.sink.audio : null
        function onVolumeChanged() { root.showVolume(); }
        function onMutedChanged() { root.showVolume(); }
    }
    function showVolume() {
        root.show("Volumen", sink.audio.volume, sink.audio.muted, true, "");
    }

    Connections {
        target: root.source ? root.source.audio : null
        function onMutedChanged() {
            root.show("Micrófono", 0, root.source.audio.muted, false,
                      root.source.audio.muted ? "silenciado" : "activo");
        }
    }

    FileView {
        id: blMax
        path: root.opt("osd", "sysfs_backlight_max", "")
        blockLoading: true
    }
    property int lastBrightness: -1
    FileView {
        id: bl
        path: root.opt("osd", "sysfs_backlight_current", "")
        onLoaded: {
            const v = parseInt(text());
            const max = parseInt(blMax.text()) || 1;
            if (root.lastBrightness !== -1 && v !== root.lastBrightness)
                root.show("Brillo", v / max, false, true, "");
            root.lastBrightness = v;
        }
    }

    property int lastCaps: -1
    FileView {
        id: caps
        path: root.opt("osd", "sysfs_capslock_led", "")
        onLoaded: {
            const v = parseInt(text());
            if (root.lastCaps !== -1 && v !== root.lastCaps)
                root.show("Bloq Mayús", 0, false, false, v ? "activado" : "desactivado");
            root.lastCaps = v;
        }
    }

    property int lastNum: -1
    Process { id: numBinds }
    FileView {
        id: num
        path: root.opt("osd", "sysfs_numlock_led", "")
        onLoaded: {
            const v = parseInt(text());
            if (root.lastNum !== -1 && v !== root.lastNum)
                root.show("Bloq Num", 0, false, false, v ? "activado" : "desactivado");
            if (v !== root.lastNum) {
                numBinds.command = [root.opt("osd", "numpad_binds_script", Quickshell.shellPath("../../hypr/scripts/numpad-binds.sh")), String(v)];
                numBinds.running = true;
            }
            root.lastNum = v;
        }
    }

    Timer {
        interval: (root.shown && root.iconKind === "brightness") ? 20 : 250
        running: true
        repeat: true
        onTriggered: bl.reload()
    }
    Timer {
        interval: 250
        running: true
        repeat: true
        onTriggered: { caps.reload(); num.reload(); }
    }

    Menus { id: menuHost; accent: root.accent; cfg: root.cfg }

    Battery { id: batteryHost; cfg: root.cfg }
    Connections {
        target: batteryHost
        function onWarning(level, percent) {
            root.showBattery((level <= 5 ? "Batería crítica" : level <= 10 ? "Batería muy baja" : "Batería baja") + " · " + percent + "%");
        }
        function onPlugChanged(plugged) {
            root.showBattery((plugged ? "Cargando" : "Desconectado") + " · " + batteryHost.percent + "%");
        }
    }

    PowerAuto { cfg: root.cfg; battery: batteryHost }

    Gpu { id: gpuHost; cfg: root.cfg }
    Connections {
        target: gpuHost
        function onOnChanged() { root.show("GPU", 0, false, false, gpuHost.on ? "GPU encendida" : "GPU apagada"); }
    }

    Launcher { id: launcherHost; accent: root.accent }
    ClipboardPanel { id: clipboardHost; accent: root.accent }

    Notifications { id: notifHost }
    Sysfreq { id: freqHost; cfg: root.cfg }
    Bar {
        menus: menuHost; notifications: notifHost; launcher: launcherHost; clipboard: clipboardHost; battery: batteryHost; freq: freqHost; accent: root.accent
        cfg: root.cfg
    }

    Headlights {}

    WorkspaceOverlay { accent: root.accent }

    PanelWindow {
        visible: root.windowVisible
        anchors.bottom: true
        margins.bottom: 70
        implicitWidth: 400
        implicitHeight: 100
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "osd"
        mask: Region {}

        Rectangle {
            id: pill
            anchors.centerIn: parent
            width: 340
            height: 60
            radius: height / 2
            color: "#000000"
            border.width: 1
            border.color: "#2a2a2a"
            opacity: 0
            scale: 0.7

            ParallelAnimation {
                id: showAnim
                NumberAnimation {
                    target: pill; property: "scale"; to: 1
                    duration: 200
                    easing.type: Easing.OutBack; easing.overshoot: 2.2
                }
                NumberAnimation { target: pill; property: "opacity"; to: 1; duration: 80 }
            }

            ParallelAnimation {
                id: hideAnim
                NumberAnimation {
                    target: pill; property: "scale"; to: 0.7
                    duration: 170
                    easing.type: Easing.InBack; easing.overshoot: 2.2
                }
                NumberAnimation { target: pill; property: "opacity"; to: 0; duration: 170; easing.type: Easing.InQuad }
                onFinished: root.windowVisible = false
            }

            Row {
                visible: !root.hasBar
                anchors.centerIn: parent
                spacing: 14

                OsdIcon {
                    id: micIcon
                    visible: root.iconKind === "mic"
                    anchors.verticalCenter: parent.verticalCenter
                    kind: "mic"
                    armed: root.armed
                    muted: root.source ? root.source.audio.muted : false
                }
                OsdIcon {
                    visible: root.iconKind === "battery"
                    anchors.verticalCenter: parent.verticalCenter
                    kind: "battery"
                    armed: root.armed
                    level: batteryHost.percent / 100
                    charging: batteryHost.charging
                    low: batteryHost.low
                }
                OsdIcon {
                    visible: root.iconKind === "gpu"
                    anchors.verticalCenter: parent.verticalCenter
                    kind: "gpu"
                    armed: root.armed
                    gpuOn: gpuHost.on
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.iconKind === "mic" ? "Micrófono " + root.stateText
                                                  : root.iconKind === "battery" || root.iconKind === "gpu" ? root.stateText
                                                  : root.title + ": " + root.stateText
                    color: "#ffffff"
                    font.pixelSize: 18
                }
            }

            Row {
                visible: root.hasBar
                anchors.centerIn: parent
                spacing: 14

                OsdIcon {
                    id: volIcon
                    visible: root.iconKind === "volume"
                    anchors.verticalCenter: parent.verticalCenter
                    kind: "volume"
                    armed: root.armed
                    muted: root.sink ? root.sink.audio.muted : false
                    level: root.sink ? root.sink.audio.volume : 0
                }
                OsdIcon {
                    visible: root.iconKind === "brightness"
                    anchors.verticalCenter: parent.verticalCenter
                    kind: "brightness"
                    level: root.value
                }
                Text {
                    visible: root.iconKind === ""
                    width: 78
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.muted ? "Silencio" : root.title
                    color: root.muted ? "#8a8a8a" : "#ffffff"
                    font.pixelSize: 16
                }
                Rectangle {
                    width: root.iconKind === "" ? 140 : 168
                    height: 8; radius: height / 2
                    anchors.verticalCenter: parent.verticalCenter
                    color: "#2a2a2a"
                    Rectangle {
                        height: parent.height; radius: 4
                        width: parent.width * Math.max(0, Math.min(1, root.value))
                        color: root.muted ? "#555555" : (root.value > 1 ? "#ff6b6b" : root.accent)
                        Behavior on width { NumberAnimation { duration: 55 } }
                    }
                }
                Text {
                    width: 44
                    horizontalAlignment: Text.AlignRight
                    anchors.verticalCenter: parent.verticalCenter
                    text: Math.round(root.value * 100) + "%"
                    color: root.muted ? "#8a8a8a" : "#ffffff"
                    font.pixelSize: 16
                }
            }
        }
    }
}
