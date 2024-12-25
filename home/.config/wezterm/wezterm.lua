local wezterm = require("wezterm")
local config = wezterm.config_builder()

wezterm.on("format-window-title", function()
	return "Terminal"
end)

config.colors = require("nordic")
config.enable_tab_bar = false
config.font_size = 16
config.font = wezterm.font_with_fallback({
	{
		family = "JetBrains Mono",
		weight = "Bold",
		style = "Normal",
	},
})
config.window_padding = {
	left = 0,
	right = 0,
	top = 0,
	bottom = 0,
}

return config
