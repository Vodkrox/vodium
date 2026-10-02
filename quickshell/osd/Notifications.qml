import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick

Scope {
    id: root

    property bool open: false
    readonly property int panelWidth: 360
    readonly property var model: server.trackedNotifications
    readonly property int count: server.trackedNotifications.values.length

    readonly property int holdDuration: 1500
    property bool holding: false
    property real holdProgress: 0
    property bool keyDown: false
    property bool repeating: false
    property bool holdDone: false
    property double lastPress: 0
    property double lastToggle: 0
    property double holdStart: 0

    function press() {
        const now = Date.now();
        const gap = now - lastPress;
        lastPress = now;
        releaseTimer.interval = repeating ? 100 : 750;
        releaseTimer.restart();

        const repeatGap = 250;
        const isRepeat = keyDown && (repeating || gap >= repeatGap || gap < 100);
        if (!isRepeat) {
            if (now - lastToggle < 300) return;
            lastToggle = now;
            keyDown = true; repeating = false; holdDone = false; holding = false; holdProgress = 0;
            holdStart = now;
            open = !open;
            return;
        }
        repeating = true;
        if (!holdDone && !holding) {
            holding = true;
            open = true;
        }
    }

    Timer {
        id: releaseTimer
        interval: 750
        onTriggered: { root.keyDown = false; root.repeating = false; root.holding = false; root.holdDone = false; root.holdProgress = 0; }
    }

    FrameAnimation {
        running: root.holding
        onTriggered: {
            root.holdProgress = Math.min(1, (Date.now() - root.holdStart) / root.holdDuration);
            if (root.holdProgress >= 1) {
                root.clearAll();
                root.holding = false;
                root.holdDone = true;
                root.holdProgress = 0;
            }
        }
    }

    IpcHandler {
        target: "notifications"
        function press(): void { root.press(); }
        function toggle(): void { root.open = !root.open; }
        function close(): void { root.open = false; }
    }

    function clearAll() {
        for (const n of server.trackedNotifications.values.slice()) n.dismiss();
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            visible: root.open
            anchors { top: true; bottom: true; left: true; right: true }
            margins { left: root.panelWidth; right: 32 }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "notifications-dismiss"
            WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            MouseArea {
                anchors.fill: parent
                onClicked: root.open = false
            }
            Item {
                anchors.fill: parent
                focus: true
                Keys.onEscapePressed: root.open = false
            }
        }
    }

    NotificationServer {
        id: server
        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: true
        imageSupported: true
        onNotification: n => { n.tracked = true; }
    }
}
