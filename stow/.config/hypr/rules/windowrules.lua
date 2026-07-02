-- ============================================================
--  WINDOW RULES
--  API: https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- ============================================================

-- Utilitários flutuantes, sempre no topo, fora do tiling (estilo "system overlay").
local function system_overlay(opts)
    hl.window_rule({
        match  = opts.match,
        float  = true,
        pin    = true,
        tile   = false,
        center = opts.center ~= false,
        size   = opts.size,
    })
end

-- ── File managers ─────────────────────────────────────────────
system_overlay({
    match = { class = "org\\.gnome\\.Nautilus|nautilus|org.gnome.Nautilus|Thunar|thunar|org.kde.dolphin|dolphin|nemo|Nemo|pcmanfm|Pcmanfm" },
    size  = { 1100, 700 },
})

-- ── File / folder pickers (GTK, Electron, portal) ───────────
system_overlay({
    match = { title = "Open File|Save As|Select File|Choose File|Select Folder|Open Folder|Save File|Select Directory|Choose Folder|Choose wallpaper|File Upload|Select a File|Select a Folder|Browse Folder|Browse Files" },
    size  = { 1100, 700 },
})

system_overlay({
    match = { class = "xdg-desktop-portal-gtk|zenity|Zenity|yad|Yad|kdialog" },
    size  = { "monitor_w*0.7", "monitor_h*0.65" },
})

-- ── Cloudflare Zero Trust (warp-taskbar) ──────────────────────
system_overlay({
    match = { class = "Cloudflare Zero Trust|com\\.cloudflare\\.WarpTaskbar|warp-taskbar" },
    size  = { 520, 640 },
})

-- ── Config de monitores ───────────────────────────────────────
system_overlay({
    match = { class = "wdisplays|network\\.cycles\\.wdisplays|nwg-displays|nwg-display" },
    size  = { 960, 640 },
})

-- ── Auth / login popups (Chrome, Firefox, Chromium) ───────────
system_overlay({
    match = {
        title = "Sign in|Log in|Login|Mozilla accounts|Google Account|Authentication|Authorize|Account chooser|Passkeys|Verify it.?s you|Choose an account|Connect to|OAuth|2-Step Verification|Enter your password",
        class = "Chromium-browser|Chromium|chrome-.*|google-chrome|Google-chrome|Firefox|firefox|zen|Brave-browser|Microsoft-edge|msedge",
    },
    size = { 520, 720 },
})

-- ── Outros utilitários de sistema (mesma vibe) ───────────────
system_overlay({
    match = { class = "pavucontrol|Pavucontrol|org\\.pulseaudio\\.pavucontrol|org\\.gnome\\.Settings|org.gnome.Calculator|org.gnome.clocks|blueman-manager|Blueman-manager|nm-connection-editor|Nm-connection-editor|org.gnome.NautilusPreviewer|org.gnome.eog|Eog|org.gnome.Evince|evince|gnome-disks|Gnome-disks|org.gnome.DiskUtility|file-roller|File-roller|org.gnome.FileRoller|hyprland-help" },
    size  = { 900, 620 },
})

system_overlay({
    match = { class = "Polkit|polkit|lxqt-policykit-agent|org.freedesktop.policykit|hyprpolkitagent" },
    size  = { 480, 280 },
})

-- Electron apps (Cursor/VSCode) — floating popups ficam na frente
hl.window_rule({
    match    = { class = "cursor|code|code-url-handler|Cursor|Code", float = true },
    tag      = "+electron-popup",
    min_size = { 1, 1 },
})
hl.window_rule({
    match        = { tag = "electron-popup", float = true },
    stay_focused = true,
})

-- Claude session borders por perfil
hl.window_rule({ match = { title = "Claude\\[pessoal\\]" },  border_color = "rgba(7c3aedee)" })
hl.window_rule({ match = { title = "Claude\\[trabalho\\]" }, border_color = "rgba(ff9900ee)" })
hl.window_rule({ match = { title = "Claude\\[worker\\]" },   border_color = "rgba(00ff41ee)" })
hl.window_rule({ match = { title = "Claude\\[auto\\]" },     border_color = "rgba(00ccffee)" })

-- ============================================================
--  LAYER RULES — overlays snappy (sem animação Hyprland)
-- ============================================================

local layers = {
    "walker",
    "quickshell.*",
    "gtk4-layer-shell",
    "gtk-layer-shell",
    "swaync",
    "selection",
    "hyprpicker",
    "wlogout",
    "logout_dialog",
}

for _, ns in ipairs(layers) do
    hl.layer_rule({
        match   = { namespace = ns },
        no_anim = true,
    })
end
