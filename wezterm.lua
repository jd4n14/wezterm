local wezterm = require("wezterm")

local config = wezterm.config_builder()
local appearance = wezterm.gui and wezterm.gui.get_appearance() or "Dark"
local is_dark = appearance:find("Dark") ~= nil
local preferred_scheme = is_dark and "nightfox" or "dayfox"

config.automatically_reload_config = true

config.font = wezterm.font_with_fallback({
  {
    family = "Cascadia Code",
    weight = "Light",
  },
  "SF Mono",
  "Menlo",
})
config.font_size = 13.5
config.line_height = 1.12
config.cell_width = 1.0

config.window_decorations = "RESIZE"
config.window_close_confirmation = "NeverPrompt"
config.native_macos_fullscreen_mode = true
config.macos_window_background_blur = 28
config.window_background_opacity = is_dark and 0.88 or 0.96
config.text_background_opacity = 1.0
config.window_padding = {
  left = 14,
  right = 14,
  top = 10,
  bottom = 10,
}

config.initial_cols = 132
config.initial_rows = 34
config.adjust_window_size_when_changing_font_size = false
config.scrollback_lines = 10000
config.enable_scroll_bar = true
config.mouse_wheel_scrolls_tabs = false
config.alternate_buffer_wheel_scroll_speed = 3
config.audible_bell = "Disabled"
config.default_cursor_style = "BlinkingBar"
config.cursor_blink_rate = 650

config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = false
config.show_tab_index_in_tab_bar = false
config.tab_max_width = 28
config.switch_to_last_active_tab_when_closing_tab = true

config.inactive_pane_hsb = {
  saturation = 0.85,
  brightness = 0.7,
}

config.color_scheme = preferred_scheme

config.leader = { key = "Space", mods = "CTRL", timeout_milliseconds = 1000 }
config.keys = {
  { key = "Enter", mods = "ALT", action = wezterm.action.ToggleFullScreen },
  { key = "d", mods = "LEADER", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "D", mods = "LEADER", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },
  { key = "h", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Left") },
  { key = "j", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Down") },
  { key = "k", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Up") },
  { key = "l", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Right") },
  { key = "w", mods = "LEADER", action = wezterm.action.CloseCurrentPane({ confirm = false }) },
  { key = "t", mods = "CMD", action = wezterm.action.SpawnTab("CurrentPaneDomain") },
  { key = "w", mods = "CMD", action = wezterm.action.CloseCurrentTab({ confirm = false }) },
  { key = "LeftArrow", mods = "CMD|OPT", action = wezterm.action.ActivateTabRelative(-1) },
  { key = "RightArrow", mods = "CMD|OPT", action = wezterm.action.ActivateTabRelative(1) },
}

config.mouse_bindings = {
  {
    event = { Down = { streak = 1, button = { WheelUp = 1 } } },
    mods = "NONE",
    action = wezterm.action.ScrollByCurrentEventWheelDelta,
  },
  {
    event = { Down = { streak = 1, button = { WheelDown = 1 } } },
    mods = "NONE",
    action = wezterm.action.ScrollByCurrentEventWheelDelta,
  },
}

config.default_prog = { '/opt/homebrew/bin/tmux', 'new-session', '-A', '-s', 'main' }

return config
