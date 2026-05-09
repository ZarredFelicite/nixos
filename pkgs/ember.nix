{ lib, writeShellApplication, nodejs, projectDir ? "/home/zarred/dev/ember" }:

writeShellApplication {
  name = "ember";
  runtimeInputs = [ nodejs ];
  text = ''
    project_dir=${lib.escapeShellArg projectDir}

    if [ ! -d "$project_dir" ]; then
      echo "Ember checkout not found at $project_dir" >&2
      exit 1
    fi

    if [ ! -f "$project_dir/package.json" ]; then
      echo "Ember package.json not found at $project_dir/package.json" >&2
      exit 1
    fi

    if [ ! -d "$project_dir/node_modules" ]; then
      echo "Ember dependencies not found at $project_dir/node_modules; run npm install" >&2
      exit 1
    fi

    cd "$project_dir"

    exec npm run dev -- "$@"
  '';
  meta = {
    description = "Wrapper for the local Ember checkout";
    mainProgram = "ember";
    platforms = lib.platforms.linux;
  };
}
