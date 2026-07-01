// NotificationCard — card individual de notificação.
// Popup (compact) ou centro (preview à direita, texto à esquerda).

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Notifications
import "../../colors" as Theme

Rectangle {
    id: root

    required property var notif

    property bool showActions: true
    property bool compact: false
    property bool read: true

    signal dismissed()
    signal clicked()

    readonly property color cBg:      Theme.Colors.bg
    readonly property color cSurface: Theme.Colors.surface
    readonly property color cElev:    Theme.Colors.elev
    readonly property color cBorder:  Theme.Colors.border
    readonly property color cFg:      Theme.Colors.fg
    readonly property color cFgMuted: Theme.Colors.fgMuted
    readonly property color cAccent:  Theme.Colors.accent
    readonly property color cDanger:  Theme.Colors.danger

    readonly property bool isCritical: root.notif
        && root.notif.urgency === NotificationUrgency.Critical

    readonly property string imagePath: {
        if (!root.notif || !root.notif.image) {
            return "";
        }
        const img = root.notif.image;
        if (img.length === 0) {
            return "";
        }
        if (img.indexOf("file://") === 0 || img.indexOf("http://") === 0
                || img.indexOf("https://") === 0 || img.indexOf("data:") === 0) {
            return img;
        }
        return "file://" + img;
    }

    readonly property string appIconPath: {
        if (!root.notif || !root.notif.appIcon) {
            return "";
        }
        const icon = root.notif.appIcon;
        if (icon.length === 0) {
            return "";
        }
        if (icon.indexOf("file://") === 0 || icon.indexOf("http://") === 0
                || icon.indexOf("https://") === 0 || icon.indexOf("data:") === 0) {
            return icon;
        }
        return "file://" + icon;
    }

    readonly property bool hasPreview: root.imagePath.length > 0

    width: root.compact ? 360 : parent ? parent.width : 460
    implicitHeight: contentRow.implicitHeight + 20

    radius: 12
    color: root.read ? root.cSurface : Qt.rgba(0, 0.831, 1, 0.06)
    opacity: (root.read && !cardHover.containsMouse) ? 0.88 : 1
    border.width: root.isCritical ? 2 : 1
    border.color: root.isCritical ? root.cDanger
        : (root.read ? root.cBorder : Qt.rgba(0, 0.831, 1, 0.35))

    Behavior on border.color { ColorAnimation { duration: 120 } }
    Behavior on opacity { NumberAnimation { duration: 120 } }

    MouseArea {
        id: cardHover
        anchors.fill: parent
        hoverEnabled: !root.compact
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    RowLayout {
        id: contentRow
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 10
        }
        spacing: 10

        // Indicador não lida
        Rectangle {
            visible: !root.read
            width: 6
            height: 6
            radius: 3
            color: root.cAccent
            Layout.alignment: Qt.AlignTop
            Layout.topMargin: 6
        }

        // Ícone do app
        Item {
            Layout.preferredWidth: root.compact ? 36 : 40
            Layout.preferredHeight: root.compact ? 36 : 40
            Layout.alignment: Qt.AlignTop

            Rectangle {
                anchors.fill: parent
                radius: 8
                color: root.cElev
                visible: root.appIconPath.length === 0
            }

            Image {
                anchors.fill: parent
                source: root.appIconPath
                visible: root.appIconPath.length > 0
                fillMode: Image.PreserveAspectCrop
                smooth: true
            }

            Rectangle {
                anchors.fill: parent
                radius: 8
                color: "transparent"
                visible: root.appIconPath.length === 0

                Text {
                    anchors.centerIn: parent
                    text: {
                        const name = root.notif ? (root.notif.appName || "?") : "?";
                        return name.charAt(0).toUpperCase();
                    }
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: root.compact ? 16 : 18
                    font.weight: Font.Bold
                    color: root.cAccent
                }
            }
        }

        // Texto (esquerda)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

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

                Rectangle {
                    width: 18
                    height: 18
                    radius: 9
                    color: closeHover.containsMouse ? root.cElev : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        color: closeHover.containsMouse ? root.cAccent : root.cFgMuted
                    }

                    MouseArea {
                        id: closeHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: function(mouse) {
                            mouse.accepted = true;
                            root.dismissed();
                        }
                    }
                }
            }

            Text {
                text: root.notif ? (root.notif.summary || "") : ""
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: root.compact ? 13 : 14
                font.weight: Font.Bold
                color: root.cFg
                wrapMode: Text.WordWrap
                maximumLineCount: root.compact ? 2 : 3
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
                maximumLineCount: root.compact ? 3 : 6
                elide: Text.ElideRight
                Layout.fillWidth: true
                visible: text.length > 0
            }

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
                            onExited: actionBtn.hovered = false
                            onClicked: function(mouse) {
                                mouse.accepted = true;
                                if (actionBtn.modelData && actionBtn.modelData.invoke) {
                                    actionBtn.modelData.invoke();
                                }
                                root.dismissed();
                            }
                        }
                    }
                }
            }
        }

        // Preview à direita
        Rectangle {
            visible: root.hasPreview
            Layout.preferredWidth: root.compact ? 56 : 112
            Layout.preferredHeight: root.compact ? 56 : 84
            Layout.alignment: Qt.AlignTop
            radius: 10
            color: root.cElev
            clip: true

            Image {
                anchors.fill: parent
                source: root.imagePath
                fillMode: Image.PreserveAspectCrop
                smooth: true
                asynchronous: true
            }
        }
    }
}
