// TodoistWidget — painel lateral de tarefas (Todoist via REST v1).
// Toggle: qs ipc call todoist toggle   ·   slide-in pela esquerda, colado à borda.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../colors" as Theme

Scope {
    id: root

    property bool shown: false
    property bool rendered: false      // mantém a PanelWindow viva durante o slide-out
    property var    rows: []
    property var    projects: []
    property var    sections: []
    property string scope: "all"            // "all" | "upcoming" | <project_id>
    property bool   scopeInit: false        // 1ª carga já força o Inbox
    property string sectionScope: "all"     // "all" | "none" | <section_id>
    property bool   busy: false
    property string errMsg: ""

    // ── drag-and-drop ──
    property bool   dragActive: false
    property string dragId: ""
    property string dragText: ""
    property string dropTargetId: ""      // task sob o cursor (""=fim da seção)
    property string dropSection: ""       // seção destino ("none"=sem seção)
    readonly property bool canDrag: root.scope !== "all" && root.scope !== "upcoming" && root.scope !== "hoje"

    onScopeChanged: {
        root.sectionScope = "all"
        if (root.scope === "hoje") root.refresh()   // dados frescos ao abrir a vista de hoje
        Quickshell.execDetached(["bash", root.script, "save-scope", root.scope, root.sectionScope])
    }
    onSectionScopeChanged: {
        Quickshell.execDetached(["bash", root.script, "save-scope", root.scope, root.sectionScope])
    }

    function resetDrag() {
        root.dragActive = false; root.dragId = ""; root.dragText = ""
        root.dropTargetId = ""; root.dropSection = ""
    }
    // ordem final da seção destino: ids da seção (na ordem exibida) sem o arrastado,
    // reinserido na posição do alvo (ou no fim se alvo vazio).
    function computeOrder(dragId, targetId, targetSection) {
        var ids = root.filteredRows()
            .filter(function (t) { return (t.section_id || "none") === targetSection && t.id !== dragId })
            .map(function (t) { return t.id })
        var pos = targetId ? ids.indexOf(targetId) : -1
        if (pos < 0) ids.push(dragId); else ids.splice(pos, 0, dragId)
        return ids
    }
    // reordena root.rows na hora (otimista) pra UI responder sem esperar o servidor
    function applyLocalReorder(dragId, targetSection, order) {
        var byId = {}
        for (var i = 0; i < root.rows.length; i++) byId[root.rows[i].id] = root.rows[i]
        if (byId[dragId]) byId[dragId].section_id = (targetSection === "none" ? null : targetSection)
        var inDest = {}
        for (var k = 0; k < order.length; k++) inDest[order[k]] = true
        var rest = root.rows.filter(function (t) { return !inDest[t.id] })
        var ordered = order.map(function (id) { return byId[id] }).filter(function (t) { return t })
        root.rows = rest.concat(ordered)   // displayItems reagrupa por seção mantendo esta ordem
    }
    function applyDrop() {
        if (!root.dragActive || !root.dragId) { root.resetDrag(); return }
        var sec = root.dropSection || "none"
        var order = root.computeOrder(root.dragId, root.dropTargetId, sec)
        root.applyLocalReorder(root.dragId, sec, order)   // reflete já (sem lag)
        Quickshell.execDetached(["bash", root.script, "drop", root.dragId, sec, root.scope, order.join(",")])
        root.resetDrag()   // sem refetch imediato — reconcilia no próximo refresh natural
    }

    function scopeOptions() {
        var o = [{ key: "hoje", label: "📅 Hoje" }, { key: "all", label: "Todas" }, { key: "upcoming", label: "Em breve" }]
        for (var i = 0; i < root.projects.length; i++)
            o.push({ key: root.projects[i].id, label: root.projects[i].name })
        return o
    }
    function scopeLabel() {
        var opts = root.scopeOptions()
        for (var i = 0; i < opts.length; i++) if (opts[i].key === root.scope) return opts[i].label
        return "Todas"
    }
    function sortByTime(arr) {
        return arr.slice().sort(function(a, b) {
            var da = a.due_datetime || a.due_date || ""
            var db = b.due_datetime || b.due_date || ""
            if (da && db) return da < db ? -1 : da > db ? 1 : 0
            if (da) return -1
            if (db) return  1
            return 0
        })
    }
    function filteredRows() {
        if (root.scope === "all") return root.rows
        if (root.scope === "upcoming") {
            var rows = root.rows.filter(function (t) { return ("" + t.due).length > 0 })
            return root.sortByTime(rows)
        }
        if (root.scope === "hoje") {
            var now = new Date()
            // Todoist retorna due_date como "YYYY-MM-DD" ou "YYYY-MM-DDTHH:MM:SS" (local, sem TZ).
            // toISOString() é UTC — usa offset pra obter a data LOCAL correta.
            var offset = now.getTimezoneOffset() * 60000
            var localNow = new Date(now.getTime() - offset)
            var todayStr = localNow.toISOString().slice(0, 10)
            return root.rows.filter(function (t) {
                if (!t.due_date) return false
                // slice(0,10): "2026-07-01T07:00:00" → "2026-07-01" para comparação correta
                return t.due_date.slice(0, 10) <= todayStr
            })
        }
        var r = root.rows.filter(function (t) { return t.project_id === root.scope })
        if (root.sectionScope === "all")  return r
        if (root.sectionScope === "none") return r.filter(function (t) { return !t.section_id })
        return r.filter(function (t) { return t.section_id === root.sectionScope })
    }
    // lista pra render: agrupa por seção (com headers) quando um projeto está
    // selecionado e "todas as seções"; senão devolve flat. Item de header = {header,count}.
    function displayItems() {
        var rows = root.filteredRows()

        // ── vista Hoje: separa atrasadas / futuras ────────────────────────────
        if (root.scope === "hoje") {
            var now = new Date()
            var offset2 = now.getTimezoneOffset() * 60000
            var todayStr = new Date(now.getTime() - offset2).toISOString().slice(0, 10)
            var overdue = [], upcoming = []
            for (var k = 0; k < rows.length; k++) {
                var t = rows[k]
                var dueDateOnly = t.due_date ? t.due_date.slice(0, 10) : ""
                var isToday = (dueDateOnly === todayStr)
                if (!isToday) {
                    overdue.push(t)   // due_date < today
                } else {
                    // Determina hora: due_datetime (UTC) ou due_date com hora local (sem Z)
                    var dt = t.due_datetime || (t.due_date && t.due_date.length > 10 ? t.due_date : null)
                    if (dt) {
                        // "2026-07-01T07:00:00" sem Z → JS parseia como LOCAL; com Z → UTC. Ambos corretos.
                        if (new Date(dt) <= now) overdue.push(t)
                        else upcoming.push(t)
                    } else {
                        upcoming.push(t)  // date-only = sem hora → não vencida ainda
                    }
                }
            }
            // ordena por due_datetime (nulls por último)
            function byTime(a, b) {
                // due_datetime (com TZ, UTC) ou due_date (local, sem TZ) como fallback
                var da = a.due_datetime || a.due_date || ""
                var db = b.due_datetime || b.due_date || ""
                if (da && db) return da < db ? -1 : da > db ? 1 : 0
                if (da) return -1
                if (db) return  1
                return 0
            }
            overdue.sort(byTime)
            upcoming.sort(byTime)
            var out = []
            if (overdue.length > 0) {
                out.push({ header: "🔴 Atrasadas", count: overdue.length, secId: "_overdue", isOverdue: true })
                for (var i = 0; i < overdue.length; i++) out.push(overdue[i])
            }
            if (upcoming.length > 0) {
                out.push({ header: "📅 Hoje", count: upcoming.length, secId: "_hoje", isOverdue: false })
                for (var j = 0; j < upcoming.length; j++) out.push(upcoming[j])
            }
            return out
        }

        // ── agrupamento por seção (projeto selecionado) ───────────────────────
        var grouping = root.scope !== "all" && root.scope !== "upcoming" && root.sectionScope === "all"
        if (!grouping) return rows
        var gOut = []
        var noSec = rows.filter(function (t) { return !t.section_id })
        for (var n = 0; n < noSec.length; n++) gOut.push(noSec[n])
        var secs = root.projectSections()
        for (var s = 0; s < secs.length; s++) {
            var inSec = rows.filter(function (t) { return t.section_id === secs[s].id })
            if (inSec.length === 0) continue
            gOut.push({ header: secs[s].name, count: inSec.length, secId: secs[s].id })
            for (var m = 0; m < inSec.length; m++) gOut.push(inSec[m])
        }
        return gOut
    }
    function projectSections() {
        return root.sections.filter(function (s) { return s.project_id === root.scope })
    }
    function hasSections() {
        return root.scope !== "all" && root.scope !== "upcoming" && root.projectSections().length > 0
    }
    function sectionOptions() {
        var o = [{ key: "all", label: "Todas as seções" }, { key: "none", label: "Sem seção" }]
        var ps = root.projectSections()
        for (var i = 0; i < ps.length; i++) o.push({ key: ps[i].id, label: ps[i].name })
        return o
    }

    readonly property string script: Qt.resolvedUrl("todoist-panel.sh").toString().replace(/^file:\/\//, "")

    readonly property color cBg:      Qt.rgba(Theme.Colors.bg.r, Theme.Colors.bg.g, Theme.Colors.bg.b, 0.97)
    readonly property color cElev:    Theme.Colors.elev
    readonly property color cBorder:  Theme.Colors.border
    readonly property color cFg:      Theme.Colors.fg
    readonly property color cFgMuted: Theme.Colors.fgMuted
    readonly property color cAccent:  Theme.Colors.accent
    readonly property color cDanger:  Theme.Colors.danger
    readonly property color cWarn:    Theme.Colors.warning

    // priority do Todoist é invertido: 4 = P1 (vermelho), 1 = sem prioridade
    function prioColor(p) {
        if (p >= 4) return Theme.Colors.severity.high
        if (p === 3) return Theme.Colors.severity.medium
        if (p === 2) return "#3498db"   // convenção Todoist P2, fora da escala de severidade
        return root.cFgMuted
    }

    Process {
        id: listProc
        command: ["bash", root.script, "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.errMsg = ""
                try {
                    const d = JSON.parse(this.text)
                    if (Array.isArray(d)) { root.rows = d }
                    else { root.rows = []; root.errMsg = (d && d.error) ? d.error : "resposta inesperada" }
                } catch (e) {
                    root.rows = []
                    root.errMsg = this.text.trim().length ? this.text.trim().slice(0, 120) : "sem resposta do script"
                }
                root.busy = false
            }
        }
    }

    Process {
        id: projProc
        command: ["bash", root.script, "projects"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(this.text)
                    if (Array.isArray(d)) {
                        root.projects = d
                        // 1ª carga abre no Inbox (não em "Todas"); depois respeita a escolha
                        if (!root.scopeInit) {
                            var ib = d.find(function (p) { return p.inbox || p.name === "Inbox" })
                            if (ib) root.scope = ib.id
                            root.scopeInit = true
                        }
                    }
                }
                catch (e) { console.log("TodoistWidget: projects parse falhou:", e) }
            }
        }
    }

    Process {
        id: sectProc
        command: ["bash", root.script, "sections"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { const d = JSON.parse(this.text); if (Array.isArray(d)) root.sections = d }
                catch (e) { console.log("TodoistWidget: sections parse falhou:", e) }
            }
        }
    }

    // add/done são fire-and-forget via execDetached; recarrega a lista logo depois
    Timer { id: reloadTimer; interval: 800; onTriggered: root.refresh() }

    function refresh() {
        if (!listProc.running) { root.busy = true; listProc.running = true }
        if (!projProc.running && root.projects.length === 0) projProc.running = true
        if (!sectProc.running && root.sections.length === 0) sectProc.running = true
    }
    function addTask(text) {
        if (!text) return
        // cria no projeto ativo (e na seção selecionada, se houver); "Todas"/"Em breve" → Inbox
        var cmd = ["bash", root.script, "add", text]
        if (root.scope !== "all" && root.scope !== "upcoming") {
            cmd.push(root.scope)
            if (root.sectionScope && root.sectionScope !== "all" && root.sectionScope !== "none")
                cmd.push(root.sectionScope)
        }
        Quickshell.execDetached(cmd)
        root.busy = true
        reloadTimer.restart()
    }
    function doneTask(id) {
        if (!id) return
        Quickshell.execDetached(["bash", root.script, "done", id])
        root.busy = true
        reloadTimer.restart()
    }

    function openPanel()  {
        root.rendered = true
        root.shown = true
        root.refresh()
        Qt.callLater(function() { input.forceActiveFocus() })
    }
    function closePanel() { root.shown = false; root.resetDrag() }
    function togglePanel() { root.shown ? root.closePanel() : root.openPanel() }

    // Restaura scope/sectionScope salvos antes do refresh — evita o forced-Inbox
    // do primeiro carregamento de projetos sobrescrever a escolha anterior.
    Process {
        id: loadScopeProc
        command: ["bash", root.script, "load-scope"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(this.text)
                    root.scope = d.scope || "all"
                    root.sectionScope = d.sectionScope || "all"
                    root.scopeInit = true
                } catch (e) { console.log("TodoistWidget: load-scope parse falhou:", e) }
                root.refresh()
            }
        }
    }

    Component.onCompleted: loadScopeProc.running = true
    Timer { interval: 300000; running: true; repeat: true; onTriggered: if (root.shown) root.refresh() }

    IpcHandler {
        target: "todoist"
        function toggle(): void { root.togglePanel() }
        function open():   void { root.openPanel()   }
        function close():  void { root.closePanel()  }
    }

    PanelWindow {
        visible: root.rendered
        anchors { top: true; left: true; bottom: true; right: true }
        exclusiveZone: 0
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        Shortcut { sequences: ["Escape"]; enabled: root.shown; onActivated: root.closePanel() }

        MouseArea {
            anchors.fill: parent
            z: -1
            onClicked: function(mouse) {
                const p = mapToItem(panel, mouse.x, mouse.y)
                if (p.x < 0 || p.y < 0 || p.x > panel.width || p.y > panel.height) root.closePanel()
            }
        }

        Rectangle {
            id: panel
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.topMargin: 10
            anchors.bottomMargin: 10
            width: 360
            x: root.shown ? 10 : -width - 4       // descola da borda (arredondado aparece)
            radius: 14
            // Semi-transparente em repouso; sólido no hover (facilita leitura).
            color: Qt.rgba(Theme.Colors.bg.r, Theme.Colors.bg.g, Theme.Colors.bg.b, panelHover.hovered ? 1.0 : 0.95)
            border.color: Qt.rgba(1, 1, 1, 0.07)
            border.width: 1

            Behavior on color { ColorAnimation { duration: 120 } }

            Behavior on x {
                NumberAnimation {
                    duration: 220; easing.type: Easing.OutCubic
                    onRunningChanged: if (!running && !root.shown) root.rendered = false
                }
            }

            // auto-hide: some após 3s sem o mouse sobre o painel
            HoverHandler { id: panelHover }
            Timer {
                interval: 3000; repeat: true
                running: root.shown && !panelHover.hovered
                onTriggered: root.closePanel()
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                // cabeçalho
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Text {
                        text: "✓ Tarefas"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 19; font.weight: Font.Bold
                        color: root.cAccent
                    }
                    Text {
                        text: root.busy ? "…" : ("" + root.filteredRows().length)
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 15
                        color: root.cFgMuted
                    }
                    Item { Layout.fillWidth: true }
                    // botão refresh
                    Rectangle {
                        width: 22; height: 22; radius: 11
                        color: rma.containsMouse ? root.cElev : "transparent"
                        Text {
                            anchors.centerIn: parent; text: "↻"
                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16
                            color: rma.containsMouse ? root.cAccent : root.cFgMuted
                            rotation: root.busy ? 0 : 0
                        }
                        MouseArea {
                            id: rma; anchors.fill: parent
                            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: root.refresh()
                        }
                    }
                    Rectangle {
                        width: 22; height: 22; radius: 11
                        color: xma.containsMouse ? root.cElev : "transparent"
                        Text {
                            anchors.centerIn: parent; text: "✕"
                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 15
                            color: xma.containsMouse ? root.cAccent : root.cFgMuted
                        }
                        MouseArea {
                            id: xma; anchors.fill: parent
                            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: root.closePanel()
                        }
                    }
                }

                // seletor de projeto (Todas / Em breve / projetos)
                Dropdown {
                    Layout.fillWidth: true
                    options: root.scopeOptions()
                    currentKey: root.scope
                    onPicked: function (key) { root.scope = key }
                }

                // seletor de seção (só aparece quando o projeto tem seções)
                Dropdown {
                    Layout.fillWidth: true
                    visible: root.hasSections()
                    options: root.sectionOptions()
                    currentKey: root.sectionScope
                    onPicked: function (key) { root.sectionScope = key }
                }

                // input de nova tarefa
                Rectangle {
                    Layout.fillWidth: true
                    height: 34; radius: 8
                    color: root.cElev
                    border.color: input.activeFocus ? root.cAccent : root.cBorder
                    border.width: 1
                    TextInput {
                        id: input
                        anchors.fill: parent
                        anchors.leftMargin: 10; anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter
                        clip: true
                        color: root.cFg
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16
                        onAccepted: { root.addTask(text.trim()); text = "" }
                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            visible: input.text.length === 0
                            text: "+ nova tarefa (Enter)"
                            color: root.cFgMuted
                            font: input.font
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: root.cBorder }

                // lista de tarefas
                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    interactive: !root.dragActive     // scroll não briga com o drag
                    contentHeight: list.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: list
                        width: parent.width
                        spacing: 8

                        Repeater {
                            model: root.displayItems()
                            Item {
                                required property var modelData
                                readonly property bool isHeader: modelData.header !== undefined
                                Layout.fillWidth: true
                                Layout.topMargin: isHeader ? 8 : 0
                                implicitHeight: isHeader ? (hdrRow.implicitHeight + 4) : trow.implicitHeight

                                // alvo de drop: header solta no fim da seção; task solta na posição dela
                                DropArea {
                                    anchors.fill: parent
                                    keys: ["todoisttask"]
                                    onEntered: {
                                        if (isHeader) { root.dropSection = modelData.secId; root.dropTargetId = "" }
                                        else { root.dropSection = modelData.section_id || "none"; root.dropTargetId = modelData.id }
                                    }
                                }
                                // indicador de onde vai cair
                                Rectangle {
                                    anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                                    height: 2; radius: 1; color: root.cAccent
                                    visible: root.dragActive && !isHeader && root.dropTargetId === modelData.id && root.dragId !== modelData.id
                                }

                                // arrasta de qualquer lugar do card (fica ATRÁS do checkbox,
                                // que declarado depois captura o próprio clique de concluir)
                                MouseArea {
                                    anchors.fill: parent
                                    enabled: !isHeader && root.canDrag
                                    cursorShape: enabled ? Qt.OpenHandCursor : Qt.ArrowCursor
                                    drag.target: ghost
                                    drag.threshold: 6
                                    // impede o Flickable de roubar o grab (senão o release some → ghost trava)
                                    preventStealing: true
                                    onPressed: function (mouse) {
                                        var g = mapToItem(panel, mouse.x, mouse.y)
                                        ghost.x = g.x - ghost.width / 2
                                        ghost.y = g.y - ghost.height / 2
                                        root.dragId = modelData.id
                                        root.dragText = modelData.content || ""
                                        root.dropTargetId = modelData.id
                                        root.dropSection = modelData.section_id || "none"
                                    }
                                    onPositionChanged: if (drag.active && !root.dragActive) root.dragActive = true
                                    onReleased: root.dragActive ? root.applyDrop() : root.resetDrag()
                                    onCanceled: root.resetDrag()   // rede: se o grab for perdido, não trava
                                }

                                // ── cabeçalho de seção ──
                                RowLayout {
                                    id: hdrRow
                                    visible: isHeader
                                    anchors.left: parent.left; anchors.right: parent.right
                                    anchors.top: parent.top
                                    spacing: 6
                                    Text {
                                        text: modelData.header || ""
                                        color: (modelData.isOverdue === true) ? root.cDanger : root.cAccent
                                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; font.weight: Font.Bold
                                    }
                                    Rectangle {
                                        Layout.alignment: Qt.AlignVCenter
                                        width: cntT.implicitWidth + 8; height: 15; radius: 7
                                        color: Qt.rgba(0, 0.831, 1, 0.13)
                                        Text {
                                            id: cntT; anchors.centerIn: parent
                                            text: isHeader ? ("" + (modelData.count || 0)) : ""
                                            color: root.cAccent
                                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11
                                        }
                                    }
                                    Item { Layout.fillWidth: true }
                                }

                                // ── linha de tarefa ──
                                RowLayout {
                                    id: trow
                                    visible: !isHeader
                                    anchors.left: parent.left; anchors.right: parent.right
                                    anchors.top: parent.top
                                    spacing: 8

                                    // hora — coluna esquerda fixa (hoje + em breve)
                                    Item {
                                        visible: (root.scope === "hoje" || root.scope === "upcoming") && !isHeader
                                        width: 42   // largura fixa → alinha todas as horas
                                        height: 18
                                        Layout.alignment: Qt.AlignTop
                                        Layout.topMargin: 1
                                        Text {
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: (modelData.due_time || "")
                                            visible: !!modelData.due_time
                                            color: root.cAccent
                                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; font.weight: Font.Bold
                                        }
                                    }

                                    Rectangle {
                                        Layout.alignment: Qt.AlignTop
                                        Layout.topMargin: 1
                                        width: 18; height: 18; radius: 5
                                        color: "transparent"
                                        border.color: cma.containsMouse ? root.cAccent : root.cBorder
                                        border.width: 2
                                        Text {
                                            anchors.centerIn: parent
                                            text: "✓"; visible: cma.containsMouse
                                            color: root.cAccent; font.pixelSize: 15
                                        }
                                        MouseArea {
                                            id: cma; anchors.fill: parent
                                            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: root.doneTask(modelData.id)
                                        }
                                    }
                                    Rectangle {
                                        Layout.fillHeight: true
                                        width: 3; radius: 2; color: root.prioColor(modelData.priority || 1)
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1
                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData.content || ""
                                            wrapMode: Text.WordWrap
                                            color: root.cFg
                                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 15
                                        }
                                        Text {
                                            // mostra due string só em vistas sem coluna de hora
                                            visible: root.scope !== "hoje" && root.scope !== "upcoming"
                                                     && ("" + (modelData.due || "")).length > 0
                                            text: "󰃭 " + (modelData.due || "")
                                            color: root.cFgMuted
                                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            visible: root.rows.length === 0 && !root.busy
                            Layout.fillWidth: true
                            text: root.errMsg.length
                                  ? ("erro: " + root.errMsg + (root.errMsg === "no_token" ? "\n→ criar ~/.config/todoist/token no host" : ""))
                                  : "sem tarefas"
                            color: root.errMsg.length ? root.cDanger : root.cFgMuted
                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }

            // ghost que segue o cursor durante o drag (fica acima da lista)
            Rectangle {
                id: ghost
                visible: root.dragActive
                z: 300
                width: 260; height: 30; radius: 6
                color: Qt.rgba(0, 0.831, 1, 0.18)
                border.color: root.cAccent; border.width: 1
                Drag.active: root.dragActive
                Drag.hotSpot.x: width / 2; Drag.hotSpot.y: height / 2
                Drag.keys: ["todoisttask"]
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left; anchors.leftMargin: 10
                    width: parent.width - 20; elide: Text.ElideRight
                    text: root.dragText; color: root.cFg
                    font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14
                }
            }
        }
    }

    // dropdown reutilizável (projeto + seção)
    component Dropdown: Rectangle {
        id: dd
        property var    options: []
        property string currentKey: ""
        property bool   open: false
        signal picked(string key)

        implicitHeight: 32
        radius: 8
        z: dd.open ? 100 : 1
        color: ddMa.containsMouse ? root.cElev : Qt.rgba(1, 1, 1, 0.04)
        border.color: dd.open ? root.cAccent : root.cBorder
        border.width: 1

        function labelFor(k) {
            for (var i = 0; i < dd.options.length; i++) if (dd.options[i].key === k) return dd.options[i].label
            return ""
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12; anchors.rightMargin: 12
            Text {
                Layout.fillWidth: true
                text: dd.labelFor(dd.currentKey)
                color: root.cFg
                font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16
                elide: Text.ElideRight
            }
            Text {
                text: dd.open ? "▴" : "▾"
                color: root.cFgMuted
                font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 15
            }
        }
        MouseArea {
            id: ddMa; anchors.fill: parent
            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: dd.open = !dd.open
        }

        Rectangle {
            visible: dd.open
            anchors.top: parent.bottom; anchors.topMargin: 4
            anchors.left: parent.left; anchors.right: parent.right
            z: 100
            implicitHeight: ddOpts.implicitHeight + 8
            radius: 8
            color: root.cElev
            border.color: root.cBorder; border.width: 1

            ColumnLayout {
                id: ddOpts
                anchors.left: parent.left; anchors.right: parent.right
                anchors.top: parent.top; anchors.margins: 4
                spacing: 0
                Repeater {
                    model: dd.options
                    Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: 30; radius: 6
                        color: itMa.containsMouse ? root.cBorder : "transparent"
                        Text {
                            anchors.fill: parent; anchors.leftMargin: 10
                            verticalAlignment: Text.AlignVCenter
                            text: modelData.label
                            elide: Text.ElideRight
                            color: modelData.key === dd.currentKey ? root.cAccent : root.cFg
                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 15
                        }
                        MouseArea {
                            id: itMa; anchors.fill: parent
                            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: { dd.picked(modelData.key); dd.open = false }
                        }
                    }
                }
            }
        }
    }
}
