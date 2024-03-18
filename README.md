# dotfiles

## Usage

### Prerequisites

- Install zsh and [oh-my-zsh](https://ohmyz.sh/#install)
- Install [nix](https://nixos.org/download)

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
rm -rf .dotfiles
```
