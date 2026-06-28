//@ pragma UseQApplication
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QPA_PLATFORMTHEME=

import "./overview/modules/overview/"
import "./overview/services/"
import "./overview/common/"
import "./overview/common/functions/"
import "./overview/common/widgets/"
import "./modules/clock/"
import "./modules/powermenu/"
import "./modules/osd/"
import "./modules/switcher/"

import QtQuick
import Quickshell
import Quickshell.Hyprland

ShellRoot {
    Overview {}
    ClockWidget {}
    PowerMenu {}
    Osd {}
    WindowSwitcher {}
}
