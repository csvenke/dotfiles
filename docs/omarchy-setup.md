# Omarchy setup

## Hardware

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

**Solution 1**: Remap capslock to escape

Add to `.config/hypr/input.conf`:

```hyprlang
input {
  kb_options = caps:escape
}
```

**Solution 2**: Remap capslock with keyd

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

# Maps capslock to escape when pressed and control when held.
capslock = overload(control, esc)

# Remaps the escape key to capslock
esc = capslock
```

**Issue**: Integrated camera is not functioning

#### Audio

**Issue**: Internal speakers are not working  
**Workaround**: Use external speakers or headphones for audio output
