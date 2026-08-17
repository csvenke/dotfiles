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

-- Vim style navigation/movement.
hl.bind("SUPER + H", hl.dsp.focus({ direction = "l" }), { description = "Move focus left" })
hl.bind("SUPER + J", hl.dsp.focus({ direction = "d" }), { description = "Move focus down" })
hl.bind("SUPER + K", hl.dsp.focus({ direction = "u" }), { description = "Move focus up" })
hl.bind("SUPER + L", hl.dsp.focus({ direction = "r" }), { description = "Move focus right" })
hl.bind("SUPER + SHIFT + H", hl.dsp.window.move({ direction = "l" }), { description = "Move window left" })
hl.bind("SUPER + SHIFT + J", hl.dsp.window.move({ direction = "d" }), { description = "Move window down" })
hl.bind("SUPER + SHIFT + K", hl.dsp.window.move({ direction = "u" }), { description = "Move window up" })
hl.bind("SUPER + SHIFT + L", hl.dsp.window.move({ direction = "r" }), { description = "Move window right" })
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

[main]

# Maps capslock to escape when pressed and super when held.
capslock = overload(super, esc)
```

## Machine specific

### MacBook Pro 14,3

#### Input Devices

**Issue**: TouchBar is not functional
**Solution**: Remap capslock to escape

**Issue**: Integrated camera is not functioning
**Solution**: No solution, dependent on touchbar
