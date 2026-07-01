#!/usr/bin/env bash
# themes/generate.sh — lê o palette.toml ativo e escreve os arquivos derivados
# (waybar/colors.css · walker/themes/dash/style.css · quickshell/colors/Colors.qml).
# Mudar cor = editar themes/<tema>/palette.toml e rodar este script.
set -euo pipefail

THEME="${1:-wild-hunt}"
BASE="$HOME/.config"
PALETTE="$BASE/themes/$THEME/palette.toml"

[[ -f "$PALETTE" ]] || { echo "palette não encontrada: $PALETTE" >&2; exit 1; }

python3 - "$PALETTE" "$BASE" <<'PY'
import sys, tomllib, pathlib

palette_path, base = sys.argv[1], pathlib.Path(sys.argv[2])
with open(palette_path, "rb") as f:
    p = tomllib.load(f)

tok = {**p["surfaces"], **p["foreground"], **p["accents"]}

# ── waybar/colors.css (arquivo inteiro) ──────────────────────────────
waybar_css = f"""/* GERADO por themes/generate.sh — editar themes/<tema>/palette.toml, não este arquivo. */
@define-color theme-bg          {tok['bg']};
@define-color theme-surface     {tok['surface']};
@define-color theme-elev        {tok['elev']};
@define-color theme-border      {tok['border']};
@define-color theme-fg          {tok['fg']};
@define-color theme-fg-muted    {tok['fg_muted']};
@define-color theme-accent      {tok['accent']};
@define-color theme-accent-soft {tok['accent_soft']};
@define-color theme-success     {tok['success']};
@define-color theme-warning     {tok['warning']};
@define-color theme-danger      {tok['danger']};
@define-color theme-info        {tok['info']};

@define-color ws-text                  @theme-fg-muted;
@define-color ws-active-bg             @theme-accent;
@define-color ws-active-text           @theme-bg;
@define-color ws-urgent-bg             @theme-danger;
@define-color ws-urgent-text           @theme-bg;
@define-color ws-special-text          @theme-warning;
@define-color ws-special-active-bg     @theme-warning;
@define-color ws-special-active-text   @theme-bg;
@define-color ws-special-hover-text    @theme-fg;

@define-color mpris-text                  @theme-fg;
@define-color clock-text                  @theme-accent;
@define-color battery-text                @theme-fg;
@define-color battery-charging-text       @theme-success;
@define-color battery-warning-text        @theme-warning;
@define-color battery-critical-text       @theme-danger;
@define-color network-text                @theme-fg;
@define-color network-disconnected-text   @theme-fg-muted;
@define-color audio-text                  @theme-fg;
@define-color audio-muted-text            @theme-fg-muted;
@define-color backlight-text              @theme-fg;
@define-color idle-inhibitor-text         @theme-fg-muted;
@define-color idle-inhibitor-active-text  @theme-bg;
"""
(base / "waybar" / "colors.css").write_text(waybar_css)

# ── walker/themes/dash/style.css — só o bloco entre marcadores ───────
walker_css = base / "walker" / "themes" / "dash" / "style.css"
tokens_block = f"""@define-color window_bg_color {tok['bg']};
@define-color surface_color {tok['surface']};
@define-color elev_color {tok['elev']};
@define-color border_color {tok['border']};
@define-color theme_fg_color {tok['fg']};
@define-color theme_fg_muted {tok['fg_muted']};
@define-color accent_bg_color {tok['accent']};
@define-color accent_soft_color {tok['accent_soft']};
@define-color success_color {tok['success']};
@define-color warning_color {tok['warning']};
@define-color danger_color {tok['danger']};
@define-color info_color {tok['info']};
@define-color error_bg_color @danger_color;
@define-color error_fg_color @window_bg_color;"""
content = walker_css.read_text()
begin, end = "/* GENERATED:BEGIN */", "/* GENERATED:END */"
if begin in content and end in content:
    pre = content.split(begin)[0]
    post = content.split(end)[1]
    walker_css.write_text(f"{pre}{begin}\n{tokens_block}\n{end}{post}")
else:
    print(f"aviso: marcadores {begin}/{end} não achados em {walker_css}", file=sys.stderr)

# ── quickshell/colors/Colors.qml (singleton, arquivo inteiro) ────────
qml = f"""pragma Singleton
import QtQuick

// GERADO por themes/generate.sh — editar themes/<tema>/palette.toml, não este arquivo.
QtObject {{
    readonly property color bg: "{tok['bg']}"
    readonly property color surface: "{tok['surface']}"
    readonly property color elev: "{tok['elev']}"
    readonly property color border: "{tok['border']}"
    readonly property color fg: "{tok['fg']}"
    readonly property color fgMuted: "{tok['fg_muted']}"
    readonly property color accent: "{tok['accent']}"
    readonly property color accentSoft: "{tok['accent_soft']}"
    readonly property color success: "{tok['success']}"
    readonly property color warning: "{tok['warning']}"
    readonly property color danger: "{tok['danger']}"
    readonly property color info: "{tok['info']}"

    readonly property QtObject severity: QtObject {{
        readonly property color critical: "{p['severity']['critical']}"
        readonly property color high: "{p['severity']['high']}"
        readonly property color medium: "{p['severity']['medium']}"
        readonly property color low: "{p['severity']['low']}"
        readonly property color ok: "{p['severity']['ok']}"
        readonly property color good: "{p['severity']['good']}"
    }}
}}
"""
(base / "quickshell" / "colors" / "Colors.qml").write_text(qml)

print("gerado: waybar/colors.css · walker/themes/dash/style.css · quickshell/colors/Colors.qml")
PY
