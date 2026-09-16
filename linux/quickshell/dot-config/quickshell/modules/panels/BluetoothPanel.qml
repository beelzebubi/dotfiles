import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import qs
import qs.widgets

// Replaces `ghostty --class=local.bluetui -e bluetui` on the waybar
// bluetooth module.
PopupPanel {
    id: panel

    panelId: "bluetooth"
    title: "Bluetooth"

    readonly property var adapter: Bluetooth.defaultAdapter

    // Paired first, then whatever the scan turned up, strongest state first.
    readonly property var devices: {
        if (!adapter) return [];
        return [...adapter.devices.values].sort((a, b) => {
            if (a.connected !== b.connected) return b.connected - a.connected;
            if (a.paired !== b.paired) return b.paired - a.paired;
            return (a.deviceName || "").localeCompare(b.deviceName || "");
        });
    }

    // Scanning is expensive, so only while the panel is actually open.
    onVisibleChanged: {
        if (panel.adapter && panel.adapter.enabled) panel.adapter.discovering = panel.visible;
    }

    Text {
        visible: !panel.adapter
        Layout.fillWidth: true
        text: "Kein Bluetooth-Adapter gefunden"
        color: Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        wrapMode: Text.WordWrap
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.spacing
        visible: !!panel.adapter

        Text {
            text: panel.adapter ? panel.adapter.name : ""
            color: Theme.subtle
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            Layout.fillWidth: true
            elide: Text.ElideRight
        }

        Text {
            visible: !!panel.adapter && panel.adapter.discovering
            text: "sucht …"
            color: Theme.gold
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
        }

        TextButton {
            label: panel.adapter && panel.adapter.enabled ? "An" : "Aus"
            accent: !!panel.adapter && panel.adapter.enabled
            onClicked: panel.adapter.enabled = !panel.adapter.enabled
        }
    }

    Text {
        visible: !!panel.adapter && panel.adapter.enabled && panel.devices.length === 0
        Layout.fillWidth: true
        text: "Keine Geräte"
        color: Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        horizontalAlignment: Text.AlignHCenter
    }

    Repeater {
        model: ScriptModel {
            values: panel.adapter && panel.adapter.enabled ? panel.devices : []
        }

        Rectangle {
            id: deviceRow
            required property var modelData

            Layout.fillWidth: true
            implicitHeight: content.implicitHeight + Theme.padding
            radius: Theme.radius / 2
            color: deviceMouse.containsMouse ? Theme.surface : "transparent"

            ColumnLayout {
                id: content
                anchors.fill: parent
                anchors.margins: Theme.padding / 2
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacing

                    Text {
                        text: deviceRow.modelData.connected ? "󰂱" : (deviceRow.modelData.paired ? "󰂯" : "󰂲")
                        color: deviceRow.modelData.connected ? Theme.foam : Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }

                    Text {
                        text: deviceRow.modelData.deviceName || deviceRow.modelData.address
                        color: deviceRow.modelData.connected ? Theme.text : Theme.subtle
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Text {
                        visible: deviceRow.modelData.batteryAvailable
                        text: Math.round(deviceRow.modelData.battery * 100) + "%"
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    visible: deviceMouse.containsMouse || deviceRow.modelData.connected || deviceRow.modelData.pairing

                    Text {
                        visible: deviceRow.modelData.pairing
                        text: "koppelt …"
                        color: Theme.gold
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                        Layout.fillWidth: true
                    }

                    Item {
                        Layout.fillWidth: true
                        visible: !deviceRow.modelData.pairing
                    }

                    TextButton {
                        label: deviceRow.modelData.connected ? "Trennen" : "Verbinden"
                        accent: !deviceRow.modelData.connected
                        onClicked: {
                            if (deviceRow.modelData.connected) deviceRow.modelData.disconnect();
                            else if (deviceRow.modelData.paired) deviceRow.modelData.connect();
                            else deviceRow.modelData.pair();
                        }
                    }

                    TextButton {
                        label: "Vergessen"
                        danger: true
                        visible: deviceRow.modelData.paired || deviceRow.modelData.bonded
                        onClicked: deviceRow.modelData.forget()
                    }
                }
            }

            MouseArea {
                id: deviceMouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
            }
        }
    }
}
