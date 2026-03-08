# dotfiles

## Requirements

- [nix](https://nixos.org/download)

## Usage

```bash
nix run github:csvenke/dotfiles#sync
```

Without flakes enabled

```bash
nix run github:csvenke/dotfiles#sync --extra-experimental-features 'nix-command flakes'
```
