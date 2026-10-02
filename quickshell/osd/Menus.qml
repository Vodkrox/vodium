import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

Scope {
    id: menus
    property color accent: "#ffffff"
    property var cfg: ({})

    property string current: ""
    property string shownName: ""
    property bool windowVisible: false

    IpcHandler {
        target: "menu"
        function toggle(name: string): void { menus.current = menus.current === name ? "" : name; }
        function close(): void { menus.current = ""; }
    }

    function toggle(name) { current = current === name ? "" : name; }

    onCurrentChanged: {
        if (current !== "") {
            shownName = current;
            hideAnim.stop();
            if (!windowVisible) { panel.scale = 0.85; panel.opacity = 0; }
            windowVisible = true;
            showAnim.restart();
        } else {
            showAnim.stop();
            hideAnim.restart();
        }
    }

    Component { id: soundC; SoundMenu { accent: menus.accent; active: menus.current === "sound" } }
    Component { id: bluetoothC; BluetoothMenu { accent: menus.accent; active: menus.current === "bluetooth" } }
    Component { id: powerC; PowerMenu { accent: menus.accent; active: menus.current === "power"; cfg: menus.cfg } }
    Component { id: wifiC; WifiMenu { accent: menus.accent; active: menus.current === "wifi" } }

    PanelWindow {
        visible: menus.windowVisible
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "menus"
        WlrLayershell.keyboardFocus: menus.current !== "" ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        MouseArea {
            anchors.fill: parent
            onClicked: menus.current = ""
        }

        Item {
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: menus.current = ""
        }

        Rectangle {
            id: panel
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: 44
            anchors.bottomMargin: 16
            width: 340
            height: loader.item ? loader.item.implicitHeight + 32 : 100
            radius: 20
            color: "#000000"
            border.width: 1
            border.color: "#2a2a2a"
            opacity: 0
            scale: 0.85
            transformOrigin: Item.BottomRight

            MouseArea { anchors.fill: parent }

            Loader {
                id: loader
                anchors.fill: parent
                anchors.margins: 16
                sourceComponent: menus.shownName === "sound" ? soundC
                    : menus.shownName === "bluetooth" ? bluetoothC
                    : menus.shownName === "wifi" ? wifiC
                    : menus.shownName === "power" ? powerC : null
            }

            ParallelAnimation {
                id: showAnim
                NumberAnimation {
                    target: panel; property: "scale"; to: 1
                    duration: 280; easing.type: Easing.OutBack; easing.overshoot: 1.8
                }
                NumberAnimation { target: panel; property: "opacity"; to: 1; duration: 120 }
            }
            ParallelAnimation {
                id: hideAnim
                NumberAnimation {
                    target: panel; property: "scale"; to: 0.85
                    duration: 220; easing.type: Easing.InBack; easing.overshoot: 1.8
                }
                NumberAnimation { target: panel; property: "opacity"; to: 0; duration: 220; easing.type: Easing.InQuad }
                onFinished: menus.windowVisible = false
            }
        }
    }
}
