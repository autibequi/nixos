-- Wayland: GLFW não define class/app_id — só title "chicote".
hl.window_rule({
    match            = { title = "^chicote$" },
    float            = true,
    pin              = true,
    size             = { "monitor_w", "monitor_h" },
    move             = "0 0",
    border_size      = 0,
    rounding         = 0,
    no_focus         = true,
    no_initial_focus = true,
    no_blur          = true,
    no_dim           = true,
})
