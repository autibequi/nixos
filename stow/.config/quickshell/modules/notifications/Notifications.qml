// Notifications — viewer Quickshell (DESATIVADO em shell.qml).
//
// swaync continua como daemon (popups, DND, histórico no control center).
// Este módulo NÃO registra NotificationServer — conflita com swaync no D-Bus.
//
// swaync ainda não expõe API para listar notificações (sem --list-notifications).
// Para um viewer custom (Walker/QS) no futuro, seria preciso um sidecar que
// grave notificações em JSON enquanto o swaync roda.
//
// Waybar / keybind: swaync-client -t -sw

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Notifications

Scope {
    id: root

    property bool centerShown: false
    property bool dnd: false

    readonly property int defaultTimeoutMs: 5000
    readonly property int maxPopups: 5

    property var activePopups: []
    // { notif, read: bool, ts: number }
    property var history: []

    readonly property int unreadCount: {
        let n = 0;
        for (let i = 0; i < root.history.length; i++) {
            if (!root.history[i].read) {
                n++;
            }
        }
        return n;
    }

    IpcHandler {
        target: "notifications"
        function toggle(): void { root.centerShown = !root.centerShown }
        function open(): void   { root.centerShown = true }
        function close(): void  { root.centerShown = false }
        function toggleDnd(): void { root.setDnd(!root.dnd) }
        function setDnd(enabled: bool): void { root.setDnd(enabled) }
        function markAllRead(): void { root.markAllRead() }
    }

    NotificationServer {
        id: server

        keepOnReload:           true
        actionsSupported:       true
        actionIconsSupported:   true
        bodyMarkupSupported:    true
        bodyImagesSupported:    true
        imageSupported:         true
        persistenceSupported:   true

        onNotification: function(notif) {
            notif.tracked = true;
            root.addNotification(notif);
        }
    }

    Component {
        id: dismissTimerComponent
        Timer {
            repeat: false
            running: false
        }
    }

    Process {
        id: waybarWriter
        running: false
        command: ["sh", "-c", "true"]
    }

    onHistoryChanged: root.updateWaybarState()
    onDndChanged: root.updateWaybarState()
    onCenterShownChanged: {
        if (root.centerShown) {
            root.updateWaybarState();
        }
    }

    Component.onCompleted: root.updateWaybarState()

    function setDnd(enabled) {
        root.dnd = !!enabled;
        root.updateWaybarState();
    }

    function markAllRead() {
        if (root.history.length === 0) {
            return;
        }
        const copy = [];
        for (let i = 0; i < root.history.length; i++) {
            const e = root.history[i];
            copy.push({ notif: e.notif, read: true, ts: e.ts });
        }
        root.history = copy;
    }

    function markNotifRead(notif) {
        for (let i = 0; i < root.history.length; i++) {
            if (root.history[i].notif === notif) {
                if (root.history[i].read) {
                    return;
                }
                const copy = root.history.slice();
                copy[i] = { notif: notif, read: true, ts: copy[i].ts };
                root.history = copy;
                return;
            }
        }
    }

    function removeEntry(entry) {
        root.history = root.history.filter(function(e) {
            return e !== entry;
        });
        try { entry.notif.dismiss(); } catch(e) {}
    }

    function updateWaybarState() {
        const unread = root.unreadCount;
        let cls = "none";
        if (root.dnd) {
            cls = unread > 0 ? "dnd-notification" : "dnd-none";
        } else if (unread > 0) {
            cls = "notification";
        }
        const payload = JSON.stringify({
            text: unread > 0 ? String(unread) : "",
            class: cls,
            icon: cls
        });
        const cmd = "mkdir -p \"${XDG_CACHE_HOME:-$HOME/.cache}/quickshell\" && printf '%s' '"
            + payload.replace(/'/g, "'\\''")
            + "' > \"${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/notif-waybar.json\""
            + " && pkill -RTMIN+11 waybar 2>/dev/null || true";
        waybarWriter.command = ["sh", "-c", cmd];
        waybarWriter.running = true;
    }

    function addNotification(notif) {
        const entry = { notif: notif, read: false, ts: Date.now() };
        root.history = [entry].concat(root.history.slice(0, 199));

        if (root.dnd) {
            return;
        }

        if (root.activePopups.length >= root.maxPopups) {
            root.dismissOldest();
        }

        const popupEntry = { notif: notif };
        root.activePopups = root.activePopups.concat([popupEntry]);

        let timeoutMs = root.defaultTimeoutMs;
        if (notif.expireTimeout > 0) {
            timeoutMs = notif.expireTimeout;
        }

        const timer = dismissTimerComponent.createObject(root, { interval: timeoutMs });
        timer.running = true;
        timer.triggered.connect(function() {
            root.dismissNotif(notif);
            timer.destroy();
        });
    }

    function dismissNotif(notif) {
        root.activePopups = root.activePopups.filter(function(e) {
            return e.notif !== notif;
        });
        root.markNotifRead(notif);
        try { notif.dismiss(); } catch(e) {}
    }

    function dismissOldest() {
        if (root.activePopups.length === 0) {
            return;
        }
        root.dismissNotif(root.activePopups[0].notif);
    }

    function clearAll() {
        const copy = root.activePopups.slice();
        for (let i = 0; i < copy.length; i++) {
            try { copy[i].notif.dismiss(); } catch(e) {}
        }
        root.activePopups = [];
    }

    PanelWindow {
        id: popupWindow
        visible: root.activePopups.length > 0 && !root.dnd

        anchors { top: true; right: true }
        exclusiveZone: 0
        color: "transparent"
        implicitWidth: 380
        implicitHeight: popupColumn.implicitHeight + 20
        WlrLayershell.layer: WlrLayer.Overlay

        Item {
            anchors.fill: parent
            anchors.margins: 10

            Column {
                id: popupColumn
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: 8

                Repeater {
                    model: root.activePopups

                    delegate: Item {
                        id: popupWrapper
                        required property var modelData
                        required property int index

                        width: popupCard.width
                        height: popupCard.height

                        transform: Translate { id: slideIn; x: 40 }

                        NumberAnimation on opacity {
                            from: 0
                            to: 1
                            duration: 220
                            easing.type: Easing.OutCubic
                            running: true
                        }

                        NumberAnimation {
                            target: slideIn
                            property: "x"
                            from: 40
                            to: 0
                            duration: 220
                            easing.type: Easing.OutCubic
                            running: true
                        }

                        NotificationCard {
                            id: popupCard
                            notif: popupWrapper.modelData.notif
                            compact: true
                            read: false
                            showActions: (popupWrapper.modelData.notif.actions || []).length <= 2
                            onDismissed: root.dismissNotif(popupWrapper.modelData.notif)
                            onClicked: root.dismissNotif(popupWrapper.modelData.notif)
                        }
                    }
                }
            }
        }
    }

    NotificationCenter {
        shown: root.centerShown
        dnd: root.dnd
        notifHistory: root.history
        onCloseRequested: root.centerShown = false
        onToggleDndRequested: root.setDnd(!root.dnd)
        onMarkAllReadRequested: root.markAllRead()
        onClearAllRequested: {
            root.history = [];
            root.clearAll();
        }
        onRemoveEntry: function(entry) { root.removeEntry(entry) }
        onMarkRead: function(entry) {
            if (entry && entry.notif) {
                root.markNotifRead(entry.notif);
            }
        }
    }
}
