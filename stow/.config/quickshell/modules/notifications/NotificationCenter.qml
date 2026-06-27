// NotificationCenter — histórico de notificações (toggle via IPC).
//
// Recebe notifHistory (lista de notificações) do Scope pai (Notifications.qml).
// Posição: top-right, abaixo da barra.
// Toggle externo: qs ipc call notifications toggle

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

Item {
    id: root

    property bool shown: false
    // Lista de notificações (mais recente primeiro) injetada pelo pai.
    property var notifHistory: []

    signal closeRequested()
    signal clearAllRequested()

    // ── Tema (Deep Dark — espelha PowerMenu.qml) ─────────────────
    readonly property color cBg:      "#0a0e14"
    readonly property color cSurface: "#1a1f29"
    readonly property color cElev:    "#2a2f3a"
    readonly property color cBorder:  "#2d3748"
    readonly property color cFg:      "#e6e6e6"
    readonly property color cFgMuted: "#9ca3af"
    readonly property color cAccent:  "#00d4ff"

    // Largura fixa do painel de histórico.
    readonly property int panelWidth: 380
    // Altura máxima do painel (px); acima disso o ScrollView ativa scroll.
    readonly property int panelMaxHeight: 580

    PanelWindow {
        id: centerWindow
        visible: root.shown

        anchors {
            top:   true
            right: true
        }
        exclusiveZone: 0
        color: "transparent"

        implicitWidth:  root.panelWidth + 20
        implicitHeight: root.panelMaxHeight + 20

        WlrLayershell.layer:         WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        Shortcut {
            sequences: ["Escape"]
            enabled: root.shown
            onActivated: root.closeRequested()
        }

        // Clique fora do painel fecha o centro.
        MouseArea {
            anchors.fill: parent
            z: -1
            onClicked: function(mouse) {
                const local = mapToItem(panel, mouse.x, mouse.y);
                const inside = local.x >= 0 && local.y >= 0
                            && local.x <= panel.width && local.y <= panel.height;
                if (!inside) {
                    root.closeRequested();
                }
            }
        }

        // ── Painel principal ──────────────────────────────────────
        Rectangle {
            id: panel
            anchors {
                top:         parent.top
                right:       parent.right
                topMargin:   10
                rightMargin: 10
            }

            width:  root.panelWidth
            // Altura: soma do header + lista, limitada ao máximo.
            height: Math.min(root.panelMaxHeight,
                             headerCol.implicitHeight + listArea.implicitHeight + 20)
            radius: 14
            color:  root.cSurface
            border.color: root.cBorder
            border.width: 1

            // ── Coluna de header ─────────────────────────────────
            ColumnLayout {
                id: headerCol
                anchors {
                    left:       parent.left
                    right:      parent.right
                    top:        parent.top
                    leftMargin: 14
                    rightMargin: 14
                    topMargin:  14
                }
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "Notificações"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                        font.weight: Font.Bold
                        color: root.cFg
                        Layout.fillWidth: true
                    }

                    // Badge de contagem
                    Rectangle {
                        visible: root.notifHistory.length > 0
                        width: countLabel.implicitWidth + 10
                        height: 18
                        radius: 9
                        color: root.cElev

                        Text {
                            id: countLabel
                            anchors.centerIn: parent
                            text: {
                                const n = root.notifHistory.length;
                                if (n > 99) {
                                    return "99+";
                                }
                                return n.toString();
                            }
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                            color: root.cAccent
                        }
                    }

                    // Botão "Limpar tudo"
                    Rectangle {
                        id: clearBtn
                        visible: root.notifHistory.length > 0
                        width: clearLabel.implicitWidth + 14
                        height: 22
                        radius: 11
                        color: clearHover.containsMouse ? root.cElev : "transparent"
                        border.color: clearHover.containsMouse ? root.cBorder : "transparent"
                        border.width: 1

                        Text {
                            id: clearLabel
                            anchors.centerIn: parent
                            text: "Limpar"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            color: clearHover.containsMouse ? root.cFg : root.cFgMuted
                        }

                        MouseArea {
                            id: clearHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.clearAllRequested()
                        }
                    }

                    // Botão fechar o centro
                    Rectangle {
                        width: 22
                        height: 22
                        radius: 11
                        color: xHover.containsMouse ? root.cElev : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: ""
                            font.family: "Symbols Nerd Font"
                            font.pixelSize: 12
                            color: xHover.containsMouse ? root.cAccent : root.cFgMuted
                        }

                        MouseArea {
                            id: xHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.closeRequested()
                        }
                    }
                }

                // Separador
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: root.cBorder
                }
            }

            // ── Lista de histórico (scrollável) ───────────────────
            // implicitHeight calculado pela Column interna.
            Item {
                id: listArea
                anchors {
                    left:         parent.left
                    right:        parent.right
                    top:          headerCol.bottom
                    bottom:       parent.bottom
                    topMargin:    8
                    bottomMargin: 8
                    leftMargin:   10
                    rightMargin:  10
                }
                // Reporta o conteúdo real para o cálculo de altura do painel.
                implicitHeight: Math.min(root.panelMaxHeight - headerCol.implicitHeight - 20,
                                         historyColumn.implicitHeight + 16)

                // Estado vazio
                Text {
                    visible: root.notifHistory.length === 0
                    anchors.centerIn: parent
                    text: "Sem notificações"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                    color: root.cFgMuted
                }

                Flickable {
                    id: flick
                    anchors.fill: parent
                    clip: true
                    contentWidth: width
                    contentHeight: historyColumn.implicitHeight

                    ScrollBar.vertical: ScrollBar {
                        policy: historyColumn.implicitHeight > flick.height
                              ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
                    }

                    Column {
                        id: historyColumn
                        width: flick.width
                        spacing: 6

                        Repeater {
                            model: root.notifHistory

                            delegate: NotificationCard {
                                required property var modelData

                                notif: modelData
                                width: historyColumn.width
                                // No centro mostramos todas as ações.
                                showActions: true

                                onDismissed: {
                                    // Remove do histórico — controlado pelo pai via binding.
                                    root.notifHistory = root.notifHistory.filter(function(n) {
                                        return n !== modelData;
                                    });
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
