import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs
import qs.services
import qs.widgets

// Notification history. Opened with `qs ipc call notifs toggleCenter`.
PanelWindow {
    id: win

    visible: Notifs.centerOpen
    color: "transparent"

    anchors {
        top: true
        right: true
        bottom: true
    }

    margins {
        top: Theme.screenMargin
        right: Theme.screenMargin
        bottom: Theme.screenMargin
    }

    implicitWidth: Theme.popupWidth

    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-notification-center"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    Rectangle {
        id: frame
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.base
        border.width: Theme.borderSize
        border.color: Theme.overlay

        focus: true
        Keys.onEscapePressed: Notifs.openCenter(false)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.padding
            spacing: Theme.spacing

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacing

                Text {
                    text: "Notifications"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.bold: true
                    Layout.fillWidth: true
                }

                TextButton {
                    label: Notifs.dnd ? "DND an" : "DND aus"
                    accent: Notifs.dnd
                    onClicked: Notifs.dnd = !Notifs.dnd
                }

                TextButton {
                    label: "Leeren"
                    danger: true
                    visible: Notifs.entries.length > 0
                    onClicked: Notifs.clear()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Theme.overlay
            }

            Text {
                visible: Notifs.entries.length === 0
                Layout.fillWidth: true
                Layout.topMargin: Theme.padding
                text: "Keine Benachrichtigungen"
                color: Theme.muted
                horizontalAlignment: Text.AlignHCenter
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
            }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: Theme.spacing
                visible: Notifs.entries.length > 0

                model: ScriptModel {
                    values: Notifs.entries
                }

                delegate: NotifCard {
                    required property var modelData
                    width: ListView.view.width
                    entry: modelData
                    notif: modelData.notif
                    expires: false
                    // Restored entries have no live object left to act on.
                    opacity: modelData.notif ? 1 : 0.7
                    onDismissed: {
                        if (modelData.notif) modelData.notif.dismiss();
                    }
                }
            }
        }
    }
}
