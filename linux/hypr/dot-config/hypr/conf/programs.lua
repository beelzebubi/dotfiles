-- Programs the rest of the config refers to.
-- Shared through require() because each required file is its own Lua scope.

return {
    terminal     = "ghostty",
    file_manager = "dolphin",
    browser      = "zen-browser",
    -- The launcher is a Noctalia panel, not a separate binary.
    menu         = "noctalia msg panel-toggle launcher",
}
