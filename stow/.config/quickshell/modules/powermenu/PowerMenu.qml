// PowerMenu — lista de sessão (lock/logout/suspend/hibernate/reboot/shutdown).
// In-house, substitui o wlogout. Lista vertical: ícone + label lado a lado, com
// largura de sobra pro texto nunca quebrar. Ícones: JetBrainsMono Nerd Font
// (instalada; "Symbols Nerd Font" não existe no sistema → fallback quebrado).
// Toggle via: qs ipc call powermenu toggle / open / close

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root
    property bool shown: false

    // Índice em foco — começa em Lock (Enter acidental tranca, não desliga).
    property int selected: 0

    // ── Tema (Deep Dark) ──────────────────────────────────────────
    readonly property color cBg:      "#0a0e14"
    readonly property color cSurface: "#1a1f29"
    readonly property color cElev:    "#2a2f3a"
    readonly property color cBorder:  "#2d3748"
    readonly property color cFg:      "#e6e6e6"
    readonly property color cFgMuted: "#9ca3af"
    readonly property color cAccent:  "#00d4ff"
    readonly property color cDanger:  "#ff5555"

    // ── Ações ─────────────────────────────────────────────────────
    readonly property var actions: [
        { label: "Lock",      key: "l", icon: "\uf023", cmd: "hyprlock",            danger: false },
        { label: "Logout",    key: "e", icon: "\uf08b", cmd: "uwsm stop",           danger: false },
        { label: "Suspend",   key: "u", icon: "\uf186", cmd: "systemctl suspend",   danger: false },
        { label: "Hibernate", key: "h", icon: "\uf2dc", cmd: "systemctl hibernate", danger: false },
        { label: "Reboot",    key: "r", icon: "\uf021", cmd: "systemctl reboot",    danger: true  },
        { label: "Shutdown",  key: "s", icon: "\uf011", cmd: "systemctl poweroff",  danger: true  }
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
            sequences: ["Up"]
            enabled: root.shown
            onActivated: root.moveSelection(-1)
        }
        Shortcut {
            sequences: ["Down"]
            enabled: root.shown
            onActivated: root.moveSelection(1)
        }
        Shortcut {
            sequences: ["Return", "Enter"]
            enabled: root.shown
            onActivated: root.activate(root.selected)
        }

        // Atalho por letra (l/e/u/h/r/s).
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

        // Fundo escurecido — clique fora fecha.
        Rectangle {
            anchors.fill: parent
            color: root.cBg
            opacity: 0.55

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        // ── Painel central com a lista ────────────────────────────
        Rectangle {
            id: panel
            anchors.centerIn: parent
            width: 300
            height: list.implicitHeight + 24
            radius: 16
            color: root.cSurface
            border.width: 2
            border.color: root.cBorder

            Column {
                id: list
                anchors.centerIn: parent
                width: parent.width - 24
                spacing: 4

                Repeater {
                    model: root.actions

                    delegate: Rectangle {
                        id: item
                        required property int index
                        required property var modelData

                        readonly property bool active: root.selected === index

                        width: parent.width
                        height: 52
                        radius: 10
                        color: item.active ? root.cElev : "transparent"

                        Behavior on color {
                            ColorAnimation { duration: 100 }
                        }

                        // Ícone + label (largura natural — nunca quebra).
                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 16

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: item.modelData.icon
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 24
                                color: iconColor()

                                function iconColor() {
                                    if (item.active && item.modelData.danger) {
                                        return root.cDanger;
                                    }
                                    if (item.active) {
                                        return root.cAccent;
                                    }
                                    return root.cFg;
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: item.modelData.label
                                font.family: "Maple Mono NF"
                                font.pixelSize: 17
                                font.weight: 600
                                wrapMode: Text.NoWrap
                                color: item.active ? root.cFg : root.cFgMuted
                            }
                        }

                        // Badge da tecla, à direita.
                        Rectangle {
                            anchors.right: parent.right
                            anchors.rightMargin: 14
                            anchors.verticalCenter: parent.verticalCenter
                            width: 26
                            height: 26
                            radius: 6
                            color: root.cBg
                            border.width: 1
                            border.color: item.active ? root.cAccent : root.cBorder

                            Text {
                                anchors.centerIn: parent
                                text: item.modelData.key
                                font.family: "Maple Mono NF"
                                font.pixelSize: 13
                                font.weight: 600
                                color: item.active ? root.cAccent : root.cFgMuted
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: root.selected = item.index
                            onClicked: root.activate(item.index)
                        }
                    }
                }
            }
        }
    }
}
