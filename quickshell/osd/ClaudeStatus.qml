import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Shapes

PanelWindow {
    id: win

    property string state: "none"
    property bool active: state !== "none"
    property bool paused: false
    property int pollMs: 1000
    property int marginTop: 14
    property int marginRight: 46

    readonly property var look: ({
        ready:   { text: "Listo",       color: "#30d158" },
        waiting: { text: "Esperando",   color: "#ffd60a" },
        error:   { text: "Error",       color: "#ff453a" },
        working: { text: "Trabajando",  color: "#ff9f0a" }
    })
    property var shownLook: look.ready
    onStateChanged: if (look[state]) shownLook = look[state]

    Process {
        id: proc
        command: [decodeURIComponent(Qt.resolvedUrl("scripts/claude-status.sh").toString().replace("file://", ""))]
        stdout: StdioCollector { onStreamFinished: win.state = text.trim() || "none" }
    }
    Timer {
        interval: win.pollMs; running: true; repeat: true; triggeredOnStart: true
        onTriggered: if (!proc.running) proc.running = true
    }

    anchors { top: true; right: true }
    margins.top: win.marginTop
    margins.right: win.marginRight
    implicitWidth: pill.width + 20
    implicitHeight: pill.height + 20
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "claude-status"
    mask: Region {}

    property real fade: active ? 1 : 0
    Behavior on fade { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    visible: fade > 0

    Rectangle {
        id: pill
        anchors.centerIn: parent
        height: 34
        width: win.state === "working" ? height : row.width + 28
        Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        radius: height / 2
        color: "#000000"
        border.width: 1
        border.color: Qt.alpha(win.shownLook.color, 0.55)
        opacity: win.fade
        scale: 0.85 + 0.15 * win.fade
        Behavior on border.color { ColorAnimation { duration: 200 } }

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 9

            Item {
                width: 18; height: 18
                anchors.verticalCenter: parent.verticalCenter

                Item {
                    id: spinner
                    anchors.fill: parent
                    opacity: win.state === "working" ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    property real angle: -90
                    Timer {
                        interval: 50
                        repeat: true
                        running: win.state === "working" && win.visible && !win.paused
                        onTriggered: spinner.angle = (spinner.angle + 360 * interval / 1000) % 360
                    }

                    Shape {
                        anchors.fill: parent
                        layer.enabled: true
                        layer.samples: 4
                        ShapePath {
                            strokeWidth: 2.2
                            strokeColor: "#4c3003"
                            fillColor: "transparent"
                            PathAngleArc { centerX: 9; centerY: 9; radiusX: 7.5; radiusY: 7.5; startAngle: 0; sweepAngle: 359.9 }
                        }
                    }
                    Rectangle {
                        width: 5; height: 5; radius: 2.5
                        color: "#ff9f0a"
                        x: 9 + 7.5 * Math.cos(parent.angle * Math.PI / 180) - width / 2
                        y: 9 + 7.5 * Math.sin(parent.angle * Math.PI / 180) - height / 2
                    }
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: 10; height: 10; radius: 5
                    color: win.shownLook.color
                    opacity: win.state === "working" ? 0 : 1
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }
            Text {
                visible: win.state !== "working"
                anchors.verticalCenter: parent.verticalCenter
                text: win.shownLook.text
                color: "#ffffff"
                font.pixelSize: 15
            }
        }
    }
}
