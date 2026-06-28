// NotificationCenter — histórico (toggle via qs ipc call notifications toggle).

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

Item {
    id: root

    property bool shown: false
    property bool dnd: false
    property var notifHistory: []
    property string filterMode: "all"

    signal closeRequested()
    signal clearAllRequested()
    signal toggleDndRequested()
    signal markAllReadRequested()
    signal removeEntry(var entry)
    signal markRead(var entry)

    readonly property color cBg:      "#0a0e14"
    readonly property color cSurface: "#1a1f29"
    readonly property color cElev:    "#2a2f3a"
    readonly property color cBorder:  "#2d3748"
    readonly property color cFg:      "#e6e6e6"
    readonly property color cFgMuted: "#9ca3af"
    readonly property color cAccent:  "#00d4ff"

    readonly property int panelWidth: 480
    readonly property int panelMaxHeight: 640

    readonly property int unreadCount: {
        let n = 0;
        for (let i = 0; i < root.notifHistory.length; i++) {
            if (!root.notifHistory[i].read) {
                n++;
            }
        }
        return n;
    }

    readonly property var displayHistory: {
        if (root.filterMode === "unread") {
            return root.notifHistory.filter(function(e) { return !e.read; });
        }
        return root.notifHistory;
    }

    PanelWindow {
        id: centerWindow
        visible: root.shown

        anchors { top: true; right: true }
        exclusiveZone: 0
        color: "transparent"
        implicitWidth: root.panelWidth + 20
        implicitHeight: root.panelMaxHeight + 20
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        Shortcut {
            sequences: ["Escape"]
            enabled: root.shown
            onActivated: root.closeRequested()
        }

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

        Rectangle {
            id: panel
            anchors {
                top: parent.top
                right: parent.right
                topMargin: 10
                rightMargin: 10
            }

            width: root.panelWidth
            height: Math.min(root.panelMaxHeight,
                             headerCol.implicitHeight + listArea.implicitHeight + 20)
            radius: 14
            color: root.cSurface
            border.color: root.cBorder
            border.width: 1

            ColumnLayout {
                id: headerCol
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    leftMargin: 14
                    rightMargin: 14
                    topMargin: 14
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
                    }

                    Rectangle {
                        visible: root.unreadCount > 0
                        width: unreadLabel.implicitWidth + 10
                        height: 18
                        radius: 9
                        color: root.cElev

                        Text {
                            id: unreadLabel
                            anchors.centerIn: parent
                            text: {
                                const n = root.unreadCount;
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

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: dndLabel.implicitWidth + 14
                        height: 22
                        radius: 11
                        color: root.dnd ? Qt.rgba(0, 0.831, 1, 0.15) : "transparent"
                        border.color: root.dnd ? root.cAccent : root.cBorder
                        border.width: 1

                        Text {
                            id: dndLabel
                            anchors.centerIn: parent
                            text: root.dnd ? "DND" : "DND off"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                            color: root.dnd ? root.cAccent : root.cFgMuted
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggleDndRequested()
                        }
                    }

                    Rectangle {
                        visible: root.unreadCount > 0
                        width: markReadLabel.implicitWidth + 14
                        height: 22
                        radius: 11
                        color: markReadHover.containsMouse ? root.cElev : "transparent"
                        border.color: markReadHover.containsMouse ? root.cBorder : "transparent"
                        border.width: 1

                        Text {
                            id: markReadLabel
                            anchors.centerIn: parent
                            text: "Lidas"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                            color: markReadHover.containsMouse ? root.cFg : root.cFgMuted
                        }

                        MouseArea {
                            id: markReadHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.markAllReadRequested()
                        }
                    }

                    Rectangle {
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
                            font.pixelSize: 10
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

                    Rectangle {
                        width: 22
                        height: 22
                        radius: 11
                        color: xHover.containsMouse ? root.cElev : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            font.family: "JetBrainsMono Nerd Font"
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

                Row {
                    spacing: 6

                    Repeater {
                        model: [
                            { id: "all", label: "Todas" },
                            { id: "unread", label: "Não lidas" }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            width: tabLabel.implicitWidth + 16
                            height: 24
                            radius: 12
                            color: root.filterMode === modelData.id
                                ? Qt.rgba(0, 0.831, 1, 0.12) : "transparent"
                            border.color: root.filterMode === modelData.id
                                ? root.cAccent : root.cBorder
                            border.width: 1

                            Text {
                                id: tabLabel
                                anchors.centerIn: parent
                                text: modelData.label
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                                color: root.filterMode === modelData.id ? root.cAccent : root.cFgMuted
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.filterMode = modelData.id
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: root.cBorder
                }
            }

            Item {
                id: listArea
                anchors {
                    left: parent.left
                    right: parent.right
                    top: headerCol.bottom
                    bottom: parent.bottom
                    topMargin: 8
                    bottomMargin: 8
                    leftMargin: 10
                    rightMargin: 10
                }
                implicitHeight: Math.min(root.panelMaxHeight - headerCol.implicitHeight - 20,
                                         historyColumn.implicitHeight + 16)

                Text {
                    visible: root.displayHistory.length === 0
                    anchors.centerIn: parent
                    text: root.filterMode === "unread"
                        ? "Nenhuma não lida"
                        : "Sem notificações"
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
                            model: root.displayHistory

                            delegate: NotificationCard {
                                required property var modelData

                                notif: modelData.notif
                                read: modelData.read
                                compact: false
                                width: historyColumn.width
                                showActions: true

                                onDismissed: root.removeEntry(modelData)
                                onClicked: root.markRead(modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}
