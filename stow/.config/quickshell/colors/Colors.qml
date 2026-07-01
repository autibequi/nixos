pragma Singleton
import QtQuick

// GERADO por themes/generate.sh — editar themes/<tema>/palette.toml, não este arquivo.
QtObject {
    readonly property color bg: "#06060d"
    readonly property color surface: "#12121b"
    readonly property color elev: "#1c1d23"
    readonly property color border: "#43453f"
    readonly property color fg: "#e6dac2"
    readonly property color fgMuted: "#9b8669"
    readonly property color accent: "#6b97b8"
    readonly property color accentSoft: "#cdab7b"
    readonly property color success: "#9aa85c"
    readonly property color warning: "#e0a44b"
    readonly property color danger: "#c25a48"
    readonly property color info: "#8bb0cc"

    readonly property QtObject severity: QtObject {
        readonly property color critical: "#c0392b"
        readonly property color high: "#e74c3c"
        readonly property color medium: "#e67e22"
        readonly property color low: "#f1c40f"
        readonly property color ok: "#16a085"
        readonly property color good: "#2ecc71"
    }
}
