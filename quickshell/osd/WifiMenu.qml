import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root
    property color accent: "#ffffff"
    property bool active: false

    property bool wifiOn: true
    property string device: ""
    property var networks: []
    property var known: []
    property string pending: ""
    property string message: ""
    property bool busy: false

    implicitHeight: col.implicitHeight

    onActiveChanged: {
        if (active) {
            pending = "";
            message = "";
            refresh();
            rescan.running = true;
        }
    }

    function refresh() {
        radioProc.running = true;
        deviceProc.running = true;
        knownProc.running = true;
        listProc.running = true;
    }

    function run(args) {
        if (action.running) return;
        busy = true;
        message = "";
        action.command = ["nmcli", ...args];
        action.running = true;
    }

    function parseLine(line) {
        const parts = line.split(":");
        const ssid = parts.slice(3).join(":").replace(/\\:/g, ":").replace(/\\\\/g, "\\");
        return { inUse: parts[0] === "*", signal: parseInt(parts[1]) || 0, secure: parts[2] !== "" && parts[2] !== "--", ssid: ssid };
    }

    function signalIcon(s) {
        return s > 75 ? "󰤨" : s > 50 ? "󰤥" : s > 25 ? "󰤢" : "󰤟";
    }

    Process {
        id: radioProc
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector { onStreamFinished: root.wifiOn = text.trim() === "enabled" }
    }
    Process {
        id: deviceProc
        command: ["nmcli", "-t", "-f", "DEVICE,TYPE", "device"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.split("\n").find(x => x.endsWith(":wifi"));
                root.device = l ? l.split(":")[0] : "";
            }
        }
    }
    Process {
        id: knownProc
        command: ["nmcli", "-t", "-f", "NAME", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: root.known = text.split("\n").filter(x => x !== "")
        }
    }
    Process {
        id: listProc
        command: ["nmcli", "-t", "-f", "IN-USE,SIGNAL,SECURITY,SSID", "device", "wifi", "list", "--rescan", "no"]
        stdout: StdioCollector {
            onStreamFinished: {
                const best = {};
                for (const line of text.split("\n")) {
                    if (line === "") continue;
                    const n = root.parseLine(line);
                    if (n.ssid === "") continue;
                    if (!best[n.ssid] || n.inUse || n.signal > best[n.ssid].signal && !best[n.ssid].inUse)
                        best[n.ssid] = n;
                }
                root.networks = Object.values(best).sort((a, b) =>
                    a.inUse !== b.inUse ? (a.inUse ? -1 : 1) : b.signal - a.signal);
            }
        }
    }
    Process { id: rescan; command: ["nmcli", "device", "wifi", "rescan"] }
    Timer {
        interval: 4000
        running: root.active && root.wifiOn
        repeat: true
        onTriggered: { listProc.running = true; }
    }

    Process {
        id: action
        stderr: StdioCollector { id: actionErr }
        onExited: code => {
            root.busy = false;
            root.pending = "";
            if (code !== 0) root.message = (actionErr.text.trim().split("\n")[0] || "No se pudo completar la acción");
            root.refresh();
        }
    }

    Column {
        id: col
        width: parent.width
        spacing: 8

        Item {
            width: parent.width
            height: 28
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Wi-Fi"
                color: "#ffffff"
                font.pixelSize: 16
                font.bold: true
            }
            Toggle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                accent: root.accent
                checked: root.wifiOn
                onToggled: {
                    root.wifiOn = !root.wifiOn;
                    root.run(["radio", "wifi", root.wifiOn ? "on" : "off"]);
                }
            }
        }

        Text {
            visible: root.busy
            text: "Conectando…"
            color: root.accent
            font.pixelSize: 13
        }
        Text {
            visible: root.message !== ""
            width: parent.width
            text: root.message
            color: "#ff6b6b"
            font.pixelSize: 12
            wrapMode: Text.WordWrap
        }

        Rectangle {
            visible: root.pending !== ""
            width: parent.width
            height: 44
            radius: 12
            color: "#1c1c1c"
            border.width: 1
            border.color: root.accent

            TextInput {
                id: pass
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                verticalAlignment: TextInput.AlignVCenter
                echoMode: TextInput.Password
                color: "#ffffff"
                font.pixelSize: 14
                clip: true
                onVisibleChanged: if (visible) { text = ""; forceActiveFocus(); }
                onAccepted: root.run(["device", "wifi", "connect", root.pending, "password", text])
                Text {
                    visible: pass.text === ""
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Contraseña de " + root.pending + " (Enter)"
                    color: "#8a8a8a"
                    font.pixelSize: 14
                }
            }
        }

        ListView {
            id: list
            visible: root.wifiOn
            width: parent.width
            height: Math.min(contentHeight, 300)
            clip: true
            spacing: 2
            model: root.networks
            delegate: MenuRow {
                required property var modelData
                width: list.width
                accent: root.accent
                text: modelData.ssid
                subtext: modelData.inUse ? "Conectado" : (root.known.includes(modelData.ssid) ? "Guardada" : "")
                icon: root.signalIcon(modelData.signal)
                highlighted: modelData.inUse
                trailing: modelData.secure ? "󰌾" : ""
                onClicked: {
                    if (modelData.inUse) root.run(["device", "disconnect", root.device]);
                    else if (root.known.includes(modelData.ssid)) root.run(["connection", "up", "id", modelData.ssid]);
                    else if (modelData.secure) root.pending = modelData.ssid;
                    else root.run(["device", "wifi", "connect", modelData.ssid]);
                }
            }
        }
    }
}
