# WSL2 setup

## Install distro

- [Ubuntu](#ubuntu)
- [Arch Linux](#arch-linux)

### Ubuntu

#### Install

```powershell
wsl --install ubuntu
```

### Arch Linux

#### Install

```powershell
wsl --install archlinux
```

#### Setup distro (as root)

Update system packages

```bash
pacman -Syu --noconfirm
```

Setup locale

```bash
export LANG=en_US.UTF-8 \
    && sed -i "s/#${LANG}/${LANG}/" /etc/locale.gen \
    && locale-gen \
    && echo "LANG=${LANG}" > /etc/locale.conf
```

Setup sudo

```bash
pacman -S sudo vi --noconfirm \
    && echo "root ALL=(ALL:ALL) ALL" > /etc/sudoers \
    && echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers
```

Setup user (replace username)

```bash
USERNAME="username" \
    && useradd -m -G wheel -s /bin/bash "$USERNAME" \
    && passwd "$USERNAME"
```

#### Set user as default

```powershell
wsl --manage archlinux --set-default-user username
```

## WSL configuration

### On windows machine

`.wslconfig`

```conf
[wsl2]
localhostForwarding=true
```

### On wsl distro

`/etc/wsl.conf`

```conf
[boot]
systemd=true

[interop]
enabled = true
appendWindowsPath = false
```
