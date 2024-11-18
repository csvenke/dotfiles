{ inputs, ... }:

{
  home.activation = {
    vault =
      inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ]
        # bash
        ''
          mkdir -p $HOME/.vault
          touch $HOME/.vault/openai-api-key.txt
          touch $HOME/.vault/anthropic-api-key.txt
        '';
  };
}
