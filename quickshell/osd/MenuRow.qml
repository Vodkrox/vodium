import QtQuick

Rectangle {
    id: root
    property string icon: ""
    property string text: ""
    property string subtext: ""
    property string trailing: ""
    property bool highlighted: false
    property color accent: "#ffffff"
    signal clicked()

    implicitHeight: 44
    radius: 12
    color: area.containsMouse ? "#1c1c1c" : "transparent"

    Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: 12
        spacing: 12

        Text {
            width: 22
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignHCenter
            text: root.icon
            color: root.highlighted ? root.accent : "#ffffff"
            font.family: "RobotoMono Nerd Font Propo"
            font.pixelSize: 18
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 22 - 40 - parent.spacing * 2
            Text {
                width: parent.width
                text: root.text
                color: "#ffffff"
                font.pixelSize: 14
                elide: Text.ElideRight
            }
            Text {
                visible: root.subtext !== ""
                width: parent.width
                text: root.subtext
                color: root.highlighted ? root.accent : "#8a8a8a"
                font.pixelSize: 12
                elide: Text.ElideRight
            }
        }

        Text {
            width: 40
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignRight
            text: root.trailing
            color: "#8a8a8a"
            font.family: "RobotoMono Nerd Font Propo"
            font.pixelSize: 14
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
