import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import qs
import qs.widgets

// Replaces `ghostty --class=local.floating -e impala` on the waybar network
// module. Quickshell.Networking only speaks NetworkManager, which is why the
// wifi stack moved from bare iwd to NetworkManager (with iwd kept as its
// backend, see install/linux/networkmanager/).
PopupPanel {
    id: panel

    panelId: "network"
    title: "Netzwerk"

    readonly property bool hasBackend: Networking.backend === NetworkBackendType.NetworkManager

    readonly property var wifiDevice: {
        if (!hasBackend) return null;
        const wifi = Networking.devices.values.filter(d => d.type === DeviceType.Wifi);
        return wifi.length > 0 ? wifi[0] : null;
    }

    readonly property var networks: {
        if (!wifiDevice) return [];
        return [...wifiDevice.networks.values].sort((a, b) => {
            if (a.connected !== b.connected) return b.connected - a.connected;
            if (a.known !== b.known) return b.known - a.known;
            return b.signalStrength - a.signalStrength;
        });
    }

    function needsPsk(security) {
        return security === WifiSecurityType.WpaPsk
            || security === WifiSecurityType.Wpa2Psk
            || security === WifiSecurityType.Sae;
    }

    function signalIcon(strength) {
        if (strength >= 0.8) return "󰤨";
        if (strength >= 0.6) return "󰤥";
        if (strength >= 0.4) return "󰤢";
        if (strength >= 0.2) return "󰤟";
        return "󰤯";
    }

    // Scanning costs power, so only run it while the panel is open.
    onVisibleChanged: {
        if (panel.wifiDevice) panel.wifiDevice.scannerEnabled = panel.visible;
    }

    // --- backend missing --------------------------------------------------

    Text {
        visible: !panel.hasBackend
        Layout.fillWidth: true
        text: "NetworkManager läuft nicht.\nsystemctl enable --now NetworkManager"
        color: Theme.love
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSmall
        wrapMode: Text.WordWrap
    }

    // --- radio toggle -----------------------------------------------------

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.spacing
        visible: panel.hasBackend

        Text {
            text: panel.wifiDevice ? panel.wifiDevice.name : "Kein WLAN-Gerät"
            color: Theme.subtle
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            Layout.fillWidth: true
            elide: Text.ElideRight
        }

        Text {
            visible: !Networking.wifiHardwareEnabled
            text: "HW-Sperre"
            color: Theme.love
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
        }

        TextButton {
            label: Networking.wifiEnabled ? "An" : "Aus"
            accent: Networking.wifiEnabled
            onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
        }
    }

    Text {
        visible: panel.hasBackend && Networking.wifiEnabled && panel.networks.length === 0
        Layout.fillWidth: true
        text: "Suche …"
        color: Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        horizontalAlignment: Text.AlignHCenter
    }

    // --- network list -----------------------------------------------------

    Repeater {
        model: ScriptModel {
            values: panel.hasBackend && Networking.wifiEnabled ? panel.networks : []
        }

        Rectangle {
            id: netRow
            required property var modelData

            // Set when the connection fails, so the psk field only appears
            // once NetworkManager has actually asked for a secret.
            property bool askPsk: false
            property int failReason: -1

            Layout.fillWidth: true
            implicitHeight: content.implicitHeight + Theme.padding
            radius: Theme.radius / 2
            color: netMouse.containsMouse || netRow.askPsk ? Theme.surface : "transparent"

            Connections {
                target: netRow.modelData

                function onConnectionFailed(reason) {
                    netRow.failReason = reason;
                    netRow.askPsk = panel.needsPsk(netRow.modelData.security);
                }

                function onStateChanged() {
                    if (netRow.modelData.state === ConnectionState.Connecting) {
                        netRow.failReason = -1;
                    }
                    if (netRow.modelData.connected) {
                        netRow.askPsk = false;
                        pskField.reset();
                    }
                }
            }

            ColumnLayout {
                id: content
                anchors.fill: parent
                anchors.margins: Theme.padding / 2
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacing

                    Text {
                        text: panel.signalIcon(netRow.modelData.signalStrength)
                        color: netRow.modelData.connected ? Theme.foam : Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }

                    Text {
                        text: netRow.modelData.name
                        color: netRow.modelData.connected ? Theme.text : Theme.subtle
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Text {
                        visible: netRow.modelData.security !== WifiSecurityType.Open
                        text: "󰌾"
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                    }

                    Text {
                        visible: netRow.modelData.stateChanging
                        text: "…"
                        color: Theme.gold
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }
                }

                Text {
                    visible: netRow.failReason >= 0
                    Layout.fillWidth: true
                    text: ConnectionFailReason.toString(netRow.failReason)
                    color: Theme.love
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    visible: netRow.askPsk

                    TextField {
                        id: pskField
                        Layout.fillWidth: true
                        placeholder: "Passwort"
                        echoMode: TextInput.Password
                        onAccepted: text => netRow.modelData.connectWithPsk(text)
                    }

                    TextButton {
                        label: "OK"
                        accent: true
                        onClicked: netRow.modelData.connectWithPsk(pskField.text)
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    visible: netMouse.containsMouse || netRow.modelData.connected

                    Item {
                        Layout.fillWidth: true
                    }

                    TextButton {
                        label: netRow.modelData.connected ? "Trennen" : "Verbinden"
                        accent: !netRow.modelData.connected
                        onClicked: {
                            if (netRow.modelData.connected) {
                                netRow.modelData.disconnect();
                            } else if (!netRow.modelData.known && panel.needsPsk(netRow.modelData.security)) {
                                // Unknown protected network: ask straight away
                                // rather than waiting for the failure.
                                netRow.askPsk = true;
                            } else {
                                netRow.modelData.connect();
                            }
                        }
                    }

                    TextButton {
                        label: "Vergessen"
                        danger: true
                        visible: netRow.modelData.known
                        onClicked: netRow.modelData.forget()
                    }
                }
            }

            MouseArea {
                id: netMouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
            }
        }
    }
}
