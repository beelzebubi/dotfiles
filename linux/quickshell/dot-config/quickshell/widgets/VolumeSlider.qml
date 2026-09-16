import QtQuick
import qs

Item {
    id: root

    property real value: 0
    property bool muted: false
    property color fillColor: Theme.foam

    signal moved(real value)

    implicitHeight: 16

    function clamp(v) {
        return Math.max(0, Math.min(1, v));
    }

    function emitFromX(x) {
        root.moved(root.clamp(root.width > 0 ? x / root.width : 0));
    }

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 6
        radius: 3
        color: Theme.overlay

        Rectangle {
            width: root.clamp(root.value) * track.width
            height: track.height
            radius: track.radius
            color: root.muted ? Theme.muted : root.fillColor
        }
    }

    Rectangle {
        width: 14
        height: 14
        radius: 7
        anchors.verticalCenter: parent.verticalCenter
        x: root.clamp(root.value) * (root.width - width)
        color: root.muted ? Theme.muted : Theme.text
    }

    MouseArea {
        anchors.fill: parent
        onPressed: mouse => root.emitFromX(mouse.x)
        onPositionChanged: mouse => {
            if (pressed) root.emitFromX(mouse.x);
        }
    }
}
