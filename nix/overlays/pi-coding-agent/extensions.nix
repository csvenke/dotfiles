# Pi extensions bundled into pi-coding-agent, fetched from the npm registry.
#
#   pname, version, hash   npm package identity and tarball hash (required)
#   files                  paths to copy out of the tarball (required)
#   description, homepage  meta attributes (required)
#   license                meta.license (optional, defaults to MIT)
#   deps                   runtime deps vendored into node_modules (optional)
[
  {
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
  }

  {
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
  }

  {
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
  }
]
