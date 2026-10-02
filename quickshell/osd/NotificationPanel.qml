import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property var notifications
    property color accent: "#ffffff"
    property bool holding: false
    property real holdProgress: 0

    Item {
        id: header
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: 28

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Notificaciones"
            color: "#ffffff"
            font.pixelSize: 16
            font.bold: true
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            visible: root.notifications && root.notifications.count > 0
            text: "Borrar todo"
            color: clearArea.containsMouse ? root.accent : "#8a8a8a"
            font.pixelSize: 13
            MouseArea {
                id: clearArea
                anchors.fill: parent
                anchors.margins: -6
                hoverEnabled: true
                onClicked: root.notifications.clearAll()
            }
        }
    }

    Text {
        anchors.centerIn: parent
        visible: !root.notifications || root.notifications.count === 0
        text: "Sin notificaciones"
        color: "#555555"
        font.pixelSize: 14
    }

    ListView {
        id: list
        anchors { top: header.bottom; topMargin: 12; bottom: parent.bottom; left: parent.left; right: parent.right }
        clip: true
        spacing: 8
        boundsBehavior: Flickable.StopAtBounds
        model: root.notifications ? root.notifications.model : null

        delegate: Rectangle {
            id: card
            required property var modelData

            width: list.width
            height: content.implicitHeight + 24
            radius: 12
            color: "#111111"
            border.width: 1
            border.color: modelData.urgency === NotificationUrgency.Critical ? "#ff6b6b" : "#2a2a2a"

            MouseArea {
                anchors.fill: parent
                onClicked: card.modelData.dismiss()
            }

            Column {
                id: content
                x: 12; y: 12
                width: parent.width - 24
                spacing: 4

                Text {
                    width: parent.width
                    visible: text !== ""
                    text: card.modelData.appName
                    color: "#8a8a8a"
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    text: card.modelData.summary
                    color: "#ffffff"
                    font.pixelSize: 14
                    font.bold: true
                    wrapMode: Text.Wrap
                }
                Text {
                    width: parent.width
                    visible: text !== ""
                    text: card.modelData.body
                    textFormat: Text.StyledText
                    color: "#b0b0b0"
                    font.pixelSize: 13
                    wrapMode: Text.Wrap
                    maximumLineCount: 6
                    elide: Text.ElideRight
                }
                Flow {
                    width: parent.width
                    spacing: 6
                    visible: card.modelData.actions.length > 0

                    Repeater {
                        model: card.modelData.actions
                        delegate: Rectangle {
                            required property var modelData
                            width: label.implicitWidth + 20
                            height: 26
                            radius: 13
                            color: "transparent"
                            border.width: 1
                            border.color: actionArea.containsMouse ? root.accent : "#3a3a3a"

                            Text {
                                id: label
                                anchors.centerIn: parent
                                text: parent.modelData.text
                                color: "#ffffff"
                                font.pixelSize: 12
                            }
                            MouseArea {
                                id: actionArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: parent.modelData.invoke()
                            }
                        }
                    }
                }
            }
        }
    }

    Item {
        id: countdown
        anchors.centerIn: parent
        width: 120; height: 120
        visible: root.holding
        z: 10

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "#e6000000"
        }
        Shape {
            anchors.fill: parent
            layer.enabled: true
            layer.samples: 4
            ShapePath {
                strokeWidth: 6
                strokeColor: "#ff453a"
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: 60; centerY: 60
                    radiusX: 54; radiusY: 54
                    startAngle: -90
                    sweepAngle: 360 * (1 - root.holdProgress)
                }
            }
        }
        Text {
            anchors.centerIn: parent
            text: Math.max(1, Math.ceil(3 * (1 - root.holdProgress)))
            color: "#ff453a"
            font.pixelSize: 56
            font.bold: true
        }
    }
}
