# dotfiles

## Requirements

- [nix](https://nixos.org/download)

## Usage

```bash
nix run github:csvenke/dotfiles#bootstrap
```

Without flakes enabled

```bash
nix run github:csvenke/dotfiles#bootstrap --extra-experimental-features 'nix-command flakes'
```
