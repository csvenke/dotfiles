{ lib
, buildGoModule
, git
}:

buildGoModule {
  pname = "llm";
  version = "0.1.0";

  src = ./.;

  vendorHash = "sha256-ndmKEpYC1YtcLuVxB7OnilLYBGDyVrroHforpG8fuUA=";

  ldflags = [
    "-s"
    "-w"
    "-X main.version=0.1.0"
  ];

  nativeBuildInputs = [ git ];

  meta = with lib; {
    description = "AI-powered commit message generator";
    license = licenses.mit;
  };
}
