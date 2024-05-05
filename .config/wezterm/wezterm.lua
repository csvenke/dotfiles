local wezterm = require("wezterm")
local config = wezterm.config_builder()

wezterm.on("format-window-title", function()
	return "Terminal"
end)

config.colors = require("nordic")
config.enable_tab_bar = false
config.font_size = 16
config.window_frame = {
	font_size = 16.0,
}
config.window_padding = {
	left = 0,
	right = 0,
	top = 0,
	bottom = 0,
}

return config
