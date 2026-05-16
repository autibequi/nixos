-- ============================================================
--  WINDOW RULES — portado de windowrules.conf
-- ============================================================

-- Nautilus como popup flutuante centralizado
hl.window_rule({
    match        = { class = "org%.gnome%.Nautilus|nautilus" },
    float        = true,
    center       = true,
    size         = { w = 1100, h = 700 },
})

-- File picker dialogs (Cursor/outros apps — match por título)
hl.window_rule({
    match        = { title = "Open File|Save As|Select File|Choose File|Select Folder|Open Folder|Save File|Select Directory|Choose Folder" },
    float        = true,
    center       = true,
    size         = { w = 1100, h = 700 },
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
    match    = { class = "cursor|code|code-url-handler|Cursor|Code", floating = true },
    tag      = "+electron-popup",
    min_size = { w = 1, h = 1 },
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
    size   = "70% 60%",
})

-- Claude session borders por perfil
hl.window_rule({ match = { title = "Claude%[pessoal%]" },  border_color = "rgba(7c3aedee)" })
hl.window_rule({ match = { title = "Claude%[trabalho%]" }, border_color = "rgba(ff9900ee)" })
hl.window_rule({ match = { title = "Claude%[worker%]" },   border_color = "rgba(00ff41ee)" })
hl.window_rule({ match = { title = "Claude%[auto%]" },     border_color = "rgba(00ccffee)" })
