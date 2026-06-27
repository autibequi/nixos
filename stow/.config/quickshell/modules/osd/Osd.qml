// Osd — overlay transitório top-center para volume/brilho/mic.
// Aparece ao detectar mudança nas fontes, some sozinho após hideDelay ms.
// Substitui o swayosd (ver services.nix — serviço comentado).
// Sem keyboardFocus: é passivo, não captura input.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire

Scope {
    id: root

    // ── Tema (Deep Dark / Alacritty — espelha PowerMenu e ClockWidget) ──
    readonly property color cBg:      "#0a0e14"
    readonly property color cSurface: "#1a1f29"
    readonly property color cBorder:  "#2d3748"
    readonly property color cFg:      "#e6e6e6"
    readonly property color cFgMuted: "#9ca3af"
    readonly property color cAccent:  "#00d4ff"
    readonly property color cDanger:  "#ff5555"

    // ── Estado do OSD ────────────────────────────────────────────────
    property bool shown: false

    // Qual canal está sendo exibido: "volume" | "brightness" | "mic"
    property string activeChannel: "volume"

    // Valor exibido na barra (0–100)
    property int displayValue: 0

    // Se true pinta o ícone em cDanger (mute ativo)
    property bool mutedState: false

    // Tempo de auto-hide em ms
    readonly property int hideDelay: 1500

    // ── Estado do brilho ─────────────────────────────────────────────
    // Path concreto descoberto em Component.onCompleted via `brightnessctl`.
    property string backlightPath: ""
    property int    brightnessRaw: 0
    property int    brightnessMax: 100

    // ── Ícones por canal e estado ────────────────────────────────────
    readonly property var icons: ({
        volume:     { normal: "",  muted: "" },
        brightness: { normal: "",  muted: "" },
        mic:        { normal: "",  muted: "" }
    })

    function currentIcon() {
        const set = icons[activeChannel];
        return (set !== undefined) ? (mutedState ? set.muted : set.normal) : "";
    }

    // ── Exibição ─────────────────────────────────────────────────────
    function showOsd(channel, value, muted) {
        activeChannel = channel;
        displayValue  = value;
        mutedState    = muted;
        shown         = true;
        hideTimer.restart();
    }

    // ── Auto-hide ────────────────────────────────────────────────────
    Timer {
        id: hideTimer
        interval: root.hideDelay
        repeat:   false
        onTriggered: root.shown = false
    }

    // ── Reatividade: volume do sink (saída) ──────────────────────────
    // Connections não usa null-guard em target pois QML avalia target
    // reativamente; se sink for null no boot o bloco é inerte.
    Connections {
        target: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null

        function onVolumeChanged() {
            if (!Pipewire.defaultAudioSink?.audio) return;
            const pct = Math.round(Pipewire.defaultAudioSink.audio.volume * 100);
            root.showOsd("volume", pct, Pipewire.defaultAudioSink.audio.muted);
        }

        function onMutedChanged() {
            if (!Pipewire.defaultAudioSink?.audio) return;
            const pct = Math.round(Pipewire.defaultAudioSink.audio.volume * 100);
            root.showOsd("volume", pct, Pipewire.defaultAudioSink.audio.muted);
        }
    }

    // ── Reatividade: mute do mic (fonte) ─────────────────────────────
    Connections {
        target: Pipewire.defaultAudioSource ? Pipewire.defaultAudioSource.audio : null

        function onMutedChanged() {
            if (!Pipewire.defaultAudioSource?.audio) return;
            const pct = Math.round(Pipewire.defaultAudioSource.audio.volume * 100);
            root.showOsd("mic", pct, Pipewire.defaultAudioSource.audio.muted);
        }
    }

    // ── Brilho: descoberta do path via brightnessctl ─────────────────
    // Roda uma vez no boot para obter o nome do dispositivo de backlight.
    Process {
        id: discoverBacklight
        command: ["brightnessctl", "--list", "--machine-readable"]
        stdout: StdioCollector {
            onStreamFinished: {
                // formato: <device>,<class>,<current>,<max>,<pct%>\n...
                // Queremos o primeiro dispositivo da classe "backlight".
                const lines = text.trim().split("\n");
                for (const line of lines) {
                    const parts = line.split(",");
                    if (parts.length >= 2 && parts[1] === "backlight") {
                        const dev = parts[0];
                        root.backlightPath = "/sys/class/backlight/" + dev + "/brightness";
                        brightnessMaxProc.running = true;
                        break;
                    }
                }
            }
        }
    }

    // Lê o valor máximo do backlight (uma vez, após descobrir o device).
    Process {
        id: brightnessMaxProc
        command: ["brightnessctl", "max"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const val = parseInt(text.trim(), 10);
                if (!isNaN(val) && val > 0) root.brightnessMax = val;
                // Abre o FileView agora que temos max e path.
                brightnessFile.path = root.backlightPath;
            }
        }
    }

    // Monitora /sys/class/backlight/<dev>/brightness com inotify via FileView.
    // onFileChanged dispara toda vez que o kernel atualiza o sysfs node.
    // path começa vazio e é preenchido por brightnessMaxProc após o boot;
    // watchChanges em string vazia é inerte (Quickshell ignora path="").
    FileView {
        id: brightnessFile
        path:         ""
        watchChanges: true

        onFileChanged: {
            const raw = parseInt(brightnessFile.text().trim(), 10);
            if (isNaN(raw)) return;

            // Só mostra OSD se o valor realmente mudou (evita disparo no boot).
            if (raw === root.brightnessRaw) return;
            root.brightnessRaw = raw;

            const pct = Math.round((raw / root.brightnessMax) * 100);
            root.showOsd("brightness", Math.min(100, Math.max(0, pct)), false);
        }
    }

    // ── PanelWindow: overlay top-center passivo ──────────────────────
    PanelWindow {
        id: overlay
        visible: root.shown

        // Âncora apenas no topo — deixa as laterais livres para não ocupar
        // toda a largura (exclusiveZone=0 garante que não empurra outras janelas).
        anchors {
            top:   true
            left:  false
            right: false
        }
        margins { top: 48 }

        // Dimensões fixas: o card OSD tem largura determinada pelo conteúdo.
        implicitWidth:  280
        implicitHeight: 64

        exclusiveZone: 0
        color: "transparent"

        WlrLayershell.layer:         WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        // ── Card visual ───────────────────────────────────────────────
        Rectangle {
            id: card
            anchors.centerIn: parent
            width:  parent.width
            height: parent.height
            radius: 14
            color:  root.cSurface
            border.color: root.cBorder
            border.width: 1

            // Fade-in/out suave
            opacity: root.shown ? 1.0 : 0.0
            Behavior on opacity {
                NumberAnimation { duration: 160; easing.type: Easing.InOutQuad }
            }

            RowLayout {
                anchors {
                    fill:           parent
                    leftMargin:     16
                    rightMargin:    16
                    topMargin:      0
                    bottomMargin:   0
                }
                spacing: 12

                // Ícone do canal
                Text {
                    text: root.currentIcon()
                    font.family:   "JetBrainsMono Nerd Font"
                    font.pixelSize: 22
                    color: root.mutedState ? root.cDanger : root.cAccent
                    Layout.alignment: Qt.AlignVCenter
                }

                // Barra de progresso + valor numérico
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 4

                    // Barra
                    Rectangle {
                        Layout.fillWidth: true
                        height: 6
                        radius: 3
                        color:  root.cBg

                        Rectangle {
                            width:  parent.width * (root.displayValue / 100.0)
                            height: parent.height
                            radius: parent.radius
                            color:  root.mutedState ? root.cDanger : root.cAccent

                            Behavior on width {
                                NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
                            }
                        }
                    }
                }

                // Percentual
                Text {
                    text: root.displayValue + "%"
                    font.pixelSize: 13
                    font.family:    "JetBrainsMono Nerd Font"
                    color: root.cFgMuted
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: 38
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }

    Component.onCompleted: {
        discoverBacklight.running = true;
    }
}
