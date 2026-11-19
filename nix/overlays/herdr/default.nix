final: prev:

let
  inherit (prev)
    lib
    jq
    coreutils
    symlinkJoin
    writeShellApplication
    writeShellScript
    writeTextDir
    ;

  herdr-dev-open = writeShellApplication {
    name = "herdr-dev-open";
    runtimeInputs = [ jq ];
    text = lib.readFile ./plugins/dev/open.sh;
  };

  herdr-dev-agent-tab = writeShellApplication {
    name = "herdr-dev-agent-tab";
    runtimeInputs = [ jq ];
    text = lib.readFile ./plugins/dev/agent-tab.sh;
  };

  herdr-dev-home = writeShellApplication {
    name = "herdr-dev-home";
    runtimeInputs = [
      jq
      coreutils
      herdr-dev-open
    ];
    text = lib.readFile ./plugins/dev/home.sh;
  };

  herdr-dev-picker = writeShellScript "herdr-dev-picker" ''
    exec "$HERDR_BIN_PATH" plugin pane open --plugin csvenke.dev --entrypoint picker
  '';

  devPlugin = writeTextDir "share/herdr/plugins/dev/herdr-plugin.toml" /* toml */ ''
    id = "csvenke.dev"
    name = "dev"
    version = "0.2.0"
    min_herdr_version = "0.9.0"
    description = "Open projects as workspaces and name tabs after running agents"
    platforms = ["linux", "macos"]

    [[actions]]
    id = "open"
    title = "Open project"
    contexts = ["workspace"]
    command = ["${herdr-dev-picker}"]

    [[actions]]
    id = "home"
    title = "Open home project"
    contexts = ["workspace"]
    command = ["${lib.getExe herdr-dev-open}", "--home"]

    [[panes]]
    id = "picker"
    title = "Open project"
    placement = "popup"
    width = 90
    height = 28
    command = ["${lib.getExe herdr-dev-open}"]

    [[events]]
    on = "pane.agent_detected"
    command = ["${lib.getExe herdr-dev-agent-tab}"]

    [[events]]
    on = "tab.closed"
    command = ["${lib.getExe herdr-dev-agent-tab}"]
  '';

  pluginDirs = [ "${devPlugin}/share/herdr/plugins/dev" ];

  wrapper = writeShellScript "herdr" ''
    herdr=${lib.getExe prev.herdr}
    if [ "$#" -eq 0 ]; then
      fresh=1
      if "$herdr" status server 2>/dev/null | grep -q '^status: running'; then
        fresh=
      fi
      for plugin in ${lib.escapeShellArgs pluginDirs}; do
        "$herdr" plugin link "$plugin" >/dev/null 2>&1 || true
      done
      if [ -n "$fresh" ]; then
        HERDR_BIN_PATH="$herdr" ${lib.getExe herdr-dev-home} </dev/null >/dev/null 2>&1 &
        disown
      fi
    fi
    exec "$herdr" "$@"
  '';
in
{
  herdr = symlinkJoin {
    name = "herdr-wrapped";
    paths = [ prev.herdr ];
    postBuild = ''
      rm $out/bin/herdr
      cp ${wrapper} $out/bin/herdr
    '';
    meta.mainProgram = "herdr";
  };
}
