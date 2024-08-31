{ pkgs }:

let
  git-main-branch = pkgs.writeShellApplication {
    name = "git-main-branch";
    runtimeInputs = with pkgs; [ git ];
    text = ''
      git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'
    '';
  };

  git-all-branches = pkgs.writeShellApplication {
    name = "git-all-branches";
    runtimeInputs = with pkgs; [ git git-main-branch ];
    text = ''
      git branch -a |
        sed "s@*@@g" |
        sed "s@ @@g" |
        sed "s@remotes/origin/@@g" |
        sed "s@HEAD->origin/$(git-main-branch)@@g" |
        sed "/^$/d" |
        sort |
        uniq
    '';
  };

  git-find-branch = pkgs.writeShellApplication {
    name = "gfb";
    runtimeInputs = with pkgs; [ git-all-branches fzf xclip ];
    text = ''
      git-all-branches | fzf | xclip -selection clipboard
    '';
  };

  git-push-current-branch = pkgs.writeShellApplication {
    name = "gpb";
    runtimeInputs = with pkgs; [ git ];
    text = ''
      git push origin "$(git branch --show-current)" -- "$@"
    '';
  };

  git-sync-current-branch = pkgs.writeShellApplication {
    name = "gsb";
    runtimeInputs = with pkgs; [ git ];
    text = ''
      git pull origin "$(git branch --show-current)"
    '';
  };

  git-sync-main-branch = pkgs.writeShellApplication {
    name = "gsm";
    runtimeInputs = with pkgs; [ git git-main-branch ];
    text = ''
      git pull origin "$(git-main-branch)"
    '';
  };

  git-checkout-main-branch = pkgs.writeShellApplication {
    name = "gcm";
    runtimeInputs = with pkgs; [ git git-main-branch ];
    text = ''
      git checkout "$(git-main-branch)"
    '';
  };

  git-checkout-branch = pkgs.writeShellApplication {
    name = "gcb";
    runtimeInputs = with pkgs; [ git-all-branches fzf ];
    text = ''
      git-all-branches | fzf | xargs git checkout
    '';
  };

  git-ui = pkgs.writeShellApplication {
    name = "gui";
    runtimeInputs = with pkgs; [ lazygit ];
    text = ''
      lazygit
    '';
  };
in

pkgs.symlinkJoin {
  name = "git-packages";
  paths = [
    pkgs.git
    git-find-branch
    git-checkout-branch
    git-push-current-branch
    git-sync-current-branch
    git-sync-main-branch
    git-checkout-main-branch
    git-ui
  ];
}
