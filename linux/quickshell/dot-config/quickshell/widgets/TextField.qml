import QtQuick
import qs

Rectangle {
    id: root

    property alias text: input.text
    property alias echoMode: input.echoMode
    property string placeholder: ""

    signal accepted(string text)

    implicitHeight: input.implicitHeight + Theme.padding
    radius: Theme.radius / 2
    color: Theme.surface
    border.width: 1
    border.color: input.activeFocus ? Theme.foam : Theme.overlay

    function reset() {
        input.text = "";
    }

    TextInput {
        id: input
        anchors.fill: parent
        anchors.leftMargin: Theme.padding / 2
        anchors.rightMargin: Theme.padding / 2
        verticalAlignment: TextInput.AlignVCenter
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSmall
        selectByMouse: true
        selectionColor: Theme.overlay
        selectedTextColor: Theme.text
        clip: true

        onAccepted: root.accepted(text)
    }

    Text {
        anchors.fill: input
        anchors.leftMargin: input.anchors.leftMargin
        verticalAlignment: Text.AlignVCenter
        visible: input.text === "" && !input.activeFocus
        text: root.placeholder
        color: Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSmall
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onClicked: input.forceActiveFocus()
        cursorShape: Qt.IBeamCursor
        z: -1
    }
}
