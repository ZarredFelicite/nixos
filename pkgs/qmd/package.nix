{
  stdenv,
  lib,
  fetchFromGitHub,
  bun,
  nodejs,
  cudaPackages,
  python3,
  cmake,
  git,
  gnumake,
  node-gyp,
  typescript,
  sqlite,
  runCommand,
}:
let
  pin = lib.importJSON ./pin.json;
  src = fetchFromGitHub {
    owner = "tobi";
    repo = "qmd";
    rev = pin.rev;
    hash = pin.srcHash;
  };

  # Step 1: FOD — download node_modules without running lifecycle scripts.
  # No patchShebangs, no native builds, so the output is deterministic and
  # won't contain any store-path references (safe for Nix 2.33+ FODs).
  node_modules_raw = stdenv.mkDerivation {
    pname = "qmd-node_modules-raw";
    inherit src;
    version = pin.version;
    impureEnvVars = lib.fetchers.proxyImpureEnvVars ++ [
      "GIT_PROXY_COMMAND"
      "SOCKS_SERVER"
    ];
    nativeBuildInputs = [ bun ];
    dontConfigure = true;
    buildPhase = ''
      export HOME=$(mktemp -d)
      bun install --no-progress --frozen-lockfile --ignore-scripts
    '';
    installPhase = ''
      mkdir -p $out/node_modules
      cp -R ./node_modules $out
    '';
    dontPatchShebangs = true;
    dontFixup = true;
    outputHash = pin."${stdenv.system}";
    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
  };

  # Step 2: Normal derivation — patch shebangs and rebuild native addons.
  # This is NOT a FOD, so it can contain store-path references freely.
  node_modules = stdenv.mkDerivation {
    pname = "qmd-node_modules";
    version = pin.version;
    dontUnpack = true;
    dontConfigure = true;

    nativeBuildInputs = [ nodejs python3 gnumake node-gyp ];

    buildPhase = ''
      # Copy the raw node_modules so we can modify them
      cp -R ${node_modules_raw}/node_modules ./node_modules
      chmod -R u+w node_modules

      # Fix shebangs so lifecycle/rebuild scripts can find interpreters
      patchShebangs node_modules

      # node-llama-cpp defaults to writing local builds under its own module
      # directory, which is read-only in the Nix store at runtime.
      substituteInPlace node_modules/node-llama-cpp/dist/config.js \
        --replace-fail \
        'export const llamaDirectory = path.join(__dirname, "..", "llama");' \
        'export const llamaDirectory = env.get("NODE_LLAMA_CPP_LLAMA_DIR").default(path.join(__dirname, "..", "llama")).asString();'

      substituteInPlace node_modules/node-llama-cpp/package.json \
        --replace-fail \
        '"cmake-js-llama": "cd llama && cmake-js",' \
        '"cmake-js-llama": "cd ''${NODE_LLAMA_CPP_LLAMA_DIR:-llama} && cmake-js",'

      # Rebuild native addons (better-sqlite3, etc.)
      export HOME=$(mktemp -d)
      export npm_config_nodedir=${nodejs}
      cd node_modules/better-sqlite3
      node-gyp rebuild
      cd ../..
    '';

    installPhase = ''
      mkdir -p $out
      cp -R node_modules $out/
    '';
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "qmd";
  version = pin.version;
  inherit src;

  nativeBuildInputs = [ typescript ];
  buildInputs = [ sqlite nodejs ];

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild

    ln -s ${node_modules}/node_modules ./node_modules

    tsc -p tsconfig.build.json

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/qmd
    mkdir -p $out/bin

    ln -s ${node_modules}/node_modules $out/lib/qmd/node_modules
    cp -r dist $out/lib/qmd/
    cp package.json $out/lib/qmd/

    cat > $out/bin/qmd <<EOF
    #!${stdenv.shell}
    set -e

    export NODE_LLAMA_CPP_LLAMA_DIR="''${XDG_CACHE_HOME:-\$HOME/.cache}/node-llama-cpp/llama"
    export NODE_LLAMA_CPP_GPU="''${NODE_LLAMA_CPP_GPU:-cuda}"
    export CUDAToolkit_ROOT="${cudaPackages.cudatoolkit}"
    export CUDA_PATH="${cudaPackages.cudatoolkit}"
    export CPATH="${cudaPackages.cudatoolkit}/include:${cudaPackages.cuda_cudart}/include:''${CPATH:-}"
    export CPLUS_INCLUDE_PATH="${cudaPackages.cudatoolkit}/include:${cudaPackages.cuda_cudart}/include:''${CPLUS_INCLUDE_PATH:-}"
    export LIBRARY_PATH="${cudaPackages.cudatoolkit}/lib:${cudaPackages.cudatoolkit}/lib64:''${LIBRARY_PATH:-}"
    if [ ! -f "\$NODE_LLAMA_CPP_LLAMA_DIR/binariesGithubRelease.json" ]; then
      mkdir -p "\$(dirname "\$NODE_LLAMA_CPP_LLAMA_DIR")"
      cp -r "$out/lib/qmd/node_modules/node-llama-cpp/llama" "\$NODE_LLAMA_CPP_LLAMA_DIR"
    fi
    chmod -R u+w "\$NODE_LLAMA_CPP_LLAMA_DIR" 2>/dev/null || true

    export DYLD_LIBRARY_PATH="${sqlite.out}/lib"
    # Prefer the real NVIDIA driver libs over CUDA toolkit stubs.
    if [ -e /run/opengl-driver/lib/libcuda.so.1 ]; then
      export LD_PRELOAD="/run/opengl-driver/lib/libcuda.so.1''${LD_PRELOAD:+ ''${LD_PRELOAD}}"
    fi
    export LD_LIBRARY_PATH="/run/opengl-driver/lib:${sqlite.out}/lib:${cudaPackages.cudatoolkit}/lib:${cudaPackages.cudatoolkit}/lib64:''${LD_LIBRARY_PATH:-}"
    export NODE_PATH="$out/lib/qmd/node_modules"
    export PATH="${lib.makeBinPath [ stdenv.cc gnumake cmake git python3 node-gyp cudaPackages.cudatoolkit ]}:\$PATH"

    exec ${nodejs}/bin/node "$out/lib/qmd/dist/qmd.js" "\$@"
    EOF
    chmod +x $out/bin/qmd

    runHook postInstall
  '';

  passthru.tests.version = runCommand "qmd-test" { } ''
    ${lib.getExe finalAttrs.finalPackage} --help > $out
    grep -q "qmd collection add" $out
  '';

  meta = {
    description = "On-device search engine for markdown notes and knowledge bases";
    homepage = "https://github.com/tobi/qmd";
    license = lib.licenses.mit;
    mainProgram = "qmd";
    platforms = lib.platforms.unix;
  };
})
