# dotfiles

## Requirements

- Install zsh and [oh-my-zsh](https://ohmyz.sh/#install)
- Install [nix](https://nixos.org/download)
- Install [direnv](https://direnv.net/)

```sh
echo "use nix" > .envrc && direnv allow .
```

## Setup

Clone repository

```sh
git clone https://github.com/csvenke/dotfiles.git ~/.dotfiles
```

Run link script

```sh
nix-shell ~/.dotfiles --command dotfiles-link
```
