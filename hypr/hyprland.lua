local local_cfg = require("local")

hl.config({
    input = {
        touchpad = {
            tap_to_click = true,
            natural_scroll = true,
        },
    },

    general = {
        gaps_in = 4,
        gaps_out = 2,
        border_size = 2,

        col = {
            active_border = "rgb(ffffff)",
            inactive_border = "rgb(2a2a2a)",
        },

        layout = "dwindle",
    },

    animations = {
        enabled = true,
    },

    decoration = {
        rounding = 10,
    },

    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        background_color = 0x000000,
    },

    dwindle = {
        preserve_split = true,
    },
})

hl.animation({ leaf = "windowsIn", enabled = true, speed = 4, bezier = "default" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 0.8, bezier = "linear", style = "slide bottom" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 3, bezier = "default" })

for i = 1, 9 do
    hl.workspace_rule({ workspace = tostring(i), persistent = true })
end

hl.on("hyprland.start", function()
    hl.exec_cmd(local_cfg.qs)
    hl.exec_cmd("awww-daemon -q")
    hl.exec_cmd(local_cfg.autoOutput)
end)

local mainMod = "SUPER"

hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(local_cfg.qs .. " ipc call launcher toggle"))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(local_cfg.qs .. " ipc call clipboard toggle"))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(local_cfg.qs .. " ipc call tray toggle"))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd(local_cfg.lock))
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(local_cfg.terminal))

hl.bind(mainMod .. " + N", hl.dsp.exec_cmd(local_cfg.qs .. " ipc call notifications press"))
hl.bind(mainMod .. " + W", hl.dsp.window.close())
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
hl.bind(mainMod .. " + left", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + M", hl.dsp.exit())

for i = 1, 9 do
    hl.bind(mainMod .. " + " .. i, hl.dsp.focus({ workspace = i }))
end

for i = 1, 7 do
    hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i, silent = true }))
end
hl.bind(mainMod .. " + SHIFT + 8", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + SHIFT + 9", hl.dsp.focus({ workspace = "e+1" }))

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })

hl.bind("XF86Calculator", hl.dsp.exec_cmd(local_cfg.calculator))

hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -n1 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -n1 set 5%-"), { locked = true, repeating = true })

require("numpad-binds")
