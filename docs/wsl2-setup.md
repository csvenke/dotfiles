# WSL2 setup

- [Ubuntu](#ubuntu)
- [Arch Linux](#arch-linux)

## Ubuntu

### Install distro

```powershell
wsl --install ubuntu
```

## Arch Linux

### Install distro

```powershell
wsl --install archlinux
```

### Setup distro (as root)

Update system packages

```bash
pacman -Syu --noconfirm
```

Setup locale

```bash
export LANG=en_US.UTF-8 && sed -i "s/#${LANG}/${LANG}/" /etc/locale.gen && locale-gen && echo "LANG=${LANG}" > /etc/locale.conf
```

Setup sudo

```bash
pacman -S sudo vi --noconfirm && echo "root ALL=(ALL:ALL) ALL" > /etc/sudoers && echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers
```

Setup user (replace username)

```bash
USERNAME="username" && useradd -m -G wheel -s /bin/bash "$USERNAME" && passwd "$USERNAME"
```

### Set user as default

```powershell
wsl --manage archlinux --set-default-user username
```
