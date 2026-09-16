pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

// Owns org.freedesktop.Notifications in place of mako, plus the history the
// notification center reads. Exposed over IPC as `qs ipc call notifs ...`.
Singleton {
    id: root

    // Live notifications currently drawn as popups, oldest first.
    property var popups: []

    // Newest first. Entries restored from disk have `notif: null` — their
    // actions are gone with the process that sent them, but the text remains.
    property var entries: []

    property bool dnd: false
    property bool centerOpen: false
    property int unread: 0

    readonly property int maxHistory: 100

    function record(notif) {
        const entry = {
            id: notif.id,
            appName: notif.appName,
            summary: notif.summary,
            body: notif.body,
            appIcon: notif.appIcon,
            image: notif.image,
            urgency: notif.urgency,
            time: Date.now(),
            notif: notif
        };

        root.entries = [entry, ...root.entries].slice(0, root.maxHistory);
        if (!root.centerOpen) root.unread += 1;
        root.persist();
    }

    // The Notification object dies right after its closed() handlers return, so
    // drop every reference to it but keep the recorded text.
    function forget(notif) {
        root.popups = root.popups.filter(n => n !== notif);
        root.entries = root.entries.map(e => {
            if (e.notif !== notif) return e;
            return {
                id: e.id,
                appName: e.appName,
                summary: e.summary,
                body: e.body,
                appIcon: e.appIcon,
                image: e.image,
                urgency: e.urgency,
                time: e.time,
                notif: null
            };
        });
    }

    function dismissPopup(notif) {
        root.popups = root.popups.filter(n => n !== notif);
    }

    function clear() {
        // dismiss() destroys the object, which re-enters forget() — copy first.
        const live = root.entries.filter(e => e.notif).map(e => e.notif);
        root.popups = [];
        root.entries = [];
        root.unread = 0;
        for (const notif of live) notif.dismiss();
        root.persist();
    }

    function openCenter(open) {
        root.centerOpen = open;
        if (open) root.unread = 0;
    }

    function persist() {
        const plain = root.entries.map(e => ({
            id: e.id,
            appName: e.appName,
            summary: e.summary,
            body: e.body,
            appIcon: e.appIcon,
            image: e.image,
            urgency: e.urgency,
            time: e.time
        }));

        historyFile.setText(JSON.stringify(plain));
    }

    NotificationServer {
        keepOnReload: true
        actionsSupported: true
        actionIconsSupported: true
        imageSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        // Only honest because the center below actually exists.
        persistenceSupported: true

        onNotification: notif => {
            // Without this quickshell discards the notification immediately.
            notif.tracked = true;
            notif.closed.connect(() => root.forget(notif));

            root.record(notif);
            if (!root.dnd) root.popups = [...root.popups, notif];
        }
    }

    // keepOnReload covers hot reload only; this survives a restart.
    FileView {
        id: historyFile
        path: Quickshell.statePath("notifications.json")
        blockLoading: true
        atomicWrites: true
        printErrors: false
    }

    Component.onCompleted: {
        try {
            const raw = historyFile.text();
            if (!raw) return;

            root.entries = JSON.parse(raw).map(e => ({
                id: e.id,
                appName: e.appName,
                summary: e.summary,
                body: e.body,
                appIcon: e.appIcon,
                image: e.image,
                urgency: e.urgency,
                time: e.time,
                notif: null
            }));
        } catch (err) {
            // No state file yet, or it was truncated. Start clean.
            root.entries = [];
        }
    }

    IpcHandler {
        target: "notifs"

        function toggleCenter(): void {
            root.openCenter(!root.centerOpen);
        }

        function toggleDnd(): void {
            root.dnd = !root.dnd;
        }

        function clear(): void {
            root.clear();
        }

        function dismissPopups(): void {
            root.popups = [];
        }
    }
}
