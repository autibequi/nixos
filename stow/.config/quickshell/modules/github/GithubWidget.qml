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
    property var myPrs:   []
    property var toReview: []

    readonly property string ghQuery: '{ mine: search(query: "is:open is:pr author:@me archived:false", type: ISSUE, first: 20) { nodes { ... on PullRequest { number title url updatedAt repository { name } reviewDecision commits(last: 1) { nodes { commit { statusCheckRollup { state } } } } } } } review: search(query: "is:open is:pr review-requested:@me archived:false", type: ISSUE, first: 20) { nodes { ... on PullRequest { number title url updatedAt author { login } repository { name } commits(last: 1) { nodes { commit { statusCheckRollup { state } } } } } } } }'

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
                 updatedAt: root.ghRelTime(node.updatedAt), stale: root.ghStale(node.updatedAt), url: node.url }
    }
    function ghMapReview(node) {
        return { number: node.number, repo: node.repository.name, title: node.title,
                 author: node.author ? node.author.login : "", ci: root.ghCi(node),
                 updatedAt: root.ghRelTime(node.updatedAt), stale: root.ghStale(node.updatedAt), url: node.url }
    }

    Process {
        id: ghProc
        command: ["gh", "api", "graphql", "-f", "query=" + root.ghQuery]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(this.text).data
                    root.myPrs   = (data.mine.nodes   || []).map(root.ghMapMine)
                    root.toReview = (data.review.nodes || []).map(root.ghMapReview)
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
            anchors.right:        parent.right
            anchors.topMargin:    10
            anchors.bottomMargin: 10
            anchors.rightMargin:  10
            width:  820
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
                        text: " GitHub"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14; font.weight: Font.Bold
                        color: root.cAccent
                    }

                    Item { Layout.fillWidth: true }

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

            // duas colunas (scroll independente) ─────────────────
            RowLayout {
                id: content
                anchors { left: parent.left; right: parent.right; top: hdr.bottom; bottom: parent.bottom }
                anchors.leftMargin: 10; anchors.rightMargin: 10
                anchors.topMargin: 6; anchors.bottomMargin: 8
                spacing: 10

                // ── coluna: Meus PRs ──────────────────────────
                ColumnLayout {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    spacing: 4
                    SecLabel { Layout.fillWidth: true; secLabel: " Meus PRs"; secCount: root.myPrs.length }
                    Flickable {
                        Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                        contentWidth: width; contentHeight: mineCol.implicitHeight
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
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
                        Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                        contentWidth: width; contentHeight: reviewCol.implicitHeight
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
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

}
