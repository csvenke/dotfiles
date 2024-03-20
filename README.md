# dotfiles

## Usage

### Prerequisites

- Install [nix](https://nixos.org/download)

### Install

- Clone repository

```bash
git clone https://github.com/csvenke/dotfiles.git ~/.dotfiles
```

- Run install script

```bash
nix-shell ~/.dotfiles/scripts/install.py
```

### Uninstall

- Run uninstall script

```bash
nix-shell ~/.dotfiles/scripts/uninstall.py
```

- Delete repository

```bash
rm -rf ~/.dotfiles
```
