# Omarchy setup

## Config

### hyprland

**`.config/hypr/input.lua`**

```lua
hl.config({
	input = {
		kb_layout = "no",
		kb_options = "",
	},
})
```

**`.config/hypr/bindings.lua`**

```lua
hl.unbind("SUPER + H")
hl.unbind("SUPER + J")
hl.unbind("SUPER + K")
hl.unbind("SUPER + L")
hl.unbind("SUPER + SHIFT + H")
hl.unbind("SUPER + SHIFT + J")
hl.unbind("SUPER + SHIFT + K")
hl.unbind("SUPER + SHIFT + L")
hl.unbind("SUPER + ALT + H")
hl.unbind("SUPER + ALT + J")
hl.unbind("SUPER + ALT + K")
hl.unbind("SUPER + ALT + L")
hl.unbind("SUPER + ALT + K")
hl.unbind("ALT + SPACE") -- Omarchy dictation toggle
hl.unbind("ALT + Alt_R") -- Omarchy dictation push-to-talk

-- Vim style navigation/movement/resizing
hl.bind("SUPER + H", hl.dsp.focus({ direction = "l" }), { description = "Move focus left" })
hl.bind("SUPER + J", hl.dsp.focus({ direction = "d" }), { description = "Move focus down" })
hl.bind("SUPER + K", hl.dsp.focus({ direction = "u" }), { description = "Move focus up" })
hl.bind("SUPER + L", hl.dsp.focus({ direction = "r" }), { description = "Move focus right" })
hl.bind("SUPER + SHIFT + H", hl.dsp.window.move({ direction = "l" }), { description = "Move window left" })
hl.bind("SUPER + SHIFT + J", hl.dsp.window.move({ direction = "d" }), { description = "Move window down" })
hl.bind("SUPER + SHIFT + K", hl.dsp.window.move({ direction = "u" }), { description = "Move window up" })
hl.bind("SUPER + SHIFT + L", hl.dsp.window.move({ direction = "r" }), { description = "Move window right" })
o.bind("SUPER + ALT + H", "Resize window left", hl.dsp.window.resize({ x = -25, y = 0, relative = true }))
o.bind("SUPER + ALT + J", "Resize window down", hl.dsp.window.resize({ x = 0, y = 25, relative = true }))
o.bind("SUPER + ALT + K", "Resize window up", hl.dsp.window.resize({ x = 0, y = -25, relative = true }))
o.bind("SUPER + ALT + L", "Resize window right", hl.dsp.window.resize({ x = 25, y = 0, relative = true }))
```

### keyd

Install `keyd`

```bash
sudo pacman -S keyd
sudo systemctl enable keyd --now
sudo keyd reload
```

Put the following in `/etc/keyd/default.conf`

```conf
[ids]

*
# Exclude my zsa voyager
-3297:1977

[main]

# Maps capslock to escape when pressed and super when held.
capslock = overload(meta, esc)
```

Voyager excluded: keyd turns RightSuper into LeftSuper.

### superwhisper

```bash
superwhisper shortcuts set hold "RightSuper"
```

### mise

Disable Omarchy's default mise tools.

```bash
omarchy-mise-default-tools disable
rm -rf ~/.local/share/mise/installs ~/.cache/mise
```

## Machine specific

### MacBook Pro 14,3

#### Input Devices

**Issue**: TouchBar is not functional
**Solution**: Remap capslock to escape

**Issue**: Integrated camera is not functioning
**Solution**: No solution, dependent on touchbar
