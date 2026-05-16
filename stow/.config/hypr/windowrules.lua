-- ============================================================
--  WINDOW RULES — portado de windowrules.conf
--  API: https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- ============================================================

-- Nautilus como popup flutuante centralizado
hl.window_rule({
    match  = { class = "org\\.gnome\\.Nautilus|nautilus" },
    float  = true,
    center = true,
    size   = { 1100, 700 },
})

-- File picker dialogs (Cursor/outros apps — match por título)
hl.window_rule({
    match  = { title = "Open File|Save As|Select File|Choose File|Select Folder|Open Folder|Save File|Select Directory|Choose Folder" },
    float  = true,
    center = true,
    size   = { 1100, 700 },
})

-- Whisper PTT overlay (eww widget)
hl.window_rule({
    match = { class = "eww-whisper-ptt" },
    float = true,
    pin   = true,
})

-- Electron apps (Cursor/VSCode) — floating popups ficam na frente
-- tag + stay_focused garante que popup mantém foco até ser fechado
hl.window_rule({
    match    = { class = "cursor|code|code-url-handler|Cursor|Code", float = true },
    tag      = "+electron-popup",
    min_size = { 1, 1 },
})
hl.window_rule({
    match        = { tag = "electron-popup" },
    stay_focused = true,
})

-- Portal de arquivo do sistema (xdg-desktop-portal-gtk)
hl.window_rule({
    match  = { class = "xdg-desktop-portal-gtk" },
    float  = true,
    center = true,
    size   = { "monitor_w*0.7", "monitor_h*0.6" },
})

-- Claude session borders por perfil
hl.window_rule({ match = { title = "Claude\\[pessoal\\]" },  border_color = "rgba(7c3aedee)" })
hl.window_rule({ match = { title = "Claude\\[trabalho\\]" }, border_color = "rgba(ff9900ee)" })
hl.window_rule({ match = { title = "Claude\\[worker\\]" },   border_color = "rgba(00ff41ee)" })
hl.window_rule({ match = { title = "Claude\\[auto\\]" },     border_color = "rgba(00ccffee)" })
