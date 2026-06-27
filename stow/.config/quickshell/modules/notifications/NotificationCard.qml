// NotificationCard — card individual de notificação.
// Usado pelo popup (Notifications.qml) e pelo centro (NotificationCenter.qml).
// Propriedades expostas: notif (Notification*), onDismissed() signal, showActions.

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Notifications

Rectangle {
    id: root

    required property var notif

    // Mostra botões de ação (default true; popup pode desabilitar por espaço).
    property bool showActions: true

    signal dismissed()

    // ── Tema (Deep Dark — espelha PowerMenu.qml) ─────────────────
    readonly property color cBg:      "#0a0e14"
    readonly property color cSurface:  "#1a1f29"
    readonly property color cElev:    "#2a2f3a"
    readonly property color cBorder:  "#2d3748"
    readonly property color cFg:      "#e6e6e6"
    readonly property color cFgMuted: "#9ca3af"
    readonly property color cAccent:  "#00d4ff"
    readonly property color cDanger:  "#ff5555"

    // Urgência crítica recebe borda colorida para destacar visualmente.
    readonly property bool isCritical: root.notif
        && root.notif.urgency === NotificationUrgency.Critical

    width: 360
    // Altura cresce com o corpo — mínimo suficiente para ícone + título + corpo 1 linha.
    implicitHeight: contentCol.implicitHeight + 20

    radius: 12
    color: root.cSurface
    border.width: root.isCritical ? 2 : 1
    border.color: root.isCritical ? root.cDanger : root.cBorder

    Behavior on border.color {
        ColorAnimation { duration: 120 }
    }

    ColumnLayout {
        id: contentCol
        anchors {
            left:   parent.left
            right:  parent.right
            top:    parent.top
            margins: 10
        }
        spacing: 4

        // ── Linha de cabeçalho: app name + botão fechar ────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: root.notif ? (root.notif.appName || "") : ""
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
                color: root.cFgMuted
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            // Botão fechar/dismiss
            Rectangle {
                width: 18
                height: 18
                radius: 9
                color: closeHover.containsMouse ? root.cElev : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: ""
                    font.family: "Symbols Nerd Font"
                    font.pixelSize: 11
                    color: closeHover.containsMouse ? root.cAccent : root.cFgMuted
                }

                MouseArea {
                    id: closeHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.dismissed()
                }
            }
        }

        // ── Corpo: ícone + título + texto ──────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // Ícone do app (letra inicial como fallback)
            Rectangle {
                width: 36
                height: 36
                radius: 8
                color: root.cElev
                Layout.alignment: Qt.AlignTop

                Text {
                    anchors.centerIn: parent
                    text: {
                        const name = root.notif ? (root.notif.appName || "?") : "?";
                        return name.charAt(0).toUpperCase();
                    }
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    color: root.cAccent
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: root.notif ? (root.notif.summary || "") : ""
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    color: root.cFg
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    visible: text.length > 0
                }

                Text {
                    text: root.notif ? (root.notif.body || "") : ""
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                    color: root.cFgMuted
                    wrapMode: Text.WordWrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    visible: text.length > 0
                }
            }
        }

        // ── Ações (botões opcionais enviados pelo app) ─────────────
        Row {
            visible: root.showActions && root.notif
                  && (root.notif.actions || []).length > 0
            spacing: 6
            Layout.alignment: Qt.AlignRight

            Repeater {
                model: root.notif ? (root.notif.actions || []) : []

                delegate: Rectangle {
                    id: actionBtn
                    required property var modelData

                    property bool hovered: false

                    height: 22
                    width: Math.max(actionLabel.implicitWidth + 16, 60)
                    radius: 11
                    color: actionBtn.hovered ? root.cAccent : root.cElev

                    Behavior on color { ColorAnimation { duration: 100 } }

                    Text {
                        id: actionLabel
                        anchors.centerIn: parent
                        text: actionBtn.modelData.text || ""
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                        font.weight: Font.Medium
                        color: actionBtn.hovered ? root.cBg : root.cFg
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: actionBtn.hovered = true
                        onExited:  actionBtn.hovered = false
                        onClicked: {
                            if (actionBtn.modelData && actionBtn.modelData.invoke) {
                                actionBtn.modelData.invoke();
                            }
                            root.dismissed();
                        }
                    }
                }
            }
        }

        // Espaçador inferior
        Item { Layout.preferredHeight: 2 }
    }
}
