{ inputs, pkgs, ... }:

let
  upstream = inputs.codex-desktop.packages.${pkgs.system}.codex-desktop;
in
upstream.overrideAttrs (old: {
  nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
    pkgs.asar
    pkgs.coreutils
    pkgs.findutils
    pkgs.nodejs
  ];

  postInstall = (old.postInstall or "") + ''
    app_dir="$out/opt/codex-desktop"
    resources_dir="$app_dir/resources"
    work_dir="$TMPDIR/codex-executor-plugin-permissions"
    extracted="$work_dir/app-extracted"
    ordering="$work_dir/app.asar.ordering"
    app_asar="$resources_dir/app.asar"

    mkdir -p "$work_dir"
    ${pkgs.asar}/bin/asar extract "$app_asar" "$extracted"
    if [ -d "$resources_dir/app.asar.unpacked" ]; then
      cp -a "$resources_dir/app.asar.unpacked/." "$extracted/"
    fi

    ${pkgs.nodejs}/bin/node ${./codex-desktop-executor-permissions.cjs} \
      "$extracted/.vite/build"

    (cd "$extracted" && find . -type f -printf '%P\n' | LC_ALL=C sort) > "$ordering"
    ${pkgs.asar}/bin/asar pack \
      "$extracted" \
      "$work_dir/app.asar" \
      --ordering "$ordering" \
      --unpack "{*.node,*.so,*.dylib}"
    mv "$work_dir/app.asar" "$app_asar"
    ${pkgs.nodejs}/bin/node ${./codex-desktop-executor-permissions.cjs} \
      --update-report "$app_dir/.codex-linux/patch-report.json" "$app_asar"
    if [ -d "$work_dir/app.asar.unpacked" ]; then
      rm -rf -- "$resources_dir/app.asar.unpacked"
      mv "$work_dir/app.asar.unpacked" "$resources_dir/app.asar.unpacked"
    fi
  '';
})
