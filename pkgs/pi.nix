{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  fetchurl,
  typescript-go,
  nix-update-script,
  versionCheckHook,
  writableTmpDirAsHomeHook,
  ripgrep,
  makeBinaryWrapper,
}:
buildNpmPackage (finalAttrs:
  let
    modelData = fetchurl {
      url = "https://registry.npmjs.org/@earendil-works/pi-ai/-/pi-ai-${finalAttrs.version}.tgz";
      hash = "sha512-4nV9JKc94iPX8bwdGPc2nTuVPKIPsffhnp3WoN9NYCNqbtoOF8LhYcIs/+Sn/alroqJK/5QRu6/Z6Ck+n0hyBA==";
    };
  in
  {
  pname = "pi-coding-agent";
  version = "0.99.1";
  src = fetchFromGitHub {
    owner = "earendil-works";
    repo = "pi";
    tag = "v${finalAttrs.version}";
    hash = "sha256-bLDEt1sKiS6ReQ6Uch0tOSLU8aykKl3UwN7WVkRE9Og=";
  };
  npmDepsHash = "sha256-eKtv1fN7X4ukuYbsj7hduGZ3W2FdmO/fAnoaWJp7MQQ=";
  # The GitHub source omits generated provider JSON; use the exact-version npm artifact.
  npmWorkspace = "packages/coding-agent";
  # Skip native module rebuild for unneeded workspaces (e.g. canvas from web-ui)
  npmRebuildFlags = [ "--ignore-scripts" ];
  nativeBuildInputs = [
    typescript-go
    makeBinaryWrapper
  ];
  # Build workspace dependencies in order, then the coding-agent.
  # Compile pi-ai directly to avoid its network-dependent model-data generator.
  # Generated provider JSON is supplied by the pinned npm artifact above.
  buildPhase = ''
    runHook preBuild
    # Hydrate the generated provider data from the pinned 0.99.1 pi-ai release.
    tar -xzf ${modelData} -C "$TMPDIR" package/dist/providers/data
    cp -r "$TMPDIR/package/dist/providers/data" packages/ai/src/providers/data
    npm run build --workspace=packages/chord
    tsgo -p packages/tui/tsconfig.build.json
    npm run build --workspace=packages/telemetry
    npm run build --workspace=packages/codemode
    npm run build --workspace=packages/mcp
    tsgo -p packages/ai/tsconfig.build.json
    tsgo -p packages/agent/tsconfig.build.json
    npm run build --workspace=packages/coding-agent
    runHook postBuild
  '';
  # npm workspace symlinks in the output point into packages/ which
  # doesn't exist there. Replace runtime deps with built content and
  # delete the rest.
  postInstall = ''
    local nm="$out/lib/node_modules/pi-monorepo/node_modules"
    # Replace workspace deps needed at runtime with real copies
    for ws in @earendil-works/pi-ai:packages/ai \
              @earendil-works/pi-agent-core:packages/agent \
              @earendil-works/pi-tui:packages/tui \
              @earendil-works/pi-telemetry:packages/telemetry \
              @earendil-works/chord:packages/chord \
              @earendil-works/pi-codemode:packages/codemode \
              @earendil-works/pi-mcp:packages/mcp; do
      IFS=: read -r pkg src <<< "$ws"
      rm "$nm/$pkg"
      cp -r "$src" "$nm/$pkg"
    done
    # Delete remaining workspace symlinks
    find "$nm" -type l -lname '*/packages/*' -delete
    # Clean up now-dangling .bin symlinks
    find "$nm/.bin" -type l ! -exec test -e {} \; -delete
  '';
  postFixup = "wrapProgram $out/bin/pi --prefix PATH : ${lib.makeBinPath [ ripgrep ]}";
  doInstallCheck = true;
  nativeInstallCheckInputs = [
    writableTmpDirAsHomeHook
    versionCheckHook
  ];
  versionCheckKeepEnvironment = [ "HOME" ];
  versionCheckProgram = "${placeholder "out"}/bin/pi";
  versionCheckProgramArg = "--version";
  passthru.updateScript = nix-update-script { };
  meta = {
    description = "Coding agent CLI with read, bash, edit, write tools and session management";
    homepage = "https://pi.dev/";
    downloadPage = "https://www.npmjs.com/package/@earendil-works/pi-coding-agent";
    changelog = "https://github.com/earendil-works/pi/blob/main/packages/coding-agent/CHANGELOG.md";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ munksgaard ];
    mainProgram = "pi";
  };
})