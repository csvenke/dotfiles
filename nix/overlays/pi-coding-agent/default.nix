final: prev:

let
  inherit (prev)
    lib
    fetchurl
    stdenvNoCC
    symlinkJoin
    makeWrapper
    ;

  mkPiExtension =
    {
      pname,
      version,
      hash,
      files,
      description,
      homepage,
      license ? lib.licenses.mit,
      deps ? [ ],
    }:
    let
      depSrcs = map (
        dep:
        dep
        // {
          src = fetchurl {
            url = "https://registry.npmjs.org/${dep.pname}/-/${lib.last (lib.splitString "/" dep.pname)}-${dep.version}.tgz";
            inherit (dep) hash;
          };
        }
      ) deps;
    in
    stdenvNoCC.mkDerivation {
      inherit pname version;

      src = fetchurl {
        url = "https://registry.npmjs.org/${pname}/-/${pname}-${version}.tgz";
        inherit hash;
      };

      sourceRoot = "package";

      installPhase = ''
        runHook preInstall
        mkdir -p $out
        cp -r ${lib.concatStringsSep " " files} $out/
        ${lib.concatMapStringsSep "\n" (dep: ''
          dep_tmp=$(mktemp -d)
          tar -xzf ${dep.src} -C "$dep_tmp"
          mkdir -p "$out/node_modules/$(dirname "${dep.pname}")"
          cp -r "$dep_tmp/package" "$out/node_modules/${dep.pname}"
          rm -rf "$dep_tmp"
        '') depSrcs}
        runHook postInstall
      '';

      meta = {
        inherit description homepage license;
      };
    };

  pi-direnv = mkPiExtension {
    pname = "pi-direnv";
    version = "0.1.0";
    hash = "sha512-N+njfllbcKvd5qbtSMS1nP5QTSaqVZSmo8gQk8TCgWefPQidcg+FG6cY79HIJggS9RiI4FjhGyhVX8DY9kcuIA==";
    files = [
      "package.json"
      "index.ts"
      "README.md"
    ];
    description = "Auto-load direnv environment at pi session start";
    homepage = "https://github.com/edmundmiller/dotfiles/tree/main/pi-packages/pi-direnv";
  };

  pi-goal-x = mkPiExtension {
    pname = "pi-goal-x";
    version = "0.32.3";
    hash = "sha512-Jip/7p+yuOx/+ckV6IQDr+WhlVvXVw16aR9HMWadc5itciABHdt4HU0Gi3pJU7gJdnB1W3yjdcq6hMwVo/6YIw==";
    files = [
      "package.json"
      "README.md"
      "extensions"
    ];
    description = "Adds /goal to pi: conversational goal planning, persistent progress, and a completion auditor";
    homepage = "https://github.com/tmonk/pi-goal-x";
  };

  pi-subagents = mkPiExtension {
    pname = "pi-subagents";
    version = "0.76.0";
    hash = "sha512-r1uoi43ysqbi2MJOGAnJWMbF3o2xBwaWI7/pwJHgGaenv/JqGEmtt5YHYWoq8JRvlhVCquTnrtFeB7e0apLlOQ==";
    files = [
      "package.json"
      "README.md"
      "LICENSE"
      "index.js"
      "src"
      "skills"
      "prompts"
      "agents"
      "inspector-runner.mjs"
      "async-retention-discovery-worker.mjs"
      "runner-peer-loader.mjs"
      "runner-peer-preload.mjs"
    ];
    deps = [
      {
        pname = "jiti";
        version = "2.7.0";
        hash = "sha512-AC/7JofJvZGrrneWNaEnJeOLUx+JlGt7tNa0wZiRPT4MY1wmfKjt2+6O2p2uz2+skll8OZZmJMNqeke7kKbNgQ==";
      }
      {
        pname = "yaml";
        version = "2.8.3";
        hash = "sha512-AvbaCLOO2Otw/lW5bmh9d/WEdcDFdQp2Z2ZUH3pX9U2ihyUY0nvLv7J6TrWowklRGPYbB/IuIMfYgxaCPg5Bpg==";
      }
      {
        pname = "acorn";
        version = "8.18.0";
        hash = "sha512-lGq+9yr1/GuAWaVYIHRjvvySG5/4VfKIvC8EWxStPdcDh/Ka7FG3twP6v4d5BkravUilhIAsG4Qj83t02LWUPQ==";
      }
      {
        pname = "undici";
        version = "8.10.2";
        hash = "sha512-/y4/bH9YNU5hi9NIrpOuvGXFcxrj3CMrV+/AYpowAYTpHn8gX/XPFjNy766FPoYY0miQhdW977JFWKGNhBdwyQ==";
      }
      {
        pname = "@js-temporal/polyfill";
        version = "0.5.1";
        hash = "sha512-hloP58zRVCRSpgDxmqCWJNlizAlUgJFqG2ypq79DCvyv9tHjRYMDOcPFjzfl/A1/YxDvRCZz8wvZvmapQnKwFQ==";
      }
      {
        pname = "jsbi";
        version = "4.3.2";
        hash = "sha512-9fqMSQbhJykSeii05nxKl4m6Eqn2P6rOlYiS+C5Dr/HPIU/7yZxu5qzbs40tgaFORiw2Amd0mirjxatXYMkIew==";
      }
    ];
    description = "Pi extension for single-agent delegation and scripted multi-agent workflows";
    homepage = "https://github.com/nicobailon/pi-subagents";
  };

  pi-web-access =
    let
      version = "0.37.0";
      nodeModules = prev.importNpmLock.buildNodeModules {
        npmRoot = ./pi-web-access;
        nodejs = prev.nodejs;
      };
    in
    stdenvNoCC.mkDerivation {
      inherit version;
      pname = "pi-web-access";

      src = fetchurl {
        url = "https://registry.npmjs.org/pi-web-access/-/pi-web-access-${version}.tgz";
        hash = "sha512-Je7D5ghQi9dpN0KhpFMuHYwKy0oBvpNrNR7zuTzSyCRsIJDC5in8yGz/3yItxvWYHF1W+q2Sq190nyaLkoWhgg==";
      };

      sourceRoot = "package";

      installPhase = ''
        runHook preInstall
        mkdir -p $out
        cp -r package.json dist README.md LICENSE $out/
        cp -rL ${nodeModules}/node_modules $out/node_modules
        runHook postInstall
      '';

      meta = {
        description = "Web search, URL fetching, GitHub repo cloning, PDF extraction, and YouTube/video understanding for pi";
        homepage = "https://github.com/nicobailon/pi-web-access";
        license = lib.licenses.mit;
      };
    };

  piExtensions = [
    pi-direnv
    pi-goal-x
    pi-subagents
    pi-web-access
  ];

  pi-latest = prev.pi-coding-agent.overrideAttrs (old: rec {
    version = "1.0.3";

    src = prev.fetchFromGitHub {
      owner = "earendil-works";
      repo = "pi";
      tag = "v${version}";
      hash = "sha256-2SfC8zEf6emG1sDG1J7hjjSBt+3hFIz1/TcwBLa/hRU=";
    };

    npmDeps = prev.fetchNpmDeps {
      inherit src;
      name = "pi-coding-agent-${version}-npm-deps";
      hash = "sha256-SpbadDFtPdwn+H2TXDl1TGAI+ejb6dbRvALZoUIvx3c=";
    };

    modelData = prev.fetchurl {
      url = "https://registry.npmjs.org/@earendil-works/pi-ai/-/pi-ai-${version}.tgz";
      hash = "sha256-3YmV+x3zyj4r0DMFO9LCi0DES7f1PCU1eMpoCCYR4O4=";
    };
  });
in
{
  pi-coding-agent = symlinkJoin {
    name = "pi-coding-agent-with-extensions-${pi-latest.version}";
    paths = [ pi-latest ];
    nativeBuildInputs = [ makeWrapper ];
    postBuild = ''
      rm $out/bin/pi
      makeWrapper ${lib.getExe pi-latest} $out/bin/pi \
        ${lib.concatMapStringsSep " \\\n          " (
          ext: ''--add-flags "--extension ${ext}"''
        ) piExtensions}
    '';
    meta = pi-latest.meta // {
      description = "pi-coding-agent with bundled extensions";
    };
  };
}
