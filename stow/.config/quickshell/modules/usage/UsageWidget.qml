// UsageWidget — quota de uso do Claude (real via `yaa claude usage --json`)
// Toggle: qs ipc call usage toggle

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../colors" as Theme

Scope {
    id: root

    property bool shown: false
    property var  rows: []
    property string spendLabel: ""
    property string spendValue: ""
    property bool   spendOk: false

    // kind cru da API → rótulo legível
    readonly property var labelMap: ({
        "session":        "Sessão 5h",
        "weekly_all":     "Semana (todos)",
        "weekly_opus":    "Opus 7d",
        "weekly_sonnet":  "Sonnet 7d",
        "weekly_cowork":  "Cowork 7d",
        "weekly_omelette":"Design 7d",
        "weekly_oauth_apps": "OAuth apps 7d"
    })

    // ── cores — fonte única em quickshell/colors/Colors.qml ────────
    readonly property color cBg:      Theme.Colors.bg
    readonly property color cElev:    Theme.Colors.elev
    readonly property color cBorder:  Theme.Colors.border
    readonly property color cFg:      Theme.Colors.fg
    readonly property color cFgMuted: Theme.Colors.fgMuted
    readonly property color cAccent:  Theme.Colors.accent

    function pctColor(p) {
        if (p >= 90) return Theme.Colors.severity.critical
        if (p >= 80) return Theme.Colors.severity.high
        if (p >= 70) return Theme.Colors.severity.medium
        if (p >= 50) return Theme.Colors.severity.low
        if (p >= 30) return Theme.Colors.severity.ok
        return Theme.Colors.severity.good
    }

    function relReset(iso) {
        if (!iso) return ""
        const diff = new Date(("" + iso).replace(/\.[0-9]+/, "")).getTime() - Date.now()
        if (isNaN(diff)) return ""
        if (diff <= 0) return "↺ agora"
        const h = Math.floor(diff / 3600000)
        const m = Math.floor((diff % 3600000) / 60000)
        return h > 0 ? "↺ " + h + "h" : "↺ " + m + "m"
    }

    Process {
        id: usageProc
        command: ["yaa", "claude", "usage", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(this.text)

                    // fonte canônica: array `limits` (uma barra por janela retornada pela API)
                    const r = (d.limits || []).map(function(l) {
                        return { label:    root.labelMap[l.kind] || l.kind,
                                 pct:      Math.floor(l.percent || 0),
                                 note:     root.relReset(l.resets_at),
                                 active:   !!l.is_active,
                                 severity: l.severity || "normal" }
                    })
                    // Sonnet 7d sai do bucket dedicado (não vem no `limits`)
                    const sn = d.seven_day_sonnet
                    r.push({ label: "Sonnet 7d",
                             pct: Math.floor((sn && sn.utilization) || 0),
                             note: (sn && sn.resets_at) ? root.relReset(sn.resets_at) : "",
                             active: false, severity: (sn && sn.severity) || "normal" })
                    root.rows = r

                    // créditos extras (spend)
                    const sp = d.spend || {}
                    root.spendOk = !!sp.enabled
                    const cur  = (sp.used && sp.used.currency) || (d.extra_usage && d.extra_usage.currency) || "USD"
                    const exp  = (sp.used && sp.used.exponent) || 2
                    const used = ((sp.used && sp.used.amount_minor) || 0) / Math.pow(10, exp)
                    const money = used.toFixed(exp) + " " + cur
                    if (sp.enabled) {
                        root.spendLabel = "Créditos extras"
                        root.spendValue = money + " (" + Math.floor(sp.percent || 0) + "%)"
                    } else {
                        const reasonMap = { "out_of_credits": "sem créditos", "not_enabled": "desativado" }
                        const why = reasonMap[sp.disabled_reason] || sp.disabled_reason || "desativado"
                        root.spendLabel = "Créditos extras: " + why
                        root.spendValue = "usado " + money
                    }
                } catch (e) {
                    console.log("UsageWidget: falha ao parsear usage:", e)
                }
            }
        }
    }

    function refresh() { if (!usageProc.running) usageProc.running = true }

    Component.onCompleted: root.refresh()

    Timer {
        interval: 180000; running: true; repeat: true
        onTriggered: root.refresh()
    }

    function openPanel()  { root.shown = true; root.refresh() }
    function closePanel() { root.shown = false }
    function togglePanel() { root.shown ? root.closePanel() : root.openPanel() }

    IpcHandler {
        target: "usage"
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
            anchors.right:        parent.right
            anchors.bottom:       parent.bottom
            anchors.rightMargin:  12
            anchors.bottomMargin: 12
            width:  460
            implicitHeight: col.implicitHeight + 32
            radius: 14
            color:        Qt.rgba(0.04, 0.055, 0.09, 0.94)
            border.color: Qt.rgba(1, 1, 1, 0.07)
            border.width: 1
            transformOrigin: Item.BottomRight
            scale: root.shown ? 1 : 0.96
            opacity: root.shown ? 1 : 0
            Behavior on scale   { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 150 } }

            // auto-hide: some após 3s sem o mouse sobre o painel
            HoverHandler { id: panelHover }
            Timer {
                interval: 3000; repeat: true
                running: root.shown && !panelHover.hovered
                onTriggered: root.closePanel()
            }

            ColumnLayout {
                id: col
                anchors { left: parent.left; right: parent.right; top: parent.top }
                anchors.margins: 16
                spacing: 12

                // cabeçalho
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Text {
                        text: "✻ Claude Usage"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 15; font.weight: Font.Bold
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

                Rectangle { Layout.fillWidth: true; height: 1; color: root.cBorder }

                // linhas de métrica
                Repeater {
                    model: root.rows
                    RowLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 10

                        Text {
                            text: modelData.label
                            Layout.preferredWidth: 126
                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12
                            color: root.cFg
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 9; radius: 5
                            color: root.cElev
                            Rectangle {
                                height: parent.height; radius: 5
                                width: parent.width * Math.min(100, modelData.pct) / 100
                                color: root.pctColor(modelData.pct)
                                Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                            }
                        }

                        Text {
                            text: modelData.pct + "%"
                            horizontalAlignment: Text.AlignRight
                            Layout.preferredWidth: 38
                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; font.weight: Font.Bold
                            color: root.pctColor(modelData.pct)
                        }

                        Text {
                            text: modelData.note
                            horizontalAlignment: Text.AlignRight
                            Layout.preferredWidth: 64
                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; color: root.cFgMuted
                        }
                    }
                }

                Rectangle {
                    visible: root.spendLabel.length > 0
                    Layout.fillWidth: true; height: 1; color: root.cBorder
                }
                RowLayout {
                    visible: root.spendLabel.length > 0
                    Layout.fillWidth: true; spacing: 8
                    Rectangle {
                        width: 7; height: 7; radius: 4
                        color: root.spendOk ? Theme.Colors.severity.good : root.cFgMuted
                    }
                    Text {
                        text: root.spendLabel
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; color: root.cFgMuted
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: root.spendValue
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; color: root.cFgMuted
                    }
                }

                Text {
                    visible: root.rows.length === 0
                    Layout.fillWidth: true
                    text: "sem dados — yaa claude usage --refresh"
                    font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; color: root.cFgMuted
                }
            }
        }
    }
}
