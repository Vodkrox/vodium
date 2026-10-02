import Quickshell
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import QtQuick

PanelWindow {
    id: win

    property bool open: false
    signal closeRequested()
    property int barWidth: 32
    property color accent: "#ffffff"

    readonly property int cols: 4
    readonly property int cell: 40
    readonly property int pad: 14
    readonly property int panelW: cols * cell + pad * 2
    readonly property int chainMax: 84
    readonly property real pitch: 27
    readonly property int count: SystemTray.items.values.length
    readonly property int panelH: Math.max(96, Math.max(1, Math.ceil(count / cols)) * cell + pad * 2)

    property real p: 0
    readonly property real travel: panelW + chainMax
    onOpenChanged: {
        if (open) { hideAnim.stop(); showAnim.restart(); }
        else { showAnim.stop(); hideAnim.restart(); }
    }

    SequentialAnimation {
        id: showAnim
        NumberAnimation { target: win; property: "p"; to: 1 + 22 / win.travel; duration: 160; easing.type: Easing.OutCubic }
        NumberAnimation { target: win; property: "p"; to: 1; duration: 130; easing.type: Easing.OutQuad }
    }
    SequentialAnimation {
        id: hideAnim
        NumberAnimation { target: win; property: "p"; to: 1 + 14 / win.travel; duration: 70; easing.type: Easing.OutQuad }
        NumberAnimation { target: win; property: "p"; to: 0; duration: 260; easing.type: Easing.InCubic }
    }

    visible: p > 0.001
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "tray"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    mask: Region { item: win.open ? outside : stage }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: win.closeRequested()
    }

    MouseArea {
        id: outside
        x: win.barWidth
        width: parent.width - win.barWidth
        height: parent.height
        onClicked: win.closeRequested()
    }

    Item {
        id: stage
        x: win.barWidth
        width: win.chainMax + win.panelW + 24
        height: parent.height
        clip: true

        readonly property real panelX: -win.panelW + (win.panelW + win.chainMax) * win.p
        readonly property real panelY: (height - win.panelH) / 2

        Repeater {
            model: 2

            Item {
                id: chain
                required property int index
                x: 0
                y: stage.panelY + (index === 0 ? 24 : win.panelH - 24) - 9
                width: Math.max(0, stage.panelX + 6)
                height: 18
                clip: true

                Repeater {
                    model: Math.ceil(win.chainMax * 1.3 / win.pitch) + 2

                    ChainLink {
                        required property int index
                        edge: index % 2 === 1
                        x: chain.width - (index + 0.5) * win.pitch - width / 2 + 6
                        y: 0
                    }
                }
            }
        }

        Rectangle {
            id: panel
            x: stage.panelX
            y: stage.panelY
            width: win.panelW
            height: win.panelH
            radius: 20
            color: "#000000"
            border.width: 1
            border.color: "#2a2a2a"

            MouseArea { anchors.fill: parent }

            Text {
                visible: win.count === 0
                anchors.centerIn: parent
                text: "Sin aplicaciones"
                color: "#8a8a8a"
                font.pixelSize: 13
            }

            Flow {
                x: win.pad
                y: win.pad
                width: win.cols * win.cell

                Repeater {
                    model: SystemTray.items

                    Rectangle {
                        id: cellItem
                        required property var modelData
                        width: win.cell
                        height: win.cell
                        radius: 12
                        color: area.containsMouse ? "#1c1c1c" : "transparent"

                        Image {
                            anchors.centerIn: parent
                            width: 22; height: 22
                            sourceSize: Qt.size(44, 44)
                            source: cellItem.modelData.icon
                            smooth: true
                        }

                        MouseArea {
                            id: area
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                            onClicked: mouse => {
                                const it = cellItem.modelData;
                                const pos = cellItem.mapToItem(null, mouse.x, mouse.y);
                                if (mouse.button === Qt.MiddleButton) it.secondaryActivate();
                                else if (mouse.button === Qt.RightButton || it.onlyMenu) {
                                    if (it.hasMenu) it.display(win, pos.x, pos.y);
                                } else it.activate();
                            }
                        }
                    }
                }
            }
        }
    }
}
