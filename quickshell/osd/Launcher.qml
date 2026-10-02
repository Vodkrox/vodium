import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

Scope {
    id: launcher
    property color accent: "#ffffff"

    property bool open: false
    property bool windowVisible: false
    property string query: ""
    property int selected: 0

    readonly property int panelWidth: 540
    readonly property int panelHeight: 500
    readonly property int hangY: 120
    readonly property int rowHeight: 52
    readonly property int panelRadius: 22

    property var pinned: []
    FileView {
        id: pinStore
        path: Qt.resolvedUrl("pinned.json")
        printErrors: false
        onLoaded: {
            try { launcher.pinned = JSON.parse(text()); } catch (e) {}
        }
    }
    function isPinned(entry) { return pinned.indexOf(entry.id) >= 0; }
    function togglePin(entry) {
        const p = isPinned(entry) ? pinned.filter(id => id !== entry.id) : pinned.concat([entry.id]);
        pinned = p;
        pinStore.setText(JSON.stringify(p, null, 2) + "\n");
        selected = Math.max(0, results.indexOf(entry));
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void { launcher.open = !launcher.open; }
        function show(): void { launcher.open = true; }
        function close(): void { launcher.open = false; }
    }

    readonly property var results: {
        const q = query.toLowerCase().trim();
        const apps = DesktopEntries.applications.values.filter(a => !a.noDisplay);
        const pins = pinned;
        const pin = a => pins.indexOf(a.id) >= 0 ? 0 : 1;
        if (q === "")
            return apps.slice().sort((a, b) => pin(a) - pin(b) || a.name.localeCompare(b.name));
        const scored = [];
        for (const a of apps) {
            const name = a.name.toLowerCase();
            let score = -1;
            if (name.startsWith(q)) score = 0;
            else if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q))) score = 1;
            else if (name.includes(q)) score = 2;
            else if ((a.genericName || "").toLowerCase().includes(q)
                     || (a.keywords || []).some(k => k.toLowerCase().includes(q))) score = 3;
            else if ((a.comment || "").toLowerCase().includes(q)) score = 4;
            if (score >= 0) scored.push({ a: a, score: score });
        }
        scored.sort((x, y) => pin(x.a) - pin(y.a) || x.score - y.score || x.a.name.localeCompare(y.a.name));
        return scored.map(s => s.a);
    }

    function launch(entry) {
        if (!entry) return;
        entry.execute();
        open = false;
    }

    onOpenChanged: {
        if (open) {
            query = "";
            selected = 0;
            hideAnim.stop();
            if (!windowVisible) {
                hanger.y = -launcher.panelHeight - 60;
                swing.rotation = 0;
            }
            windowVisible = true;
            showAnim.restart();
            swingAnim.restart();
        } else {
            showAnim.stop();
            swingAnim.stop();
            hideAnim.restart();
        }
    }

    PanelWindow {
        visible: launcher.windowVisible
        anchors { top: true; bottom: true; left: true; right: true }
        color: Qt.rgba(0, 0, 0, 0.35)
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "launcher-veil"
        MouseArea { anchors.fill: parent; onClicked: launcher.open = false }
    }

    PanelWindow {
        visible: true
        mask: launcher.windowVisible ? fullMask : emptyMask
        Region { id: emptyMask }
        Region { id: fullMask; item: root }
        anchors { top: true }
        implicitWidth: launcher.panelWidth + 120
        implicitHeight: launcher.hangY + launcher.panelHeight + 80
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "launcher"
        WlrLayershell.keyboardFocus: launcher.windowVisible && launcher.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        Item { id: root; anchors.fill: parent }

        Item {
            id: swing
            width: launcher.panelWidth
            height: parent.height
            x: (parent.width - width) / 2
            transformOrigin: Item.Top

            Item {
                id: hanger
                width: parent.width
                height: launcher.panelHeight
                y: -launcher.panelHeight - 60

                Repeater {
                    model: 2
                    delegate: Item {
                        id: chain
                        required property int index
                        readonly property real pitch: 27
                        x: index === 0 ? 46 : launcher.panelWidth - 46
                        width: 0
                        y: 0
                        height: 0

                        Repeater {
                            model: 8
                            delegate: ChainLink {
                                required property int index
                                edge: index % 2 === 1
                                x: -width / 2
                                y: -6 - index * chain.pitch - height / 2
                                transformOrigin: Item.Center
                                rotation: 90
                                visible: hanger.y - 6 - index * chain.pitch > -40
                            }
                        }

                        Rectangle {
                            x: -9; y: -9
                            width: 18; height: 18; radius: 9
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "#ffffff" }
                                GradientStop { position: 0.5; color: "#6c778b" }
                                GradientStop { position: 1.0; color: "#d5deec" }
                            }
                            Rectangle {
                                anchors.centerIn: parent
                                width: 6; height: 6; radius: 3
                                color: "#111111"
                            }
                        }
                    }
                }

                Rectangle {
                    id: panel
                    width: parent.width
                    height: parent.height
                    radius: launcher.panelRadius
                    color: "#000000"
                    border.width: 1
                    border.color: "#2a2a2a"

                    MouseArea { anchors.fill: parent }

                    Rectangle {
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width - 80
                        height: 2
                        radius: 1
                        color: launcher.accent
                        opacity: 0.55
                    }

                    Rectangle {
                        id: searchBox
                        anchors { top: parent.top; left: parent.left; right: parent.right; margins: 18 }
                        anchors.topMargin: 26
                        height: 48
                        radius: 24
                        color: "#141414"
                        border.width: 1
                        border.color: input.activeFocus ? launcher.accent : "#2a2a2a"
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        Text {
                            id: searchIcon
                            anchors { left: parent.left; leftMargin: 18; verticalCenter: parent.verticalCenter }
                            text: "󰍉"
                            color: launcher.accent
                            font.family: "RobotoMono Nerd Font Propo"
                            font.pixelSize: 20
                        }
                        TextInput {
                            id: input
                            anchors {
                                left: searchIcon.right; leftMargin: 12
                                right: parent.right; rightMargin: 18
                                verticalCenter: parent.verticalCenter
                            }
                            color: "#ffffff"
                            selectionColor: launcher.accent
                            selectedTextColor: "#000000"
                            font.pixelSize: 17
                            clip: true
                            focus: true
                            text: launcher.query
                            onTextChanged: { launcher.query = text; launcher.selected = 0; }

                            Text {
                                visible: input.text === ""
                                text: "Buscar aplicaciones…"
                                color: "#6a6a6a"
                                font.pixelSize: 17
                            }

                            Keys.onEscapePressed: launcher.open = false
                            Keys.onDownPressed: launcher.selected = Math.min(launcher.selected + 1, launcher.results.length - 1)
                            Keys.onUpPressed: launcher.selected = Math.max(launcher.selected - 1, 0)
                            Keys.onTabPressed: launcher.selected = (launcher.selected + 1) % Math.max(1, launcher.results.length)
                            Keys.onReturnPressed: launcher.launch(launcher.results[launcher.selected])
                            Keys.onEnterPressed: launcher.launch(launcher.results[launcher.selected])
                            Keys.onPressed: event => {
                                if (event.modifiers & Qt.ControlModifier) {
                                    if (event.key === Qt.Key_N || event.key === Qt.Key_J) {
                                        launcher.selected = Math.min(launcher.selected + 1, launcher.results.length - 1);
                                        event.accepted = true;
                                    } else if (event.key === Qt.Key_P || event.key === Qt.Key_K) {
                                        launcher.selected = Math.max(launcher.selected - 1, 0);
                                        event.accepted = true;
                                    }
                                }
                            }
                        }
                    }

                    ListView {
                        id: list
                        anchors {
                            top: searchBox.bottom; topMargin: 12
                            left: parent.left; right: parent.right; bottom: parent.bottom
                            leftMargin: 12; rightMargin: 12; bottomMargin: 16
                        }
                        clip: true
                        spacing: 2
                        model: launcher.results
                        currentIndex: launcher.selected
                        boundsBehavior: Flickable.StopAtBounds
                        highlightMoveDuration: 0
                        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                        delegate: Rectangle {
                            id: row
                            required property var modelData
                            required property int index
                            readonly property bool sel: index === launcher.selected
                            width: list.width
                            height: launcher.rowHeight
                            radius: 14
                            color: sel ? "#1c1c1c" : "transparent"
                            Behavior on color { ColorAnimation { duration: 90 } }

                            Rectangle {
                                anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
                                width: 3
                                height: row.sel ? 24 : 0
                                radius: 2
                                color: launcher.accent
                                Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                            }

                            Image {
                                id: appIcon
                                anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
                                width: 34; height: 34
                                sourceSize: Qt.size(68, 68)
                                asynchronous: true
                                smooth: true
                                source: {
                                    const i = row.modelData.icon || "";
                                    return i.startsWith("/") ? "file://" + i : Quickshell.iconPath(i || "application-x-executable", true);
                                }
                            }

                            Column {
                                anchors {
                                    left: appIcon.right; leftMargin: 14
                                    right: parent.right; rightMargin: 42
                                    verticalCenter: parent.verticalCenter
                                }
                                spacing: 1
                                Text {
                                    width: parent.width
                                    text: row.modelData.name
                                    color: "#ffffff"
                                    font.pixelSize: 15
                                    font.bold: row.sel
                                    elide: Text.ElideRight
                                }
                                Text {
                                    visible: text !== ""
                                    width: parent.width
                                    text: row.modelData.genericName || row.modelData.comment || ""
                                    color: row.sel ? launcher.accent : "#7a7a7a"
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                }
                            }

                            Text {
                                visible: launcher.isPinned(row.modelData)
                                anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
                                text: "󰐃"
                                color: launcher.accent
                                font.family: "RobotoMono Nerd Font Propo"
                                font.pixelSize: 16
                            }

                            MouseArea {
                                id: rowArea
                                anchors.fill: parent
                                acceptedButtons: Qt.RightButton
                                onClicked: launcher.togglePin(row.modelData)
                            }
                        }

                        Text {
                            visible: launcher.results.length === 0
                            anchors.centerIn: parent
                            text: "Sin resultados"
                            color: "#6a6a6a"
                            font.pixelSize: 15
                        }
                    }
                }
            }

            SequentialAnimation {
                id: showAnim
                NumberAnimation {
                    target: hanger; property: "y"; to: launcher.hangY + 22
                    duration: 160; easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: hanger; property: "y"; to: launcher.hangY
                    duration: 130; easing.type: Easing.OutQuad
                }
                onFinished: input.forceActiveFocus()
            }
            SequentialAnimation {
                id: hideAnim
                NumberAnimation {
                    target: hanger; property: "y"; to: launcher.hangY + 14
                    duration: 70; easing.type: Easing.OutQuad
                }
                NumberAnimation {
                    target: hanger; property: "y"; to: -launcher.panelHeight - 60
                    duration: 260; easing.type: Easing.InCubic
                }
                onFinished: launcher.windowVisible = false
            }
            SequentialAnimation {
                id: swingAnim
                PauseAnimation { duration: 140 }
                NumberAnimation { target: swing; property: "rotation"; to: 1.4; duration: 90; easing.type: Easing.OutQuad }
                NumberAnimation { target: swing; property: "rotation"; to: 0; duration: 1000; easing.type: Easing.OutElastic; easing.amplitude: 1.0; easing.period: 0.5 }
            }
        }
    }
}
