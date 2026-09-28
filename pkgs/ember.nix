{ lib, runCommand, projectDir ? "/home/zarred/dev/ember" }:

runCommand "ember-cli-link" {
  meta = {
    description = "Link to the locally built Ember CLI";
    mainProgram = "ember";
    platforms = lib.platforms.linux;
  };
} ''
  mkdir -p "$out/bin"
  ln -s ${lib.escapeShellArg "${projectDir}/dist/src/app/main.js"} "$out/bin/ember"
''
