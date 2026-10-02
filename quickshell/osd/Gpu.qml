import Quickshell
import Quickshell.Io
import QtQuick

Scope {
    id: root

    property var cfg: ({})
    property bool on: false
    readonly property string device: cfg.gpu && cfg.gpu.pci_device !== undefined
        ? cfg.gpu.pci_device : ""

    FileView {
        id: status
        path: root.device
        onLoaded: {
            const s = text().trim();
            if (s === "active" || s === "resuming") root.on = true;
            else if (s === "suspended" || s === "suspending") root.on = false;
        }
    }
    Timer {
        interval: 250
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: status.reload()
    }
}
