// Notifications — daemon de notificação in-house (substitui swaync).
//
// Responsabilidades:
//   • Registra-se no protocolo Wayland via NotificationServer.
//   • Empilha popups no canto top-right com auto-dismiss por timeout.
//   • Guarda histórico para o NotificationCenter (toggleável via IPC).
//
// Toggle do centro:
//   qs ipc call notifications toggle
//   qs ipc call notifications open
//   qs ipc call notifications close

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Notifications

Scope {
    id: root

    // ── Visibilidade do centro de histórico ───────────────────────
    property bool centerShown: false

    // Timeout padrão para auto-dismiss de popups (ms).
    readonly property int defaultTimeoutMs: 5000

    // Popups que estão ativos agora (lista de objetos com notif + timerId).
    property var activePopups: []

    // Histórico completo (mais recente primeiro) — lido pelo NotificationCenter.
    property var history: []

    // Máximo de popups empilhados simultaneamente.
    readonly property int maxPopups: 5

    // ── IPC: toggle/open/close do centro ─────────────────────────
    IpcHandler {
        target: "notifications"
        function toggle(): void { root.centerShown = !root.centerShown }
        function open(): void   { root.centerShown = true }
        function close(): void  { root.centerShown = false }
    }

    // ── Servidor Wayland de notificações ─────────────────────────
    NotificationServer {
        id: server

        keepOnReload:           true
        actionsSupported:       true
        bodyMarkupSupported:    true
        imageSupported:         true
        persistenceSupported:   true

        onNotification: function(notif) {
            notif.tracked = true;
            root.addNotification(notif);
        }
    }

    // Componente reutilizável para timers de auto-dismiss.
    Component {
        id: dismissTimerComponent
        Timer {
            repeat: false
            running: false
        }
    }

    // ── API interna ───────────────────────────────────────────────

    function addNotification(notif) {
        // Histórico: insere no início (mais recente primeiro).
        root.history = [notif].concat(root.history.slice(0, 99));

        // Limite de popups simultâneos.
        if (root.activePopups.length >= root.maxPopups) {
            root.dismissOldest();
        }

        const entry = { notif: notif };
        root.activePopups = root.activePopups.concat([entry]);

        // Timer de auto-dismiss individual.
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

    // ── Janela de popups (top-right, sobreposta) ──────────────────
    PanelWindow {
        id: popupWindow

        // Popup stack é sempre visível enquanto houver popups.
        visible: root.activePopups.length > 0

        anchors {
            top:   true
            right: true
        }
        // Sem reserva de espaço — flutua sobre as janelas.
        exclusiveZone: 0
        color: "transparent"

        // Largura fixa (card width 360 + margem).
        implicitWidth: 380
        // Altura automática (Column cresce conforme os cards).
        implicitHeight: popupColumn.implicitHeight + 20

        WlrLayershell.layer: WlrLayer.Overlay

        // Margem top-right consistente com o restante do shell.
        Item {
            anchors.fill: parent
            anchors.margins: 10

            Column {
                id: popupColumn
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: 8

                // Um card por popup ativo.
                Repeater {
                    model: root.activePopups

                    delegate: Item {
                        id: popupWrapper
                        required property var modelData
                        required property int index

                        width: popupCard.width
                        height: popupCard.height

                        // Animação de entrada: desliza da direita.
                        transform: Translate {
                            id: slideIn
                            x: 40
                        }

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
                            // Ações no popup: mostrar só se há 1-2 ações (não polui o stack).
                            showActions: (popupWrapper.modelData.notif.actions || []).length <= 2

                            onDismissed: root.dismissNotif(popupWrapper.modelData.notif)
                        }
                    }
                }
            }
        }
    }

    // ── Centro de notificações (histórico, toggled via IPC) ───────
    NotificationCenter {
        shown: root.centerShown
        notifHistory: root.history
        onCloseRequested: root.centerShown = false
        onClearAllRequested: {
            root.history = [];
            root.clearAll();
        }
    }
}
