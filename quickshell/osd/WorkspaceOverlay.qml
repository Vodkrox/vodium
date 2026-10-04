import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

Item {
    id: root

    property color accent: "#ffffff"
    property int current: 1
    property var occupied: [1]
    property bool shown: false
    property bool windowVisible: false

    readonly property int slot: 30
    readonly property int ringSize: 26

    function activeIndex() {
        return root.occupied.indexOf(root.current);
    }

    onCurrentChanged: ballPulse.restart()

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

    Timer { id: hideTimer; interval: 1200; onTriggered: root.shown = false }

    Process {
        id: wsQuery
        command: ["hyprctl", "-j", "workspaces"]
        stdout: StdioCollector {
            onStreamFinished: {
                let ws;
                try { ws = JSON.parse(text); } catch (e) { return; }
                const ids = ws.filter(w => w.windows > 0).map(w => w.id);
                if (!ids.includes(root.current)) ids.push(root.current);
                ids.sort((a, b) => a - b);
                root.occupied = ids;
            }
        }
    }

    Process {
        running: true
        command: ["sh", "-c", "socat -u UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock -"]
        stdout: SplitParser {
            onRead: line => {
                const parts = line.split(">>");
                if (parts[0] === "workspacev2" || parts[0] === "openwindow" || parts[0] === "closewindow"
                    || parts[0] === "movewindowv2") {
                    if (parts[0] === "workspacev2") {
                        const id = parseInt(parts[1].split(",")[0]);
                        if (!isNaN(id)) root.current = id;
                        root.shown = true;
                        hideTimer.restart();
                    }
                    wsQuery.running = true;
                }
            }
        }
    }

    PanelWindow {
        visible: root.windowVisible
        anchors.top: true
        margins.top: 5
        implicitWidth: Math.max(1, root.occupied.length) * root.slot + 24 + 40
        implicitHeight: 84
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "workspace-overlay"
        mask: Region {}

        Rectangle {
            id: pill
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 8
            width: Math.max(1, root.occupied.length) * root.slot + 24
            height: 44
            radius: height / 2
            color: "#000000"
            border.width: 1
            border.color: "#2a2a2a"
            opacity: 0
            scale: 0.7
            Behavior on width { NumberAnimation { duration: 150 } }

            ParallelAnimation {
                id: showAnim
                NumberAnimation {
                    target: pill; property: "scale"; to: 1
                    duration: 160
                    easing.type: Easing.OutBack; easing.overshoot: 4
                }
                NumberAnimation { target: pill; property: "opacity"; to: 1; duration: 50 }
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

            Rectangle {
                id: ball
                width: root.ringSize; height: root.ringSize; radius: width / 2
                color: root.accent
                y: (parent.height - height) / 2
                readonly property real rowLeftPadding: (pill.width - root.occupied.length * root.slot) / 2
                x: rowLeftPadding + Math.max(0, root.activeIndex()) * root.slot + (root.slot - width) / 2
                Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                transform: Scale {
                    id: stretch
                    origin.x: root.ringSize / 2
                    origin.y: root.ringSize / 2
                    xScale: 1; yScale: 1
                }

                SequentialAnimation {
                    id: ballPulse
                    ParallelAnimation {
                        NumberAnimation { target: stretch; property: "xScale"; to: 1.7; duration: 70; easing.type: Easing.OutQuad }
                        NumberAnimation { target: stretch; property: "yScale"; to: 0.6; duration: 70; easing.type: Easing.OutQuad }
                    }
                    ParallelAnimation {
                        NumberAnimation { target: stretch; property: "xScale"; to: 1; duration: 170; easing.type: Easing.OutBack; easing.overshoot: 3.5 }
                        NumberAnimation { target: stretch; property: "yScale"; to: 1; duration: 170; easing.type: Easing.OutBack; easing.overshoot: 3.5 }
                    }
                }
            }

            Row {
                anchors.centerIn: parent
                spacing: 0
                Repeater {
                    model: root.occupied
                    Text {
                        required property var modelData
                        width: root.slot; height: 44
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: modelData
                        color: modelData === root.current ? "#000000" : "#808080"
                        font.pixelSize: 16
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }
            }
        }
    }
}
