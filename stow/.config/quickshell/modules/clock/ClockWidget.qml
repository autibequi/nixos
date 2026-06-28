// ClockWidget — painel Walker-style: info copiável (esq) + calendário scroll (dir)
// Toggle via: qs ipc call clock toggle / open / close

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root
    property bool shown: false

    readonly property int shellW: 820
    readonly property int shellH: 540
    readonly property int leftW: 300

    // Tipografia — escala única pro painel
    readonly property int fontClock:   42
    readonly property int fontWeekday: 14
    readonly property int fontLabel:   11
    readonly property int fontValue:   14
    readonly property int fontHint:    12
    readonly property int fontMonth:   20
    readonly property int fontDay:     16
    readonly property int fontBadge:   12
    readonly property int fontIcon:    13
    readonly property int rowH:        40
    readonly property int dayCellH:    42
    readonly property int dayCellMinW: 46

    // ── Tema Walker / neon ────────────────────────────────────────
    readonly property color cBg:       "#0a0e14"
    readonly property color cSurface:  "#1a1f29"
    readonly property color cElev:     "#2a2f3a"
    readonly property color cBorder:   "#2d3748"
    readonly property color cFg:       "#e6e6e6"
    readonly property color cFgMuted:  "#9ca3af"
    readonly property color cFgDimmer: "#4a5568"
    readonly property color cAccent:   "#00d4ff"

    readonly property var monthNames: [
        "Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
        "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"
    ]

    readonly property int scrollPast: 12
    readonly property int scrollFuture: 12

    property date now: new Date()
    property var monthList: []
    property string timezoneName: ""
    property string copiedHint: ""

    readonly property var locale: Qt.locale("pt_BR")

    readonly property var weekdayNames: [
        "domingo", "segunda-feira", "terça-feira", "quarta-feira",
        "quinta-feira", "sexta-feira", "sábado"
    ]

    function longDateText(d) {
        return root.weekdayNames[d.getDay()] + ", "
             + d.getDate() + " de "
             + root.monthNames[d.getMonth()] + " de "
             + d.getFullYear();
    }

    function pad2(n) {
        return n.toString().padStart(2, "0");
    }

    function isoDate(d) {
        return d.getFullYear() + "-" + pad2(d.getMonth() + 1) + "-" + pad2(d.getDate());
    }

    function brDate(d) {
        return pad2(d.getDate()) + "/" + pad2(d.getMonth() + 1) + "/" + d.getFullYear();
    }

    function dateTimeText(d) {
        return root.isoDate(d) + " " + root.pad2(d.getHours()) + ":"
             + root.pad2(d.getMinutes()) + ":" + root.pad2(d.getSeconds());
    }

    function timeText(d) {
        return root.pad2(d.getHours()) + ":" + root.pad2(d.getMinutes());
    }

    function timeSecondsText(d) {
        return root.timeText(d) + ":" + root.pad2(d.getSeconds());
    }

    function buildMonthList() {
        const list = [];
        let m = root.now.getMonth() - root.scrollPast;
        let y = root.now.getFullYear();
        while (m < 0) {
            m += 12;
            y -= 1;
        }
        const total = root.scrollPast + root.scrollFuture + 1;
        for (let i = 0; i < total; i++) {
            list.push({ month: m, year: y });
            m += 1;
            if (m > 11) {
                m = 0;
                y += 1;
            }
        }
        return list;
    }

    function isoWeekInfo(d) {
        const date = new Date(d.getTime());
        date.setHours(0, 0, 0, 0);
        date.setDate(date.getDate() + 4 - (date.getDay() || 7));
        const yearStart = new Date(date.getFullYear(), 0, 1);
        const week = Math.ceil((((date - yearStart) / 86400000) + 1) / 7);
        return { week: week, year: date.getFullYear() };
    }

    function dayOfYear(d) {
        const start = new Date(d.getFullYear(), 0, 0);
        return Math.floor((d - start) / 86400000);
    }

    function copyText(text, hint) {
        if (!text || text.length === 0) return;
        const safe = text.replace(/'/g, "'\\''");
        Quickshell.execDetached(["sh", "-c", "printf '%s' '" + safe + "' | wl-copy"]);
        root.copiedHint = hint;
        copyHintTimer.restart();
    }

    function formatIsoDate(y, m, day) {
        return y + "-" + pad2(m + 1) + "-" + pad2(day);
    }

    function openPanel() {
        root.now = new Date();
        root.monthList = root.buildMonthList();
        root.shown = true;
        tzProc.running = true;
        scrollToToday.restart();
    }

    function closePanel() {
        root.shown = false;
    }

    function togglePanel() {
        if (root.shown) root.closePanel();
        else root.openPanel();
    }

    Timer {
        id: tick
        interval: 1000
        running: root.shown
        repeat: true
        onTriggered: root.now = new Date()
    }

    Timer {
        id: copyHintTimer
        interval: 1600
        onTriggered: root.copiedHint = ""
    }

    Timer {
        id: scrollToToday
        interval: 120
        repeat: false
        onTriggered: calList.positionViewAtIndex(root.scrollPast, ListView.Center)
    }

    Process {
        id: tzProc
        running: false
        command: ["timedatectl", "show", "-p", "Timezone", "--value"]
        stdout: StdioCollector {
            onStreamFinished: {
                const tz = text.trim();
                root.timezoneName = tz.length > 0 ? tz : "local";
            }
        }
    }

    IpcHandler {
        target: "clock"
        function toggle(): void { root.togglePanel() }
        function open(): void { root.openPanel() }
        function close(): void { root.closePanel() }
    }

    PanelWindow {
        id: popup
        visible: root.shown

        anchors { left: true; right: true; bottom: true }
        margins { bottom: 42 }

        implicitWidth: root.shellW
        implicitHeight: root.shellH
        exclusiveZone: 0
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        Shortcut {
            sequences: ["Escape"]
            enabled: root.shown
            onActivated: root.closePanel()
        }

        MouseArea {
            anchors.fill: parent
            z: -1
            onClicked: function(mouse) {
                const local = mapToItem(shell, mouse.x, mouse.y);
                if (local.x < 0 || local.y < 0 || local.x > shell.width || local.y > shell.height)
                    root.closePanel();
            }
        }

        Rectangle {
            id: shell
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.shellW
            height: root.shellH
            radius: 20
            color: root.cBg
            border.color: root.cBorder
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                // ── Esquerda ──────────────────────────────────────
                Rectangle {
                    Layout.preferredWidth: root.leftW
                    Layout.fillHeight: true
                    radius: 14
                    color: root.cSurface
                    border.color: root.cBorder
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 10

                        Text {
                            Layout.fillWidth: true
                            text: root.timeSecondsText(root.now)
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: root.fontClock
                            font.weight: Font.Bold
                            color: root.cAccent
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.weekdayNames[root.now.getDay()]
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: root.fontWeekday
                            color: root.cFgMuted
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: root.cBorder
                        }

                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                            ColumnLayout {
                                width: parent.width
                                spacing: 5

                                CopyRow { Layout.fillWidth: true; label: "Hora"; value: root.timeText(root.now) }
                                CopyRow { Layout.fillWidth: true; label: "Data"; value: root.brDate(root.now) }
                                CopyRow { Layout.fillWidth: true; label: "Data completa"; value: root.longDateText(root.now) }
                                CopyRow { Layout.fillWidth: true; label: "ISO"; value: root.isoDate(root.now) }
                                CopyRow { Layout.fillWidth: true; label: "Data e hora"; value: root.dateTimeText(root.now) }
                                CopyRow {
                                    Layout.fillWidth: true
                                    label: "Semana ISO"
                                    value: {
                                        const w = root.isoWeekInfo(root.now);
                                        return "W" + root.pad2(w.week) + " · " + w.year;
                                    }
                                }
                                CopyRow {
                                    Layout.fillWidth: true
                                    label: "Dia do ano"
                                    value: root.dayOfYear(root.now).toString() + " / 365"
                                    copyValue: root.dayOfYear(root.now).toString()
                                }
                                CopyRow {
                                    Layout.fillWidth: true
                                    label: "Fuso horário"
                                    value: root.timezoneName.length > 0 ? root.timezoneName : "local"
                                }
                                CopyRow {
                                    Layout.fillWidth: true
                                    label: "Unix"
                                    value: Math.floor(root.now.getTime() / 1000).toString()
                                }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            Layout.preferredHeight: root.copiedHint.length > 0 ? implicitHeight : 0
                            visible: root.copiedHint.length > 0
                            text: "Copiado · " + root.copiedHint
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: root.fontHint
                            color: root.cAccent
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }

                // ── Direita: calendário ───────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 14
                    color: root.cSurface
                    border.color: root.cBorder
                    border.width: 1
                    clip: true

                    ScrollView {
                        id: calScroll
                        anchors.fill: parent
                        anchors.margins: 12
                        clip: true
                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                        ListView {
                            id: calList
                            width: calScroll.availableWidth
                            spacing: 20
                            model: root.monthList
                            boundsBehavior: Flickable.StopAtBounds
                            cacheBuffer: 800

                            delegate: Item {
                                id: monthWrap
                                width: calList.width
                                height: monthCard.implicitHeight

                                ScrollMonthCard {
                                    id: monthCard
                                    width: monthWrap.width
                                    month: root.monthList[index].month
                                    year: root.monthList[index].year
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    component CopyRow: Rectangle {
        id: row
        property string label: ""
        property string value: ""
        property string copyValue: row.value

        Layout.preferredHeight: root.rowH
        radius: 8
        color: rowHover.containsMouse ? Qt.rgba(0, 0.831, 1, 0.10) : "transparent"
        border.color: rowHover.containsMouse ? Qt.rgba(0, 0.831, 1, 0.28) : "transparent"
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 6

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: row.label
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: root.fontLabel
                    color: root.cFgMuted
                }
                Text {
                    text: row.value
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: root.fontValue
                    font.weight: Font.Medium
                    color: rowHover.containsMouse ? root.cAccent : root.cFg
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            Text {
                text: "\uf0c5"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: root.fontIcon
                color: rowHover.containsMouse ? root.cAccent : root.cFgDimmer
            }
        }

        MouseArea {
            id: rowHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.copyText(row.copyValue, row.label)
        }
    }

    component ScrollMonthCard: Column {
        id: card
        property int month: 0
        property int year: 2026
        property int gridSpacing: 6
        property bool isCurrentMonth: card.month === root.now.getMonth()
                                    && card.year === root.now.getFullYear()
        property real cellW: {
            if (width <= 0) return root.dayCellMinW;
            return Math.max(root.dayCellMinW, Math.floor((width - gridSpacing * 6) / 7));
        }
        property real gridContentW: cellW * 7 + gridSpacing * 6
        property int cellH: Math.max(root.dayCellH, Math.round(cellW * 0.82))

        spacing: 10
        width: parent ? parent.width : 400

        // Cabeçalho do mês — título centralizado, badge à direita
        Item {
            width: card.width
            height: 30

            Text {
                anchors.centerIn: parent
                text: root.monthNames[card.month] + " " + card.year
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: root.fontMonth
                font.weight: Font.Bold
                color: card.isCurrentMonth ? root.cAccent : root.cFg
            }

            Rectangle {
                visible: card.isCurrentMonth
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                radius: 7
                color: root.cAccent
                implicitWidth: hojeLabel.implicitWidth + 12
                implicitHeight: hojeLabel.implicitHeight + 6

                Text {
                    id: hojeLabel
                    anchors.centerIn: parent
                    text: "hoje"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: root.fontBadge
                    font.weight: Font.Bold
                    color: root.cBg
                }
            }
        }

        // Grid centralizado e células preenchendo a largura disponível
        Item {
            width: card.width
            height: grid.implicitHeight

            MonthGrid {
                id: grid
                anchors.horizontalCenter: parent.horizontalCenter
                width: card.gridContentW
                month: card.month
                year: card.year
                spacing: card.gridSpacing
                locale: root.locale

                delegate: Item {
                    implicitWidth: card.cellW
                    implicitHeight: card.cellH

                    property bool inMonth: model.visibleMonth
                    property bool isToday: model.visibleMonth
                                        && model.day === root.now.getDate()
                                        && card.isCurrentMonth
                    property bool hovered: dayHover.containsMouse && model.visibleMonth

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 2
                        radius: 8
                        color: isToday ? root.cAccent : hovered ? root.cElev : "transparent"
                        border.color: hovered && !isToday ? root.cAccent : "transparent"
                        border.width: 1
                    }

                    Text {
                        anchors.centerIn: parent
                        text: model.day
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: root.fontDay
                        font.weight: (isToday || hovered) ? Font.Bold : Font.Medium
                        color: {
                            if (!inMonth) return root.cFgDimmer;
                            if (isToday) return root.cBg;
                            if (hovered) return root.cAccent;
                            return root.cFg;
                        }
                    }

                    MouseArea {
                        id: dayHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: model.visibleMonth ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            if (!model.visibleMonth) return;
                            root.copyText(root.formatIsoDate(card.year, card.month, model.day),
                                          root.formatIsoDate(card.year, card.month, model.day));
                        }
                    }
                }
            }
        }

        Rectangle {
            width: card.width
            height: 1
            color: root.cBorder
        }
    }
}
