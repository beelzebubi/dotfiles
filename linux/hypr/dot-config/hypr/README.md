Hyprland
--------

`linux/hypr` is a Lua config, which is the format Hyprland uses as of 0.56.
`hyprland.lua` is the entry point and pulls the rest in with `require`, one
scope per file, so an error in one of them does not take the whole config
down:

| File | Contents |
| ---- | -------- |
| `hyprland.lua` | autostart, look and feel, animations, input, window and workspace rules |
| `conf/programs.lua` | terminal, file manager, browser, launcher - returned as a table the other files require |
| `conf/monitor.lua` | `hl.monitor()` |
| `conf/env.lua` | `hl.env()`, including the NVIDIA variables |
| `conf/keybindings.lua` | every `hl.bind()` |

`hyprpaper.conf` stays in its own format - it belongs to hyprpaper, not to
Hyprland, and Noctalia draws the wallpaper now anyway.


