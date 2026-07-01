// TodoistWidget — painel lateral de tarefas (Todoist via REST v1).
// Toggle: qs ipc call todoist toggle   ·   slide-in pela esquerda, colado à borda.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root

    property bool shown: false
    property bool rendered: false      // mantém a PanelWindow viva durante o slide-out
    property var    rows: []
    property var    projects: []
    property string scope: "all"          // "all" | "upcoming" | <project_id>
    property bool   dropOpen: false
    property bool   busy: false
    property string errMsg: ""

    function scopeOptions() {
        var o = [{ key: "all", label: "Todas" }, { key: "upcoming", label: "Em breve" }]
        for (var i = 0; i < root.projects.length; i++)
            o.push({ key: root.projects[i].id, label: root.projects[i].name })
        return o
    }
    function scopeLabel() {
        var opts = root.scopeOptions()
        for (var i = 0; i < opts.length; i++) if (opts[i].key === root.scope) return opts[i].label
        return "Todas"
    }
    function filteredRows() {
        if (root.scope === "all") return root.rows
        if (root.scope === "upcoming") return root.rows.filter(function (t) { return ("" + t.due).length > 0 })
        return root.rows.filter(function (t) { return t.project_id === root.scope })
    }

    readonly property string script: Qt.resolvedUrl("todoist-panel.sh").toString().replace(/^file:\/\//, "")

    readonly property color cBg:      Qt.rgba(0.04, 0.055, 0.09, 0.97)
    readonly property color cElev:    "#2a2f3a"
    readonly property color cBorder:  "#2d3748"
    readonly property color cFg:      "#e6e6e6"
    readonly property color cFgMuted: "#9ca3af"
    readonly property color cAccent:  "#00d4ff"

    // priority do Todoist é invertido: 4 = P1 (vermelho), 1 = sem prioridade
    function prioColor(p) {
        if (p >= 4) return "#e74c3c"
        if (p === 3) return "#e67e22"
        if (p === 2) return "#3498db"
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
                try { const d = JSON.parse(this.text); if (Array.isArray(d)) root.projects = d }
                catch (e) { console.log("TodoistWidget: projects parse falhou:", e) }
            }
        }
    }

    // add/done compartilham um Process; ao terminar, recarrega a lista
    Process {
        id: mutProc
        onRunningChanged: if (!running) root.refresh()
    }

    function refresh() {
        if (!listProc.running) { root.busy = true; listProc.running = true }
        if (!projProc.running && root.projects.length === 0) projProc.running = true
    }
    function addTask(text) {
        if (!text || mutProc.running) return
        mutProc.command = ["bash", root.script, "add", text]
        mutProc.running = true
    }
    function doneTask(id) {
        if (!id || mutProc.running) return
        mutProc.command = ["bash", root.script, "done", id]
        mutProc.running = true
    }

    function openPanel()  { root.rendered = true; root.shown = true; root.refresh() }
    function closePanel() { root.shown = false }
    function togglePanel() { root.shown ? root.closePanel() : root.openPanel() }

    Component.onCompleted: root.refresh()
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
            width: 360
            x: root.shown ? 0 : -width
            color: root.cBg
            border.color: Qt.rgba(1, 1, 1, 0.07)
            border.width: 1

            Behavior on x {
                NumberAnimation {
                    duration: 220; easing.type: Easing.OutCubic
                    onRunningChanged: if (!running && !root.shown) root.rendered = false
                }
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
                        font.pixelSize: 16; font.weight: Font.Bold
                        color: root.cAccent
                    }
                    Text {
                        text: root.busy ? "…" : ("" + root.filteredRows().length)
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12
                        color: root.cFgMuted
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        width: 22; height: 22; radius: 11
                        color: xma.containsMouse ? root.cElev : "transparent"
                        Text {
                            anchors.centerIn: parent; text: "✕"
                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12
                            color: xma.containsMouse ? root.cAccent : root.cFgMuted
                        }
                        MouseArea {
                            id: xma; anchors.fill: parent
                            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: root.closePanel()
                        }
                    }
                }

                // seletor de escopo (projeto / inbox / em breve)
                Rectangle {
                    id: scopeBtn
                    Layout.fillWidth: true
                    height: 32; radius: 8
                    z: 50
                    color: sma.containsMouse ? root.cElev : Qt.rgba(1, 1, 1, 0.04)
                    border.color: root.dropOpen ? root.cAccent : root.cBorder
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12; anchors.rightMargin: 12
                        Text {
                            Layout.fillWidth: true
                            text: root.scopeLabel()
                            color: root.cFg
                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13
                            elide: Text.ElideRight
                        }
                        Text {
                            text: root.dropOpen ? "▴" : "▾"
                            color: root.cFgMuted
                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12
                        }
                    }
                    MouseArea {
                        id: sma; anchors.fill: parent
                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: root.dropOpen = !root.dropOpen
                    }

                    // popup de opções
                    Rectangle {
                        visible: root.dropOpen
                        anchors.top: parent.bottom; anchors.topMargin: 4
                        anchors.left: parent.left; anchors.right: parent.right
                        z: 100
                        implicitHeight: opts.implicitHeight + 8
                        radius: 8
                        color: root.cElev
                        border.color: root.cBorder; border.width: 1

                        ColumnLayout {
                            id: opts
                            anchors.left: parent.left; anchors.right: parent.right
                            anchors.top: parent.top; anchors.margins: 4
                            spacing: 0
                            Repeater {
                                model: root.scopeOptions()
                                Rectangle {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    height: 28; radius: 6
                                    color: oma.containsMouse ? root.cBorder : "transparent"
                                    Text {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        verticalAlignment: Text.AlignVCenter
                                        text: modelData.label
                                        elide: Text.ElideRight
                                        color: modelData.key === root.scope ? root.cAccent : root.cFg
                                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12
                                    }
                                    MouseArea {
                                        id: oma; anchors.fill: parent
                                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: { root.scope = modelData.key; root.dropOpen = false }
                                    }
                                }
                            }
                        }
                    }
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
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13
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
                    contentHeight: list.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: list
                        width: parent.width
                        spacing: 6

                        Repeater {
                            model: root.filteredRows()
                            RowLayout {
                                required property var modelData
                                Layout.fillWidth: true
                                spacing: 10

                                // checkbox = concluir
                                Rectangle {
                                    width: 18; height: 18; radius: 5
                                    color: "transparent"
                                    border.color: cma.containsMouse ? root.cAccent : root.cBorder
                                    border.width: 2
                                    Text {
                                        anchors.centerIn: parent
                                        text: "✓"; visible: cma.containsMouse
                                        color: root.cAccent; font.pixelSize: 12
                                    }
                                    MouseArea {
                                        id: cma; anchors.fill: parent
                                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: root.doneTask(modelData.id)
                                    }
                                }
                                // faixa de prioridade
                                Rectangle { width: 3; height: 18; radius: 2; color: root.prioColor(modelData.priority) }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.content
                                        wrapMode: Text.WordWrap
                                        color: root.cFg
                                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12
                                    }
                                    Text {
                                        visible: ("" + modelData.due).length > 0
                                        text: "󰃭 " + modelData.due
                                        color: root.cFgMuted
                                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10
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
                            color: root.errMsg.length ? "#e74c3c" : root.cFgMuted
                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }
        }
    }
}
