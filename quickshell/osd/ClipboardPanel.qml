import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

Scope {
    id: cb
    property color accent: "#ffffff"

    property bool open: false
    property bool windowVisible: false
    property string query: ""
    property int selected: 0
    property bool confirmWipe: false
    property var items: []

    readonly property int panelWidth: 540
    readonly property int panelHeight: 500
    readonly property int hangY: 120
    readonly property int panelRadius: 22
    readonly property string thumbDir: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/vodkrox-clip-"

    IpcHandler {
        target: "clipboard"
        function toggle(): void { cb.open = !cb.open; }
        function show(): void { cb.open = true; }
        function close(): void { cb.open = false; }
    }

    property var history: []
    property var pins: []
    property var thumbsReady: ({})

    readonly property var all: {
        const norm = t => t.split(/\s+/).filter(w => w).join(" ");
        const np = pins.map(norm);
        const out = pins.map((t, i) => ({ id: "", text: norm(t), full: t, image: "", pinned: true, pin: i }));
        for (const h of history) {
            if (h.image === "" && np.some(p => p === h.text || (h.text.endsWith("…") && p.startsWith(h.text.slice(0, -1))))) continue;
            out.push(h);
        }
        return out;
    }

    readonly property var results: {
        const q = query.toLowerCase().trim();
        return q === "" ? all : all.filter(i => i.text.toLowerCase().includes(q));
    }

    FileView {
        id: pinStore
        path: Qt.resolvedUrl("clipboard-pins.json")
        printErrors: false
        onLoaded: { try { cb.pins = JSON.parse(text()); } catch (e) {} }
    }
    function savePins(p) {
        pins = p;
        pinStore.setText(JSON.stringify(p, null, 2) + "\n");
    }

    function refresh() { if (!lister.running) lister.running = true; }

    Process {
        id: lister
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of text.split("\n")) {
                    const t = line.indexOf("\t");
                    if (t <= 0) continue;
                    const id = line.slice(0, t), preview = line.slice(t + 1);
                    const img = /^\[\[ binary data .*(png|jpe?g|bmp|webp|gif)/i.test(preview);
                    out.push({ id: id, text: preview, full: "", image: img ? cb.thumbDir + id : "", pinned: false, pin: -1 });
                }
                cb.history = out;
                cb.selected = Math.min(cb.selected, Math.max(0, cb.results.length - 1));
            }
        }
    }

    Instantiator {
        model: cb.history.filter(h => h.image !== "")
        delegate: Process {
            required property var modelData
            running: true
            command: ["sh", "-c", 'cliphist decode "$1" > "$2"', "sh", modelData.id, modelData.image]
            onExited: {
                const r = Object.assign({}, cb.thumbsReady);
                r[modelData.id] = true;
                cb.thumbsReady = r;
            }
        }
    }

    Process { id: copier }
    Process { id: deleter; onExited: cb.refresh() }
    Process { id: wiper; onExited: cb.refresh() }
    Process { id: decoder; stdout: StdioCollector { onStreamFinished: cb.addPin(text) } }

    Process {
        id: watcher
        running: true
        command: ["sh", "-c", "exec wl-paste --watch sh -c 'if wl-paste --list-types | grep -qx x-kde-passwordManagerHint; then cat >/dev/null; else cliphist -max-items 20 store; fi'"]
    }

    function addPin(t) {
        if (t.trim() === "" || pins.indexOf(t) >= 0) return;
        savePins([t].concat(pins));
    }

    function choose(entry) {
        if (!entry) return;
        copier.command = entry.pinned
            ? ["wl-copy", "--", entry.full]
            : ["sh", "-c", 'cliphist decode "$1" | wl-copy', "sh", entry.id];
        copier.running = true;
        open = false;
    }

    function remove(entry) {
        if (!entry) return;
        if (entry.pinned) {
            savePins(pins.filter((_, i) => i !== entry.pin));
        } else {
            deleter.command = ["sh", "-c", 'printf "%s\\t\\n" "$1" | cliphist delete', "sh", entry.id];
            deleter.running = true;
        }
    }

    function togglePin(entry) {
        if (!entry) return;
        if (entry.pinned) { remove(entry); return; }
        if (entry.image !== "") return;
        decoder.command = ["cliphist", "decode", entry.id];
        decoder.running = true;
    }

    function wipe() {
        if (!confirmWipe) { confirmWipe = true; return; }
        confirmWipe = false;
        wiper.command = ["cliphist", "wipe"];
        wiper.running = true;
    }

    onOpenChanged: {
        if (open) {
            query = "";
            selected = 0;
            confirmWipe = false;
            refresh();
            hideAnim.stop();
            if (!windowVisible) {
                hanger.y = -cb.panelHeight - 60;
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
        visible: cb.windowVisible
        anchors { top: true; bottom: true; left: true; right: true }
        color: Qt.rgba(0, 0, 0, 0.35)
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "clipboard-veil"
        MouseArea { anchors.fill: parent; onClicked: cb.open = false }
    }

    PanelWindow {
        visible: true
        mask: cb.windowVisible ? fullMask : emptyMask
        Region { id: emptyMask }
        Region { id: fullMask; item: root }
        anchors { top: true }
        implicitWidth: cb.panelWidth + 120
        implicitHeight: cb.hangY + cb.panelHeight + 80
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "clipboard"
        WlrLayershell.keyboardFocus: cb.windowVisible && cb.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        Item { id: root; anchors.fill: parent }

        Item {
            id: swing
            width: cb.panelWidth
            height: parent.height
            x: (parent.width - width) / 2
            transformOrigin: Item.Top

            Item {
                id: hanger
                width: parent.width
                height: cb.panelHeight
                y: -cb.panelHeight - 60

                Repeater {
                    model: 2
                    delegate: Item {
                        id: chain
                        required property int index
                        readonly property real pitch: 27
                        x: index === 0 ? 46 : cb.panelWidth - 46
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
                    radius: cb.panelRadius
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
                        color: cb.accent
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
                        border.color: input.activeFocus ? cb.accent : "#2a2a2a"
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        Text {
                            id: searchIcon
                            anchors { left: parent.left; leftMargin: 18; verticalCenter: parent.verticalCenter }
                            text: "󰅌"
                            color: cb.accent
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
                            selectionColor: cb.accent
                            selectedTextColor: "#000000"
                            font.pixelSize: 17
                            clip: true
                            focus: true
                            text: cb.query
                            onTextChanged: { cb.query = text; cb.selected = 0; }

                            Text {
                                visible: input.text === ""
                                text: "Buscar en el portapapeles…"
                                color: "#6a6a6a"
                                font.pixelSize: 17
                            }

                            Keys.onEscapePressed: cb.open = false
                            Keys.onDownPressed: cb.selected = Math.min(cb.selected + 1, cb.results.length - 1)
                            Keys.onUpPressed: cb.selected = Math.max(cb.selected - 1, 0)
                            Keys.onTabPressed: cb.selected = (cb.selected + 1) % Math.max(1, cb.results.length)
                            Keys.onReturnPressed: cb.choose(cb.results[cb.selected])
                            Keys.onEnterPressed: cb.choose(cb.results[cb.selected])
                            Keys.onDeletePressed: cb.remove(cb.results[cb.selected])
                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Space) {
                                    cb.togglePin(cb.results[cb.selected]);
                                    event.accepted = true;
                                } else if (event.modifiers & Qt.ControlModifier) {
                                    if (event.key === Qt.Key_N || event.key === Qt.Key_J) {
                                        cb.selected = Math.min(cb.selected + 1, cb.results.length - 1);
                                        event.accepted = true;
                                    } else if (event.key === Qt.Key_P || event.key === Qt.Key_K) {
                                        cb.selected = Math.max(cb.selected - 1, 0);
                                        event.accepted = true;
                                    } else if (event.key === Qt.Key_S) {
                                        cb.togglePin(cb.results[cb.selected]);
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
                            left: parent.left; right: parent.right; bottom: footer.top
                            leftMargin: 12; rightMargin: 12; bottomMargin: 6
                        }
                        clip: true
                        spacing: 2
                        model: cb.results
                        currentIndex: cb.selected
                        boundsBehavior: Flickable.StopAtBounds
                        highlightMoveDuration: 0
                        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                        delegate: Rectangle {
                            id: row
                            required property var modelData
                            required property int index
                            readonly property bool sel: index === cb.selected
                            readonly property bool isImage: modelData.image !== ""
                            width: list.width
                            height: isImage ? 72 : 48
                            radius: 14
                            color: sel ? "#1c1c1c" : "transparent"
                            Behavior on color { ColorAnimation { duration: 90 } }

                            Rectangle {
                                anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
                                width: 3
                                height: row.sel ? 24 : 0
                                radius: 2
                                color: cb.accent
                                Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                            }

                            Rectangle {
                                id: thumb
                                visible: row.isImage
                                anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
                                width: 56; height: 56
                                radius: 8
                                color: "#141414"
                                clip: true
                                Image {
                                    anchors.fill: parent
                                    source: row.isImage && cb.thumbsReady[row.modelData.id] ? "file://" + row.modelData.image : ""
                                    sourceSize: Qt.size(112, 112)
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: false
                                }
                            }

                            Text {
                                id: kindIcon
                                visible: !row.isImage
                                anchors { left: parent.left; leftMargin: 18; verticalCenter: parent.verticalCenter }
                                text: "󰈙"
                                color: row.sel ? cb.accent : "#7a7a7a"
                                font.family: "RobotoMono Nerd Font Propo"
                                font.pixelSize: 18
                            }

                            Text {
                                anchors {
                                    left: row.isImage ? thumb.right : kindIcon.right; leftMargin: 14
                                    right: parent.right; rightMargin: 42
                                    verticalCenter: parent.verticalCenter
                                }
                                text: row.isImage ? "Imagen" : row.modelData.text
                                color: "#ffffff"
                                font.pixelSize: 14
                                font.bold: row.sel
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }

                            Text {
                                visible: row.modelData.pinned
                                anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
                                text: "󰐃"
                                color: cb.accent
                                font.family: "RobotoMono Nerd Font Propo"
                                font.pixelSize: 16
                            }

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: mouse => {
                                    if (mouse.button === Qt.RightButton) cb.togglePin(row.modelData);
                                    else cb.choose(row.modelData);
                                }
                            }
                        }

                        Text {
                            visible: cb.results.length === 0
                            anchors.centerIn: parent
                            text: cb.query === "" ? "Historial vacío" : "Sin resultados"
                            color: "#6a6a6a"
                            font.pixelSize: 15
                        }
                    }

                    Item {
                        id: footer
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 16 }
                        height: 28

                        Rectangle {
                            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                            width: wipeText.width + 24
                            height: 26
                            radius: 13
                            color: cb.confirmWipe ? "#3a1212" : "#141414"
                            border.width: 1
                            border.color: cb.confirmWipe ? "#ff6b6b" : "#2a2a2a"
                            Text {
                                id: wipeText
                                anchors.centerIn: parent
                                text: cb.confirmWipe ? "¿Seguro?" : "Vaciar"
                                color: cb.confirmWipe ? "#ff6b6b" : "#9a9a9a"
                                font.pixelSize: 12
                            }
                            MouseArea { anchors.fill: parent; onClicked: cb.wipe() }
                        }
                    }
                }
            }

            SequentialAnimation {
                id: showAnim
                NumberAnimation {
                    target: hanger; property: "y"; to: cb.hangY + 22
                    duration: 160; easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: hanger; property: "y"; to: cb.hangY
                    duration: 130; easing.type: Easing.OutQuad
                }
                onFinished: input.forceActiveFocus()
            }
            SequentialAnimation {
                id: hideAnim
                NumberAnimation {
                    target: hanger; property: "y"; to: cb.hangY + 14
                    duration: 70; easing.type: Easing.OutQuad
                }
                NumberAnimation {
                    target: hanger; property: "y"; to: -cb.panelHeight - 60
                    duration: 260; easing.type: Easing.InCubic
                }
                onFinished: cb.windowVisible = false
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
