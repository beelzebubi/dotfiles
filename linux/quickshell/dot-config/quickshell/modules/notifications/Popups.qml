import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs
import qs.services

// Transient popups, top right — the position mako.ini used.
PanelWindow {
    id: win

    visible: Notifs.popups.length > 0
    color: "transparent"

    anchors {
        top: true
        right: true
    }

    margins {
        top: Theme.screenMargin
        right: Theme.screenMargin
    }

    implicitWidth: Theme.popupWidth
    implicitHeight: Math.max(1, stack.implicitHeight)

    // Respect waybar's exclusive zone so popups land below the bar instead of
    // on top of it, but reserve no space of our own.
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-notifications"
    // Popups must never steal focus from the focused window.
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // Without a mask the whole anchored area swallows clicks, killing the right
    // hand side of the screen even when nothing is drawn there.
    mask: Region {
        item: stack
    }

    ColumnLayout {
        id: stack
        width: parent.width
        spacing: Theme.spacing

        Repeater {
            model: ScriptModel {
                values: Notifs.popups
            }

            NotifCard {
                required property var modelData
                notif: modelData
                expires: true
                Layout.fillWidth: true
                onDismissed: Notifs.dismissPopup(modelData)
            }
        }
    }
}
