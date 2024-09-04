# dotfiles

## Requirements

- [nix](https://nixos.org/download)

## Usage

```bash
nix run github:csvenke/dotfiles#install
```

If you dont have flakes enabled

```bash
nix run --extra-experimental-features 'nix-command flakes' github:csvenke/dotfiles#install
```
