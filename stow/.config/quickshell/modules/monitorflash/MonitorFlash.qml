// MonitorFlash — pisca uma borda no monitor que recebe foco via Super+Esc.
//
// follow_mouse=1 faz o foco trocar ao mover o mouse entre telas; por isso o
// flash NÃO reage ao foco automaticamente — é disparado por IPC só na ação
// deliberada do keybind:  qs ipc call monitorFlash flash
//
// Uma janela layer-shell (overlay) por monitor. A janela só fica visível
// enquanto a borda está acesa (visible ligado à opacity) e é click-through
// (mask vazio), então em repouso tem custo zero e nunca rouba input.

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import "../../colors" as Theme

Scope {
    id: root

    readonly property color flashColor: Theme.Colors.accent
    readonly property int   borderWidth: 6

    signal flashRequested()

    IpcHandler {
        target: "monitorFlash"
        function flash(): void { root.flashRequested() }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            anchors {
                top:    true
                bottom: true
                left:   true
                right:  true
            }
            exclusiveZone: 0
            color: "transparent"

            // só existe na tela enquanto a borda está acesa → custo zero em repouso
            visible: borderRect.opacity > 0

            WlrLayershell.layer:         WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            // input region vazia → cliques atravessam pro desktop
            mask: Region {}

            // só anima o monitor focado no instante do flash
            readonly property bool isFocused: Hyprland.focusedMonitor
                && Hyprland.focusedMonitor.name === modelData.name

            Connections {
                target: root
                function onFlashRequested() {
                    if (win.isFocused) flashAnim.restart()
                }
            }

            Rectangle {
                id: borderRect
                anchors.fill: parent
                color: "transparent"
                border.color: root.flashColor
                border.width: root.borderWidth
                opacity: 0
            }

            SequentialAnimation {
                id: flashAnim
                NumberAnimation {
                    target: borderRect; property: "opacity"
                    from: 0; to: 0.95; duration: 90; easing.type: Easing.OutQuad
                }
                PauseAnimation { duration: 220 }
                NumberAnimation {
                    target: borderRect; property: "opacity"
                    to: 0; duration: 340; easing.type: Easing.InQuad
                }
            }
        }
    }
}
