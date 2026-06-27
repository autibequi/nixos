// PowerMenu — overlay de sessão (lock/logout/suspend/hibernate/reboot/shutdown).
// In-house, substitui o wlogout GTK. Molde: ClockWidget (Scope + IpcHandler + PanelWindow).
// Toggle via: qs ipc call powermenu toggle / open / close
// Tema: Deep Dark (espelha ClockWidget pra consistência visual).

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root
    property bool shown: false

    // Índice da ação em foco — começa em lock (mais seguro: Enter acidental tranca, não desliga).
    property int selected: 0

    // ── Tema (Deep Dark / Alacritty) ──────────────────────────────
    readonly property color cBg:       "#0a0e14"
    readonly property color cSurface:  "#1a1f29"
    readonly property color cElev:     "#2a2f3a"
    readonly property color cBorder:   "#2d3748"
    readonly property color cFg:       "#e6e6e6"
    readonly property color cFgMuted:  "#9ca3af"
    readonly property color cAccent:   "#00d4ff"
    readonly property color cDanger:   "#ff5555"

    // ── Ações de sessão ───────────────────────────────────────────
    // Comandos espelham o layout antigo do wlogout (uwsm/systemctl/hyprlock).
    // `danger` pinta o ícone de vermelho em foco (reboot/shutdown).
    readonly property var actions: [
        { id: "lock",      label: "Lock",      key: "l", icon: "", cmd: "hyprlock",            danger: false },
        { id: "logout",    label: "Logout",    key: "e", icon: "", cmd: "uwsm stop",           danger: false },
        { id: "suspend",   label: "Suspend",   key: "u", icon: "", cmd: "systemctl suspend",   danger: false },
        { id: "hibernate", label: "Hibernate", key: "h", icon: "", cmd: "systemctl hibernate", danger: false },
        { id: "reboot",    label: "Reboot",    key: "r", icon: "", cmd: "systemctl reboot",    danger: true  },
        { id: "shutdown",  label: "Shutdown",  key: "s", icon: "", cmd: "systemctl poweroff",  danger: true  }
    ]

    function open() {
        root.selected = 0;
        root.shown = true;
    }
    function close() {
        root.shown = false;
    }
    function toggle() {
        if (root.shown) {
            root.close();
            return;
        }
        root.open();
    }

    function run(cmd) {
        // execDetached sobrevive ao logout matar a sessão do shell.
        Quickshell.execDetached(["sh", "-c", cmd]);
        root.close();
    }

    function activate(index) {
        const action = root.actions[index];
        if (!action) {
            return;
        }
        root.run(action.cmd);
    }

    function moveSelection(delta) {
        let next = root.selected + delta;
        if (next < 0) {
            next = root.actions.length - 1;
        }
        if (next >= root.actions.length) {
            next = 0;
        }
        root.selected = next;
    }

    function activateByKey(letter) {
        for (let i = 0; i < root.actions.length; i++) {
            if (root.actions[i].key === letter) {
                root.activate(i);
                return;
            }
        }
    }

    IpcHandler {
        target: "powermenu"
        function toggle(): void { root.toggle() }
        function open(): void   { root.open() }
        function close(): void  { root.close() }
    }

    PanelWindow {
        id: overlay
        visible: root.shown

        anchors {
            top:    true
            bottom: true
            left:   true
            right:  true
        }
        exclusiveZone: 0
        color: "transparent"

        WlrLayershell.layer:         WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        Shortcut {
            sequences: ["Escape"]
            enabled: root.shown
            onActivated: root.close()
        }
        Shortcut {
            sequences: ["Left"]
            enabled: root.shown
            onActivated: root.moveSelection(-1)
        }
        Shortcut {
            sequences: ["Right"]
            enabled: root.shown
            onActivated: root.moveSelection(1)
        }
        Shortcut {
            sequences: ["Return", "Enter"]
            enabled: root.shown
            onActivated: root.activate(root.selected)
        }

        // Atalho por letra (l/e/u/h/r/s) — gerado a partir da lista de ações.
        Repeater {
            model: root.actions
            delegate: Item {
                required property var modelData
                Shortcut {
                    sequence: modelData.key
                    enabled: root.shown
                    onActivated: root.activateByKey(modelData.key)
                }
            }
        }

        // Fundo escurecido — clique fora dos cards fecha.
        Rectangle {
            anchors.fill: parent
            color: root.cBg
            opacity: 0.55

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        Row {
            id: cards
            anchors.centerIn: parent
            spacing: 18

            Repeater {
                model: root.actions

                delegate: Rectangle {
                    id: card
                    required property int index
                    required property var modelData

                    readonly property bool active: root.selected === index

                    width:  150
                    height: 170
                    radius: 16
                    color: card.active ? root.cElev : root.cSurface
                    border.width: 2
                    border.color: card.active ? root.cAccent : root.cBorder

                    Behavior on border.color {
                        ColorAnimation { duration: 120 }
                    }
                    Behavior on color {
                        ColorAnimation { duration: 120 }
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 14

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: card.modelData.icon
                            font.family: "Symbols Nerd Font"
                            font.pixelSize: 46
                            color: dangerInFocus() ? root.cDanger : iconColor()

                            function iconColor() {
                                if (card.active) {
                                    return root.cAccent;
                                }
                                return root.cFg;
                            }
                            function dangerInFocus() {
                                return card.active && card.modelData.danger;
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: card.modelData.label
                            font.pixelSize: 16
                            font.bold: card.active
                            color: card.active ? root.cFg : root.cFgMuted
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: card.modelData.key
                            font.family: "Symbols Nerd Font"
                            font.pixelSize: 12
                            color: root.cFgMuted
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: root.selected = card.index
                        onClicked: root.activate(card.index)
                    }
                }
            }
        }
    }
}
