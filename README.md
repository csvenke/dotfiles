# dotfiles

## Usage

### Prerequisites

- Install [nix](https://nixos.org/download)
- Install zsh
- Install [oh-my-zsh](https://ohmyz.sh/#install)

### Install

- Clone repository

```sh
git clone https://github.com/csvenke/dotfiles.git ~/.dotfiles
```

- Run install script

```sh
nix-shell ~/.dotfiles/scripts/install.sh
```

### Uninstall

- Run uninstall script

```sh
nix-shell ~/.dotfiles/scripts/uninstall.sh
```

- Delete repository

```sh
rm -rf ~/.dotfiles
```
