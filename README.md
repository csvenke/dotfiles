# dotfiles

## Requirements

- [nix](https://nixos.org/download)

## Install

```bash
nix run github:csvenke/dotfiles#bootstrap
```

Without flakes enabled:

```bash
nix --extra-experimental-features 'nix-command flakes' run github:csvenke/dotfiles#bootstrap
```
