# dotfiles

## Requirements

- Install zsh and [oh-my-zsh](https://ohmyz.sh/#install)
- Install [nix](https://nixos.org/download)

## Installing

Clone repository

```sh
git clone https://github.com/csvenke/dotfiles.git ~/.dotfiles
```

Run install script

```sh
nix-shell ~/.dotfiles/scripts/install.sh
```

## Removing

Run remove script

```sh
nix-shell ~/.dotfiles/scripts/remove.sh
```

Delete repository

```sh
rm -rf .dotfiles
```
