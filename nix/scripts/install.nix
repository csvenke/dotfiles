{
  writeShellApplication,
  stow,
  git,
  nix,
}:

writeShellApplication {
  name = "install";
  runtimeInputs = [
    stow
    git
    nix
  ];
  text = ''
    migrate_dotfiles_path_to_xdg_config_v1() {
      local new="$1"
      local old="$HOME/.dotfiles"

      if [[ ! -d "$old" && -d "$new" ]]; then
        return
      fi

      stow -v --dir="$old/home" --target="$HOME" --delete .
      mv "$old" "$new"
      nix profile remove dotfiles
    }

    DOTFILES_URL="https://github.com/csvenke/dotfiles.git"
    DOTFILES_BRANCH="master"
    DOTFILES_PATH="$HOME/.config/dotfiles"

    migrate_dotfiles_path_to_xdg_config_v1 "$DOTFILES_PATH"

    if [ ! -d "$DOTFILES_PATH" ]; then
      git clone "$DOTFILES_URL" "$DOTFILES_PATH"
    else
      git -C "$DOTFILES_PATH" pull origin "$DOTFILES_BRANCH"
    fi

    stow -v --dir="$DOTFILES_PATH/home" --target="$HOME" --adopt --restow .
    nix profile add "$DOTFILES_PATH"
    nix profile upgrade --all
    nix profile wipe-history --older-than 7d
  '';
}
