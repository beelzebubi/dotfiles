Quickshell
----------

`linux/quickshell` is the notification daemon and the quick settings panels.
It replaces `mako`, and the `ghostty -e <tui>` launchers that used to hang off
the waybar modules. The bar itself is still waybar.

    ~/.config/quickshell/
    ├── shell.qml                     entry point
    ├── Theme.qml                     Rosé Pine tokens, same as waybar
    ├── services/Notifs.qml           notification server, history, DND
    ├── services/Panels.qml           which panel is open
    ├── modules/notifications/        popups + history center
    ├── modules/panels/               audio, network and bluetooth panels
    └── widgets/                      shared slider and button

Everything is driven over IPC, because waybar is a separate process:

| Trigger | Command |
| ------- | ------- |
| waybar audio module | `qs ipc call panels toggle audio` |
| waybar network module | `qs ipc call panels toggle network` |
| waybar bluetooth module | `qs ipc call panels toggle bluetooth` |
| `SUPER ALT CTRL SHIFT + N` | `qs ipc call notifs toggleCenter` |
| `SUPER SHIFT + N` | `qs ipc call notifs toggleDnd` |

The TUIs stay installed as a fallback for what the panels do not cover
(per-stream routing, codecs, pairing edge cases): middle click the audio module
for `wiremix`, right click the bluetooth module for `bluetui`, right click the
network module for `nmtui`.

### Wifi moved to NetworkManager

`Quickshell.Networking` only implements a NetworkManager backend — its
`NetworkBackendType` enum knows `None` and `NetworkManager`, nothing else — so
the network panel needs NetworkManager running. This setup used bare `iwd`
through `impala` before.

The migration keeps `iwd`: NetworkManager is installed in front of it and
configured to use it as the wifi backend via
`install/linux/networkmanager/wifi-backend-iwd.conf`, which `install.sh` drops
into `/etc/NetworkManager/conf.d/`. The known networks under `/var/lib/iwd`
therefore keep working, and `wpa_supplicant` is not involved.

`impala` is gone from `pkgs.txt` because it talks to iwd directly and would
fight NetworkManager over the same device.

`org.freedesktop.Notifications` can only be owned by one process. `install.sh`
masks `mako.service` if mako is still installed, otherwise dbus can activate it
and one of the two loses the name.

