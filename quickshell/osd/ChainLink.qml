import QtQuick

Image {
    id: root
    property bool edge: false
    property real length: 34
    property real thickness: 18

    width: length
    height: thickness
    source: edge ? "assets/chain-edge.png" : "assets/chain-ring.png"
    sourceSize: Qt.size(136, 72)
    smooth: true
    mipmap: true
    asynchronous: false
    cache: true
}
