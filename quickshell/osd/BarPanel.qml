import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: win

    property bool onLeft: false
    property bool covered: false
    property bool pinned: false
    property bool expanded: false
    property int expandedWidth: 32
    default property alias content: slide.data

    readonly property bool shown: !covered || pinned || expanded || hover.hovered || holdTimer.running
    property int barWidth: 32
    property int edgeWidth: 3
    property int hoverHoldMs: 300
    property int slideAnimMs: 180
    property int widthAnimMs: 220

    anchors { top: true; bottom: true; left: onLeft; right: !onLeft }
    implicitWidth: Math.max(barWidth, expandedWidth)
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    mask: Region { item: hitbox }

    Item {
        id: hitbox
        y: 0
        height: parent.height
        width: win.shown ? slide.width : win.edgeWidth
        x: win.onLeft ? 0 : parent.width - width

        HoverHandler {
            id: hover
            onHoveredChanged: if (!hovered) holdTimer.restart()
        }
    }

    Timer { id: holdTimer; interval: win.hoverHoldMs }

    Item {
        id: slide
        width: win.expanded ? win.expandedWidth : win.barWidth
        height: parent.height
        clip: true
        x: win.onLeft ? (win.shown ? 0 : -width) : (win.shown ? parent.width - width : parent.width)
        Behavior on x { NumberAnimation { duration: win.slideAnimMs; easing.type: Easing.OutCubic } }
        Behavior on width { NumberAnimation { duration: win.widthAnimMs; easing.type: Easing.OutCubic } }
    }
}
