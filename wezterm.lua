local wezterm = require("wezterm")

-- Keep in sync with herdr + Grok TUI (Tokyo Night family).
local SCHEME_DARK = "Tokyo Night"
local SCHEME_LIGHT = "Tokyo Night Day"
local OPACITY_DARK = 0.72
local OPACITY_LIGHT = 0.82

local HOME = wezterm.home_dir
local HERDR_SYNC = HOME .. "/.config/wezterm/sync-herdr-theme.sh"

local function is_dark_appearance(appearance)
	return appearance:find("Dark") ~= nil
end

local function theme_for_appearance(appearance)
	if is_dark_appearance(appearance) then
		return {
			mode = "dark",
			color_scheme = SCHEME_DARK,
			window_background_opacity = OPACITY_DARK,
		}
	end
	return {
		mode = "light",
		color_scheme = SCHEME_LIGHT,
		window_background_opacity = OPACITY_LIGHT,
	}
end

--- Herdr cannot detect light/dark under WezTerm (no CSI 2031).
--- Mirror OS appearance into ~/.config/herdr/config.toml instead.
local function sync_herdr_theme(mode)
	-- Fire-and-forget; failures must not break the terminal.
	wezterm.background_child_process({ HERDR_SYNC, mode })
end

--- Apply light/dark theme to a live window (WezTerm fires window-config-reloaded
--- when the OS appearance changes).
local function apply_appearance(window)
	local overrides = window:get_config_overrides() or {}
	local theme = theme_for_appearance(window:get_appearance())
	local changed = false

	if overrides.color_scheme ~= theme.color_scheme then
		overrides.color_scheme = theme.color_scheme
		changed = true
	end
	if overrides.window_background_opacity ~= theme.window_background_opacity then
		overrides.window_background_opacity = theme.window_background_opacity
		changed = true
	end

	if changed then
		window:set_config_overrides(overrides)
	end

	-- Always attempt herdr sync (script is idempotent).
	sync_herdr_theme(theme.mode)
end

wezterm.on("window-config-reloaded", function(window, _pane)
	apply_appearance(window)
end)

wezterm.on("window-focus-changed", function(window, _pane)
	-- Catch appearance flips that happen while WezTerm was unfocused.
	if window:is_focused() then
		apply_appearance(window)
	end
end)

local config = wezterm.config_builder()

-- Initial values for the first frame (before per-window overrides land).
local boot_appearance = wezterm.gui and wezterm.gui.get_appearance() or "Dark"
local boot_theme = theme_for_appearance(boot_appearance)

-- Sync herdr on config load (covers cold start before any window event).
sync_herdr_theme(boot_theme.mode)

config.automatically_reload_config = true

-- macOS dead keys: Option+e then e → é, Option+n then n → ñ, etc.
-- Default is left=false (Alt/Meta) / right=true (compose). Enable left so
-- the usual Option key produces accents. Prefer Right Option if you need Alt
-- for bindings (e.g. Alt+Enter fullscreen still works with Right Option).
config.send_composed_key_when_left_alt_is_pressed = true
config.send_composed_key_when_right_alt_is_pressed = true
config.use_ime = true

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
config.macos_window_background_blur = 40
config.window_background_opacity = boot_theme.window_background_opacity
config.text_background_opacity = 1.0
config.window_padding = {
	left = 0,
	right = 0,
	top = 0,
	bottom = 0,
}

config.initial_cols = 132
config.initial_rows = 34
config.adjust_window_size_when_changing_font_size = false
config.scrollback_lines = 10000
config.enable_scroll_bar = false
config.mouse_wheel_scrolls_tabs = false
config.alternate_buffer_wheel_scroll_speed = 3
config.audible_bell = "Disabled"
config.default_cursor_style = "BlinkingBar"
config.cursor_blink_rate = 650

-- Tab bar hidden: herdr handles tabs/sessions.
config.enable_tab_bar = false
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.show_tab_index_in_tab_bar = false
config.tab_max_width = 28
config.switch_to_last_active_tab_when_closing_tab = true

config.inactive_pane_hsb = {
	saturation = 0.85,
	brightness = 0.7,
}

config.color_scheme = boot_theme.color_scheme

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

-- Herdr is the session/pane multiplexer; WezTerm is just the host terminal.
config.default_prog = {
	"/bin/zsh",
	"-lc",
	"exec /opt/homebrew/bin/herdr",
}

return config
