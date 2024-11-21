# dotfiles

## Requirements

- [nix](https://nixos.org/download)

## Usage

```bash
nix run github:csvenke/dotfiles#install
```

Without flakes enabled

```bash
nix run github:csvenke/dotfiles#install --extra-experimental-features 'nix-command flakes'
```
