{
  stdenv,
  fetchFromGitHub,
}:

stdenv.mkDerivation rec {
  pname = "ticket";
  version = "0.3.2";

  src = fetchFromGitHub {
    owner = "wedow";
    repo = "ticket";
    rev = "v${version}";
    hash = "sha256-orxqAwJBL+LHe+I9M+djYGa/yfvH67HdR/VVy8fdg90=";
  };

  dontBuild = true;

  installPhase = ''
    mkdir -p $out/bin
    cp ticket $out/bin/tk
    chmod +x $out/bin/tk
  '';

  meta = {
    description = "Minimal git-backed issue tracker for AI agents";
    homepage = "https://github.com/wedow/ticket";
  };
}
