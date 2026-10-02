import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root
    property color accent: "#ffffff"
    property bool active: false
    property var cfg: ({})

    implicitHeight: col.implicitHeight

    readonly property string tunedAdm: cfg.menus && cfg.menus.tuned_adm_path !== undefined ? cfg.menus.tuned_adm_path : "/usr/sbin/tuned-adm"
    readonly property var modes: [
        { key: "saver", label: "Ahorro", icon: "󰌪" },
        { key: "normal", label: "Normal", icon: "󰾅" },
        { key: "performance", label: "Rendimiento", icon: "󰓅" }
    ]

    property var mapping: ({ saver: "powersave", normal: "balanced", performance: "throughput-performance" })
    property string currentProfile: ""
    property bool settings: false
    property string editing: "saver"
    property var profiles: []

    readonly property var stateDefs: [
        { key: "charging", label: "Cargando", icon: "󰂄" },
        { key: "battery", label: "En batería", icon: "󰁹" },
        { key: "low", label: "Batería baja", icon: "󰂃" }
    ]
    readonly property var stateChoices: [{ key: "none", label: "Ninguno" }].concat(modes)
    property var states: ({ charging: "none", battery: "none", low: "none" })

    FileView {
        id: statesStore
        path: Quickshell.shellPath("../../config.json")
        printErrors: false
        onLoaded: {
            try {
                root.fullCfg = JSON.parse(text());
                root.states = Object.assign({}, root.states, root.fullCfg.power ? root.fullCfg.power.states : {});
            } catch (e) {}
        }
    }
    property var fullCfg: ({})
    function setState(state, mode) {
        const s = Object.assign({}, states);
        s[state] = mode;
        states = s;
        const c = Object.assign({}, fullCfg);
        c.power = Object.assign({}, c.power, { states: s });
        fullCfg = c;
        statesStore.setText(JSON.stringify(c, null, 2) + "\n");
    }

    FileView {
        id: store
        path: Qt.resolvedUrl("power.json")
        printErrors: false
        onLoaded: {
            try { root.mapping = Object.assign({}, root.mapping, JSON.parse(text())); } catch (e) {}
        }
    }
    function setMapping(mode, profile) {
        const m = Object.assign({}, mapping);
        m[mode] = profile;
        mapping = m;
        store.setText(JSON.stringify(m, null, 2) + "\n");
    }

    Process {
        id: activeProc
        command: [root.tunedAdm, "active"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.match(/Current active profile:\s*(\S+)/);
                root.currentProfile = m ? m[1] : "";
            }
        }
    }
    Process {
        id: listProc
        command: [root.tunedAdm, "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of text.split("\n")) {
                    const m = line.match(/^-\s+(\S+)\s+-\s+(.*)$/);
                    if (m) out.push({ name: m[1], desc: m[2] });
                }
                root.profiles = out;
            }
        }
    }
    Process {
        id: applyProc
        onExited: activeProc.running = true
    }
    function apply(profile) {
        applyProc.command = [tunedAdm, "profile", profile];
        applyProc.running = true;
        currentProfile = profile;
    }

    onActiveChanged: {
        if (active) {
            settings = false;
            store.reload();
            statesStore.reload();
            activeProc.running = true;
            listProc.running = true;
        }
    }
    Component.onCompleted: { store.reload(); statesStore.reload(); }

    Column {
        id: col
        width: parent.width
        spacing: 8

        Item {
            width: parent.width
            height: 28
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.settings ? (root.editing === "states" ? "Modo según estado" : "Perfiles de cada modo") : "Energía"
                color: "#ffffff"
                font.pixelSize: 16
                font.bold: true
            }
            Text {
                id: gear
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                text: root.settings ? "󰄬" : "󰒓"
                color: gearArea.containsMouse || root.settings ? root.accent : "#8a8a8a"
                font.family: "RobotoMono Nerd Font Propo"
                font.pixelSize: 20
                rotation: root.settings ? 90 : 0
                Behavior on rotation { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
                MouseArea {
                    id: gearArea
                    anchors.fill: parent
                    anchors.margins: -6
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.settings = !root.settings
                }
            }
        }

        Column {
            visible: !root.settings
            width: parent.width
            spacing: 2
            Repeater {
                model: root.modes
                MenuRow {
                    required property var modelData
                    width: col.width
                    accent: root.accent
                    icon: modelData.icon
                    text: modelData.label
                    subtext: root.mapping[modelData.key]
                    highlighted: root.currentProfile === root.mapping[modelData.key]
                    trailing: highlighted ? "󰄬" : ""
                    onClicked: root.apply(root.mapping[modelData.key])
                }
            }
            Text {
                visible: root.currentProfile !== "" && !root.modes.some(m => root.mapping[m.key] === root.currentProfile)
                width: parent.width
                topPadding: 4
                text: "Perfil activo: " + root.currentProfile
                color: "#8a8a8a"
                font.pixelSize: 12
            }
        }

        Column {
            visible: root.settings
            width: parent.width
            spacing: 8

            Row {
                spacing: 6
                Repeater {
                    model: root.modes.concat([{ key: "states", label: "Estados" }])
                    Rectangle {
                        required property var modelData
                        readonly property bool sel: root.editing === modelData.key
                        height: 30
                        width: tabText.implicitWidth + 24
                        radius: 15
                        color: sel ? root.accent : "#1c1c1c"
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Text {
                            id: tabText
                            anchors.centerIn: parent
                            text: modelData.label
                            color: parent.sel ? "#000000" : "#ffffff"
                            font.pixelSize: 13
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.editing = modelData.key
                        }
                    }
                }
            }

            Column {
                visible: root.editing === "states"
                width: parent.width
                spacing: 10
                Repeater {
                    model: root.stateDefs
                    Column {
                        required property var modelData
                        width: col.width
                        spacing: 4
                        Text {
                            text: modelData.icon + "  " + modelData.label
                            color: "#ffffff"
                            font.family: "RobotoMono Nerd Font Propo"
                            font.pixelSize: 13
                        }
                        Row {
                            spacing: 6
                            Repeater {
                                model: root.stateChoices
                                Rectangle {
                                    required property var modelData
                                    readonly property string stateKey: parent.parent.modelData.key
                                    readonly property bool sel: root.states[stateKey] === modelData.key
                                    height: 26
                                    width: choiceText.implicitWidth + 20
                                    radius: 13
                                    color: sel ? root.accent : "#1c1c1c"
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                    Text {
                                        id: choiceText
                                        anchors.centerIn: parent
                                        text: modelData.label
                                        color: parent.sel ? "#000000" : "#ffffff"
                                        font.pixelSize: 12
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.setState(parent.stateKey, modelData.key)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            ListView {
                id: list
                visible: root.editing !== "states"
                width: parent.width
                height: 260
                clip: true
                spacing: 2
                model: root.profiles
                delegate: MenuRow {
                    required property var modelData
                    width: list.width
                    accent: root.accent
                    text: modelData.name
                    subtext: modelData.desc
                    highlighted: root.mapping[root.editing] === modelData.name
                    trailing: highlighted ? "󰄬" : ""
                    onClicked: root.setMapping(root.editing, modelData.name)
                }
            }
        }
    }
}
