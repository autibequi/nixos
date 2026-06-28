// WindowSwitcher — alt-tab visual in-house.
// Substitui o picker.lua (rofi de texto). Toggle via: qs ipc call switcher toggle
// Molde: PowerMenu.qml (Scope + IpcHandler + PanelWindow Overlay + WlrKeyboardFocus.Exclusive).
// Fonte de dados: Hyprland.clients (nativo do Quickshell.Hyprland) — sem hyprctl extra.

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root

    property bool shown: false

    // Índice do card em foco — começa em 0 (janela mais recentemente focada).
    property int selected: 0

    // Snapshot das janelas capturado no momento de abrir.
    // Congelar evita que a lista mude enquanto o usuário está navegando.
    property var windowSnapshot: []

    // ── Tema Deep Dark (espelha PowerMenu.qml para consistência) ──
    readonly property color cBg:      "#0a0e14"
    readonly property color cSurface: "#1a1f29"
    readonly property color cElev:    "#2a2f3a"
    readonly property color cBorder:  "#2d3748"
    readonly property color cFg:      "#e6e6e6"
    readonly property color cFgMuted: "#9ca3af"
    readonly property color cAccent:  "#00d4ff"

    function open() {
        // Capturar snapshot na abertura: ordena por focusHistoryID para que a
        // janela mais recentemente usada fique em primeiro lugar.
        const raw = Hyprland.clients;
        const sorted = Array.from(raw).sort(function(a, b) {
            return (a.focusHistoryID ?? 9999) - (b.focusHistoryID ?? 9999);
        });
        root.windowSnapshot = sorted;
        root.selected = 0;
        root.shown = true;
    }

    function close() {
        root.shown = false;
        root.windowSnapshot = [];
    }

    function toggle() {
        if (root.shown) {
            root.close();
            return;
        }
        root.open();
    }

    function moveSelection(delta) {
        const count = root.windowSnapshot.length;
        if (count === 0) {
            return;
        }
        let next = root.selected + delta;
        if (next < 0) {
            next = count - 1;
        }
        if (next >= count) {
            next = 0;
        }
        root.selected = next;
    }

    function activateSelected() {
        const win = root.windowSnapshot[root.selected];
        if (!win) {
            return;
        }
        // Foca a janela pelo endereço — funciona mesmo que ela esteja em fullscreen
        // ou coberta por outra janela (o caso de dor que motivou este widget).
        Hyprland.dispatch("focuswindow address:" + win.address);
        root.close();
    }

    IpcHandler {
        target: "switcher"
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
            sequences: ["Tab"]
            enabled: root.shown
            onActivated: root.moveSelection(1)
        }
        Shortcut {
            sequences: ["Shift+Tab"]
            enabled: root.shown
            onActivated: root.moveSelection(-1)
        }
        Shortcut {
            sequences: ["Right", "Down"]
            enabled: root.shown
            onActivated: root.moveSelection(1)
        }
        Shortcut {
            sequences: ["Left", "Up"]
            enabled: root.shown
            onActivated: root.moveSelection(-1)
        }
        Shortcut {
            sequences: ["Return", "Enter"]
            enabled: root.shown
            onActivated: root.activateSelected()
        }

        // Fundo escurecido — clique fora dos cards fecha.
        Rectangle {
            anchors.fill: parent
            color: root.cBg
            opacity: 0.60

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        // Painel central com a lista de janelas.
        // Altura: header(40) + conteúdo + footer(28) + margens do Flickable(16).
        // Limitado a parent.height - 80 para não sair da tela.
        Rectangle {
            id: panel
            anchors.centerIn: parent
            width:  Math.min(720, parent.width  - 80)
            height: Math.min(40 + contentCol.implicitHeight + 16 + 28, parent.height - 80)
            radius: 16
            color:  root.cSurface
            border.width: 1
            border.color: root.cBorder
            clip: true

            // Título do painel.
            Rectangle {
                id: header
                anchors.top:   parent.top
                anchors.left:  parent.left
                anchors.right: parent.right
                height: 40
                color: root.cElev
                radius: 16

                // Quadrado no rodapé do header cobre o radius inferior para ficar reto.
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left:   parent.left
                    anchors.right:  parent.right
                    height: 16
                    color:  root.cElev
                }

                Text {
                    anchors.centerIn: parent
                    text: "Window Switcher"
                    font.pixelSize: 13
                    font.bold: true
                    color: root.cFgMuted
                }
            }

            // Lista de cards de janelas — scroll vertical quando a lista for longa.
            Flickable {
                anchors.top:    header.bottom
                anchors.left:   parent.left
                anchors.right:  parent.right
                anchors.bottom: footer.top
                anchors.topMargin:    8
                anchors.leftMargin:   8
                anchors.rightMargin:  8
                anchors.bottomMargin: 0
                contentHeight: contentCol.implicitHeight
                clip: true

                Column {
                    id: contentCol
                    width: parent.width
                    spacing: 6

                    Repeater {
                        model: root.windowSnapshot

                        delegate: Rectangle {
                            id: card
                            required property int index
                            required property var modelData

                            readonly property bool active: root.selected === index

                            width:  parent.width
                            height: 64
                            radius: 10
                            color:  card.active ? root.cElev : "transparent"
                            border.width: card.active ? 2 : 0
                            border.color: root.cAccent

                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left:  parent.left
                                anchors.right: parent.right
                                anchors.leftMargin:  12
                                anchors.rightMargin: 12
                                spacing: 12

                                // Ícone da aplicação via nerd font (classe → símbolo).
                                // v1: bloco fixo com inicial maiúscula da classe; sem thumbnails.
                                Rectangle {
                                    width:  40
                                    height: 40
                                    radius: 8
                                    color:  card.active ? root.cAccent : root.cBorder

                                    Text {
                                        anchors.centerIn: parent
                                        text: {
                                            const cls = card.modelData.class ?? "";
                                            return cls.length > 0 ? cls.charAt(0).toUpperCase() : "?";
                                        }
                                        font.pixelSize: 18
                                        font.bold: true
                                        color: card.active ? root.cBg : root.cFg
                                    }
                                }

                                // Textos: título + classe + workspace.
                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 3

                                    Text {
                                        width: panel.width - 100
                                        text: card.modelData.title ?? "(sem título)"
                                        font.pixelSize: 14
                                        font.bold: card.active
                                        color: card.active ? root.cFg : root.cFgMuted
                                        elide: Text.ElideRight
                                    }

                                    Row {
                                        spacing: 8

                                        Text {
                                            text: card.modelData.class ?? "?"
                                            font.pixelSize: 11
                                            color: root.cFgMuted
                                        }

                                        Text {
                                            text: "·"
                                            font.pixelSize: 11
                                            color: root.cFgMuted
                                        }

                                        Text {
                                            text: {
                                                const ws = card.modelData.workspace;
                                                if (!ws) {
                                                    return "ws ?";
                                                }
                                                const name = ws.name ?? "";
                                                return name !== "" ? name : ("ws " + (ws.id ?? "?"));
                                            }
                                            font.pixelSize: 11
                                            color: card.active ? root.cAccent : root.cFgMuted
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: root.selected = card.index
                                onClicked: {
                                    root.selected = card.index;
                                    root.activateSelected();
                                }
                            }
                        }
                    }
                }
            }

            // Rodapé com dica de atalhos.
            Rectangle {
                id: footer
                anchors.bottom: parent.bottom
                anchors.left:   parent.left
                anchors.right:  parent.right
                height: 28
                color:  root.cElev
                radius: 16

                // Quadrado no topo do footer cobre o radius superior para ficar reto.
                Rectangle {
                    anchors.top:   parent.top
                    anchors.left:  parent.left
                    anchors.right: parent.right
                    height: 16
                    color:  root.cElev
                }

                Text {
                    anchors.centerIn: parent
                    text: "Tab / ↑↓ navegar   ·   Enter focar   ·   Esc fechar"
                    font.pixelSize: 11
                    color: root.cFgMuted
                }
            }
        }
    }
}
