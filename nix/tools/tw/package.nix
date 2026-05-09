{ lib, buildGoModule }:

buildGoModule rec {
  pname = "tw";
  version = "0.1.0";

  src = ./.;

  vendorHash = "sha256-hocnLCzWN8srQcO3BMNkd2lt0m54Qe7sqAhUxVZlz1k=";

  meta = {
    description = "Team workflow CLI for AI agent orchestration";
    mainProgram = "tw";
  };
}
