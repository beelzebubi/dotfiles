-------------------
--- KEYBINDINGS ---
-------------------

-- See https://wiki.hypr.land/configuring/core/binds/

local programs = require("conf.programs")

local mainMod = "SUPER"                        -- the "Windows" key
local hyprKey = "SUPER + ALT + CTRL + SHIFT"

hl.bind(mainMod .. " + space", hl.dsp.exec_cmd(programs.menu))
-- hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))

-- OS commands
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("noctalia msg session lock"))
hl.bind(mainMod .. " + comma", hl.dsp.exec_cmd("noctalia msg settings-toggle"),
        { description = "Noctalia settings window" })
hl.bind(hyprKey .. " + W", hl.dsp.exec_cmd("noctalia msg config-reload"),
        { description = "Reload the Noctalia config" })

-- Noctalia notifications
-- hyprKey already contains SHIFT, so DND uses mainMod + SHIFT instead.
hl.bind(hyprKey .. " + N", hl.dsp.exec_cmd("noctalia msg panel-toggle control-center notifications"))
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("noctalia msg notification-dnd-toggle"))

-- Applications
hl.bind(hyprKey .. " + Return", hl.dsp.exec_cmd(programs.terminal))
hl.bind(hyprKey .. " + E", hl.dsp.exec_cmd(programs.file_manager))

-- Noctalia panels (replaces rofi, wlogout and grim/slurp)
-- The launcher itself is mainMod + space, at the top of this file.
hl.bind(hyprKey .. " + Escape", hl.dsp.exec_cmd("noctalia msg panel-toggle session"),
        { description = "Session menu" })
hl.bind(hyprKey .. " + Print", hl.dsp.exec_cmd("noctalia msg screenshot-fullscreen pick"),
        { description = "Screenshot, pick a display" })
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("noctalia msg screenshot-region"),
        { description = "Screenshot a region" })
hl.bind(hyprKey .. " + C", hl.dsp.exec_cmd("noctalia msg panel-toggle clipboard"),
        { description = "Clipboard history" })

-- Windows
hl.bind(hyprKey .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(hyprKey .. " + P", hl.dsp.window.pseudo())   -- dwindle

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Switch workspaces with mainMod + [0-9]
-- Move the active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10   -- workspace 10 sits on the 0 key
    hl.bind(mainMod .. " + " .. key,           hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key,   hl.dsp.window.move({ workspace = i }))
end

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
-- hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Move the current workspace to the next/previous monitor
hl.bind(mainMod .. " + SHIFT + period", hl.dsp.workspace.move({ monitor = "+1" }))
hl.bind(mainMod .. " + SHIFT + comma",  hl.dsp.workspace.move({ monitor = "-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness.
-- Going through Noctalia instead of wpctl/brightnessctl gets the OSD as well.
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("noctalia msg volume-up 5%"),   { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("noctalia msg volume-down 5%"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("noctalia msg volume-mute"),    { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("noctalia msg mic-mute"),       { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("noctalia msg brightness-up"),  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("noctalia msg brightness-down"),{ locked = true, repeating = true })

-- MPRIS, handled by Noctalia - playerctl is no longer needed
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("noctalia msg media next"),     { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("noctalia msg media toggle"),   { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("noctalia msg media toggle"),   { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("noctalia msg media previous"), { locked = true })
