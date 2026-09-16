import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import qs
import qs.services
import qs.widgets

Rectangle {
    id: card

    // The live Notification, or null for an entry restored from disk.
    property var notif: null
    property var entry: null
    // Popups expire on a timer; cards in the center stay until dismissed.
    property bool expires: false

    readonly property string appName: entry ? entry.appName : (notif ? notif.appName : "")
    readonly property string summary: entry ? entry.summary : (notif ? notif.summary : "")
    readonly property string body: entry ? entry.body : (notif ? notif.body : "")
    readonly property string appIcon: entry ? entry.appIcon : (notif ? notif.appIcon : "")
    readonly property string image: entry ? entry.image : (notif ? notif.image : "")
    readonly property int urgency: entry ? entry.urgency : (notif ? notif.urgency : NotificationUrgency.Normal)

    readonly property bool critical: urgency === NotificationUrgency.Critical

    signal dismissed

    implicitHeight: layout.implicitHeight + 2 * Theme.padding
    radius: Theme.notifRadius
    color: Theme.base
    border.width: Theme.borderSize
    border.color: critical ? Theme.love : (urgency === NotificationUrgency.Low ? Theme.overlay : Theme.rose)

    // There is no auto-expiry in quickshell: every popup needs its own timer.
    Timer {
        running: card.expires && !card.critical
        interval: {
            if (!card.notif) return Theme.defaultTimeout;
            // expireTimeout is in seconds and -1 means "server decides".
            const t = card.notif.expireTimeout;
            return t > 0 ? t * 1000 : Theme.defaultTimeout;
        }
        onTriggered: card.dismissed()
    }

    RowLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: Theme.padding
        spacing: Theme.padding

        // notif.image is usually an image:// url built from raw pixel hints,
        // while appIcon is a theme icon name.
        Image {
            visible: source != ""
            source: {
                if (card.image) return card.image;
                if (card.appIcon) return Quickshell.iconPath(card.appIcon, true);
                return "";
            }
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            fillMode: Image.PreserveAspectFit
            sourceSize.width: 32
            sourceSize.height: 32
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                visible: text !== ""
                text: card.appName
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            Text {
                visible: text !== ""
                text: card.summary
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.bold: true
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }

            Text {
                visible: text !== ""
                text: card.body
                color: Theme.subtle
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                textFormat: Text.StyledText
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                maximumLineCount: 6
                elide: Text.ElideRight
                onLinkActivated: link => Qt.openUrlExternally(link)
            }

            // Actions only exist while the sending app is still around.
            RowLayout {
                visible: repeater.count > 0
                Layout.topMargin: 4
                spacing: 6

                Repeater {
                    id: repeater
                    model: card.notif ? card.notif.actions : []

                    TextButton {
                        required property var modelData
                        label: modelData.text
                        accent: true
                        onClicked: {
                            modelData.invoke();
                            card.dismissed();
                        }
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton && card.notif) card.notif.dismiss();
            card.dismissed();
        }
    }
}
