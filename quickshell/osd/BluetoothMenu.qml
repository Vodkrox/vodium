import Quickshell
import Quickshell.Bluetooth
import QtQuick

Item {
    id: root
    property color accent: "#ffffff"
    property bool active: false

    readonly property var adapter: Bluetooth.defaultAdapter
    implicitHeight: col.implicitHeight

    onActiveChanged: {
        if (!active && adapter) adapter.discovering = false;
    }

    readonly property var sortedDevices: [...Bluetooth.devices.values].filter(d => d.paired || d.connected
        || (d.name && !/^([0-9a-f]{2}[-:]){5}[0-9a-f]{2}$/i.test(d.name))).sort((a, b) => {
        if (a.connected !== b.connected) return a.connected ? -1 : 1;
        if (a.paired !== b.paired) return a.paired ? -1 : 1;
        return (a.name || "").localeCompare(b.name || "");
    })
    onSortedDevicesChanged: settle.restart()
    Timer { id: settle; interval: 400; onTriggered: devices.values = root.sortedDevices }

    ScriptModel {
        id: devices
        values: []
    }
    Component.onCompleted: devices.values = root.sortedDevices

    function subtitle(d) {
        if (d.connected)
            return d.batteryAvailable ? "Conectado · " + Math.round(d.battery * 100) + "%" : "Conectado";
        return d.paired ? "Emparejado" : "";
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
                text: "Bluetooth"
                color: "#ffffff"
                font.pixelSize: 16
                font.bold: true
            }
            Chip {
                visible: root.adapter && root.adapter.enabled
                anchors.right: toggle.left
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                implicitHeight: 26
                accent: root.accent
                selected: root.adapter ? root.adapter.discovering : false
                text: selected ? "Detener" : "Buscar"
                onClicked: { if (root.adapter) root.adapter.discovering = !root.adapter.discovering; }
            }
            Toggle {
                id: toggle
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                accent: root.accent
                checked: root.adapter ? root.adapter.enabled : false
                onToggled: { if (root.adapter) root.adapter.enabled = !root.adapter.enabled; }
            }
        }

        Text {
            visible: !root.adapter
            text: "No se encontró ningún adaptador Bluetooth"
            color: "#8a8a8a"
            font.pixelSize: 13
        }

        Text {
            visible: root.adapter && root.adapter.enabled && root.adapter.discovering
            text: "󰂰  Buscando dispositivos…"
            color: root.accent
            font.family: "RobotoMono Nerd Font Propo"
            font.pixelSize: 13
        }

        ListView {
            id: list
            visible: root.adapter && root.adapter.enabled
            width: parent.width
            height: Math.min(contentHeight, 300)
            clip: true
            spacing: 2
            model: devices
            delegate: MenuRow {
                required property var modelData
                width: list.width
                accent: root.accent
                text: modelData.name || modelData.address
                subtext: root.subtitle(modelData)
                icon: modelData.connected ? "󰂱" : "󰂯"
                highlighted: modelData.connected
                onClicked: {
                    if (modelData.connected) modelData.disconnect();
                    else if (modelData.paired) modelData.connect();
                    else modelData.pair();
                }
            }
        }
    }
}
