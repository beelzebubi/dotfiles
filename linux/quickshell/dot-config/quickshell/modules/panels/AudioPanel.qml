import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs
import qs.widgets

// Replaces `ghostty --class=local.wiremix -e wiremix` on the waybar
// pulseaudio module.
PopupPanel {
    id: panel

    panelId: "audio"
    title: "Audio"

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream)
    readonly property var streams: Pipewire.nodes.values.filter(n => n.isStream && n.audio)

    function labelFor(node) {
        if (!node) return "";
        return node.description || node.nickname || node.name;
    }

    // PwNode volume/mute state is only populated while the node is bound.
    PwObjectTracker {
        objects: {
            const list = panel.sinks.concat(panel.streams);
            if (panel.sink) list.push(panel.sink);
            if (panel.source) list.push(panel.source);
            return list;
        }
    }

    // --- default sink -----------------------------------------------------

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: panel.labelFor(panel.sink) || "Kein Ausgabegerät"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            Text {
                visible: !!panel.sink
                text: panel.sink && panel.sink.audio ? Math.round(panel.sink.audio.volume * 100) + "%" : ""
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing
            visible: !!panel.sink && !!panel.sink.audio

            TextButton {
                label: panel.sink && panel.sink.audio && panel.sink.audio.muted ? "󰝟" : "󰕾"
                onClicked: panel.sink.audio.muted = !panel.sink.audio.muted
            }

            VolumeSlider {
                Layout.fillWidth: true
                value: panel.sink && panel.sink.audio ? panel.sink.audio.volume : 0
                muted: panel.sink && panel.sink.audio ? panel.sink.audio.muted : false
                onMoved: v => panel.sink.audio.volume = v
            }
        }
    }

    // --- default source ---------------------------------------------------

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4
        visible: !!panel.source && !!panel.source.audio

        Text {
            text: panel.labelFor(panel.source)
            color: Theme.subtle
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            Layout.fillWidth: true
            elide: Text.ElideRight
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing

            TextButton {
                label: panel.source && panel.source.audio && panel.source.audio.muted ? "󰍭" : "󰍬"
                onClicked: panel.source.audio.muted = !panel.source.audio.muted
            }

            VolumeSlider {
                Layout.fillWidth: true
                fillColor: Theme.iris
                value: panel.source && panel.source.audio ? panel.source.audio.volume : 0
                muted: panel.source && panel.source.audio ? panel.source.audio.muted : false
                onMoved: v => panel.source.audio.volume = v
            }
        }
    }

    // --- output selection -------------------------------------------------

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 1
        color: Theme.overlay
        visible: panel.sinks.length > 1
    }

    Repeater {
        model: ScriptModel {
            values: panel.sinks.length > 1 ? panel.sinks : []
        }

        Rectangle {
            required property var modelData

            Layout.fillWidth: true
            implicitHeight: row.implicitHeight + Theme.padding
            radius: Theme.radius / 2
            color: sinkMouse.containsMouse ? Theme.surface : "transparent"

            RowLayout {
                id: row
                anchors.fill: parent
                anchors.margins: Theme.padding / 2
                spacing: Theme.spacing

                Text {
                    text: modelData === panel.sink ? "󰄬" : " "
                    color: Theme.foam
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }

                Text {
                    text: panel.labelFor(modelData)
                    color: modelData === panel.sink ? Theme.text : Theme.subtle
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }

            MouseArea {
                id: sinkMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Pipewire.preferredDefaultAudioSink = modelData
            }
        }
    }

    // --- per application streams ------------------------------------------

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 1
        color: Theme.overlay
        visible: panel.streams.length > 0
    }

    Repeater {
        model: ScriptModel {
            values: panel.streams
        }

        ColumnLayout {
            required property var modelData

            Layout.fillWidth: true
            spacing: 2

            Text {
                text: panel.labelFor(modelData)
                color: Theme.subtle
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            VolumeSlider {
                Layout.fillWidth: true
                fillColor: Theme.pine
                value: modelData.audio ? modelData.audio.volume : 0
                muted: modelData.audio ? modelData.audio.muted : false
                onMoved: v => modelData.audio.volume = v
            }
        }
    }
}
