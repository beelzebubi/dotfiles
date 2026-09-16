pragma Singleton

import Quickshell

// Rosé Pine Moon. Same palette the old mako.ini and rofi's rose-pine-moon.rasi
// used, so notifications keep the look they had before the migration.
Singleton {
    readonly property color base: "#232136"
    readonly property color surface: "#2a273f"
    readonly property color overlay: "#393552"
    readonly property color muted: "#6e6a86"
    readonly property color subtle: "#908caa"
    readonly property color text: "#e0def4"

    readonly property color love: "#eb6f92"
    readonly property color gold: "#f6c177"
    readonly property color rose: "#ea9a97"
    readonly property color pine: "#3e8fb0"
    readonly property color foam: "#9ccfd8"
    readonly property color iris: "#c4a7e7"

    // waybar/style.css uses the same family, so bar and shell match.
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 12
    readonly property int fontSizeSmall: 10

    // Carried over from mako.ini one to one.
    readonly property int popupWidth: 420
    readonly property int screenMargin: 20
    readonly property int padding: 10
    readonly property int borderSize: 2
    readonly property int notifRadius: 2
    readonly property int defaultTimeout: 5000

    // Panels are new, so they follow hyprland's decoration.rounding (10)
    // rather than mako's near-square corners.
    readonly property int radius: 10
    readonly property int panelWidth: 380
    readonly property int spacing: 8
}
