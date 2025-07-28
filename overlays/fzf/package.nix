{
  fzf,
  fetchFromGitHub,
  stdenv,
}:

let
  fzf-tab-completion = stdenv.mkDerivation rec {
    pname = "fzf-tab-completion";
    version = "4850357beac6f8e37b66bd78ccf90008ea3de40b";
    src = fetchFromGitHub {
      owner = "lincheney";
      repo = pname;
      rev = version;
      sha256 = "sha256-pgcrRRbZaLoChVPeOvw4jjdDCokUK1ew0Wfy42bXfQo=";
    };
    installPhase = ''
      mkdir -p $out/share/fzf-tab-completion/
      cp -r bash/* $out/share/fzf-tab-completion/
    '';
    meta.homepage = "https://github.com/lincheney/fzf-tab-completion";
  };
in

fzf.overrideAttrs (oldAttrs: {
  postPatch =
    (oldAttrs.postPatch or "")
    # bash
    + ''
      echo "" >> shell/completion.bash
      echo "# Load fzf-tab-completion enhancement" >> shell/completion.bash
      echo "source ${fzf-tab-completion}/share/fzf-tab-completion/fzf-bash-completion.sh" >> shell/completion.bash
      echo "bind -x '\"\\t\": fzf_bash_completion'" >> shell/completion.bash
    '';
})
