# dotfiles

## Usage

### Prerequisites

- Install [nix](https://nixos.org/download)

```bash
nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs-unstable
nix-channel --update
```

### Install

- Clone repository

```bash
git clone https://github.com/csvenke/dotfiles.git ~/.dotfiles
```

- Run install script

```bash
nix-shell ~/.dotfiles/scripts/install.py
```

### Uninstall

- Run uninstall script

```bash
nix-shell ~/.dotfiles/scripts/uninstall.py
```

- Delete repository

```bash
rm -rf ~/.dotfiles
```

## Dotflakes

Included nix flakes for setting up development environments per project. They can be accessed through the `$DOTFLAKES` environment variable.

> Note: These are useful for projects where you cannot have the `flake.nix` and `flake.lock` in source control

From the terminal

```bash
nix develop path:$DOTFLAKES/python3
```

From `.envrc` file

> Note: As a security mechanism you have to run `direnv allow` once per change

```
use flake path:$DOTFLAKES/node
use flake path:$DOTFLAKES/dotnet
```
