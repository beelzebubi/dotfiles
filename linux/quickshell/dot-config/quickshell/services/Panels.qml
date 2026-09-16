pragma Singleton

import Quickshell
import Quickshell.Io

// Which quick-settings panel is open. Waybar drives this over IPC, since the
// bar stays waybar rather than moving into quickshell:
//   qs ipc call panels toggle audio
Singleton {
    id: root

    // "" | "audio" | "bluetooth"
    property string current: ""

    function toggle(name) {
        root.current = root.current === name ? "" : name;
    }

    function close() {
        root.current = "";
    }

    IpcHandler {
        target: "panels"

        function toggle(name: string): void {
            root.toggle(name);
        }

        function show(name: string): void {
            root.current = name;
        }

        function close(): void {
            root.close();
        }
    }
}
