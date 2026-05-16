-- Gerado originalmente por nwg-displays em 2026-05-01
-- NOTA: nwg-displays ainda gera .conf — edite este arquivo manualmente após regenerar

hl.monitor({ output = "eDP-1", mode = "2560x1600@60.0", position = "4377x122", scale = 2.0 })
hl.monitor({ output = "DP-2",  mode = "3840x2160@60.0", position = "5657x0",   scale = 2.0 })
-- Fallback para monitores desconhecidos
hl.monitor({ output = "", mode = "highres", position = "auto", scale = 2 })
