// GithubWidget — sidepanel GitHub + Jira (mocado)
// Toggle: qs ipc call github toggle

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root

    property bool shown: false

    // ── GitHub mock ───────────────────────────────────────────────
    readonly property var myPrs: [
        { number: 843, repo: "coruja",   title: "[FUK2-12924] ranking de numerais na busca",    status: "review",   statusLabel: "Aguardando", ci: "passing", updatedAt: "há 2h", stale: false, url: "https://github.com/estrategiahq/coruja/pull/843" },
        { number: 840, repo: "coruja",   title: "[FUK2-13238] endpoint POST busca ecommerce",   status: "approved", statusLabel: "Aprovado",   ci: "passing", updatedAt: "há 6h", stale: false, url: "https://github.com/estrategiahq/coruja/pull/840" },
        { number: 834, repo: "coruja",   title: "[FUK2-13201] timeout no refresh de sessão",    status: "changes",  statusLabel: "Mudanças",   ci: "failing", updatedAt: "há 1d", stale: false, url: "https://github.com/estrategiahq/coruja/pull/834" }
    ]

    readonly property var toReview: [
        { number: 841, repo: "coruja",   title: "[FUK2-13432] oculta contadores pendência",     author: "pedrohlcastro", ci: "passing", updatedAt: "há 4h", stale: false, url: "https://github.com/estrategiahq/coruja/pull/841" },
        { number: 836, repo: "coruja",   title: "[FUK2-13429] fix 500 classificação batch ldi", author: "molina",        ci: "passing", updatedAt: "há 1d", stale: true,  url: "https://github.com/estrategiahq/coruja/pull/836" },
        { number: 835, repo: "accounts", title: "[FUK2-13201] rotate refresh token endpoint",   author: "william",       ci: "failing", updatedAt: "há 2d", stale: true,  url: "https://github.com/estrategiahq/coruja/pull/835" }
    ]

    // ── Jira mock ─────────────────────────────────────────────────
    readonly property var jiraColumns: [
        { id: "backlog", label: "Backlog",   count: 8 },
        { id: "todo",    label: "A fazer",   count: 5 },
        { id: "doing",   label: "Fazendo",   count: 2 },
        { id: "review",  label: "Em review", count: 1 },
        { id: "done",    label: "Feito",     count: 4 }
    ]

    readonly property var jiraActive: [
        { key: "FUK2-12924", summary: "Ranking de numerais na busca",         status: "doing",  updatedAt: "há 2h", url: "https://estrategia.atlassian.net/browse/FUK2-12924" },
        { key: "FUK2-13201", summary: "Timeout no refresh de sessão",         status: "doing",  updatedAt: "há 1d", url: "https://estrategia.atlassian.net/browse/FUK2-13201" },
        { key: "FUK2-13239", summary: "Filtros e colunas de itens no search", status: "review", updatedAt: "há 3h", url: "https://estrategia.atlassian.net/browse/FUK2-13239" }
    ]

    // ── cores ─────────────────────────────────────────────────────
    readonly property color cBg:      "#0a0e14"
    readonly property color cSurface: "#1a1f29"
    readonly property color cElev:    "#2a2f3a"
    readonly property color cBorder:  "#2d3748"
    readonly property color cFg:      "#e6e6e6"
    readonly property color cFgMuted: "#9ca3af"
    readonly property color cAccent:  "#00d4ff"
    readonly property color cGreen:   "#4ade80"
    readonly property color cRed:     "#f87171"
    readonly property color cYellow:  "#fbbf24"
    readonly property color cOrange:  "#fb923c"
    readonly property color cPurple:  "#a78bfa"
    readonly property color cBlue:    "#60a5fa"

    function jiraColumnColor(colId) {
        if (colId === "doing")  return root.cYellow
        if (colId === "review") return root.cAccent
        if (colId === "todo")   return root.cBlue
        if (colId === "done")   return root.cGreen
        return root.cFgMuted
    }

    function openPanel()  { root.shown = true  }
    function closePanel() { root.shown = false }
    function togglePanel() {
        if (root.shown) {
            root.closePanel()
        } else {
            root.openPanel()
        }
    }

    IpcHandler {
        target: "github"
        function toggle(): void { root.togglePanel() }
        function open():   void { root.openPanel()   }
        function close():  void { root.closePanel()  }
    }

    PanelWindow {
        visible: root.shown
        anchors { top: true; right: true; left: true; bottom: true }
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
                const local  = mapToItem(panel, mouse.x, mouse.y)
                const inside = local.x >= 0 && local.y >= 0
                            && local.x <= panel.width && local.y <= panel.height
                if (!inside) root.closePanel()
            }
        }

        Rectangle {
            id: panel
            anchors.top:         parent.top
            anchors.right:       parent.right
            anchors.topMargin:   10
            anchors.rightMargin: 10
            width:  420
            height: Math.min(860, hdr.height + content.implicitHeight + 28)
            radius: 14
            color:        root.cSurface
            border.color: root.cBorder
            border.width: 1

            // cabeçalho ──────────────────────────────────────────
            Item {
                id: hdr
                anchors { left: parent.left; right: parent.right; top: parent.top }
                anchors.leftMargin: 14; anchors.rightMargin: 14; anchors.topMargin: 14
                height: hdrRow.implicitHeight + 14

                RowLayout {
                    id: hdrRow
                    anchors { left: parent.left; right: parent.right }
                    spacing: 8

                    Text {
                        text: " Dev"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14; font.weight: Font.Bold
                        color: root.cAccent
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: "mock"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 9; color: root.cFgMuted; opacity: 0.5
                    }

                    Rectangle {
                        width: 22; height: 22; radius: 11
                        color: xma.containsMouse ? root.cElev : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: "✕"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12
                            color: xma.containsMouse ? root.cAccent : root.cFgMuted
                        }
                        MouseArea {
                            id: xma; anchors.fill: parent
                            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: root.closePanel()
                        }
                    }
                }

                Rectangle {
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                    height: 1; color: root.cBorder
                }
            }

            // lista scrollável ───────────────────────────────────
            Item {
                id: content
                anchors { left: parent.left; right: parent.right; top: hdr.bottom; bottom: parent.bottom }
                anchors.leftMargin: 10; anchors.rightMargin: 10
                anchors.topMargin: 6; anchors.bottomMargin: 8
                implicitHeight: Math.min(820 - hdr.height, listCol.implicitHeight + 12)

                Flickable {
                    anchors.fill: parent; clip: true
                    contentWidth: width; contentHeight: listCol.implicitHeight
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    Column {
                        id: listCol
                        width: parent.width
                        spacing: 4

                        // ── GitHub: meus PRs ──────────────────
                        SecLabel { width: listCol.width; secLabel: " Meus PRs";     secCount: root.myPrs.length    }
                        Repeater {
                            model: root.myPrs
                            PrCard {
                                required property var modelData
                                width: listCol.width
                                prNumber: modelData.number; prRepo: modelData.repo
                                prTitle: modelData.title; prStatus: modelData.status
                                prStatusLabel: modelData.statusLabel; prCi: modelData.ci
                                prUpdatedAt: modelData.updatedAt; prAuthor: ""
                                prStale: modelData.stale; prUrl: modelData.url
                            }
                        }

                        Item { width: 1; height: 4 }

                        // ── GitHub: para revisar ──────────────
                        SecLabel { width: listCol.width; secLabel: " Para revisar"; secCount: root.toReview.length }
                        Repeater {
                            model: root.toReview
                            PrCard {
                                required property var modelData
                                width: listCol.width
                                prNumber: modelData.number; prRepo: modelData.repo
                                prTitle: modelData.title; prStatus: "waiting"
                                prStatusLabel: "Aguardando"; prCi: modelData.ci
                                prUpdatedAt: modelData.updatedAt; prAuthor: modelData.author
                                prStale: modelData.stale; prUrl: modelData.url
                            }
                        }

                        // ── divisor ───────────────────────────
                        Item { width: 1; height: 8 }
                        Rectangle { width: listCol.width; height: 1; color: root.cBorder }
                        Item { width: 1; height: 4 }

                        // ── Jira: header + board ──────────────
                        SecLabel { width: listCol.width; secLabel: "󱃕 Jira · FUK2 Sprint 23"; secCount: root.jiraActive.length }

                        Flow {
                            width: listCol.width
                            spacing: 5

                            Repeater {
                                model: root.jiraColumns
                                delegate: Item {
                                    width:  colPill.width
                                    height: colPill.height

                                    property color colClr: root.jiraColumnColor(modelData.id)

                                    Rectangle {
                                        id: colPill
                                        width:  colTxt.implicitWidth + 12
                                        height: 20; radius: 10
                                        color:        Qt.rgba(colClr.r, colClr.g, colClr.b, 0.12)
                                        border.color: Qt.rgba(colClr.r, colClr.g, colClr.b, 0.40)
                                        border.width: 1

                                        Text {
                                            id: colTxt
                                            anchors.centerIn: parent
                                            text: modelData.label + " · " + modelData.count
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 9
                                            color: colClr
                                        }
                                    }
                                }
                            }
                        }

                        Item { width: 1; height: 2 }

                        // ── Jira: tickets ativos ──────────────
                        Repeater {
                            model: root.jiraActive
                            JiraCard {
                                required property var modelData
                                width: listCol.width
                                ticketKey:     modelData.key
                                ticketSummary: modelData.summary
                                ticketStatus:  modelData.status
                                ticketUpdated: modelData.updatedAt
                                ticketUrl:     modelData.url
                            }
                        }
                    }
                }
            }
        }
    }

    // ── componentes inline ─────────────────────────────────────────

    component SecLabel: Item {
        id: sl
        property string secLabel: ""
        property int    secCount: 0
        implicitHeight: 26

        RowLayout {
            anchors.fill: parent; anchors.leftMargin: 4; spacing: 6

            Text {
                text: sl.secLabel
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 10; font.weight: Font.Bold
                color: root.cFgMuted
            }

            Rectangle {
                width: slCnt.implicitWidth + 8; height: 15; radius: 7; color: root.cElev
                Text {
                    id: slCnt; anchors.centerIn: parent
                    text: sl.secCount.toString()
                    font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9; color: root.cFgMuted
                }
            }

            Item { Layout.fillWidth: true }
        }
    }

    component PrCard: Rectangle {
        id: pr

        property int    prNumber:      0
        property string prRepo:        ""
        property string prTitle:       ""
        property string prStatus:      "waiting"
        property string prStatusLabel: ""
        property string prCi:          "passing"
        property string prUpdatedAt:   ""
        property string prAuthor:      ""
        property bool   prStale:       false
        property string prUrl:         ""

        readonly property color statusClr: {
            if (pr.prStatus === "approved") return root.cGreen
            if (pr.prStatus === "changes")  return root.cOrange
            return root.cYellow
        }

        implicitHeight: prCol.implicitHeight + 18
        radius: 8
        color:        prMa.containsMouse ? Qt.rgba(0, 0.831, 1, 0.06) : root.cBg
        border.width: 1
        border.color: {
            if (prMa.containsMouse) return Qt.rgba(0, 0.831, 1, 0.28)
            if (pr.prStale)         return Qt.rgba(0.98, 0.573, 0.235, 0.45)
            return root.cBorder
        }

        Rectangle {
            visible: pr.prStale
            anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 8
            width: 7; height: 7; radius: 4; color: root.cOrange
        }

        Column {
            id: prCol
            anchors { left: parent.left; right: parent.right; top: parent.top }
            anchors.leftMargin: 10; anchors.rightMargin: 10; anchors.topMargin: 9
            spacing: 4

            RowLayout {
                width: parent.width; spacing: 6
                Text {
                    text: pr.prRepo + " #" + pr.prNumber
                    font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; color: root.cFgMuted
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: pr.prCi === "passing" ? "✓" : "✗"
                    font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; font.weight: Font.Bold
                    color: pr.prCi === "passing" ? root.cGreen : root.cRed
                }
                Rectangle {
                    width: prStLbl.implicitWidth + 10; height: 16; radius: 8
                    color:        Qt.rgba(pr.statusClr.r, pr.statusClr.g, pr.statusClr.b, 0.12)
                    border.color: Qt.rgba(pr.statusClr.r, pr.statusClr.g, pr.statusClr.b, 0.40)
                    border.width: 1
                    Text {
                        id: prStLbl; anchors.centerIn: parent
                        text: pr.prStatusLabel
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9; color: pr.statusClr
                    }
                }
            }

            Text {
                width: parent.width; text: pr.prTitle
                font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; font.weight: Font.Medium
                color: prMa.containsMouse ? root.cAccent : root.cFg; elide: Text.ElideRight
            }

            RowLayout {
                width: parent.width; spacing: 4
                Text {
                    visible: pr.prAuthor.length > 0
                    text: "@" + pr.prAuthor
                    font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; color: root.cFgMuted
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: pr.prUpdatedAt
                    font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; color: root.cFgMuted
                }
            }
        }

        MouseArea {
            id: prMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (pr.prUrl.length > 0) {
                    Quickshell.execDetached(["xdg-open", pr.prUrl])
                    root.closePanel()
                }
            }
        }
    }

    component JiraCard: Rectangle {
        id: jc

        property string ticketKey:     ""
        property string ticketSummary: ""
        property string ticketStatus:  "doing"
        property string ticketUpdated: ""
        property string ticketUrl:     ""

        readonly property color statusClr: root.jiraColumnColor(jc.ticketStatus)

        readonly property string statusLabel: {
            if (jc.ticketStatus === "doing")  return "Fazendo"
            if (jc.ticketStatus === "review") return "Em review"
            return jc.ticketStatus
        }

        implicitHeight: jcCol.implicitHeight + 18
        radius: 8
        color:        jcMa.containsMouse ? Qt.rgba(0, 0.831, 1, 0.06) : root.cBg
        border.width: 1
        border.color: jcMa.containsMouse ? Qt.rgba(0, 0.831, 1, 0.28) : root.cBorder

        Column {
            id: jcCol
            anchors { left: parent.left; right: parent.right; top: parent.top }
            anchors.leftMargin: 10; anchors.rightMargin: 10; anchors.topMargin: 9
            spacing: 4

            RowLayout {
                width: parent.width; spacing: 6
                Text {
                    text: jc.ticketKey
                    font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10
                    font.weight: Font.Bold; color: root.cAccent
                }
                Item { Layout.fillWidth: true }
                Rectangle {
                    width: jcStLbl.implicitWidth + 10; height: 16; radius: 8
                    color:        Qt.rgba(jc.statusClr.r, jc.statusClr.g, jc.statusClr.b, 0.12)
                    border.color: Qt.rgba(jc.statusClr.r, jc.statusClr.g, jc.statusClr.b, 0.40)
                    border.width: 1
                    Text {
                        id: jcStLbl; anchors.centerIn: parent
                        text: jc.statusLabel
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9; color: jc.statusClr
                    }
                }
            }

            Text {
                width: parent.width; text: jc.ticketSummary
                font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; font.weight: Font.Medium
                color: jcMa.containsMouse ? root.cAccent : root.cFg; elide: Text.ElideRight
            }

            Text {
                text: jc.ticketUpdated
                font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; color: root.cFgMuted
            }
        }

        MouseArea {
            id: jcMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (jc.ticketUrl.length > 0) {
                    Quickshell.execDetached(["xdg-open", jc.ticketUrl])
                    root.closePanel()
                }
            }
        }
    }
}
