{ lib, writeShellApplication, nix, projectDir ? "/home/zarred/dev/nanobot" }:

writeShellApplication {
  name = "nanobot";
  runtimeInputs = [ nix ];
  text = ''
    project_dir=${lib.escapeShellArg projectDir}

    if [ ! -d "$project_dir" ]; then
      echo "nanobot checkout not found at $project_dir" >&2
      exit 1
    fi

    if [ ! -f "$project_dir/shell.nix" ]; then
      echo "nanobot shell not found at $project_dir/shell.nix" >&2
      exit 1
    fi

    cd "$project_dir"

    if [ "$#" -eq 0 ]; then
      exec ${nix}/bin/nix-shell "$project_dir/shell.nix" \
        --run "exec .venv/bin/nanobot"
    fi

    args_escaped="$(printf '%q ' "$@")"

    exec ${nix}/bin/nix-shell "$project_dir/shell.nix" \
      --run "exec .venv/bin/nanobot ''${args_escaped}"
  '';
  meta = {
    description = "Wrapper for the local nanobot checkout";
    mainProgram = "nanobot";
    platforms = lib.platforms.linux;
  };
}
