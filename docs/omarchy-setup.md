# Omarchy setup

## Config

### hyprland

**`.config/hypr/bindings.conf`**

```hyprlang
# Vim-style window navigation
unbind = SUPER, H
unbind = SUPER, J
unbind = SUPER, K
unbind = SUPER, L
unbind = SUPER SHIFT, H
unbind = SUPER SHIFT, J
unbind = SUPER SHIFT, K
unbind = SUPER SHIFT, L

# Move focus between windows
bindd = SUPER, H, Focus on left window, movefocus, l
bindd = SUPER, J, Focus on below window, movefocus, d
bindd = SUPER, K, Focus on above window, movefocus, u
bindd = SUPER, L, Focus on right window, movefocus, r

# Move (swap) windows
bindd = SUPER SHIFT, H, Swap window to the left, swapwindow, l
bindd = SUPER SHIFT, J, Swap window down, swapwindow, d
bindd = SUPER SHIFT, K, Swap window up, swapwindow, u
bindd = SUPER SHIFT, L, Swap window to the right, swapwindow, r
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
