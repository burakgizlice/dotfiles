local wezterm = require("wezterm")
local act = wezterm.action

local config = wezterm.config_builder()

config.color_scheme = "rose-pine-moon"
config.font = wezterm.font("Hack Nerd Font")
config.font_size = 15.0
config.window_background_opacity = 0.8
-- config.macos_window_background_blur = 50  -- macOS-only; no-op on Linux
config.hide_tab_bar_if_only_one_tab = true
config.window_decorations = "RESIZE"

-- Toggle fullscreen with Super+Enter (or press F11)
config.keys = {
  {
    key = "Return",
    mods = "SUPER",
    action = act.ToggleFullScreen,
  },
  {
    key = "F11",
    action = act.ToggleFullScreen,
  },
}

return config
