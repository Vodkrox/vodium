import QtQuick

Item {
    id: root
    property string glyph: ""
    property string family: "RobotoMono Nerd Font Mono"
    property int size: 16
    property color color: "#ffffff"
    property bool inkCentered: false
    signal clicked()
    signal scrolled(int dy)

    width: 32
    height: 36

    TextMetrics {
        id: metrics
        text: root.glyph
        font: label.font
    }

    Text {
        id: label
        anchors.verticalCenter: parent.verticalCenter
        x: root.inkCentered ? root.width / 2 + 1.4 - (metrics.tightBoundingRect.x + metrics.tightBoundingRect.width / 2)
                            : (root.width - width) / 2 + 1
        text: root.glyph
        color: root.color
        font.family: root.family
        font.pixelSize: root.size
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
        onWheel: wheel => root.scrolled(wheel.angleDelta.y)
    }
}
