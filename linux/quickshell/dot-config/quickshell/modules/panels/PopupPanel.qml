import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs
import qs.services

// Shared shell for the quick settings panels. Anchored top right, below
// waybar's exclusive zone, roughly under the bar item that opens it.
PanelWindow {
    id: win

    property string panelId: ""
    property string title: ""
    default property alias content: body.data

    visible: Panels.current === panelId
    color: "transparent"

    anchors {
        top: true
        right: true
    }

    margins {
        top: Theme.screenMargin
        right: Theme.screenMargin
    }

    implicitWidth: Theme.panelWidth
    implicitHeight: frame.implicitHeight

    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-panel"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    Rectangle {
        id: frame
        width: parent.width
        implicitHeight: layout.implicitHeight + 2 * Theme.padding
        radius: Theme.radius
        color: Theme.base
        border.width: Theme.borderSize
        border.color: Theme.overlay

        focus: true
        Keys.onEscapePressed: Panels.close()

        ColumnLayout {
            id: layout
            anchors.fill: parent
            anchors.margins: Theme.padding
            spacing: Theme.spacing

            Text {
                text: win.title
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.bold: true
                Layout.fillWidth: true
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Theme.overlay
            }

            ColumnLayout {
                id: body
                Layout.fillWidth: true
                spacing: Theme.spacing
            }
        }
    }
}
