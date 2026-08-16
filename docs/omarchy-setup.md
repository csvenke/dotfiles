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
-- Vim style navigation/movement.
hl.unbind("SUPER + J")
hl.unbind("SUPER + K")
hl.unbind("SUPER + L")

o.bind("SUPER + H", "Move focus left", hl.dsp.focus({ direction = "l" }))
o.bind("SUPER + J", "Move focus down", hl.dsp.focus({ direction = "d" }))
o.bind("SUPER + K", "Move focus up", hl.dsp.focus({ direction = "u" }))
o.bind("SUPER + L", "Move focus right", hl.dsp.focus({ direction = "r" }))
o.bind("SUPER + SHIFT + H", "Move window left", hl.dsp.window.move({ direction = "l" }))
o.bind("SUPER + SHIFT + J", "Move window down", hl.dsp.window.move({ direction = "d" }))
o.bind("SUPER + SHIFT + K", "Move window up", hl.dsp.window.move({ direction = "u" }))
o.bind("SUPER + SHIFT + L", "Move window right", hl.dsp.window.move({ direction = "r" }))
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

#### Power Management

**Issue**: Sleep/Suspend functionality is not working properly  
**Solution**: Configure the system to lock instead of suspend when the lid is closed, and use Hyprland to manage display state

1. Configure systemd login manager:

   Edit `/etc/systemd/logind.conf`:

   ```conf
   [Login]
   HandleLidSwitch=lock
   HandleLidSwitchExternalPower=lock
   ```

2. Configure Hyprland lid switch behavior:

   Add to `.config/hypr/bindings.conf`:

   ```hyprlang
   bindl = , switch:on:Lid Switch, exec, hyprctl keyword monitor "eDP-1,disable"
   bindl = , switch:off:Lid Switch, exec, hyprctl keyword monitor "eDP-1,preferred,auto,2"
   ```

#### Input Devices

**Issue**: TouchBar is not functional

**Solution**: Remap capslock to escape

Add to `.config/hypr/input.conf`:

```hyprlang
input {
  kb_options = caps:escape
}
```

**Issue**: Integrated camera is not functioning

#### Audio

**Issue**: Internal speakers are not working  
**Workaround**: Use external speakers or headphones for audio output
