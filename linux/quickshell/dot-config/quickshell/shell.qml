import Quickshell
import qs.modules.notifications
import qs.modules.panels

// Notification daemon (replacing mako) plus the quick settings panels that
// replace the `ghostty -e <tui>` launchers on waybar. The bar itself stays
// waybar, so everything here is driven over `qs ipc`.
ShellRoot {
    Popups {}
    Center {}

    AudioPanel {}
    BluetoothPanel {}
}
