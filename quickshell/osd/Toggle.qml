import QtQuick

Rectangle {
    id: root
    property bool checked: false
    property color accent: "#ffffff"
    signal toggled()

    implicitWidth: 44
    implicitHeight: 24
    radius: height / 2
    color: checked ? accent : "#2a2a2a"
    Behavior on color { ColorAnimation { duration: 120 } }

    Rectangle {
        width: 18; height: 18; radius: 9
        y: 3
        x: root.checked ? root.width - width - 3 : 3
        color: root.checked ? "#000000" : "#ffffff"
        Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
