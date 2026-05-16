-- ============================================================
--  THEME — portado de theme.sh
--  dark_theme(), light_theme(), toggle_theme()
-- ============================================================

local HOME = os.getenv("HOME")

local THEME_STATE_FILE = HOME .. "/.cache/hyprland/hyprutils_theme_state"
local ALACRITTY_CONFIG = HOME .. "/.config/alacritty/alacritty.toml"
local WALLPAPER_DARK   = HOME .. "/assets/wallpapers/the-wild-hunt-of-odin.jpg"
local WALLPAPER_LIGHT  = HOME .. "/assets/wallpapers/the-death-of-socrates.jpg"

local _theme_state = "dark"  -- estado em memória (sincronizado com arquivo em disco)

local function write_gtk_config(path, theme_name, prefer_dark)
    local dark_val = prefer_dark and "1" or "0"
    local content = "[Settings]\n" ..
        "gtk-theme-name=" .. theme_name .. "\n" ..
        "gtk-application-prefer-dark-theme=" .. dark_val .. "\n" ..
        "gtk-icon-theme-name=Adwaita\n" ..
        "gtk-font-name=Sans 10\n" ..
        "gtk-cursor-theme-name=Adwaita\n" ..
        "gtk-cursor-theme-size=24\n" ..
        "gtk-enable-animations=true\n"
    local f = io.open(path, "w")
    if f then f:write(content) f:close() end
end

local function apply_gtk_theme(gtk_theme, color_scheme)
    local prefer_dark = color_scheme == "prefer-dark"
    os.execute("mkdir -p " .. HOME .. "/.config/gtk-3.0")
    os.execute("mkdir -p " .. HOME .. "/.config/gtk-4.0")
    write_gtk_config(HOME .. "/.config/gtk-3.0/settings.ini", gtk_theme, prefer_dark)
    write_gtk_config(HOME .. "/.config/gtk-4.0/settings.ini", gtk_theme, prefer_dark)

    hl.exec_cmd("sh -c 'command -v gsettings >/dev/null 2>&1 && " ..
        "gsettings set org.gnome.desktop.interface gtk-theme \"" .. gtk_theme .. "\" 2>/dev/null; " ..
        "gsettings set org.gnome.desktop.interface color-scheme \"" .. color_scheme .. "\" 2>/dev/null || true'")

    hl.exec_cmd("sh -c 'command -v dconf >/dev/null 2>&1 && " ..
        "dconf write /org/gnome/desktop/interface/gtk-theme \"'\\'" .. gtk_theme .. "\\''\" 2>/dev/null; " ..
        "dconf write /org/gnome/desktop/interface/color-scheme \"'\\'" .. color_scheme .. "\\''\" 2>/dev/null || true'")

    hl.exec_cmd("killall -SIGHUP xsettingsd 2>/dev/null || true")
end

local function save_theme_state(state)
    _theme_state = state
    os.execute("mkdir -p " .. HOME .. "/.cache/hyprland")
    local f = io.open(THEME_STATE_FILE, "w")
    if f then f:write(state) f:close() end
end

local function load_theme_state()
    local f = io.open(THEME_STATE_FILE, "r")
    if f then
        local s = f:read("*l")
        f:close()
        if s then _theme_state = s end
    end
end

load_theme_state()

function dark_theme()
    save_theme_state("dark")
    apply_gtk_theme("adw-gtk3-dark", "prefer-dark")

    -- Alacritty: troca tema
    hl.exec_cmd("sh -c '[ -f " .. ALACRITTY_CONFIG .. " ] && " ..
        "sed -i \"s|import = \\[\\\"~/.config/alacritty/light-theme.toml\\\"\\]" ..
        "|import = [\\\"~/.config/alacritty/dark-theme.toml\\\"]|g\" " ..
        ALACRITTY_CONFIG .. " || true'")

    -- Wallpaper
    hl.exec_cmd("swww img " .. WALLPAPER_DARK ..
        " --transition-type fade --transition-fps 30 --transition-duration 1.2")

    -- Regenera cores centralizadas
    hl.exec_cmd("sh -c 'command -v vennon-theme-apply >/dev/null 2>&1 && vennon-theme-apply dark || true'")
end

function light_theme()
    save_theme_state("light")
    apply_gtk_theme("adw-gtk3", "prefer-light")

    hl.exec_cmd("sh -c '[ -f " .. ALACRITTY_CONFIG .. " ] && " ..
        "sed -i \"s|import = \\[\\\"~/.config/alacritty/dark-theme.toml\\\"\\]" ..
        "|import = [\\\"~/.config/alacritty/light-theme.toml\\\"]|g\" " ..
        ALACRITTY_CONFIG .. " || true'")

    hl.exec_cmd("swww img " .. WALLPAPER_LIGHT ..
        " --transition-type fade --transition-fps 30 --transition-duration 1.2")

    hl.exec_cmd("sh -c 'command -v vennon-theme-apply >/dev/null 2>&1 && vennon-theme-apply light || true'")
end

function toggle_theme()
    if _theme_state == "dark" then
        light_theme()
        hl.exec_cmd("notify-send -t 500 'Theme changed to light'")
    else
        dark_theme()
        hl.exec_cmd("notify-send -t 500 'Theme changed to dark'")
    end
end
