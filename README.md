# dotfiles

## Requirements

- Install zsh and [oh-my-zsh](https://ohmyz.sh/#install)
- Install [nix](https://nixos.org/download)
- Install [direnv](https://direnv.net/)

## Setup

Clone repository

```sh
git clone https://github.com/csvenke/dotfiles.git ~/.dotfiles
```

Run init script

```sh
nix-shell ~/.dotfiles --command dotfiles-init
```
