// ClockWidget — popover com 3 meses (anterior/atual/próximo), navegação via setas,
// dropdown de mês e ano editável.
// Toggle via: qs ipc call clock toggle / open / close
// Tema: Deep Dark (espelha alacritty/dark-theme.toml)

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root
    property bool shown: false

    // ── Tema (Deep Dark / Alacritty) ──────────────────────────────
    readonly property color cBg:        "#0a0e14"
    readonly property color cSurface:   "#1a1f29"
    readonly property color cElev:      "#2a2f3a"
    readonly property color cBorder:    "#2d3748"
    readonly property color cFg:        "#e6e6e6"
    readonly property color cFgMuted:   "#9ca3af"
    readonly property color cFgDimmer:  "#4a5568"
    readonly property color cAccent:    "#00d4ff"
    readonly property color cAccentS:   "#ff79c6"

    readonly property var monthNames: [
        "Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
        "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"
    ]

    // ── Estado: data sendo visualizada ────────────────────────────
    // `now` muda a cada segundo (pra hora viva); `displayedMonth`/`displayedYear`
    // controla qual mês a navegação está em — independente da data real.
    property date now: new Date()
    property int displayedMonth: now.getMonth()
    property int displayedYear:  now.getFullYear()

    function gotoPrev() {
        let m = displayedMonth - 1;
        let y = displayedYear;
        if (m < 0) { m = 11; y -= 1; }
        displayedMonth = m;
        displayedYear  = y;
    }
    function gotoNext() {
        let m = displayedMonth + 1;
        let y = displayedYear;
        if (m > 11) { m = 0; y += 1; }
        displayedMonth = m;
        displayedYear  = y;
    }
    function gotoToday() {
        displayedMonth = now.getMonth();
        displayedYear  = now.getFullYear();
    }
    function prevMonthOf(m, y) {
        return m === 0 ? { m: 11, y: y - 1 } : { m: m - 1, y: y };
    }
    function nextMonthOf(m, y) {
        return m === 11 ? { m: 0, y: y + 1 } : { m: m + 1, y: y };
    }

    Timer {
        interval: 1000
        running: root.shown
        repeat:  true
        onTriggered: root.now = new Date()
    }

    // ── IPC: toggle/open/close de fora ────────────────────────────
    IpcHandler {
        target: "clock"
        function toggle(): void {
            if (!root.shown) root.gotoToday();
            root.shown = !root.shown;
        }
        function open(): void {
            root.gotoToday();
            root.shown = true;
        }
        function close(): void { root.shown = false }
    }

    // ── Janela popover ────────────────────────────────────────────
    PanelWindow {
        id: popup
        visible: root.shown

        anchors {
            left:   true
            right:  true
            bottom: true
        }
        margins { bottom: 42 }

        implicitHeight: 420
        exclusiveZone:  0
        color: "transparent"

        WlrLayershell.layer:        WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        Shortcut {
            sequences: ["Escape"]
            enabled: root.shown
            onActivated: root.shown = false
        }
        Shortcut {
            sequences: ["Left"]
            enabled: root.shown
            onActivated: root.gotoPrev()
        }
        Shortcut {
            sequences: ["Right"]
            enabled: root.shown
            onActivated: root.gotoNext()
        }
        Shortcut {
            sequences: ["Home"]
            enabled: root.shown
            onActivated: root.gotoToday()
        }

        // Click fora dos cards → fecha
        MouseArea {
            anchors.fill: parent
            z: -1
            onClicked: function(mouse) {
                const local = mapToItem(cards, mouse.x, mouse.y);
                const inside = local.x >= 0 && local.y >= 0
                            && local.x <= cards.width && local.y <= cards.height;
                if (!inside) root.shown = false;
            }
        }

        // ── 3 cards lado a lado ───────────────────────────────────
        Row {
            id: cards
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10

            // ── Mês anterior (compacto) ───────────────────────────
            MiniMonthCard {
                month: root.prevMonthOf(root.displayedMonth, root.displayedYear).m
                year:  root.prevMonthOf(root.displayedMonth, root.displayedYear).y
                onClicked: root.gotoPrev()
            }

            // ── Mês atual (grande, com hora e edição) ─────────────
            MainMonthCard {}

            // ── Próximo mês (compacto) ────────────────────────────
            MiniMonthCard {
                month: root.nextMonthOf(root.displayedMonth, root.displayedYear).m
                year:  root.nextMonthOf(root.displayedMonth, root.displayedYear).y
                onClicked: root.gotoNext()
            }
        }
    }

    // ============================================================
    //  Component: MiniMonthCard (mês lateral compacto)
    // ============================================================
    component MiniMonthCard: Rectangle {
        id: mini
        property int month: 0
        property int year:  2026
        signal clicked()

        width:  200
        height: 240
        radius: 12
        color:  root.cSurface
        border.color: root.cBorder
        border.width: 1
        opacity: miniHover.containsMouse ? 1.0 : 0.9

        Behavior on opacity { NumberAnimation { duration: 150 } }

        MouseArea {
            id: miniHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: mini.clicked()
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 6

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: root.monthNames[mini.month] + " " + mini.year
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
                font.weight: Font.Medium
                color: root.cFgMuted
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: root.cBorder
            }

            MonthGrid {
                id: miniGrid
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                Layout.fillHeight: true
                month: mini.month
                year:  mini.year
                spacing: 1
                locale: Qt.locale("pt_BR")
                delegate: Text {
                    text: model.day
                    color: !model.visibleMonth ? root.cFgDimmer : root.cFgMuted
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 9
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }

    // ============================================================
    //  Component: MainMonthCard (mês atual grande)
    // ============================================================
    component MainMonthCard: Rectangle {
        id: main
        width:  340
        height: 420
        radius: 14
        color:  root.cSurface
        border.color: root.cBorder
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 8

            // ── Header: ←  Mês ▼  Ano(editável)  → ────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                // Seta anterior
                Rectangle {
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    radius: 8
                    color: leftHover.containsMouse ? root.cElev : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: "◀"
                        color: root.cFg
                        font.pixelSize: 12
                    }
                    MouseArea {
                        id: leftHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.gotoPrev()
                    }
                }

                // Nome do mês (clicável → dropdown)
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 28
                    radius: 8
                    color: monthHover.containsMouse ? root.cElev : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: root.monthNames[root.displayedMonth] + " ▾"
                        color: root.cFg
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        font.weight: Font.Bold
                    }
                    MouseArea {
                        id: monthHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: monthMenu.open()
                    }

                    // Dropdown de meses
                    Menu {
                        id: monthMenu
                        Repeater {
                            model: root.monthNames
                            MenuItem {
                                text: modelData
                                onTriggered: root.displayedMonth = index
                            }
                        }
                    }
                }

                // Ano editável
                Rectangle {
                    Layout.preferredWidth: 70
                    Layout.preferredHeight: 28
                    radius: 8
                    color: yearField.activeFocus || yearHover.containsMouse
                           ? root.cElev : "transparent"
                    border.color: yearField.activeFocus ? root.cAccent : "transparent"
                    border.width: 1

                    TextField {
                        id: yearField
                        anchors.fill: parent
                        anchors.margins: 2
                        text: root.displayedYear.toString()
                        color: root.cFg
                        background: null
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        horizontalAlignment: TextInput.AlignHCenter
                        verticalAlignment: TextInput.AlignVCenter
                        selectByMouse: true
                        inputMethodHints: Qt.ImhDigitsOnly
                        validator: IntValidator { bottom: 1900; top: 9999 }

                        onEditingFinished: {
                            const parsed = parseInt(text, 10);
                            if (!isNaN(parsed) && parsed >= 1900 && parsed <= 9999)
                                root.displayedYear = parsed;
                            else
                                text = root.displayedYear.toString();
                        }

                        Keys.onEscapePressed: {
                            text = root.displayedYear.toString();
                            focus = false;
                        }
                    }

                    MouseArea {
                        id: yearHover
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                    }
                }

                // Seta próxima
                Rectangle {
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    radius: 8
                    color: rightHover.containsMouse ? root.cElev : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: "▶"
                        color: root.cFg
                        font.pixelSize: 12
                    }
                    MouseArea {
                        id: rightHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.gotoNext()
                    }
                }
            }

            // ── Hora grande (só se visualizando o mês atual) ──────
            Text {
                Layout.alignment: Qt.AlignHCenter
                visible: root.displayedMonth === root.now.getMonth()
                      && root.displayedYear  === root.now.getFullYear()
                text: Qt.formatDateTime(root.now, "HH:mm")
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 48
                font.weight: Font.Bold
                color: root.cAccent
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                visible: root.displayedMonth === root.now.getMonth()
                      && root.displayedYear  === root.now.getFullYear()
                text: Qt.formatDate(root.now, "dddd, dd MMMM")
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
                color: root.cFgMuted
            }

            // ── Botão "Hoje" (só aparece se navegando outro mês) ──
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredHeight: 26
                Layout.preferredWidth: 90
                visible: !(root.displayedMonth === root.now.getMonth()
                        && root.displayedYear === root.now.getFullYear())
                radius: 13
                color: todayHover.containsMouse ? root.cAccent : root.cElev
                Text {
                    anchors.centerIn: parent
                    text: "Hoje"
                    color: todayHover.containsMouse ? root.cBg : root.cFg
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                    font.weight: Font.Bold
                }
                MouseArea {
                    id: todayHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.gotoToday()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: root.cBorder
            }

            // ── Calendário do mês visualizado ─────────────────────
            MonthGrid {
                id: mainGrid
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                Layout.fillHeight: true
                month: root.displayedMonth
                year:  root.displayedYear
                spacing: 4
                locale: Qt.locale("pt_BR")
                delegate: Item {
                    id: dayCell
                    implicitWidth: 32
                    implicitHeight: 28
                    property bool isToday: model.visibleMonth
                                        && model.day === root.now.getDate()
                                        && root.displayedMonth === root.now.getMonth()
                                        && root.displayedYear === root.now.getFullYear()
                    property bool hovered: dayHover.containsMouse && model.visibleMonth

                    // Halo/glow externo (só hoje)
                    Rectangle {
                        visible: dayCell.isToday
                        anchors.centerIn: parent
                        width:  parent.implicitHeight + 4
                        height: parent.implicitHeight + 4
                        radius: width / 2
                        color: "transparent"
                        border.color: root.cAccent
                        border.width: 1
                        opacity: 0.45
                    }

                    // Círculo principal
                    Rectangle {
                        anchors.centerIn: parent
                        width:  dayCell.implicitHeight - 4
                        height: dayCell.implicitHeight - 4
                        radius: width / 2
                        color: dayCell.isToday  ? root.cAccent
                             : dayCell.hovered  ? root.cElev
                             : "transparent"
                        border.color: (dayCell.hovered && !dayCell.isToday) ? root.cAccent : "transparent"
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 120 } }

                        // Pulse sutil no "hoje"
                        SequentialAnimation on scale {
                            running: dayCell.isToday
                            loops: Animation.Infinite
                            NumberAnimation { from: 1.0; to: 1.06; duration: 1200; easing.type: Easing.InOutSine }
                            NumberAnimation { from: 1.06; to: 1.0; duration: 1200; easing.type: Easing.InOutSine }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: model.day
                        color: {
                            if (!model.visibleMonth)  return root.cFgDimmer;
                            if (dayCell.isToday)      return root.cBg;
                            if (dayCell.hovered)      return root.cAccent;
                            return root.cFg;
                        }
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        font.weight: (dayCell.isToday || dayCell.hovered) ? Font.Bold : Font.Normal
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    MouseArea {
                        id: dayHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: model.visibleMonth ? Qt.PointingHandCursor : Qt.ArrowCursor
                        acceptedButtons: Qt.LeftButton
                    }
                }
            }
        }
    }
}
