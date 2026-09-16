import QtQuick
import qs

Rectangle {
    id: root

    property string label: ""
    property bool accent: false
    property bool danger: false

    signal clicked

    implicitWidth: text.implicitWidth + 2 * Theme.padding
    implicitHeight: text.implicitHeight + Theme.padding
    radius: Theme.radius / 2
    color: mouse.containsMouse ? Theme.overlay : Theme.surface
    border.width: 1
    border.color: root.danger ? Theme.love : (root.accent ? Theme.foam : Theme.overlay)

    Text {
        id: text
        anchors.centerIn: parent
        text: root.label
        color: root.danger ? Theme.love : (root.accent ? Theme.foam : Theme.text)
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSmall
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
