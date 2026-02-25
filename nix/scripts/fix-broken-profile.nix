{
  writeShellApplication,
  nix,
}:

writeShellApplication {
  name = "fix-broken-profile";
  runtimeInputs = [
    nix
  ];
  text = ''
    DOTFILES_PATH="$HOME/.config/dotfiles"

    nix-collect-garbage -d
    rm ~/.local/state/nix/profiles/profile*
    rm ~/.nix-profile
    nix profile add "$DOTFILES_PATH"
    nix profile list
  '';
}
