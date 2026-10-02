import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

Item {
    id: root
    property color accent: "#ffffff"
    property bool active: false

    implicitHeight: col.implicitHeight

    PwObjectTracker { objects: Pipewire.nodes.values }

    ScriptModel {
        id: sinks
        values: Pipewire.nodes.values.filter(n => n.audio && !n.isStream && n.isSink)
    }
    ScriptModel {
        id: sources
        values: Pipewire.nodes.values.filter(n => n.audio && !n.isStream && !n.isSink)
    }

    function label(node) {
        return node.description || node.nickname || node.name;
    }

    Column {
        id: col
        width: parent.width
        spacing: 8

        Text { text: "Salida"; color: "#ffffff"; font.pixelSize: 16; font.bold: true }

        Row {
            width: parent.width
            spacing: 12
            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: 24
                text: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio.muted ? "󰖁" : "󰕾"
                color: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio.muted ? "#8a8a8a" : "#ffffff"
                font.family: "RobotoMono Nerd Font Propo"
                font.pixelSize: 20
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Pipewire.defaultAudioSink.audio.muted = !Pipewire.defaultAudioSink.audio.muted
                }
            }
            Slider {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 24 - 44 - parent.spacing * 2
                accent: root.accent
                maxValue: 1.0
                value: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio.volume : 0
                muted: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio.muted : false
                onMoved: v => { Pipewire.defaultAudioSink.audio.volume = v; }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: 44
                horizontalAlignment: Text.AlignRight
                text: Math.round((Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio.volume : 0) * 100) + "%"
                color: "#ffffff"
                font.pixelSize: 14
            }
        }

        Repeater {
            model: sinks
            MenuRow {
                required property var modelData
                width: col.width
                accent: root.accent
                text: root.label(modelData)
                icon: "󰓃"
                highlighted: Pipewire.defaultAudioSink === modelData
                trailing: highlighted ? "󰄬" : ""
                onClicked: Pipewire.preferredDefaultAudioSink = modelData
            }
        }

        Rectangle { width: parent.width; height: 1; color: "#2a2a2a" }

        Text { text: "Entrada"; color: "#ffffff"; font.pixelSize: 16; font.bold: true }

        Row {
            width: parent.width
            spacing: 12
            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: 24
                text: Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio.muted ? "󰍭" : "󰍬"
                color: Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio.muted ? "#8a8a8a" : "#ffffff"
                font.family: "RobotoMono Nerd Font Propo"
                font.pixelSize: 20
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Pipewire.defaultAudioSource.audio.muted = !Pipewire.defaultAudioSource.audio.muted
                }
            }
            Slider {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 24 - 44 - parent.spacing * 2
                accent: root.accent
                maxValue: 1.0
                value: Pipewire.defaultAudioSource ? Pipewire.defaultAudioSource.audio.volume : 0
                muted: Pipewire.defaultAudioSource ? Pipewire.defaultAudioSource.audio.muted : false
                onMoved: v => { Pipewire.defaultAudioSource.audio.volume = v; }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: 44
                horizontalAlignment: Text.AlignRight
                text: Math.round((Pipewire.defaultAudioSource ? Pipewire.defaultAudioSource.audio.volume : 0) * 100) + "%"
                color: "#ffffff"
                font.pixelSize: 14
            }
        }

        Repeater {
            model: sources
            MenuRow {
                required property var modelData
                width: col.width
                accent: root.accent
                text: root.label(modelData)
                icon: "󰍬"
                highlighted: Pipewire.defaultAudioSource === modelData
                trailing: highlighted ? "󰄬" : ""
                onClicked: Pipewire.preferredDefaultAudioSource = modelData
            }
        }
    }
}
