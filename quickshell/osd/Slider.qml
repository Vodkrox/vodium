import QtQuick

Item {
    id: root
    property real value: 0
    property real maxValue: 1.0
    property color accent: "#ffffff"
    property bool muted: false
    signal moved(real v)

    implicitHeight: 24

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 8
        radius: 4
        color: "#2a2a2a"

        Rectangle {
            height: parent.height
            radius: 4
            width: parent.width * Math.max(0, Math.min(1, root.value / root.maxValue))
            color: root.muted ? "#555555" : root.accent
        }
    }

    Rectangle {
        width: 16; height: 16; radius: 8
        anchors.verticalCenter: parent.verticalCenter
        x: (root.width - width) * Math.max(0, Math.min(1, root.value / root.maxValue))
        color: "#ffffff"
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        function update(mx) {
            root.moved(Math.max(0, Math.min(1, mx / width)) * root.maxValue);
        }
        onPressed: mouse => update(mouse.x)
        onPositionChanged: mouse => { if (pressed) update(mouse.x); }
    }
}
