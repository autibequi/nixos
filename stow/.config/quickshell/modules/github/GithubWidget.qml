// GithubWidget — sidepanel GitHub (real via gh)
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

    // ── GitHub (real via `gh api graphql`) ────────────────────────
    property var readyPrs: []
    property var myPrs:    []
    property var toReview: []

    readonly property string ghQuery: '{ mine: search(query: "is:open is:pr author:@me archived:false", type: ISSUE, first: 100) { nodes { ... on PullRequest { number title url updatedAt additions deletions labels(first: 5) { nodes { name color } } repository { name } reviewDecision commits(last: 1) { nodes { commit { statusCheckRollup { state } } } } } } } review: search(query: "is:open is:pr review-requested:@me archived:false", type: ISSUE, first: 100) { nodes { ... on PullRequest { number title url updatedAt additions deletions labels(first: 5) { nodes { name color } } author { login } repository { name } commits(last: 1) { nodes { commit { statusCheckRollup { state } } } } } } } }'

    function ghRelTime(iso) {
        const h = Math.floor((Date.now() - new Date(iso).getTime()) / 3600000)
        if (h < 1)  return "agora"
        if (h < 24) return "há " + h + "h"
        return "há " + Math.floor(h / 24) + "d"
    }
    function ghStale(iso) { return Date.now() - new Date(iso).getTime() > 2 * 86400000 }
    function ghCi(node) {
        const c = node.commits && node.commits.nodes && node.commits.nodes[0]
        const roll = c && c.commit && c.commit.statusCheckRollup
        if (!roll) return "passing"
        return (roll.state === "FAILURE" || roll.state === "ERROR") ? "failing" : "passing"
    }
    function ghStatus(node) {
        if (node.reviewDecision === "APPROVED")          return "approved"
        if (node.reviewDecision === "CHANGES_REQUESTED") return "changes"
        return "review"
    }
    function ghStatusLabel(s) {
        if (s === "approved") return "Aprovado"
        if (s === "changes")  return "Mudanças"
        return "Aguardando"
    }
    function ghMapMine(node) {
        const s = root.ghStatus(node)
        return { number: node.number, repo: node.repository.name, title: node.title,
                 status: s, statusLabel: root.ghStatusLabel(s), ci: root.ghCi(node),
                 updatedAt: root.ghRelTime(node.updatedAt), stale: root.ghStale(node.updatedAt), url: node.url,
                 additions: node.additions || 0, deletions: node.deletions || 0,
                 labels: (node.labels && node.labels.nodes) ? node.labels.nodes : [] }
    }
    function ghMapReview(node) {
        return { number: node.number, repo: node.repository.name, title: node.title,
                 author: node.author ? node.author.login : "", ci: root.ghCi(node),
                 updatedAt: root.ghRelTime(node.updatedAt), stale: root.ghStale(node.updatedAt), url: node.url,
                 additions: node.additions || 0, deletions: node.deletions || 0,
                 labels: (node.labels && node.labels.nodes) ? node.labels.nodes : [] }
    }

    Process {
        id: ghProc
        command: ["gh", "api", "graphql", "-f", "query=" + root.ghQuery]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(this.text).data
                    const byRecent = function(a, b) { return new Date(b.updatedAt).getTime() - new Date(a.updatedAt).getTime() }
                    const mapped  = (data.mine.nodes || []).slice().sort(byRecent).map(root.ghMapMine)
                    root.readyPrs = mapped.filter(function(p) { return p.status === "approved" })
                    root.myPrs    = mapped.filter(function(p) { return p.status !== "approved" })
                    root.toReview = (data.review.nodes || []).slice().sort(byRecent).map(root.ghMapReview)
                } catch (e) {
                    console.log("GithubWidget: falha ao parsear gh graphql:", e)
                }
            }
        }
    }

    function ghRefresh() { if (!ghProc.running) ghProc.running = true }

    Component.onCompleted: root.ghRefresh()

    Timer {
        interval: 180000; running: true; repeat: true
        onTriggered: root.ghRefresh()
    }

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

    function openPanel()  { root.shown = true; root.ghRefresh() }
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
            anchors.top:          parent.top
            anchors.bottom:       parent.bottom
            anchors.topMargin:    10
            anchors.bottomMargin: 10
            width:  1100
            radius: 14
            x: root.shown ? (parent.width - width - 10) : (parent.width + 10)
            color:        Qt.rgba(0.04, 0.055, 0.09, 0.90)
            border.color: Qt.rgba(1, 1, 1, 0.07)
            border.width: 1

            Behavior on x {
                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
            }

            // auto-hide: some após 3s sem o mouse sobre o painel
            HoverHandler { id: panelHover }
            Timer {
                interval: 3000; repeat: true
                running: root.shown && !panelHover.hovered
                onTriggered: root.closePanel()
            }

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
                        text: " GitHub"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 17; font.weight: Font.Bold
                        color: root.cAccent
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: 22; height: 22; radius: 11
                        color: xma.containsMouse ? root.cElev : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: "✕"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 15
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

            // duas colunas (scroll independente) ─────────────────
            RowLayout {
                id: content
                anchors { left: parent.left; right: parent.right; top: hdr.bottom; bottom: parent.bottom }
                anchors.leftMargin: 10; anchors.rightMargin: 10
                anchors.topMargin: 6; anchors.bottomMargin: 8
                spacing: 10

                // ── coluna: Prontos pra mergear ───────────────
                ColumnLayout {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    spacing: 4
                    SecLabel { Layout.fillWidth: true; secLabel: "󰄬 Prontos"; secCount: root.readyPrs.length; secAccent: root.cGreen }
                    Flickable {
                        id: readyFlick
                        Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                        contentWidth: width; contentHeight: readyCol.implicitHeight
                        flickDeceleration: 10000; boundsBehavior: Flickable.StopAtBounds
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                        WheelHandler {
                            onWheel: (e) => {
                                const max = Math.max(0, readyFlick.contentHeight - readyFlick.height)
                                readyFlick.contentY = Math.max(0, Math.min(max, readyFlick.contentY - e.angleDelta.y * 4))
                            }
                        }
                        Column {
                            id: readyCol
                            width: parent.width; spacing: 4
                            Repeater {
                                model: root.readyPrs
                                PrCard {
                                    required property var modelData
                                    width: readyCol.width
                                    prNumber: modelData.number; prRepo: modelData.repo
                                    prTitle: modelData.title; prStatus: modelData.status
                                    prStatusLabel: modelData.statusLabel; prCi: modelData.ci
                                    prUpdatedAt: modelData.updatedAt; prAuthor: ""
                                    prStale: modelData.stale; prUrl: modelData.url
                                    prAdditions: modelData.additions; prDeletions: modelData.deletions
                                    prLabels: modelData.labels
                                }
                            }
                            Text {
                                visible: root.readyPrs.length === 0
                                text: "nenhum PR pronto"
                                font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14
                                color: root.cFgMuted; leftPadding: 6
                            }
                        }
                    }
                }

                // ── coluna: Meus PRs ──────────────────────────
                ColumnLayout {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    spacing: 4
                    SecLabel { Layout.fillWidth: true; secLabel: " Meus PRs"; secCount: root.myPrs.length }
                    Flickable {
                        id: mineFlick
                        Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                        contentWidth: width; contentHeight: mineCol.implicitHeight
                        flickDeceleration: 10000; boundsBehavior: Flickable.StopAtBounds
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                        WheelHandler {
                            onWheel: (e) => {
                                const max = Math.max(0, mineFlick.contentHeight - mineFlick.height)
                                mineFlick.contentY = Math.max(0, Math.min(max, mineFlick.contentY - e.angleDelta.y * 4))
                            }
                        }
                        Column {
                            id: mineCol
                            width: parent.width; spacing: 4
                            Repeater {
                                model: root.myPrs
                                PrCard {
                                    required property var modelData
                                    width: mineCol.width
                                    prNumber: modelData.number; prRepo: modelData.repo
                                    prTitle: modelData.title; prStatus: modelData.status
                                    prStatusLabel: modelData.statusLabel; prCi: modelData.ci
                                    prUpdatedAt: modelData.updatedAt; prAuthor: ""
                                    prStale: modelData.stale; prUrl: modelData.url
                                    prAdditions: modelData.additions; prDeletions: modelData.deletions
                                    prLabels: modelData.labels
                                }
                            }
                        }
                    }
                }

                // ── coluna: Para revisar ──────────────────────
                ColumnLayout {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    spacing: 4
                    SecLabel { Layout.fillWidth: true; secLabel: " Para revisar"; secCount: root.toReview.length }
                    Flickable {
                        id: reviewFlick
                        Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                        contentWidth: width; contentHeight: reviewCol.implicitHeight
                        flickDeceleration: 10000; boundsBehavior: Flickable.StopAtBounds
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                        WheelHandler {
                            onWheel: (e) => {
                                const max = Math.max(0, reviewFlick.contentHeight - reviewFlick.height)
                                reviewFlick.contentY = Math.max(0, Math.min(max, reviewFlick.contentY - e.angleDelta.y * 4))
                            }
                        }
                        Column {
                            id: reviewCol
                            width: parent.width; spacing: 4
                            Repeater {
                                model: root.toReview
                                PrCard {
                                    required property var modelData
                                    width: reviewCol.width
                                    prNumber: modelData.number; prRepo: modelData.repo
                                    prTitle: modelData.title; prStatus: "waiting"
                                    prStatusLabel: "Aguardando"; prCi: modelData.ci
                                    prUpdatedAt: modelData.updatedAt; prAuthor: modelData.author
                                    prStale: modelData.stale; prUrl: modelData.url
                                    prAdditions: modelData.additions; prDeletions: modelData.deletions
                                    prLabels: modelData.labels
                                }
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
        property string secLabel:  ""
        property int    secCount:  0
        property color  secAccent: root.cFgMuted
        implicitHeight: 26

        RowLayout {
            anchors.fill: parent; anchors.leftMargin: 4; spacing: 6

            Text {
                text: sl.secLabel
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13; font.weight: Font.Bold
                color: sl.secAccent
            }

            Rectangle {
                width: slCnt.implicitWidth + 8; height: 15; radius: 7
                color: Qt.rgba(sl.secAccent.r, sl.secAccent.g, sl.secAccent.b, 0.15)
                Text {
                    id: slCnt; anchors.centerIn: parent
                    text: sl.secCount.toString()
                    font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; color: sl.secAccent
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
        property int    prAdditions:   0
        property int    prDeletions:   0
        property var    prLabels:      []

        readonly property color statusClr: {
            if (pr.prStatus === "approved") return root.cGreen
            if (pr.prStatus === "changes")  return root.cOrange
            return root.cYellow
        }
        // faixa lateral prioriza atenção: CI quebrado pinta vermelho, senão estado do review
        readonly property color stripeClr: pr.prCi === "failing" ? root.cRed : pr.statusClr
        // prefixo entre colchetes ([FUK2-123], [FUK2 12038]…) vai isolado na 1ª linha
        readonly property var prTitleParts: {
            const m = pr.prTitle.match(/^\s*(\[[^\]]*\])\s*([\s\S]*)$/)
            if (!m) return { prefix: "[FUK2-???]", body: pr.prTitle }
            return { prefix: m[1], body: m[2].replace(/^[\s:·\-–—]+/, "") }
        }

        implicitHeight: prCol.implicitHeight + 18
        radius: 8
        clip: true
        color:        prMa.containsMouse ? Qt.rgba(0, 0.831, 1, 0.06) : root.cBg
        border.width: 1
        border.color: {
            if (prMa.containsMouse) return Qt.rgba(0, 0.831, 1, 0.28)
            if (pr.prStale)         return Qt.rgba(0.98, 0.573, 0.235, 0.45)
            return root.cBorder
        }

        Rectangle {
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            width: 3
            color: pr.stripeClr
        }

        Column {
            id: prCol
            anchors { left: parent.left; right: parent.right; top: parent.top }
            anchors.leftMargin: 12; anchors.rightMargin: 10; anchors.topMargin: 9
            spacing: 3

            // 1ª linha: prefixo [..] (se houver) à esquerda · CI à direita
            RowLayout {
                width: parent.width; spacing: 6
                Text {
                    text: pr.prTitleParts.prefix
                    font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14; font.weight: Font.Bold
                    color: root.cAccent
                }
                Item { Layout.fillWidth: true }
                Repeater {
                    model: pr.prLabels
                    Rectangle {
                        required property var modelData
                        readonly property color lc: Qt.color("#" + (modelData.color || "555555"))
                        radius: 4
                        Layout.alignment: Qt.AlignVCenter
                        width: lblT.implicitWidth + 8; height: 14
                        color:        Qt.rgba(lc.r, lc.g, lc.b, 0.18)
                        border.color: Qt.rgba(lc.r, lc.g, lc.b, 0.55)
                        border.width: 1
                        Text {
                            id: lblT; anchors.centerIn: parent
                            text: modelData.name
                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12
                            color: Qt.rgba(lc.r, lc.g, lc.b, 1)
                        }
                    }
                }
                Rectangle {
                    visible: pr.prStale
                    Layout.alignment: Qt.AlignVCenter
                    width: 7; height: 7; radius: 4; color: root.cOrange
                }
                Text {
                    text: pr.prCi === "passing" ? "✓" : "✗"
                    font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14; font.weight: Font.Bold
                    color: pr.prCi === "passing" ? root.cGreen : root.cRed
                }
            }

            // 2ª linha: corpo do título (ou título inteiro quando não há prefixo)
            Text {
                width: parent.width
                text: pr.prTitleParts.body
                font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16; font.weight: Font.Medium
                color: prMa.containsMouse ? root.cAccent : root.cFg; elide: Text.ElideRight
            }

            Item { width: 1; height: 4 }

            // rodapé — meta + tags à esquerda, criado em à direita
            RowLayout {
                width: parent.width; spacing: 5
                Text {
                    visible: pr.prAuthor.length > 0
                    text: "@" + pr.prAuthor + "  ·"
                    font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; color: root.cFgMuted
                }
                Text {
                    text: pr.prRepo + " #" + pr.prNumber
                    font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; color: root.cFgMuted
                }
                Text {
                    visible: pr.prAdditions > 0 || pr.prDeletions > 0
                    text: "·"
                    font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; color: root.cFgMuted
                }
                Text {
                    visible: pr.prAdditions > 0
                    text: "+" + pr.prAdditions
                    font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; color: root.cGreen
                }
                Text {
                    visible: pr.prDeletions > 0
                    text: "-" + pr.prDeletions
                    font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; color: root.cRed
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: pr.prUpdatedAt
                    font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; color: root.cFgMuted
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

}
