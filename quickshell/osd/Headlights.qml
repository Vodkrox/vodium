import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

Scope {
    id: root

    property bool windowVisible: false
    property real progress: 0
    property real lit: 0
    property real flash: 0
    property real alpha: 0
    property bool introDone: false

    function play() {
        anim.stop();
        outro.stop();
        progress = 0; lit = 0; flash = 0; alpha = 0;
        introDone = false;
        windowVisible = true;
        anim.start();
    }

    function tryFinish() {
        if (windowVisible && introDone && !outro.running) outro.start();
    }

    IpcHandler {
        target: "headlights"
        function play(): void { root.play(); }
    }

    Process {
        running: true
        command: ["sh", "-c", `f="\${XDG_RUNTIME_DIR:-/tmp}/vodkrox-headlights-$(printf '%s' "$HYPRLAND_INSTANCE_SIGNATURE" | tr / _)"; if [ -e "$f" ]; then echo no; else : > "$f"; echo yes; fi`]
        stdout: StdioCollector { onStreamFinished: if (text.trim() === "yes") root.play() }
    }

    SequentialAnimation {
        id: anim
        ParallelAnimation {
            NumberAnimation { target: root; property: "alpha"; to: 1; duration: 200 }
            NumberAnimation { target: root; property: "progress"; to: 1; duration: 900; easing.type: Easing.OutCubic }
        }
        NumberAnimation { target: root; property: "lit"; to: 1; duration: 300; easing.type: Easing.OutQuad }
        PauseAnimation { duration: 430 }
        ScriptAction { script: { root.introDone = true; root.tryFinish(); } }
    }

    SequentialAnimation {
        id: outro
        NumberAnimation { target: root; property: "flash"; to: 1; duration: 120; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "alpha"; to: 0; duration: 250; easing.type: Easing.InQuart }
        ScriptAction { script: { root.windowVisible = false; root.flash = 0; } }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            visible: root.windowVisible
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "headlights"
            mask: Region {}

            Item {
                anchors.fill: parent
                opacity: root.alpha

                Rectangle { anchors.fill: parent; color: "#000000"; opacity: 0.92 }

                HeadlightSide {
                    anchors.fill: parent
                    progress: root.progress
                    lit: root.lit
                    flash: root.flash
                }
                HeadlightSide {
                    anchors.fill: parent
                    progress: root.progress
                    lit: root.lit
                    flash: root.flash
                    transform: Scale { origin.x: width / 2; xScale: -1 }
                }
            }
        }
    }
}
