pragma Singleton

import Quickshell

// Rosé Pine, matching waybar/themes/rose-pine.css - the theme style.css
// actually imports - so bar and shell share one palette.
Singleton {
    readonly property color base: "#191724"
    readonly property color surface: "#1f1d2e"
    readonly property color overlay: "#26233a"
    readonly property color muted: "#6e6a86"
    readonly property color subtle: "#908caa"
    readonly property color text: "#e0def4"

    readonly property color love: "#eb6f92"
    readonly property color gold: "#f6c177"
    readonly property color rose: "#ebbcba"
    readonly property color pine: "#31748f"
    readonly property color foam: "#9ccfd8"
    readonly property color iris: "#c4a7e7"

    // waybar/style.css uses the same family, so bar and shell match.
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 12
    readonly property int fontSizeSmall: 10

    // Geometry carried over from mako.ini one to one.
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
