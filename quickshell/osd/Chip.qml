import QtQuick

Rectangle {
    id: root
    property string text: ""
    property bool selected: false
    property color accent: "#ffffff"
    signal clicked()

    implicitWidth: label.implicitWidth + 24
    implicitHeight: 30
    radius: height / 2
    color: selected ? accent : area.containsMouse ? "#1c1c1c" : "#141414"
    border.width: 1
    border.color: selected ? accent : "#2a2a2a"
    Behavior on color { ColorAnimation { duration: 100 } }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: root.selected ? "#000000" : "#ffffff"
        font.pixelSize: 13
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
